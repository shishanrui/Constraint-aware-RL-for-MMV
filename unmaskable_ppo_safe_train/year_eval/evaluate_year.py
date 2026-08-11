from __future__ import annotations

import sys
import argparse
import csv
from datetime import timedelta
from pathlib import Path

_THIS_FILE = Path(__file__).resolve()
_ROOT = _THIS_FILE.parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))
from typing import Dict, Tuple

import numpy as np
import pandas as pd
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import DummyVecEnv, VecNormalize

from mmv_env.pmv_model import fanger_pmv
from mmv_env.safety import SafetyShield
from mmv_env.signals import decode_ac_setpoint_index
from year_eval.env_factory import make_eval_env
from year_eval.eval_config import CFG
from year_eval.signals_map import (
    CO2_SETPOINT_PPM,
    CSV_COL_DATETIME,
    CSV_COL_HEA,
    CSV_COL_OCC,
    CSV_COL_RAIN,
    DT_CONTROL_S,
    DT_LOG_S,
    IN_CO2_SET,
    IN_HEA_FRA,
    IN_OCC_FRA,
    IN_SYS_ON,
    IN_TROO_SET,
    IN_WIN_OPE,
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
    WEA_TDRYBUL,
    WEA_WIN_SPE,
    decode_action,
)


def k_to_c(temp_k: float) -> float:
    return float(temp_k) - 273.15


def _slug_float(v: float) -> str:
    return f"{float(v):g}".replace(".", "p")


def _default_output_csv_with_fallback(base_csv: Path, *, fallback: str, fallback_ac_sp_c: float) -> Path:
    suffix = f"_shieldv2_uacoff_nvfb-{fallback}"
    if fallback == "occupied_ac":
        suffix += f"_sp{_slug_float(fallback_ac_sp_c)}C"
    return base_csv.with_name(f"{base_csv.stem}{suffix}{base_csv.suffix}")


def simtime_to_ymd_hm(t_s_abs: float, base_datetime: pd.Timestamp | None) -> str:
    if base_datetime is None:
        return ""
    dt = base_datetime + timedelta(seconds=float(t_s_abs))
    return f"{dt.year}/{dt.month}/{dt.day} {dt.hour}:{dt.minute:02d}"


def mode_to_str(mode: int) -> str:
    if mode == MODE_OFF:
        return "OFF"
    if mode == MODE_NV:
        return "NV"
    if mode == MODE_AC:
        return "AC"
    return f"UNK_{int(mode)}"


def parse_action_components(action) -> Tuple[int, int]:
    arr = np.asarray(action, dtype=np.int64).reshape(-1)
    if arr.size != 2:
        raise ValueError(f"Expected MultiDiscrete action with 2 elements, got shape={arr.shape} value={action!r}")
    return int(arr[0]), int(arr[1])


def rain_interp_mm(t_s_abs: float, rain_hourly_mm: np.ndarray) -> float:
    h0 = int(t_s_abs // 3600.0)
    if h0 < 0:
        h0 = 0
    if h0 >= rain_hourly_mm.size - 1:
        return float(rain_hourly_mm[-1])
    h1 = h0 + 1
    a = (t_s_abs - 3600.0 * h0) / 3600.0
    return float((1.0 - a) * rain_hourly_mm[h0] + a * rain_hourly_mm[h1])


def _init_fixed_jan1_no_warmup(env) -> None:
    env.episode_start_hour = int(CFG.episode_start_hour)
    env.current_step = 0
    env.prev_mode = MODE_OFF
    env.current_mode = MODE_OFF
    env.time_since_ac_on_s = 0.0
    env.prev_applied_ac_sp_k = float(env.default_ac_sp_k)
    env.prev_fan_cmd = 0.0
    env.current_fan_cmd = 0.0
    env.prev_occ_fra = 0.0
    env.fan_controller.reset()
    env.features.reset_trm_history(prefill_tout_k=[])
    env.features.reset_feature_history()
    env._recreate_fmu(warmup_start_hour=CFG.episode_start_hour)

    occ0, hea0, _rain0, _, _ = env._exogenous_at_step(0)
    env.backend.set_reals(
        {
            IN_TROO_SET: float(env.default_ac_sp_k),
            IN_CO2_SET: float(CO2_SETPOINT_PPM),
            IN_SYS_ON: 0.0,
            IN_WIN_OPE: 0.0,
            IN_HEA_FRA: float(hea0),
            IN_OCC_FRA: float(occ0),
        }
    )


def compute_pmv(env, *, troo_k: float, rh_frac: float, mode: int, fan_cmd: float, window_flow: float) -> Tuple[float, float, float]:
    indoor_air_speed = env._effective_air_speed(
        mode=mode,
        fan_cmd=float(fan_cmd),
        window_mdot_kg_s=float(window_flow),
    )
    pmv_result = fanger_pmv(
        ta_c=k_to_c(troo_k),
        rh_pct=100.0 * float(rh_frac),
        air_speed_m_s=float(indoor_air_speed),
    )
    return float(indoor_air_speed), float(pmv_result.pmv), float(pmv_result.ppd_pct)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run year-long evaluation for one trained PMV model.")
    parser.add_argument("--model-path", type=str, default=str(CFG.model_path), help="Path to PPO model .zip")
    parser.add_argument("--vecnorm-path", type=str, default=str(CFG.vecnorm_path), help="Path to VecNormalize .pkl")
    parser.add_argument("--out-csv", type=str, default=None, help="Output CSV path")
    parser.add_argument("--fmu-path", type=str, default=str(CFG.fmu_path), help="Evaluation FMU path")
    parser.add_argument("--input-csv", type=str, default=str(CFG.input_csv_path), help="Evaluation input CSV path")
    parser.add_argument("--horizon-hours", type=int, default=CFG.horizon_hours, help="Evaluation horizon in hours")
    parser.add_argument(
        "--invalid-nv-fallback",
        choices=["off", "occupied_ac"],
        default="occupied_ac",
        help="Deployment fallback for weather-blocked NV.",
    )
    parser.add_argument("--fallback-ac-sp-c", type=float, default=29.0, help="Occupied-AC fallback setpoint.")
    args = parser.parse_args()

    model_path = Path(args.model_path)
    vecnorm_path = Path(args.vecnorm_path)
    invalid_nv_fallback = str(args.invalid_nv_fallback)
    fallback_ac_sp_c = float(args.fallback_ac_sp_c)
    fallback_ac_sp_k = fallback_ac_sp_c + 273.15
    output_csv = (
        Path(args.out_csv)
        if args.out_csv is not None
        else _default_output_csv_with_fallback(
            Path(CFG.output_csv),
            fallback=invalid_nv_fallback,
            fallback_ac_sp_c=fallback_ac_sp_c,
        )
    )
    fmu_path = Path(args.fmu_path)
    input_csv_path = Path(args.input_csv)
    horizon_hours_cfg = int(args.horizon_hours)

    output_csv.parent.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(input_csv_path, parse_dates=[CSV_COL_DATETIME])
    rain_hourly_mm = df[CSV_COL_RAIN].to_numpy(dtype=float)

    base_datetime: pd.Timestamp | None = None
    dt0 = pd.to_datetime(df[CSV_COL_DATETIME].iloc[0], errors="coerce")
    if not pd.isna(dt0):
        base_datetime = dt0.replace(hour=0, minute=0, second=0, microsecond=0)

    print(f"[YEAR-EVAL] Using dt_comm_s={CFG.eval_env_cfg.dt_comm_s}")
    print(f"[YEAR-EVAL] invalid_nv_fallback={invalid_nv_fallback} fallback_ac_sp_c={fallback_ac_sp_c:g}")
    model = PPO.load(str(model_path), device="cpu")

    def _make_env_for_vecnorm():
        return make_eval_env(
            train_cfg=CFG.eval_env_cfg,
            fmu_path=fmu_path,
            input_csv_path=input_csv_path,
            seed=CFG.vecnorm_seed,
        )

    vec_base = DummyVecEnv([_make_env_for_vecnorm])
    vecnorm = VecNormalize.load(str(vecnorm_path), vec_base)
    vecnorm.training = False
    vecnorm.norm_reward = False

    env = make_eval_env(
        train_cfg=CFG.eval_env_cfg,
        fmu_path=fmu_path,
        input_csv_path=input_csv_path,
        seed=CFG.eval_seed,
    )
    env.safety = SafetyShield(
        invalid_nv_fallback=invalid_nv_fallback,
        fallback_ac_sp_k=fallback_ac_sp_k,
    )
    _init_fixed_jan1_no_warmup(env)

    available_hours = int(len(df))
    horizon_hours = int(min(horizon_hours_cfg, available_hours - CFG.episode_start_hour))
    if horizon_hours <= 0:
        raise RuntimeError("No available horizon in input CSV from selected episode_start_hour.")
    t_end_s = float(horizon_hours) * 3600.0

    fmu_names = [
        OUT_TROO,
        OUT_CO2,
        OUT_P_ASHP,
        OUT_P_FAN_SUP,
        OUT_P_FAN_RET,
        OUT_RH_ROO,
        OUT_WIN_OPE_MASS_FLOW,
        WEA_TDRYBUL,
        WEA_WIN_SPE,
        IN_TROO_SET,
        IN_SYS_ON,
        IN_WIN_OPE,
    ]

    cols = [
        "time_s",
        "datetime_mdHM",
        "mode",
        "mode_num",
        "TRoo_K",
        "TRoo_C",
        "CO2Roo_ppm",
        "PFanSup_W",
        "PFanRet_W",
        "PASHP_W",
        "T_outdoor_K",
        "T_outdoor_C",
        "wind_speed_m_s",
        "rain_mm",
        "heaFra",
        "occFra",
        "sp_requested_K",
        "sp_requested_C",
        "TRooSet_cmd_K",
        "TRooSet_cmd_C",
        "uSysOn_cmd",
        "uWinOpe_cmd",
        "mode_requested",
        "mode_applied",
        "override_reason",
        "invalid_nv_fallback",
        "invalid_nv_fallback_applied",
        "fallback_ac_sp_K",
        "fallback_ac_sp_C",
        "reward_10min",
        "energy_kWh_10min",
        "energy_kWh_10min_true",
        "overridden",
        "P_sys_kW",
        "nv_allowed",
        "prev_mode",
        "unoccupied_ac_penalty",
        "nv_blocked_penalty",
        "nv_unbenefit_penalty",
        "min_ac_hold_penalty",
        "nv_bonus_occ",
        "nv_bonus_unocc",
        "switch_penalty",
        "sp_jump_penalty",
        "RhRoo_frac",
        "RhRoo_pct",
        "window_mdot_kg_s",
        "ceiling_fan_cmd",
        "indoor_air_speed_m_s",
        "pmv",
        "ppd_pct",
    ]

    last_mode_requested = MODE_OFF
    last_mode_applied = MODE_OFF
    last_sp_requested_k = float(env.default_ac_sp_k)
    last_override_reason = ""
    last_invalid_nv_fallback_applied = 0.0
    last_overridden = 0.0
    last_reward_10min = 0.0
    last_energy_kwh_10min = 0.0
    last_energy_kwh_10min_true = 0.0
    last_nv_allowed = 0.0
    last_prev_mode = float(MODE_OFF)
    last_unoccupied_ac_penalty = 0.0
    last_nv_blocked_penalty = 0.0
    last_nv_unbenefit_penalty = 0.0
    last_min_ac_hold_penalty = 0.0
    last_nv_bonus_occ = 0.0
    last_nv_bonus_unocc = 0.0
    last_switch_penalty = 0.0
    last_sp_jump_penalty = 0.0
    last_fan_cmd = 0.0

    eval_t0_s = float(env.backend.time)

    def write_row(writer, t_abs_s: float, t_rel_s: float, out: Dict[str, float]) -> None:
        hour_idx = int(t_abs_s // 3600.0)
        hour_idx = min(max(hour_idx, 0), len(df) - 1)
        occ = float(df.iloc[hour_idx][CSV_COL_OCC])
        hea = float(df.iloc[hour_idx][CSV_COL_HEA])
        rain_mm = rain_interp_mm(t_abs_s, rain_hourly_mm)
        p_sys_kw = (float(out[OUT_P_ASHP]) + float(out[OUT_P_FAN_SUP]) + float(out[OUT_P_FAN_RET])) / 1000.0
        indoor_air_speed, pmv, ppd_pct = compute_pmv(
            env,
            troo_k=float(out[OUT_TROO]),
            rh_frac=float(out[OUT_RH_ROO]),
            mode=int(last_mode_applied),
            fan_cmd=float(last_fan_cmd),
            window_flow=float(out[OUT_WIN_OPE_MASS_FLOW]),
        )

        writer.writerow(
            {
                "time_s": float(t_rel_s),
                "datetime_mdHM": simtime_to_ymd_hm(t_abs_s, base_datetime),
                "mode": mode_to_str(int(last_mode_applied)),
                "mode_num": float(last_mode_applied),
                "TRoo_K": float(out[OUT_TROO]),
                "TRoo_C": k_to_c(float(out[OUT_TROO])),
                "CO2Roo_ppm": float(out[OUT_CO2]),
                "PFanSup_W": float(out[OUT_P_FAN_SUP]),
                "PFanRet_W": float(out[OUT_P_FAN_RET]),
                "PASHP_W": float(out[OUT_P_ASHP]),
                "T_outdoor_K": float(out[WEA_TDRYBUL]),
                "T_outdoor_C": k_to_c(float(out[WEA_TDRYBUL])),
                "wind_speed_m_s": float(out[WEA_WIN_SPE]),
                "rain_mm": float(rain_mm),
                "heaFra": float(hea),
                "occFra": float(occ),
                "sp_requested_K": float(last_sp_requested_k),
                "sp_requested_C": k_to_c(float(last_sp_requested_k)),
                "TRooSet_cmd_K": float(out[IN_TROO_SET]),
                "TRooSet_cmd_C": k_to_c(float(out[IN_TROO_SET])),
                "uSysOn_cmd": float(out[IN_SYS_ON]),
                "uWinOpe_cmd": float(out[IN_WIN_OPE]),
                "mode_requested": float(last_mode_requested),
                "mode_applied": float(last_mode_applied),
                "override_reason": str(last_override_reason),
                "invalid_nv_fallback": invalid_nv_fallback,
                "invalid_nv_fallback_applied": float(last_invalid_nv_fallback_applied),
                "fallback_ac_sp_K": float(fallback_ac_sp_k),
                "fallback_ac_sp_C": float(fallback_ac_sp_c),
                "reward_10min": float(last_reward_10min),
                "energy_kWh_10min": float(last_energy_kwh_10min),
                "energy_kWh_10min_true": float(last_energy_kwh_10min_true),
                "overridden": float(last_overridden),
                "P_sys_kW": float(p_sys_kw),
                "nv_allowed": float(last_nv_allowed),
                "prev_mode": float(last_prev_mode),
                "unoccupied_ac_penalty": float(last_unoccupied_ac_penalty),
                "nv_blocked_penalty": float(last_nv_blocked_penalty),
                "nv_unbenefit_penalty": float(last_nv_unbenefit_penalty),
                "min_ac_hold_penalty": float(last_min_ac_hold_penalty),
                "nv_bonus_occ": float(last_nv_bonus_occ),
                "nv_bonus_unocc": float(last_nv_bonus_unocc),
                "switch_penalty": float(last_switch_penalty),
                "sp_jump_penalty": float(last_sp_jump_penalty),
                "RhRoo_frac": float(out[OUT_RH_ROO]),
                "RhRoo_pct": 100.0 * float(out[OUT_RH_ROO]),
                "window_mdot_kg_s": float(out[OUT_WIN_OPE_MASS_FLOW]),
                "ceiling_fan_cmd": float(last_fan_cmd),
                "indoor_air_speed_m_s": float(indoor_air_speed),
                "pmv": float(pmv),
                "ppd_pct": float(ppd_pct),
            }
        )

    with output_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=cols)
        writer.writeheader()

        t_abs = float(env.backend.time)
        out0 = env.backend.get_reals(fmu_names)
        write_row(writer, t_abs_s=t_abs, t_rel_s=t_abs - eval_t0_s, out=out0)

        while (float(env.backend.time) - eval_t0_s) < t_end_s - 1e-9:
            occ, hea, rain_csv, _, _ = env._exogenous_at_step(env.current_step)
            out_now = env.backend.get_reals(
                [OUT_TROO, WEA_TDRYBUL, WEA_WIN_SPE, OUT_P_ASHP, OUT_P_FAN_SUP, OUT_P_FAN_RET, OUT_RH_ROO, OUT_WIN_OPE_MASS_FLOW]
            )
            p_sys_kw_now = (
                float(out_now[OUT_P_ASHP]) + float(out_now[OUT_P_FAN_SUP]) + float(out_now[OUT_P_FAN_RET])
            ) / 1000.0
            indoor_air_speed_now, _, _ = compute_pmv(
                env,
                troo_k=float(out_now[OUT_TROO]),
                rh_frac=float(out_now[OUT_RH_ROO]),
                mode=int(env.current_mode),
                fan_cmd=float(env.current_fan_cmd),
                window_flow=float(out_now[OUT_WIN_OPE_MASS_FLOW]),
            )
            nv_allowed_now = env._nv_allowed(
                rain_mm=float(rain_csv),
                wind_m_s=float(out_now[WEA_WIN_SPE]),
                tout_k=float(out_now[WEA_TDRYBUL]),
                current_mode=int(env.current_mode),
                time_since_ac_on_s=float(env.time_since_ac_on_s),
            )
            troo_now = float(out_now[OUT_TROO])
            tout_now = float(out_now[WEA_TDRYBUL])
            feat_now = env.features.build_obs(
                TRoo_K=float(troo_now),
                Tout_K=float(tout_now),
                occFra=float(occ),
                heaFra=float(hea),
                wind_m_s=float(out_now[WEA_WIN_SPE]),
                rain_mm=float(rain_csv),
                rh_frac=float(out_now[OUT_RH_ROO]),
                indoor_air_speed_m_s=float(indoor_air_speed_now),
                fan_cmd=float(env.current_fan_cmd),
                nv_allowed=float(nv_allowed_now),
                prev_mode=int(env.prev_mode),
                time_since_ac_on_s=float(env.time_since_ac_on_s),
                sp_applied_k=float(env.default_ac_sp_k if int(env.current_mode) != MODE_AC else env.prev_applied_ac_sp_k),
                t_in_episode_s=float(env.current_step) * float(DT_CONTROL_S),
                P_sys_kW=float(p_sys_kw_now),
            )

            obs_norm = vecnorm.normalize_obs(feat_now.obs[None, :])
            action, _ = model.predict(obs_norm, deterministic=CFG.deterministic_policy)
            action_mode_idx, action_sp_idx = parse_action_components(action)
            requested_mode, requested_sp_k = decode_action(
                action_mode_idx,
                action_sp_idx,
            )
            selected_sp_k = decode_ac_setpoint_index(action_sp_idx)
            requested_sp_k = float(selected_sp_k if requested_sp_k is None else requested_sp_k)

            last_mode_requested = int(requested_mode)
            last_sp_requested_k = float(requested_sp_k)

            decision = env.safety.decide(
                requested_mode=int(requested_mode),
                requested_troo_set_k=float(selected_sp_k),
                default_ac_sp_k=float(env.default_ac_sp_k),
                occ_fra=float(occ),
                wind_m_s=float(out_now[WEA_WIN_SPE]),
                rain_mm=float(rain_csv),
                currently_in_ac=(env.current_mode == MODE_AC),
                time_since_ac_on_s=float(env.time_since_ac_on_s),
                tout_k=float(out_now[WEA_TDRYBUL]),
            )

            env.backend.set_reals(
                {
                    IN_TROO_SET: float(decision.TRooSet_K),
                    IN_CO2_SET: float(CO2_SETPOINT_PPM),
                    IN_SYS_ON: float(decision.uSysOn),
                    IN_WIN_OPE: float(decision.uWinOpe),
                    IN_HEA_FRA: float(hea),
                    IN_OCC_FRA: float(occ),
                }
            )

            last_mode_applied = int(decision.applied_mode)
            last_override_reason = "" if decision.reason is None else str(decision.reason)
            last_invalid_nv_fallback_applied = 1.0 if decision.invalid_nv_fallback_applied else 0.0
            last_overridden = 1.0 if bool(decision.overridden) else 0.0
            last_nv_allowed = float(nv_allowed_now)
            last_prev_mode = float(env.current_mode)
            fan_sp_ref_k = float(decision.TRooSet_K) if int(decision.applied_mode) == MODE_AC else float(requested_sp_k)
            requested_fan_cmd = float(
                env.fan_controller.command(
                    mode=env._mode_to_name(int(decision.applied_mode)),
                    ac_sp_c=float(fan_sp_ref_k - 273.15),
                    t_indoor_k=float(troo_now),
                )
            )
            applied_fan_cmd = (
                requested_fan_cmd
                if float(occ) >= float(OCC_ON_THRESHOLD) and int(decision.applied_mode) != MODE_OFF
                else 0.0
            )
            last_fan_cmd = float(applied_fan_cmd)

            energy_kwh_true = 0.0
            for _ in range(int(DT_CONTROL_S // DT_LOG_S)):
                env.backend.step(DT_LOG_S)
                env.sim_time_s = float(env.backend.time)
                t_abs = float(env.backend.time)
                out = env.backend.get_reals(fmu_names)
                p_sys_kw_m = (
                    float(out[OUT_P_ASHP]) + float(out[OUT_P_FAN_SUP]) + float(out[OUT_P_FAN_RET])
                ) / 1000.0
                energy_kwh_true += float(p_sys_kw_m) * (float(DT_LOG_S) / 3600.0)
                write_row(writer, t_abs_s=t_abs, t_rel_s=t_abs - eval_t0_s, out=out)

            prev_mode_for_reward = int(env.current_mode)
            prev_fan_cmd_for_reward = float(env.current_fan_cmd)
            prev_occ_for_reward = float(env.prev_occ_fra)

            if decision.applied_mode == MODE_AC:
                if env.current_mode == MODE_AC:
                    env.time_since_ac_on_s += float(DT_CONTROL_S)
                else:
                    env.time_since_ac_on_s = float(DT_CONTROL_S)
            else:
                env.time_since_ac_on_s = 0.0

            env.prev_mode = prev_mode_for_reward
            env.current_mode = int(decision.applied_mode)
            env.prev_fan_cmd = prev_fan_cmd_for_reward
            env.current_fan_cmd = float(applied_fan_cmd)

            out_end = env._read_outputs()
            _, pmv_end, _ = compute_pmv(
                env,
                troo_k=float(out_end["TRoo"]),
                rh_frac=float(out_end["RhRoo"]),
                mode=int(env.current_mode),
                fan_cmd=float(env.current_fan_cmd),
                window_flow=float(out_end["WinFlow"]),
            )

            rb = env.reward_calc.compute(
                pmv=float(pmv_end),
                occ_fra=float(occ),
                prev_occ_fra=float(prev_occ_for_reward),
                P_ashp_W=float(out_end["PASHP"]),
                P_fan_sup_W=float(out_end["PFanSup"]),
                P_fan_ret_W=float(out_end["PFanRet"]),
                overridden=bool(decision.overridden),
                override_reason=decision.reason,
                mode_requested=int(requested_mode),
                mode_applied=int(decision.applied_mode),
                prev_mode=int(prev_mode_for_reward),
                sp_applied_k=float(decision.TRooSet_K),
                prev_sp_applied_k=float(env.prev_applied_ac_sp_k),
                nv_allowed=float(nv_allowed_now),
                tout_k=float(tout_now),
                troo_k=float(troo_now),
            )

            if int(decision.applied_mode) == MODE_AC:
                env.prev_applied_ac_sp_k = float(decision.TRooSet_K)

            env.prev_occ_fra = float(occ)
            env.current_step += 1

            last_reward_10min = float(rb.total_reward)
            last_energy_kwh_10min = float(rb.energy_kwh)
            last_energy_kwh_10min_true = float(energy_kwh_true)
            last_unoccupied_ac_penalty = float(rb.unoccupied_ac_penalty)
            last_nv_blocked_penalty = float(rb.nv_blocked_penalty)
            last_nv_unbenefit_penalty = float(rb.nv_unbenefit_penalty)
            last_min_ac_hold_penalty = float(rb.min_ac_hold_penalty)
            last_nv_bonus_occ = float(rb.nv_bonus_occ)
            last_nv_bonus_unocc = float(rb.nv_bonus_unocc)
            last_switch_penalty = float(rb.switch_penalty)
            last_sp_jump_penalty = float(rb.sp_jump_penalty)

    try:
        env.backend.terminate()
    except Exception:
        pass

    print(f"[YEAR-EVAL] saved: {output_csv}")


if __name__ == "__main__":
    main()
