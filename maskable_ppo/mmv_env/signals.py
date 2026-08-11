"""
signals.py
Single source of truth for PMV training/evaluation constants.

Conventions:
- Temperatures in the RL pipeline are Kelvin (K).
- Relative humidity from the FMU is stored as fraction [0, 1].
- FMU power outputs are Watts (W).
- RL control step is 10 minutes (600 s).
"""

from __future__ import annotations

from pathlib import Path
from typing import Tuple


# -----------------------------
# FMU and csv file
# -----------------------------
ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

TRAIN_FMU_FILENAME = str(DATA / "HCDLabPMVPITrain.fmu")
EVAL_FMU_FILENAME = str(DATA / "HCDLabPMVPIEval.fmu")
FMU_FILENAME = TRAIN_FMU_FILENAME
INPUT_DATA_CSV = str(DATA / "input_data.csv")

# -----------------------------
# Time settings
# -----------------------------
DT_COMM_S: float = 10.0
DT_CONTROL_S: float = 600.0
DT_LOG_S: float = 60.0

# -----------------------------
# CSV input data
# -----------------------------
CSV_COL_DATETIME: str = "datetime"
CSV_COL_OCC: str = "BldgOcc"
CSV_COL_HEA: str = "BldgLight"
CSV_COL_WIND: str = "WindSpeed_m_s"
CSV_COL_RAIN: str = "LiquidPrecipitationDepth_mm"

# -----------------------------
# FMU variable names
# -----------------------------
IN_TROO_SET: str = "TRooSet"
IN_CO2_SET: str = "CO2Set"
IN_SYS_ON: str = "uSysOn"
IN_WIN_OPE: str = "uWinOpe"
IN_HEA_FRA: str = "heaFra"
IN_OCC_FRA: str = "occFra"

OUT_TROO: str = "TRoo"
OUT_CO2: str = "CO2Roo"
OUT_YVAL: str = "yValChi"
OUT_YFAN: str = "yFanSup"
OUT_YDAM: str = "yDamOut"
OUT_P_ASHP: str = "PASHP"
OUT_P_FAN_SUP: str = "PFanSup"
OUT_P_FAN_RET: str = "PFanRet"
OUT_RH_ROO: str = "RhRoo"
OUT_WIN_OPE_MASS_FLOW: str = "winOpe.m2_flow"

WEA_TDRYBUL: str = "weaBus.TDryBul"
WEA_WIN_SPE: str = "weaBus.winSpe"

# -----------------------------
# Control constants
# -----------------------------
CO2_SETPOINT_PPM: float = 800.0
OCC_ON_THRESHOLD: float = 0.05
T_WC_K: float = 273.15 + 18.0
WINDOW_COLD_LIMIT_ENABLED: bool = False
WIND_LIMIT_M_S: float = 8.0
MIN_AC_ON_S: float = 30.0 * 60.0

# -----------------------------
# PMV reward / shaping constants
# -----------------------------
PMV_COMFORT_DEADBAND: float = 0.5
FAN_JUMP_FREE_DELTA: float = 0.2

# ============================================================
# MULTI-DISCRETE ACTION SPACE WITH RL MODE + AC SETPOINT
# Ceiling fan is handled by a deterministic low-level controller.
# ============================================================

MODE_OFF: int = 0
MODE_NV: int = 1
MODE_AC: int = 2

AC_SP_C_MIN: float = 25.0
AC_SP_C_MAX: float = 30.0
AC_SP_STEP_C: float = 0.5

AC_SP_VALUES_C = [
    round(AC_SP_C_MIN + i * AC_SP_STEP_C, 3)
    for i in range(int(round((AC_SP_C_MAX - AC_SP_C_MIN) / AC_SP_STEP_C)) + 1)
]
N_AC_SP: int = len(AC_SP_VALUES_C)

N_MODES: int = 3
RULE_BASED_FAN_MAX_CMD: float = 0.5
ACTION_SPACE_NVECS: Tuple[int, int] = (N_MODES, N_AC_SP)


def decode_action(mode_idx: int, sp_idx: int):
    """
    Decode MultiDiscrete action into mode-conditional controls.

    Semantics:
    - OFF -> AC setpoint is ignored
    - NV  -> AC setpoint index is decoded for logging/action-space consistency,
             but the applied FMU setpoint and fan controller ignore it
    - AC  -> AC setpoint is applied directly
    """
    mode = int(mode_idx)
    sp_i = int(sp_idx)

    if mode == MODE_OFF:
        return MODE_OFF, None

    if mode in {MODE_NV, MODE_AC} and 0 <= sp_i < N_AC_SP:
        sp_c = AC_SP_VALUES_C[sp_i]
        return mode, sp_c + 273.15

    raise ValueError(f"Invalid MultiDiscrete action: mode_idx={mode_idx}, sp_idx={sp_idx}")
