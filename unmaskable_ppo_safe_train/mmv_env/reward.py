"""
Reward function for PMV-based MMV RL control.
"""

from __future__ import annotations

from dataclasses import dataclass

from .signals import FAN_JUMP_FREE_DELTA, OCC_ON_THRESHOLD, PMV_COMFORT_DEADBAND


JOULE_PER_KWH = 3.6e6


@dataclass
class RewardBreakdown:
    total_reward: float
    comfort_penalty: float
    energy_penalty: float
    unoccupied_ac_penalty: float
    nv_blocked_penalty: float
    nv_unbenefit_penalty: float
    min_ac_hold_penalty: float
    override_penalty: float
    nv_bonus: float
    nv_bonus_occ: float
    nv_bonus_unocc: float
    switch_penalty: float
    sp_jump_penalty: float
    energy_kwh: float


class RewardCalculator:
    def __init__(
        self,
        dt_control_s: float,
        w_energy: float = 1.0,
        w_pmv: float = 1.0,
        *,
        w_invalid_request: float = 0.10,
        w_switch: float = 0.02,
        nv_bonus_beta: float = 0.10,
        nv_bonus_unocc_beta: float = 0.05,
        w_nv_unbenefit: float = 0.01,
        mode_nv: int = 1,
        mode_ac: int = 2,
        w_sp_jump: float = 0.0,
        nv_benefit_margin_c: float = 0.3,
        pmv_inner_preference_band: float = 0.3,
        pmv_inner_preference_reward: float = 0.1,
        pmv_comfort_deadband: float = PMV_COMFORT_DEADBAND,
        fan_jump_free_delta: float = FAN_JUMP_FREE_DELTA,
        occ_on_threshold: float = OCC_ON_THRESHOLD,
    ):
        self.dt_control_s = float(dt_control_s)
        self.w_energy = float(w_energy)
        self.w_pmv = float(w_pmv)
        self.w_invalid_request = float(w_invalid_request)
        self.w_switch = float(w_switch)
        self.nv_bonus_beta = float(nv_bonus_beta)
        self.nv_bonus_unocc_beta = float(nv_bonus_unocc_beta)
        self.w_nv_unbenefit = float(w_nv_unbenefit)
        self.mode_nv = int(mode_nv)
        self.mode_ac = int(mode_ac)
        self.w_sp_jump = float(w_sp_jump)
        self.nv_benefit_margin_c = float(nv_benefit_margin_c)
        self.pmv_inner_preference_band = float(pmv_inner_preference_band)
        self.pmv_inner_preference_reward = float(pmv_inner_preference_reward)
        self.pmv_comfort_deadband = float(pmv_comfort_deadband)
        self.fan_jump_free_delta = float(fan_jump_free_delta)
        self.occ_on_threshold = float(occ_on_threshold)

    def power_to_kwh(self, power_w: float) -> float:
        return float(power_w) * self.dt_control_s / JOULE_PER_KWH

    def _comfort_penalty(self, pmv: float, occ_fra: float) -> float:
        if float(occ_fra) < self.occ_on_threshold:
            return 0.0
        abs_pmv = abs(float(pmv))
        inner = self.pmv_inner_preference_band
        outer = self.pmv_comfort_deadband
        peak = self.pmv_inner_preference_reward
        if abs_pmv <= inner:
            return self.w_pmv * peak
        if outer <= inner:
            return -self.w_pmv * ((abs_pmv - inner) ** 2)
        curvature = peak / ((outer - inner) ** 2)
        return self.w_pmv * (peak - curvature * ((abs_pmv - inner) ** 2))

    @staticmethod
    def _is_nv_block_reason(reason: str | None) -> bool:
        if reason is None:
            return False
        return str(reason) in {"rain_wind_block_nv", "tout_below_window_cold_limit"}

    def _nv_is_beneficial(self, *, tout_k: float | None, troo_k: float | None) -> bool:
        if tout_k is None or troo_k is None:
            return False
        return float(tout_k) < (float(troo_k) - self.nv_benefit_margin_c)

    def compute(
        self,
        *,
        pmv: float,
        occ_fra: float,
        prev_occ_fra: float,
        P_ashp_W: float,
        P_fan_sup_W: float,
        P_fan_ret_W: float,
        overridden: bool,
        override_reason: str | None,
        mode_requested: int,
        mode_applied: int,
        prev_mode: int,
        sp_applied_k: float | None = None,
        prev_sp_applied_k: float | None = None,
        nv_allowed: float = 0.0,
        tout_k: float | None = None,
        troo_k: float | None = None,
    ) -> RewardBreakdown:
        occ = float(occ_fra)
        comfort_penalty = self._comfort_penalty(pmv=pmv, occ_fra=occ)

        total_power_w = float(P_ashp_W) + float(P_fan_sup_W) + float(P_fan_ret_W)
        energy_kwh = self.power_to_kwh(total_power_w)
        energy_penalty = -self.w_energy * energy_kwh
        nv_blocked_penalty = 0.0
        unoccupied_ac_penalty = 0.0
        nv_unbenefit_penalty = 0.0
        min_ac_hold_penalty = 0.0
        if overridden and self._is_nv_block_reason(override_reason):
            nv_blocked_penalty = -self.w_invalid_request
        elif overridden and str(override_reason or "") == "min_ac_on_time_hold":
            min_ac_hold_penalty = -self.w_invalid_request
        elif overridden and str(override_reason or "") == "unoccupied_ac_block":
            unoccupied_ac_penalty = -self.w_invalid_request
        nv_beneficial = self._nv_is_beneficial(tout_k=tout_k, troo_k=troo_k)
        if int(mode_requested) == self.mode_nv and float(nv_allowed) >= 0.5 and not nv_beneficial:
            nv_unbenefit_penalty = -self.w_nv_unbenefit
        # Constraint priority ensures at most one invalid-request penalty is
        # applied at each decision step.
        override_penalty = nv_blocked_penalty + min_ac_hold_penalty + unoccupied_ac_penalty

        in_band = abs(float(pmv)) <= self.pmv_comfort_deadband
        nv_bonus_occ = (
            self.nv_bonus_beta
            if occ >= self.occ_on_threshold
            and int(mode_applied) == self.mode_nv
            and float(nv_allowed) >= 0.5
            and in_band
            else 0.0
        )
        nv_bonus_unocc = (
            self.nv_bonus_unocc_beta
            if occ < self.occ_on_threshold
            and int(mode_applied) == self.mode_nv
            and float(nv_allowed) >= 0.5
            and nv_beneficial
            else 0.0
        )
        nv_bonus = nv_bonus_occ + nv_bonus_unocc

        switch_penalty = -self.w_switch if int(mode_applied) != int(prev_mode) else 0.0

        sp_jump_penalty = 0.0
        if (
            int(prev_mode) == self.mode_ac
            and int(mode_applied) == self.mode_ac
            and prev_sp_applied_k is not None
            and sp_applied_k is not None
        ):
            delta_c = abs(float(sp_applied_k) - float(prev_sp_applied_k))
            excess_c = max(0.0, delta_c - 2.0)
            sp_jump_penalty = -self.w_sp_jump * excess_c

        total = (
            comfort_penalty
            + energy_penalty
            + override_penalty
            + nv_unbenefit_penalty
            + nv_bonus
            + switch_penalty
            + sp_jump_penalty
        )

        return RewardBreakdown(
            total_reward=float(total),
            comfort_penalty=float(comfort_penalty),
            energy_penalty=float(energy_penalty),
            unoccupied_ac_penalty=float(unoccupied_ac_penalty),
            nv_blocked_penalty=float(nv_blocked_penalty),
            nv_unbenefit_penalty=float(nv_unbenefit_penalty),
            min_ac_hold_penalty=float(min_ac_hold_penalty),
            override_penalty=float(override_penalty),
            nv_bonus=float(nv_bonus),
            nv_bonus_occ=float(nv_bonus_occ),
            nv_bonus_unocc=float(nv_bonus_unocc),
            switch_penalty=float(switch_penalty),
            sp_jump_penalty=float(sp_jump_penalty),
            energy_kwh=float(energy_kwh),
        )
