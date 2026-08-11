"""Post-sampling safety arbitration for the flat-PPO v2 experiments.

The constraint priority mirrors the MaskablePPO action mask:
1. Minimum AC-on hold.
2. Case-study unoccupied-AC lockout.
3. Weather/cold blocking of natural ventilation.

Training uses ``invalid_nv_fallback="off"`` so blocked NV cannot become an
indirect AC command. Evaluation may instead use ``"occupied_ac"`` as the
deployment-oriented protection sensitivity.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from .signals import (
    MIN_AC_ON_S,
    MODE_AC,
    MODE_NV,
    MODE_OFF,
    OCC_ON_THRESHOLD,
    T_WC_K,
    WINDOW_COLD_LIMIT_ENABLED,
    WIND_LIMIT_M_S,
)


INVALID_NV_FALLBACK_OFF = "off"
INVALID_NV_FALLBACK_OCCUPIED_AC = "occupied_ac"
VALID_INVALID_NV_FALLBACKS = {
    INVALID_NV_FALLBACK_OFF,
    INVALID_NV_FALLBACK_OCCUPIED_AC,
}


@dataclass(frozen=True)
class SafetyDecision:
    requested_mode: int
    applied_mode: int
    uSysOn: float
    uWinOpe: float
    TRooSet_K: float
    fan_cmd: float
    overridden: bool
    reason: Optional[str] = None
    invalid_nv_fallback_applied: bool = False


class SafetyShield:
    def __init__(
        self,
        wind_limit_m_s: float = WIND_LIMIT_M_S,
        min_ac_on_s: float = MIN_AC_ON_S,
        occ_on_threshold: float = OCC_ON_THRESHOLD,
        window_cold_limit_enabled: bool = WINDOW_COLD_LIMIT_ENABLED,
        invalid_nv_fallback: str = INVALID_NV_FALLBACK_OFF,
        fallback_ac_sp_k: Optional[float] = None,
    ):
        self.wind_limit_m_s = float(wind_limit_m_s)
        self.min_ac_on_s = float(min_ac_on_s)
        self.occ_on_threshold = float(occ_on_threshold)
        self.window_cold_limit_enabled = bool(window_cold_limit_enabled)
        fallback = str(invalid_nv_fallback).strip().lower()
        if fallback not in VALID_INVALID_NV_FALLBACKS:
            raise ValueError(
                f"invalid_nv_fallback must be one of {sorted(VALID_INVALID_NV_FALLBACKS)}, got {fallback!r}"
            )
        self.invalid_nv_fallback = fallback
        self.fallback_ac_sp_k = None if fallback_ac_sp_k is None else float(fallback_ac_sp_k)

    def decide(
        self,
        requested_mode: int,
        requested_troo_set_k: Optional[float],
        default_ac_sp_k: float,
        occ_fra: float,
        wind_m_s: float,
        rain_mm: float,
        currently_in_ac: bool,
        time_since_ac_on_s: float,
        tout_k: Optional[float] = None,
    ) -> SafetyDecision:
        req = int(requested_mode)
        req_sp_k = float(default_ac_sp_k) if requested_troo_set_k is None else float(requested_troo_set_k)

        applied = req
        overridden = False
        reason: Optional[str] = None
        invalid_nv_fallback_applied = False

        occupied = float(occ_fra) >= self.occ_on_threshold
        ac_hold = bool(currently_in_ac) and float(time_since_ac_on_s) < self.min_ac_on_s
        hazard = (float(rain_mm) > 0.0) or (float(wind_m_s) > self.wind_limit_m_s)
        too_cold = (
            self.window_cold_limit_enabled
            and tout_k is not None
            and float(tout_k) < T_WC_K
        )

        # Match the MaskablePPO priority: the equipment hold overrides the
        # occupancy lockout and weather gates.
        if ac_hold:
            if req != MODE_AC:
                applied = MODE_AC
                overridden = True
                reason = "min_ac_on_time_hold"
        elif req == MODE_AC and not occupied:
            applied = MODE_OFF
            overridden = True
            reason = "unoccupied_ac_block"
        elif req == MODE_NV and (hazard or too_cold):
            overridden = True
            reason = "rain_wind_block_nv" if hazard else "tout_below_window_cold_limit"
            if self.invalid_nv_fallback == INVALID_NV_FALLBACK_OCCUPIED_AC and occupied:
                applied = MODE_AC
                invalid_nv_fallback_applied = True
            else:
                applied = MODE_OFF

        if applied == MODE_OFF:
            u_sys_on = 0.0
            u_win_ope = 0.0
            troo_set = float(default_ac_sp_k)
        elif applied == MODE_NV:
            u_sys_on = 0.0
            u_win_ope = 1.0
            troo_set = float(default_ac_sp_k)
        elif applied == MODE_AC:
            u_sys_on = 1.0
            u_win_ope = 0.0
            troo_set = (
                float(self.fallback_ac_sp_k)
                if invalid_nv_fallback_applied and self.fallback_ac_sp_k is not None
                else float(req_sp_k)
            )
        else:
            raise ValueError(f"Unknown mode: {requested_mode}")

        return SafetyDecision(
            requested_mode=req,
            applied_mode=applied,
            uSysOn=u_sys_on,
            uWinOpe=u_win_ope,
            TRooSet_K=troo_set,
            fan_cmd=0.0,
            overridden=bool(overridden),
            reason=reason,
            invalid_nv_fallback_applied=bool(invalid_nv_fallback_applied),
        )
