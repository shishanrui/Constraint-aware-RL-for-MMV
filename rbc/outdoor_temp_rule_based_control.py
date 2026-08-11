from __future__ import annotations

# Outdoor-temperature rule-based MMV controller runner for HCDLabPMVPIEval FMU
#
# This version is aligned to RL year-eval logging:
# - Full-year minute logs by default
# - Output CSV columns compatible with baseline_rl/year_eval/evaluate_year.py
# - AC minimum ON time: 30 min, with unoccupied override disabling forced AC
# - While occupied, use NV below an outdoor-temperature threshold, else AC
# - When unoccupied, allow OFF or NV (but not AC)
# - Fixed AC setpoint / fixed temperature band for PMV-oriented evaluation

import argparse
import csv
from dataclasses import dataclass
from datetime import timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd

from airflow_model import AirSpeedModelConfig, CombinedAirSpeedModel
from fan_controller import CeilingFanController
from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave
from pmv_model import DEFAULT_CLO, DEFAULT_MET, DEFAULT_WME, fanger_pmv


# -----------------------------
# Settings
# -----------------------------
#
_ROOT = Path(__file__).resolve().parent
FMU_PATH = str(_ROOT / "HCDLabPMVPIEval.fmu")
INPUT_CSV = str(_ROOT / "input_data.csv")

# Year-long run by default (capped by input csv length)
HOURS_TO_RUN = 24 * 365

DT_CONTROL = 600.0   # 10 min control decision interval
# DT_COMM = 10.0       # FMU communication step
DT_COMM = 1.0       # avoid [IDASolve failed with IDA_ILL_INPUT, mxstep steps taken before reaching tout.]
print("Using DT_COMM:", DT_COMM)
DT_LOG = 60.0        # minute logging

# Fixed AC setpoint values to sweep for PMV evaluation.
VALID_FIXED_AC_SP_VALUES_C = (26.0, 26.5, 27.0, 27.5, 28.0, 28.5, 29.0, 29.5, 30.0, 29.56)
# FIXED_AC_SP_C = 29.0
# FIXED_AC_SP_C = 29.5
FIXED_AC_SP_C = 30.0
# FIXED_AC_SP_C = 29.56

OUTDIR = _ROOT / "mmv_rulebased_out"

CO2_SETPOINT_PPM = 800.0
T_WC_K = 273.15 + 18.0
WIND_LIMIT = 8.0

TOO_COLD_OFF_C = 24.0

# Outdoor-temperature-only NV threshold.
# Adjust NV_OUTDOOR_THRESHOLD_C to change the main cutoff:
# - already in NV: stay in NV while Tout < NV_OUTDOOR_THRESHOLD_C
# - not in NV: enter NV only below threshold minus the hysteresis band
NV_OUTDOOR_THRESHOLD_C = 30.0
NV_OUTDOOR_HYSTERESIS_C = 0.5
NV_OUTDOOR_ENTER_C = NV_OUTDOOR_THRESHOLD_C - NV_OUTDOOR_HYSTERESIS_C
NV_OUTDOOR_EXIT_C = NV_OUTDOOR_THRESHOLD_C

# Minimum AC ON time (anti short-cycling)
MIN_AC_ON_S = 30.0 * 60.0

BYPASS_MIN_AC_ON_WHEN_UNOCCUPIED = True

# Keep false for year runs to avoid plotting overhead.
PLOT_RESULTS = False

MODE_OFF = 0
MODE_NV = 1
MODE_AC = 2

PMV_MET = DEFAULT_MET
PMV_CLO = DEFAULT_CLO
PMV_WME = DEFAULT_WME


# -----------------------------
# Helpers
# -----------------------------
def k_to_c(temp_k: float) -> float:
    return float(temp_k) - 273.15


def simtime_to_ymd_hm(t_s_abs: float, base_datetime: Optional[pd.Timestamp]) -> str:
    if base_datetime is None:
        return ""
    dt = base_datetime + timedelta(seconds=float(t_s_abs))
    return f"{dt.year}/{dt.month}/{dt.day} {dt.hour}:{dt.minute:02d}"


def rain_interp_mm(t_s_abs: float, rain_hourly_mm: np.ndarray) -> float:
    h0 = int(t_s_abs // 3600.0)
    if h0 < 0:
        h0 = 0
    if h0 >= rain_hourly_mm.size - 1:
        return float(rain_hourly_mm[-1])
    h1 = h0 + 1
    a = (t_s_abs - 3600.0 * h0) / 3600.0
    return float((1.0 - a) * rain_hourly_mm[h0] + a * rain_hourly_mm[h1])


def mode_to_num(mode: str) -> int:
    if mode == "OFF":
        return MODE_OFF
    if mode == "NV":
        return MODE_NV
    if mode == "AC":
        return MODE_AC
    raise ValueError(f"Unknown mode: {mode}")


def c_to_k(temp_c: float) -> float:
    return float(temp_c) + 273.15


def validate_fixed_ac_sp_c(ac_sp_c: float) -> float:
    ac_sp_c = float(ac_sp_c)
    if ac_sp_c not in VALID_FIXED_AC_SP_VALUES_C:
        raise ValueError(
            f"Unsupported fixed AC setpoint {ac_sp_c:.1f} C. "
            f"Choose one of: {', '.join(f'{v:.1f}' for v in VALID_FIXED_AC_SP_VALUES_C)} C."
        )
    return ac_sp_c


def validate_nv_thresholds(enter_c: float, exit_c: float) -> Tuple[float, float]:
    enter_c = float(enter_c)
    exit_c = float(exit_c)
    if exit_c <= enter_c:
        raise ValueError(
            f"NV exit threshold ({exit_c:.1f} C) must be greater than "
            f"NV enter threshold ({enter_c:.1f} C)."
        )
    return enter_c, exit_c


def select_troo_set_k(mode: str, fixed_ac_sp_k: float) -> float:
    # Keep the commanded setpoint fixed for all modes. OFF/NV still disable HVAC/window
    # through uSysOn/uWinOpe, so this does not change the control branch structure.
    _ = mode
    return float(fixed_ac_sp_k)


def default_out_csv(ac_sp_c: float, nv_enter_c: float, nv_exit_c: float) -> Path:
    ac_sp_label = f"{float(ac_sp_c):.1f}".replace(".", "p")
    dt_comm_label = f"{float(DT_COMM):g}".replace(".", "p")
    enter_label = f"{float(nv_enter_c):.1f}".replace(".", "p")
    exit_label = f"{float(nv_exit_c):.1f}".replace(".", "p")
    return OUTDIR / (
        f"rulebased_outdoor_temp_fixed_sp_{ac_sp_label}C_"
        f"nv_enter_{enter_label}C_exit_{exit_label}C_dtcomm_{dt_comm_label}s.csv"
    )


@dataclass
class ControlDecision:
    mode: str
    TRooSet: float
    CO2Set: float
    uSysOn: float
    uWinOpe: float
    heaFra: float
    occFra: float
    Trm: float
    Tout: float
    wind: float
    rain: float


class OutdoorTempRuleBasedController:
    """
    Outdoor-temperature threshold controller with:
    - Occupied AC/NV hysteresis based only on outdoor temperature
    - Unoccupied OFF/NV hysteresis based only on outdoor temperature
    - Minimum AC ON time
    """

    def __init__(
        self,
        fixed_ac_sp_c: float = FIXED_AC_SP_C,
        nv_outdoor_enter_c: float = NV_OUTDOOR_ENTER_C,
        nv_outdoor_exit_c: float = NV_OUTDOOR_EXIT_C,
        min_ac_on_s: float = MIN_AC_ON_S,
        bypass_min_ac_on_when_unoccupied: bool = BYPASS_MIN_AC_ON_WHEN_UNOCCUPIED,
    ):
        self.fixed_ac_sp_c = validate_fixed_ac_sp_c(fixed_ac_sp_c)
        self.fixed_ac_sp_k = c_to_k(self.fixed_ac_sp_c)
        self.nv_outdoor_enter_c, self.nv_outdoor_exit_c = validate_nv_thresholds(
            nv_outdoor_enter_c,
            nv_outdoor_exit_c,
        )
        self.nv_outdoor_enter_k = c_to_k(self.nv_outdoor_enter_c)
        self.nv_outdoor_exit_k = c_to_k(self.nv_outdoor_exit_c)

        self.min_ac_on_s = float(min_ac_on_s)
        self.bypass_min_ac_on_when_unoccupied = bool(bypass_min_ac_on_when_unoccupied)

        self.mode_prev = "OFF"
        self.ac_on_since_s: Optional[float] = None
        self.last_override_reason = ""

    def _trm_k(self) -> float:
        # PMV evaluation uses a fixed AC target rather than the adaptive comfort model.
        # Keep Trm as NaN in the log to make it explicit that no running-mean outdoor
        # temperature is driving the controller anymore.
        return float("nan")

    def _pack(
        self,
        mode: str,
        hea_fra: float,
        occ_fra: float,
        trm_k: float,
        tout_k: float,
        wind_m_s: float,
        rain_mm: float,
    ) -> ControlDecision:
        if mode == "AC":
            u_sys_on, u_win_ope = 1.0, 0.0
        elif mode == "NV":
            u_sys_on, u_win_ope = 0.0, 1.0
        else:
            u_sys_on, u_win_ope = 0.0, 0.0

        return ControlDecision(
            mode=mode,
            TRooSet=select_troo_set_k(mode=mode, fixed_ac_sp_k=self.fixed_ac_sp_k),
            CO2Set=CO2_SETPOINT_PPM,
            uSysOn=u_sys_on,
            uWinOpe=u_win_ope,
            heaFra=float(hea_fra),
            occFra=float(occ_fra),
            Trm=float(trm_k),
            Tout=float(tout_k),
            wind=float(wind_m_s),
            rain=float(rain_mm),
        )

    def _decide_base(
        self,
        t_indoor_k: float,
        t_outdoor_k: float,
        wind_speed: float,
        rain_mm: float,
        hea_fra: float,
        occ_fra: float,
    ) -> ControlDecision:
        trm_k = self._trm_k()
        # Rain/high wind/cold outdoor air disable NV, then occupied fallback is AC
        # and unoccupied fallback is OFF.
        nv_weather_ok = (rain_mm <= 0.0) and (wind_speed <= WIND_LIMIT) and (t_outdoor_k > T_WC_K)
        nv_enter_ok = nv_weather_ok and (t_outdoor_k < self.nv_outdoor_enter_k)
        nv_hold_ok = nv_weather_ok and (t_outdoor_k < self.nv_outdoor_exit_k)

        # Unoccupied branch: allow outdoor-temperature NV with explicit OFF->NV /
        # NV->OFF hysteresis so small Tout fluctuations do not chatter states.
        if occ_fra == 0.0:
            if not nv_weather_ok:
                mode = "OFF"
            elif self.mode_prev == "NV":
                mode = "NV" if nv_hold_ok else "OFF"
            else:
                mode = "NV" if nv_enter_ok else "OFF"
            return self._pack(mode, hea_fra, occ_fra, trm_k, t_outdoor_k, wind_speed, rain_mm)

        # Occupied branch:
        # - AC is the default occupied fallback.
        # - NV enters below the lower outdoor-temperature threshold.
        # - NV stays active below the upper threshold to avoid AC/NV chatter.
        # - OFF is only reachable when unoccupied.
        if self.mode_prev == "AC":
            mode = "NV" if nv_enter_ok else "AC"
        elif self.mode_prev == "NV":
            mode = "NV" if nv_hold_ok else "AC"
        else:
            mode = "NV" if nv_enter_ok else "AC"

        return self._pack(mode, hea_fra, occ_fra, trm_k, t_outdoor_k, wind_speed, rain_mm)

    def decide(
        self,
        t_s: float,
        t_indoor_k: float,
        t_outdoor_k: float,
        wind_speed: float,
        rain_mm: float,
        hea_fra: float,
        occ_fra: float,
    ) -> Tuple[ControlDecision, ControlDecision]:
        """
        Returns (requested/base decision, applied/final decision).
        """
        self.last_override_reason = ""

        base = self._decide_base(
            t_indoor_k=t_indoor_k,
            t_outdoor_k=t_outdoor_k,
            wind_speed=wind_speed,
            rain_mm=rain_mm,
            hea_fra=hea_fra,
            occ_fra=occ_fra,
        )
        final = base

        # Track AC enter timing.
        if self.mode_prev != "AC" and base.mode == "AC":
            self.ac_on_since_s = float(t_s)

        # Enforce minimum AC ON time if currently in AC and base wants to exit.
        should_hold_ac = (
            self.mode_prev == "AC"
            and self.ac_on_since_s is not None
            and final.mode != "AC"
        )
        if should_hold_ac:
            elapsed = float(t_s) - float(self.ac_on_since_s)
            bypass_hold = self.bypass_min_ac_on_when_unoccupied and occ_fra == 0.0
            if elapsed < self.min_ac_on_s and not bypass_hold:
                final = self._pack(
                    "AC",
                    hea_fra=hea_fra,
                    occ_fra=occ_fra,
                    trm_k=base.Trm,
                    tout_k=base.Tout,
                    wind_m_s=base.wind,
                    rain_mm=base.rain,
                )
                self.last_override_reason = "min_ac_on_time_hold"

        # Track AC leave.
        if self.mode_prev == "AC" and final.mode != "AC":
            self.ac_on_since_s = None

        self.mode_prev = final.mode
        return base, final


def _fmu_get_reals(fmu: FMU2Slave, vr: Dict[str, int], names: List[str]) -> Dict[str, float]:
    vrs = [vr[n] for n in names]
    vals = fmu.getReal(vrs)
    return {n: float(v) for n, v in zip(names, vals)}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the outdoor-temperature rule-based controller with a fixed AC setpoint."
    )
    parser.add_argument(
        "--ac-sp-c",
        type=float,
        default=FIXED_AC_SP_C,
        help="Optional override for the fixed AC setpoint in Celsius.",
    )
    parser.add_argument(
        "--nv-enter-c",
        type=float,
        default=NV_OUTDOOR_ENTER_C,
        help="Outdoor temperature below which OFF/AC may enter NV, in Celsius.",
    )
    parser.add_argument(
        "--nv-exit-c",
        type=float,
        default=NV_OUTDOOR_EXIT_C,
        help="Outdoor temperature at or above which NV exits to OFF/AC, in Celsius.",
    )
    parser.add_argument(
        "--out-csv",
        type=Path,
        default=None,
        help="Optional output CSV path.",
    )
    parser.add_argument(
        "--horizon-hours",
        type=int,
        default=HOURS_TO_RUN,
        help="Simulation horizon in hours (default: 8760, capped by the input CSV).",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    fixed_ac_sp_c = validate_fixed_ac_sp_c(args.ac_sp_c)
    nv_enter_c, nv_exit_c = validate_nv_thresholds(args.nv_enter_c, args.nv_exit_c)
    out_csv = (
        args.out_csv
        if args.out_csv is not None
        else default_out_csv(fixed_ac_sp_c, nv_enter_c, nv_exit_c)
    )

    OUTDIR.mkdir(parents=True, exist_ok=True)
    out_csv.parent.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(INPUT_CSV, parse_dates=["datetime"])
    if len(df) < 1:
        raise RuntimeError("input_data.csv is empty")

    rain_hourly = df["LiquidPrecipitationDepth_mm"].to_numpy(dtype=float)

    base_datetime: Optional[pd.Timestamp] = None
    dt0 = pd.to_datetime(df["datetime"].iloc[0], errors="coerce")
    if not pd.isna(dt0):
        base_datetime = dt0.replace(hour=0, minute=0, second=0, microsecond=0)

    if args.horizon_hours <= 0:
        raise ValueError("--horizon-hours must be > 0")
    t_end_hours = int(min(args.horizon_hours, len(df)))
    t_end = float(t_end_hours) * 3600.0

    if DT_CONTROL <= 0 or DT_COMM <= 0 or DT_LOG <= 0:
        raise ValueError("DT_CONTROL, DT_COMM, DT_LOG must be > 0")
    if abs((DT_CONTROL / DT_LOG) - round(DT_CONTROL / DT_LOG)) > 1e-9:
        raise ValueError("DT_CONTROL must be an integer multiple of DT_LOG")

    unzipdir = extract(FMU_PATH)
    md = read_model_description(unzipdir)
    vr = {v.name: v.valueReference for v in md.modelVariables}

    required = [
        "TRooSet", "CO2Set", "uSysOn", "uWinOpe", "heaFra", "occFra",
        "TRoo", "CO2Roo", "yValChi", "yFanSup", "yDamOut",
        "PFanSup", "PFanRet", "PASHP", "weaBus.TDryBul", "weaBus.winSpe",
        "RhRoo", "winOpe.m2_flow",
    ]
    for name in required:
        if name not in vr:
            raise RuntimeError(f"Missing required FMU variable: {name}")

    fmu = FMU2Slave(
        guid=md.guid,
        unzipDirectory=unzipdir,
        modelIdentifier=md.coSimulation.modelIdentifier,
        instanceName="inst_rulebased",
    )
    fmu.instantiate()
    fmu.setupExperiment(startTime=0.0)
    fmu.enterInitializationMode()
    fmu.exitInitializationMode()

    controller = OutdoorTempRuleBasedController(
        fixed_ac_sp_c=fixed_ac_sp_c,
        nv_outdoor_enter_c=nv_enter_c,
        nv_outdoor_exit_c=nv_exit_c,
        min_ac_on_s=MIN_AC_ON_S,
        bypass_min_ac_on_when_unoccupied=BYPASS_MIN_AC_ON_WHEN_UNOCCUPIED,
    )
    air_speed_model = CombinedAirSpeedModel(AirSpeedModelConfig(fan_cmd_max_allowed=0.5))
    fan_controller = CeilingFanController()

    cols = [
        "time_s",
        "datetime_mdHM",
        "mode",
        "mode_num",
        "TRoo_K",
        "TRoo_C",
        "CO2Roo_ppm",
        "yValChi",
        "yFanSup",
        "yDamOut",
        "PFanSup_W",
        "PFanRet_W",
        "PASHP_W",
        "T_outdoor_K",
        "T_outdoor_C",
        "Trm_K",
        "Trm_C",
        "wind_speed_m_s",
        "window_m2_flow_kg_s",
        "window_face_velocity_m_s",
        "rain_mm",
        "heaFra",
        "occFra",
        "sp_requested_K",
        "sp_requested_C",
        "TRooSet_cmd_K",
        "TRooSet_cmd_C",
        "uSysOn_cmd",
        "uWinOpe_cmd",
        "sysOnBool_in",
        "winOpeBool_in",
        "mode_requested",
        "mode_applied",
        "override_reason",
        "reward_10min",
        "e_cold_K",
        "energy_kWh_10min",
        "energy_kWh_10min_true",
        "overridden",
        "P_sys_kW",
        "nv_allowed",
        "nv_benefit",
        "RhRoo_frac",
        "RhRoo_pct",
        "pmv_met",
        "pmv_clo",
        "pmv_wme",
        "ceiling_fan_cmd",
        "fan_air_speed_m_s",
        "ac_bg_air_speed_m_s",
        "nv_air_speed_m_s",
        "indoor_air_speed_m_s",
        "pmv",
        "ppd_pct",
        "prev_mode",
        "mode_switch_flag",
    ]

    # Initialize with OFF command at t=0.
    fmu.setReal([vr["TRooSet"]], [float(controller.fixed_ac_sp_k)])
    fmu.setReal([vr["CO2Set"]], [CO2_SETPOINT_PPM])
    fmu.setReal([vr["uSysOn"]], [0.0])
    fmu.setReal([vr["uWinOpe"]], [0.0])
    fmu.setReal([vr["heaFra"]], [0.0])
    fmu.setReal([vr["occFra"]], [0.0])

    signal_names = [
        "TRoo",
        "CO2Roo",
        "yValChi",
        "yFanSup",
        "yDamOut",
        "PFanSup",
        "PFanRet",
        "PASHP",
        "weaBus.TDryBul",
        "weaBus.winSpe",
        "RhRoo",
        "winOpe.m2_flow",
        "TRooSet",
        "uSysOn",
        "uWinOpe",
    ]

    n_minutes = int(round(DT_CONTROL / DT_LOG))

    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=cols)
        writer.writeheader()

        t = 0.0
        while t < t_end - 1e-9:
            h = int(t // 3600.0)
            h = min(max(h, 0), len(df) - 1)

            row_h = df.iloc[h]
            occ_fra = float(row_h["BldgOcc"])
            hea_fra = float(row_h["BldgLight"])
            rain_mm = rain_interp_mm(t, rain_hourly)

            pre = _fmu_get_reals(fmu, vr, ["TRoo", "weaBus.TDryBul", "weaBus.winSpe"])
            t_indoor_k = pre["TRoo"]
            t_outdoor_k = pre["weaBus.TDryBul"]
            wind_m_s = pre["weaBus.winSpe"]

            prev_mode_num = mode_to_num(controller.mode_prev)
            min_ac_hold_flag = (
                (prev_mode_num == MODE_AC)
                and (controller.ac_on_since_s is not None)
                and ((float(t) - float(controller.ac_on_since_s)) < controller.min_ac_on_s)
                and (occ_fra > 0.0)
            )

            base_dec, app_dec = controller.decide(
                t_s=t,
                t_indoor_k=t_indoor_k,
                t_outdoor_k=t_outdoor_k,
                wind_speed=wind_m_s,
                rain_mm=rain_mm,
                hea_fra=hea_fra,
                occ_fra=occ_fra,
            )

            mode_req_num = mode_to_num(base_dec.mode)
            mode_app_num = mode_to_num(app_dec.mode)
            overridden = float(mode_req_num != mode_app_num)
            override_reason = controller.last_override_reason if overridden > 0.0 else ""
            mode_switch_flag = float(mode_app_num != prev_mode_num)

            hazard = (rain_mm > 0.0) or (wind_m_s > WIND_LIMIT)
            too_cold = (t_outdoor_k <= T_WC_K)
            ac_hold_flag = (
                (prev_mode_num == MODE_AC)
                and (occ_fra > 0.0)
                and (min_ac_hold_flag or (base_dec.mode != "NV"))
            )
            nv_threshold_k = controller.nv_outdoor_exit_k if prev_mode_num == MODE_NV else controller.nv_outdoor_enter_k
            nv_temp_ok = t_outdoor_k < nv_threshold_k
            nv_allowed = float((not hazard) and (not too_cold) and nv_temp_ok and (not ac_hold_flag))
            nv_benefit = float(nv_temp_ok)

            # Apply final command for the next control interval.
            fmu.setReal([vr["TRooSet"]], [float(app_dec.TRooSet)])
            fmu.setReal([vr["CO2Set"]], [float(app_dec.CO2Set)])
            fmu.setReal([vr["uSysOn"]], [float(app_dec.uSysOn)])
            fmu.setReal([vr["uWinOpe"]], [float(app_dec.uWinOpe)])
            fmu.setReal([vr["heaFra"]], [float(app_dec.heaFra)])
            fmu.setReal([vr["occFra"]], [float(app_dec.occFra)])

            interval_energy_kwh = 0.0

            for _ in range(n_minutes):
                if t >= t_end - 1e-9:
                    break

                t_target = min(t + DT_LOG, t_end)
                dt_this_log = t_target - t

                # Advance FMU to next log point using communication steps.
                while t < t_target - 1e-9:
                    dt_step = min(DT_COMM, t_target - t)
                    fmu.doStep(currentCommunicationPoint=t, communicationStepSize=dt_step)
                    t += dt_step

                out = _fmu_get_reals(fmu, vr, signal_names)

                p_sys_kw = (out["PASHP"] + out["PFanSup"] + out["PFanRet"]) / 1000.0
                interval_energy_kwh += float(p_sys_kw) * (float(dt_this_log) / 3600.0)

                e_cold_k = float(max(0.0, c_to_k(TOO_COLD_OFF_C) - out["TRoo"]))
                rh_frac = float(out["RhRoo"])
                rh_pct = 100.0 * rh_frac
                window_m2_flow_kg_s = float(max(0.0, out["winOpe.m2_flow"]))
                fan_cmd = (
                    0.0
                    if float(app_dec.occFra) <= 0.0
                    else float(fan_controller.command(app_dec.mode, fixed_ac_sp_c, out["TRoo"]))
                )
                air_speed = air_speed_model.component_breakdown(
                    mode=app_dec.mode,
                    fan_cmd=fan_cmd,
                    window_mdot_kg_s=window_m2_flow_kg_s,
                    fan_allowed_when_off=False,
                )
                pmv_result = fanger_pmv(
                    ta_c=k_to_c(out["TRoo"]),
                    rh_pct=rh_pct,
                    air_speed_m_s=float(air_speed["v_effective_mps"]),
                    met=PMV_MET,
                    clo=PMV_CLO,
                    wme=PMV_WME,
                )

                writer.writerow(
                    {
                        "time_s": float(t),
                        "datetime_mdHM": simtime_to_ymd_hm(t, base_datetime),
                        "mode": app_dec.mode,
                        "mode_num": float(mode_app_num),
                        "TRoo_K": float(out["TRoo"]),
                        "TRoo_C": k_to_c(out["TRoo"]),
                        "CO2Roo_ppm": float(out["CO2Roo"]),
                        "yValChi": float(out["yValChi"]),
                        "yFanSup": float(out["yFanSup"]),
                        "yDamOut": float(out["yDamOut"]),
                        "PFanSup_W": float(out["PFanSup"]),
                        "PFanRet_W": float(out["PFanRet"]),
                        "PASHP_W": float(out["PASHP"]),
                        "T_outdoor_K": float(out["weaBus.TDryBul"]),
                        "T_outdoor_C": k_to_c(out["weaBus.TDryBul"]),
                        "Trm_K": float(app_dec.Trm),
                        "Trm_C": k_to_c(app_dec.Trm),
                        "wind_speed_m_s": float(out["weaBus.winSpe"]),
                        "window_m2_flow_kg_s": float(window_m2_flow_kg_s),
                        "window_face_velocity_m_s": float(air_speed["v_window_face_mps"]),
                        "rain_mm": float(rain_interp_mm(t, rain_hourly)),
                        "heaFra": float(app_dec.heaFra),
                        "occFra": float(app_dec.occFra),
                        "sp_requested_K": float(base_dec.TRooSet),
                        "sp_requested_C": k_to_c(base_dec.TRooSet),
                        "TRooSet_cmd_K": float(out["TRooSet"]),
                        "TRooSet_cmd_C": k_to_c(out["TRooSet"]),
                        "uSysOn_cmd": float(app_dec.uSysOn),
                        "uWinOpe_cmd": float(app_dec.uWinOpe),
                        "sysOnBool_in": 1.0 if float(out["uSysOn"]) > 0.5 else 0.0,
                        "winOpeBool_in": 1.0 if float(out["uWinOpe"]) > 0.1 else 0.0,
                        "mode_requested": float(mode_req_num),
                        "mode_applied": float(mode_app_num),
                        "override_reason": override_reason,
                        "reward_10min": np.nan,
                        "e_cold_K": e_cold_k,
                        "energy_kWh_10min": float(interval_energy_kwh),
                        "energy_kWh_10min_true": float(interval_energy_kwh),
                        "overridden": float(overridden),
                        "P_sys_kW": float(p_sys_kw),
                        "nv_allowed": float(nv_allowed),
                        "nv_benefit": float(nv_benefit),
                        "RhRoo_frac": float(rh_frac),
                        "RhRoo_pct": float(rh_pct),
                        "pmv_met": float(PMV_MET),
                        "pmv_clo": float(PMV_CLO),
                        "pmv_wme": float(PMV_WME),
                        "ceiling_fan_cmd": float(fan_cmd),
                        "fan_air_speed_m_s": float(air_speed["v_fan_effective_mps"]),
                        "ac_bg_air_speed_m_s": float(air_speed["v_ac_bg_mps"]),
                        "nv_air_speed_m_s": float(air_speed["v_nv_mps"]),
                        "indoor_air_speed_m_s": float(air_speed["v_effective_mps"]),
                        "pmv": float(pmv_result.pmv),
                        "ppd_pct": float(pmv_result.ppd_pct),
                        "prev_mode": float(prev_mode_num),
                        "mode_switch_flag": float(mode_switch_flag),
                    }
                )

    try:
        fmu.terminate()
    except Exception:
        pass
    fmu.freeInstance()

    print(f"Saved: {out_csv}")

    if PLOT_RESULTS:
        import matplotlib.pyplot as plt

        df_out = pd.read_csv(out_csv)
        ts_h = df_out["time_s"] / 3600.0

        plt.figure()
        plt.plot(ts_h, df_out["TRoo_C"])
        plt.xlabel("Time [h]")
        plt.ylabel("TRoo [C]")
        plt.title("Zone Temperature")

        plt.figure()
        plt.plot(ts_h, df_out["PASHP_W"])
        plt.xlabel("Time [h]")
        plt.ylabel("PASHP [W]")
        plt.title("ASHP Power")

        plt.show()


if __name__ == "__main__":
    main()
