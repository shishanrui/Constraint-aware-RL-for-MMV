"""
Feature engineering + history stacking for PMV RL.
"""

from __future__ import annotations

import math
from collections import deque
from dataclasses import dataclass
from typing import Deque, Optional

import numpy as np

from .pmv_model import PMVResult, fanger_pmv


def K_to_C(temp_k: float) -> float:
    return float(temp_k) - 273.15


@dataclass
class PMVState:
    pmv: float
    ppd_pct: float
    rh_pct: float
    air_speed_m_s: float


@dataclass
class FeatureOutput:
    obs: np.ndarray
    base_feat: np.ndarray
    pmv_state: PMVState


class FeatureBuilder:
    """Builds stacked observation vectors for PMV control."""

    def __init__(self, n_stack: int = 3):
        self.n_stack = int(n_stack)
        self.feat_hist: Deque[np.ndarray] = deque(maxlen=self.n_stack)
        self._base_dim: Optional[int] = None

    def reset_trm_history(self, prefill_tout_k=None) -> None:
        # Compatibility no-op for scripts that still call this method.
        _ = prefill_tout_k

    def reset_feature_history(self) -> None:
        self.feat_hist.clear()

    def _compute_pmv_state(
        self,
        *,
        TRoo_K: float,
        rh_frac: float,
        indoor_air_speed_m_s: float,
    ) -> PMVState:
        rh_pct = 100.0 * float(rh_frac)
        pmv_result: PMVResult = fanger_pmv(
            ta_c=K_to_C(TRoo_K),
            rh_pct=rh_pct,
            air_speed_m_s=float(indoor_air_speed_m_s),
        )
        return PMVState(
            pmv=float(pmv_result.pmv),
            ppd_pct=float(pmv_result.ppd_pct),
            rh_pct=float(rh_pct),
            air_speed_m_s=float(indoor_air_speed_m_s),
        )

    def _base_features(
        self,
        *,
        TRoo_K: float,
        Tout_K: float,
        pmv_state: PMVState,
        occFra: float,
        heaFra: float,
        wind_m_s: float,
        rain_mm: float,
        nv_allowed: float,
        prev_mode: int,
        time_since_ac_on_s: float,
        sp_applied_k: float,
        t_in_episode_s: float,
        P_sys_kW: float,
        fan_cmd: float,
    ) -> np.ndarray:
        t = float(t_in_episode_s)
        day_s = 86400.0
        week_s = 7.0 * 86400.0
        p_day = (t % day_s) / day_s
        p_week = (t % week_s) / week_s

        return np.array(
            [
                float(TRoo_K),
                float(Tout_K),
                float(Tout_K - TRoo_K),
                float(pmv_state.rh_pct),
                float(pmv_state.air_speed_m_s),
                float(pmv_state.pmv),
                float(occFra),
                float(heaFra),
                float(wind_m_s),
                float(rain_mm),
                float(nv_allowed),
                float(prev_mode),
                float(time_since_ac_on_s),
                float(sp_applied_k),
                float(fan_cmd),
                float(P_sys_kW),
                float(math.sin(2.0 * math.pi * p_day)),
                float(math.cos(2.0 * math.pi * p_day)),
                float(math.sin(2.0 * math.pi * p_week)),
                float(math.cos(2.0 * math.pi * p_week)),
            ],
            dtype=np.float32,
        )

    def build_obs(
        self,
        *,
        TRoo_K: float,
        Tout_K: float,
        occFra: float,
        heaFra: float,
        wind_m_s: float,
        rain_mm: float,
        rh_frac: float,
        indoor_air_speed_m_s: float,
        fan_cmd: float,
        nv_allowed: float = 0.0,
        prev_mode: int,
        time_since_ac_on_s: float,
        sp_applied_k: float,
        t_in_episode_s: float = 0.0,
        P_sys_kW: float = 0.0,
    ) -> FeatureOutput:
        pmv_state = self._compute_pmv_state(
            TRoo_K=TRoo_K,
            rh_frac=rh_frac,
            indoor_air_speed_m_s=indoor_air_speed_m_s,
        )
        base = self._base_features(
            TRoo_K=TRoo_K,
            Tout_K=Tout_K,
            pmv_state=pmv_state,
            occFra=occFra,
            heaFra=heaFra,
            wind_m_s=wind_m_s,
            rain_mm=rain_mm,
            nv_allowed=nv_allowed,
            prev_mode=prev_mode,
            time_since_ac_on_s=time_since_ac_on_s,
            sp_applied_k=sp_applied_k,
            t_in_episode_s=t_in_episode_s,
            P_sys_kW=P_sys_kW,
            fan_cmd=fan_cmd,
        )

        if self._base_dim is None:
            self._base_dim = int(base.shape[0])

        if len(self.feat_hist) == 0:
            for _ in range(self.n_stack):
                self.feat_hist.append(base.copy())
        else:
            self.feat_hist.append(base.copy())

        obs = np.concatenate(list(self.feat_hist), axis=0).astype(np.float32)
        return FeatureOutput(obs=obs, base_feat=base, pmv_state=pmv_state)

    @property
    def obs_dim(self) -> Optional[int]:
        if self._base_dim is None:
            return None
        return self._base_dim * self.n_stack
