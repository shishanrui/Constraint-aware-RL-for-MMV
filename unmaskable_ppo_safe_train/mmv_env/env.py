"""
PMV-based MMV environment.

- input_data.csv is hourly (8760 rows/year)
- RL control step is 10 minutes (DT_CONTROL_S=600)
- occ/hea: sample-and-hold hourly
- wind: from FMU weather bus
- rain: from CSV, linearly interpolated within the hour
- PMV is computed in Python from TRoo, RhRoo, and effective indoor air speed
"""

from __future__ import annotations

import random
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import gymnasium as gym
import numpy as np
import pandas as pd
from gymnasium import spaces
from gymnasium.utils import seeding

from .airflow_model import AirSpeedModelConfig, CombinedAirSpeedModel
from .fan_controller import CeilingFanController
from .features import FeatureBuilder
from .fmu_backend import FMUBackend, FMUBackendConfig
from .reward import RewardCalculator
from .safety import SafetyShield
from .signals import (
    ACTION_SPACE_NVECS,
    CO2_SETPOINT_PPM,
    CSV_COL_DATETIME,
    CSV_COL_HEA,
    CSV_COL_OCC,
    CSV_COL_RAIN,
    DT_COMM_S,
    DT_CONTROL_S,
    FMU_FILENAME,
    IN_CO2_SET,
    IN_HEA_FRA,
    IN_OCC_FRA,
    IN_SYS_ON,
    IN_TROO_SET,
    IN_WIN_OPE,
    INPUT_DATA_CSV,
    MIN_AC_ON_S,
    MODE_AC,
    MODE_NV,
    MODE_OFF,
    OCC_ON_THRESHOLD,
    OUT_CO2,
    OUT_P_ASHP,
    OUT_P_FAN_RET,
    OUT_P_FAN_SUP,
    OUT_RH_ROO,
    OUT_TROO,
    OUT_WIN_OPE_MASS_FLOW,
    RULE_BASED_FAN_MAX_CMD,
    T_WC_K,
    WEA_TDRYBUL,
    WEA_WIN_SPE,
    WIND_LIMIT_M_S,
    WINDOW_COLD_LIMIT_ENABLED,
    decode_ac_setpoint_index,
    decode_action,
)


EPISODE_DAYS = 7
CONTROL_STEPS_PER_HOUR = int(3600 // DT_CONTROL_S)
EPISODE_HOURS = EPISODE_DAYS * 24
WARMUP_HOURS = 7 * 24

EPISODE_STEPS = EPISODE_HOURS * CONTROL_STEPS_PER_HOUR
WARMUP_STEPS = WARMUP_HOURS * CONTROL_STEPS_PER_HOUR


class MMVEnv(gym.Env):
    metadata = {"render_modes": []}

    def __init__(
        self,
        month: Optional[int] = None,
        w_energy: float = 1.0,
        w_pmv: float = 1.0,
        w_invalid_request: float = 0.10,
        seed: Optional[int] = None,
        w_switch: float = 0.02,
        nv_bonus_beta: float = 0.10,
        nv_bonus_unocc_beta: float = 0.05,
        w_nv_unbenefit: float = 0.01,
        w_sp_jump: float = 0.05,
        default_ac_sp_c: float = 26.0,
        dt_comm_s: float = DT_COMM_S,
    ):
        super().__init__()
        self.month = month
        self.rng = random.Random(seed)
        self.default_ac_sp_k = float(default_ac_sp_c) + 273.15
        self.dt_comm_s = float(dt_comm_s)

        self.df = pd.read_csv(INPUT_DATA_CSV, parse_dates=[CSV_COL_DATETIME])

        self.backend = FMUBackend(
            FMUBackendConfig(
                fmu_path=FMU_FILENAME,
                dt_comm_s=self.dt_comm_s,
                fmi_logging_on=False,
                quiet_stderr_during_step=True,
                unzip_root_dir=str(Path(FMU_FILENAME).resolve().parent / ".fmu_extract"),
            )
        )
        self.backend.load()
        self.backend.require_vars(
            [
                IN_TROO_SET,
                IN_CO2_SET,
                IN_SYS_ON,
                IN_WIN_OPE,
                IN_HEA_FRA,
                IN_OCC_FRA,
                OUT_TROO,
                OUT_CO2,
                OUT_P_ASHP,
                OUT_P_FAN_SUP,
                OUT_P_FAN_RET,
                OUT_RH_ROO,
                OUT_WIN_OPE_MASS_FLOW,
                WEA_TDRYBUL,
                WEA_WIN_SPE,
            ]
        )

        self.safety = SafetyShield()
        self.air_speed_model = CombinedAirSpeedModel(
            AirSpeedModelConfig(fan_cmd_max_allowed=RULE_BASED_FAN_MAX_CMD)
        )
        self.fan_controller = CeilingFanController()
        self.features = FeatureBuilder(n_stack=3)
        self.reward_calc = RewardCalculator(
            dt_control_s=DT_CONTROL_S,
            w_energy=w_energy,
            w_pmv=w_pmv,
            w_invalid_request=w_invalid_request,
            w_switch=w_switch,
            nv_bonus_beta=nv_bonus_beta,
            nv_bonus_unocc_beta=nv_bonus_unocc_beta,
            w_nv_unbenefit=w_nv_unbenefit,
            w_sp_jump=w_sp_jump,
        )

        self.current_step = 0
        self.episode_start_hour = 0
        self.prev_mode = MODE_OFF
        self.current_mode = MODE_OFF
        self.time_since_ac_on_s = 0.0
        self.sim_time_s = 0.0
        self.prev_applied_ac_sp_k = float(self.default_ac_sp_k)
        self.prev_fan_cmd = 0.0
        self.current_fan_cmd = 0.0
        self.prev_occ_fra = 0.0

        dummy = self.features.build_obs(
            TRoo_K=300.15,
            Tout_K=300.15,
            occFra=0.0,
            heaFra=0.0,
            wind_m_s=0.0,
            rain_mm=0.0,
            rh_frac=0.5,
            indoor_air_speed_m_s=0.0,
            fan_cmd=0.0,
            nv_allowed=0.0,
            prev_mode=MODE_OFF,
            time_since_ac_on_s=0.0,
            sp_applied_k=float(self.default_ac_sp_k),
            t_in_episode_s=0.0,
            P_sys_kW=0.0,
        )
        self.observation_space = spaces.Box(
            low=-np.inf,
            high=np.inf,
            shape=dummy.obs.shape,
            dtype=np.float32,
        )
        self.features.reset_feature_history()

        self.action_space = spaces.MultiDiscrete(ACTION_SPACE_NVECS)
        self.seed(seed)

    def seed(self, seed=None):
        self.np_random, seed = seeding.np_random(seed)
        return [seed]

    def reset(self, *, seed=None, options=None):
        super().reset(seed=seed)

        valid_hours = self._valid_start_hours()
        if not valid_hours:
            raise RuntimeError(
                "No valid episode start hours found. Need warmup before start hour and a full episode after it."
            )

        self.episode_start_hour = int(self.np_random.choice(valid_hours))
        warmup_start_hour = self.episode_start_hour - WARMUP_HOURS

        self.current_step = 0
        self.prev_mode = MODE_OFF
        self.current_mode = MODE_OFF
        self.time_since_ac_on_s = 0.0
        self.prev_applied_ac_sp_k = float(self.default_ac_sp_k)
        self.prev_fan_cmd = 0.0
        self.current_fan_cmd = 0.0
        self.prev_occ_fra = 0.0
        self.fan_controller.reset()

        self.features.reset_trm_history(prefill_tout_k=[])
        self.features.reset_feature_history()

        self._recreate_fmu(warmup_start_hour=warmup_start_hour)
        self._warmup_to_episode_start(warmup_start_hour=warmup_start_hour)

        occ, hea, rain_csv, _, _ = self._exogenous_at_step(0)
        self.backend.set_reals(
            {
                IN_TROO_SET: float(self.default_ac_sp_k),
                IN_CO2_SET: CO2_SETPOINT_PPM,
                IN_SYS_ON: 0.0,
                IN_WIN_OPE: 0.0,
                IN_HEA_FRA: occ * 0.0 + hea,
                IN_OCC_FRA: occ,
            }
        )

        outputs = self._read_outputs()
        p_sys_kw = self._power_kw(outputs)
        nv_allowed = self._nv_allowed(
            rain_mm=rain_csv,
            wind_m_s=float(outputs["WinFmu"]),
            tout_k=float(outputs["Tout"]),
            current_mode=self.current_mode,
            time_since_ac_on_s=self.time_since_ac_on_s,
        )
        indoor_air_speed = self._effective_air_speed(
            mode=self.current_mode,
            fan_cmd=self.current_fan_cmd,
            window_mdot_kg_s=float(outputs["WinFlow"]),
        )

        feat_out = self.features.build_obs(
            TRoo_K=outputs["TRoo"],
            Tout_K=outputs["Tout"],
            occFra=occ,
            heaFra=hea,
            wind_m_s=float(outputs["WinFmu"]),
            rain_mm=rain_csv,
            rh_frac=float(outputs["RhRoo"]),
            indoor_air_speed_m_s=indoor_air_speed,
            fan_cmd=self.current_fan_cmd,
            nv_allowed=float(nv_allowed),
            prev_mode=self.prev_mode,
            time_since_ac_on_s=self.time_since_ac_on_s,
            sp_applied_k=float(self.default_ac_sp_k),
            t_in_episode_s=0.0,
            P_sys_kW=p_sys_kw,
        )

        if self.observation_space.shape != feat_out.obs.shape:
            self.observation_space = spaces.Box(
                low=-np.inf,
                high=np.inf,
                shape=feat_out.obs.shape,
                dtype=np.float32,
            )

        return feat_out.obs, {}

    def step(self, action):
        occ, hea, rain_csv, hour_idx, _ = self._exogenous_at_step(self.current_step)

        action_mode_idx, action_sp_idx = self._parse_action_components(action)
        requested_mode, requested_sp_k = decode_action(
            action_mode_idx,
            action_sp_idx,
        )
        # The setpoint branch is sampled for every MultiDiscrete action. Keep it
        # available so a minimum-hold correction to AC matches MaskablePPO.
        selected_sp_k = decode_ac_setpoint_index(action_sp_idx)
        requested_sp_k = float(selected_sp_k if requested_sp_k is None else requested_sp_k)

        pre = self.backend.get_reals([WEA_WIN_SPE, WEA_TDRYBUL, OUT_TROO])
        wind_now = float(pre[WEA_WIN_SPE])
        tout_now = float(pre[WEA_TDRYBUL])
        troo_now = float(pre[OUT_TROO])

        nv_allowed_dec = self._nv_allowed(
            rain_mm=rain_csv,
            wind_m_s=wind_now,
            tout_k=tout_now,
            current_mode=self.current_mode,
            time_since_ac_on_s=self.time_since_ac_on_s,
        )

        decision = self.safety.decide(
            requested_mode=int(requested_mode),
            requested_troo_set_k=float(selected_sp_k),
            default_ac_sp_k=self.default_ac_sp_k,
            occ_fra=occ,
            wind_m_s=wind_now,
            rain_mm=rain_csv,
            currently_in_ac=(self.current_mode == MODE_AC),
            time_since_ac_on_s=self.time_since_ac_on_s,
            tout_k=tout_now,
        )

        prev_mode_for_reward = int(self.current_mode)
        prev_fan_cmd_for_reward = float(self.current_fan_cmd)
        prev_occ_for_reward = float(self.prev_occ_fra)
        sp_applied_k = float(decision.TRooSet_K)
        fan_sp_ref_k = float(sp_applied_k) if int(decision.applied_mode) == MODE_AC else float(requested_sp_k)
        fan_requested_cmd = float(
            self.fan_controller.command(
                mode=self._mode_to_name(int(decision.applied_mode)),
                ac_sp_c=float(fan_sp_ref_k - 273.15),
                t_indoor_k=float(troo_now),
            )
        )
        fan_applied_cmd = (
            fan_requested_cmd
            if float(occ) >= OCC_ON_THRESHOLD and int(decision.applied_mode) != MODE_OFF
            else 0.0
        )

        self.backend.set_reals(
            {
                IN_TROO_SET: float(decision.TRooSet_K),
                IN_CO2_SET: CO2_SETPOINT_PPM,
                IN_SYS_ON: float(decision.uSysOn),
                IN_WIN_OPE: float(decision.uWinOpe),
                IN_HEA_FRA: hea,
                IN_OCC_FRA: occ,
            }
        )

        self.backend.step(DT_CONTROL_S)
        self.sim_time_s = float(self.backend.time)
        outputs = self._read_outputs()
        p_sys_kw = self._power_kw(outputs)

        if decision.applied_mode == MODE_AC:
            if prev_mode_for_reward == MODE_AC:
                self.time_since_ac_on_s += DT_CONTROL_S
            else:
                self.time_since_ac_on_s = DT_CONTROL_S
        else:
            self.time_since_ac_on_s = 0.0

        self.prev_mode = prev_mode_for_reward
        self.current_mode = int(decision.applied_mode)
        self.prev_fan_cmd = prev_fan_cmd_for_reward
        self.current_fan_cmd = float(fan_applied_cmd)

        next_step = self.current_step + 1
        occ_next, hea_next, rain_next, _, _ = self._exogenous_at_step(next_step)
        nv_allowed_next = self._nv_allowed(
            rain_mm=rain_next,
            wind_m_s=float(outputs["WinFmu"]),
            tout_k=float(outputs["Tout"]),
            current_mode=self.current_mode,
            time_since_ac_on_s=self.time_since_ac_on_s,
        )
        indoor_air_speed_next = self._effective_air_speed(
            mode=self.current_mode,
            fan_cmd=self.current_fan_cmd,
            window_mdot_kg_s=float(outputs["WinFlow"]),
        )

        sp_obs_next_k = float(sp_applied_k if int(decision.applied_mode) == MODE_AC else self.default_ac_sp_k)

        feat_out = self.features.build_obs(
            TRoo_K=outputs["TRoo"],
            Tout_K=outputs["Tout"],
            occFra=occ_next,
            heaFra=hea_next,
            wind_m_s=float(outputs["WinFmu"]),
            rain_mm=rain_next,
            rh_frac=float(outputs["RhRoo"]),
            indoor_air_speed_m_s=indoor_air_speed_next,
            fan_cmd=self.current_fan_cmd,
            nv_allowed=float(nv_allowed_next),
            prev_mode=self.prev_mode,
            time_since_ac_on_s=self.time_since_ac_on_s,
            sp_applied_k=float(sp_obs_next_k),
            t_in_episode_s=next_step * DT_CONTROL_S,
            P_sys_kW=p_sys_kw,
        )

        rb = self.reward_calc.compute(
            pmv=float(feat_out.pmv_state.pmv),
            occ_fra=float(occ),
            prev_occ_fra=float(prev_occ_for_reward),
            P_ashp_W=outputs["PASHP"],
            P_fan_sup_W=outputs["PFanSup"],
            P_fan_ret_W=outputs["PFanRet"],
            overridden=bool(decision.overridden),
            override_reason=decision.reason,
            mode_requested=int(requested_mode),
            mode_applied=int(decision.applied_mode),
            prev_mode=int(prev_mode_for_reward),
            sp_applied_k=float(sp_applied_k),
            prev_sp_applied_k=float(self.prev_applied_ac_sp_k),
            nv_allowed=float(nv_allowed_dec),
            tout_k=float(tout_now),
            troo_k=float(troo_now),
        )

        if int(decision.applied_mode) == MODE_AC:
            self.prev_applied_ac_sp_k = float(sp_applied_k)

        self.prev_occ_fra = float(occ)
        self.current_step += 1
        terminated = False
        truncated = self.current_step >= EPISODE_STEPS

        info = {
            "comfort_penalty": rb.comfort_penalty,
            "energy_penalty": rb.energy_penalty,
            "unoccupied_ac_penalty": rb.unoccupied_ac_penalty,
            "nv_blocked_penalty": rb.nv_blocked_penalty,
            "nv_unbenefit_penalty": rb.nv_unbenefit_penalty,
            "min_ac_hold_penalty": rb.min_ac_hold_penalty,
            "override_penalty": rb.override_penalty,
            "nv_bonus": rb.nv_bonus,
            "nv_bonus_occ": rb.nv_bonus_occ,
            "nv_bonus_unocc": rb.nv_bonus_unocc,
            "energy_kwh": rb.energy_kwh,
            "sp_jump_penalty": rb.sp_jump_penalty,
            "action_mode_idx": int(action_mode_idx),
            "action_sp_idx": int(action_sp_idx),
            "action_fan_idx": -1,
            "mode_applied": int(decision.applied_mode),
            "mode_requested": int(requested_mode),
            "overridden": bool(decision.overridden),
            "override_reason": decision.reason,
            "invalid_nv_fallback_applied": bool(decision.invalid_nv_fallback_applied),
            "hour_idx": int(hour_idx),
            "TRoo_K": outputs["TRoo"],
            "Tout_K": outputs["Tout"],
            "PASHP_W": outputs["PASHP"],
            "PFanSup_W": outputs["PFanSup"],
            "PFanRet_W": outputs["PFanRet"],
            "RhRoo_frac": outputs["RhRoo"],
            "RhRoo_pct": 100.0 * float(outputs["RhRoo"]),
            "window_mdot_kg_s": outputs["WinFlow"],
            "indoor_air_speed_m_s": float(indoor_air_speed_next),
            "pmv": float(feat_out.pmv_state.pmv),
            "ppd_pct": float(feat_out.pmv_state.ppd_pct),
            "nv_allowed_dec": float(nv_allowed_dec),
            "tout_minus_troo_dec_c": float(tout_now - troo_now),
            "sim_time_s": float(self.sim_time_s),
            "sp_requested_K": float(requested_sp_k),
            "sp_requested_C": float(requested_sp_k - 273.15),
            "sp_applied_K": float(sp_applied_k),
            "sp_applied_C": float(sp_applied_k - 273.15),
            "fan_requested_cmd": float(fan_requested_cmd),
            "fan_applied_cmd": float(self.current_fan_cmd),
            "prev_fan_cmd": float(prev_fan_cmd_for_reward),
        }

        return feat_out.obs, rb.total_reward, terminated, truncated, info

    def close(self):
        try:
            self.backend.terminate()
        except Exception:
            pass
        super().close()

    @staticmethod
    def _parse_action_components(action) -> Tuple[int, int]:
        arr = np.asarray(action, dtype=np.int64).reshape(-1)
        if arr.size != 2:
            raise ValueError(
                f"Expected MultiDiscrete action with 2 elements, got shape={arr.shape} value={action!r}"
            )
        return int(arr[0]), int(arr[1])

    def _valid_start_hours(self) -> List[int]:
        n = len(self.df)
        lo = WARMUP_HOURS
        hi = n - EPISODE_HOURS
        if hi <= lo:
            return []

        candidates = list(range(lo, hi))
        if self.month is None:
            return candidates

        dt = self.df[CSV_COL_DATETIME]
        m = int(self.month)
        return [h for h in candidates if int(dt.iloc[h].month) == m]

    def _row_at_hour(self, hour_idx: int) -> pd.Series:
        return self.df.iloc[int(hour_idx)]

    def _recreate_fmu(self, *, warmup_start_hour: int):
        try:
            self.backend.terminate()
        except Exception:
            pass

        self.backend.instantiate(instance_name="mmv_env_pmv")
        start_time_s = float(warmup_start_hour) * 3600.0
        self.backend.reset(start_time=start_time_s)
        self.sim_time_s = start_time_s

    def _warmup_to_episode_start(self, *, warmup_start_hour: int):
        for k in range(WARMUP_STEPS):
            hour_idx = warmup_start_hour + (k // CONTROL_STEPS_PER_HOUR)
            row = self._row_at_hour(hour_idx)
            self.backend.set_reals(
                {
                    IN_TROO_SET: float(self.default_ac_sp_k),
                    IN_CO2_SET: CO2_SETPOINT_PPM,
                    IN_SYS_ON: 0.0,
                    IN_WIN_OPE: 0.0,
                    IN_HEA_FRA: float(row[CSV_COL_HEA]),
                    IN_OCC_FRA: float(row[CSV_COL_OCC]),
                }
            )
            self.backend.step(DT_CONTROL_S)
            self.sim_time_s = float(self.backend.time)

    def _read_outputs(self) -> Dict[str, float]:
        out = self.backend.get_reals(
            [
                OUT_TROO,
                OUT_CO2,
                OUT_P_ASHP,
                OUT_P_FAN_SUP,
                OUT_P_FAN_RET,
                OUT_RH_ROO,
                OUT_WIN_OPE_MASS_FLOW,
                WEA_TDRYBUL,
                WEA_WIN_SPE,
            ]
        )
        return {
            "TRoo": float(out[OUT_TROO]),
            "CO2": float(out[OUT_CO2]),
            "PASHP": float(out[OUT_P_ASHP]),
            "PFanSup": float(out[OUT_P_FAN_SUP]),
            "PFanRet": float(out[OUT_P_FAN_RET]),
            "RhRoo": float(out[OUT_RH_ROO]),
            "WinFlow": float(out[OUT_WIN_OPE_MASS_FLOW]),
            "Tout": float(out[WEA_TDRYBUL]),
            "WinFmu": float(out[WEA_WIN_SPE]),
        }

    @staticmethod
    def _power_kw(outputs: Dict[str, float]) -> float:
        return (float(outputs["PASHP"]) + float(outputs["PFanSup"]) + float(outputs["PFanRet"])) / 1000.0

    @staticmethod
    def _mode_to_name(mode: int) -> str:
        if int(mode) == MODE_AC:
            return "AC"
        if int(mode) == MODE_NV:
            return "NV"
        return "OFF"

    def _effective_air_speed(self, *, mode: int, fan_cmd: float, window_mdot_kg_s: float) -> float:
        return float(
            self.air_speed_model.effective_air_speed(
                mode=self._mode_to_name(mode),
                fan_cmd=float(fan_cmd),
                window_mdot_kg_s=float(window_mdot_kg_s),
                fan_allowed_when_off=False,
            )
        )

    def _nv_allowed(
        self,
        *,
        rain_mm: float,
        wind_m_s: float,
        tout_k: float,
        current_mode: int,
        time_since_ac_on_s: float,
    ) -> float:
        hazard = (float(rain_mm) > 0.0) or (float(wind_m_s) > WIND_LIMIT_M_S)
        too_cold = WINDOW_COLD_LIMIT_ENABLED and (float(tout_k) < T_WC_K)
        ac_hold = (int(current_mode) == MODE_AC) and (float(time_since_ac_on_s) < MIN_AC_ON_S)
        return float((not hazard) and (not too_cold) and (not ac_hold))

    def _exogenous_at_step(self, control_step: int) -> Tuple[float, float, float, int, float]:
        base_hour = self.episode_start_hour + (control_step // CONTROL_STEPS_PER_HOUR)
        frac = (control_step % CONTROL_STEPS_PER_HOUR) / CONTROL_STEPS_PER_HOUR

        row0 = self._row_at_hour(base_hour)
        row1 = self._row_at_hour(min(base_hour + 1, len(self.df) - 1))

        occ = float(row0[CSV_COL_OCC])
        hea = float(row0[CSV_COL_HEA])

        rain0 = float(row0[CSV_COL_RAIN])
        rain1 = float(row1[CSV_COL_RAIN])
        rain = rain0 + (rain1 - rain0) * frac

        return occ, hea, rain, base_hour, frac
