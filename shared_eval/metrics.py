from __future__ import annotations

from collections import deque
from typing import Any

import numpy as np
import pandas as pd


def infer_dt_s(df: pd.DataFrame, *, time_col: str = "time_s", fallback_dt_s: float = 60.0) -> float:
    if time_col in df.columns and len(df) >= 2:
        t = pd.to_numeric(df[time_col], errors="coerce")
        dt = t.diff().dropna()
        if dt.size > 0:
            median_dt = float(dt.median())
            if median_dt > 0.0:
                return median_dt
    return float(fallback_dt_s)


def ensure_mode_applied(
    df: pd.DataFrame,
    *,
    mode_applied_col: str = "mode_applied",
    mode_num_col: str = "mode_num",
    mode_text_col: str = "mode",
) -> pd.Series:
    if mode_applied_col in df.columns:
        return pd.to_numeric(df[mode_applied_col], errors="coerce")
    if mode_num_col in df.columns:
        return pd.to_numeric(df[mode_num_col], errors="coerce")
    if mode_text_col in df.columns:
        return df[mode_text_col].map({"OFF": 0.0, "NV": 1.0, "AC": 2.0})
    raise ValueError(
        f"Missing mode columns. Need one of: {mode_applied_col}, {mode_num_col}, {mode_text_col}"
    )


def derive_power_kw(
    df: pd.DataFrame,
    *,
    p_sys_kw_col: str = "P_sys_kW",
    p_ashp_col: str = "PASHP_W",
    p_fan_sup_col: str = "PFanSup_W",
    p_fan_ret_col: str = "PFanRet_W",
) -> pd.Series:
    if p_sys_kw_col in df.columns:
        return pd.to_numeric(df[p_sys_kw_col], errors="coerce").fillna(0.0)
    needed = [p_ashp_col, p_fan_sup_col, p_fan_ret_col]
    if all(c in df.columns for c in needed):
        p_w = (
            pd.to_numeric(df[p_ashp_col], errors="coerce").fillna(0.0)
            + pd.to_numeric(df[p_fan_sup_col], errors="coerce").fillna(0.0)
            + pd.to_numeric(df[p_fan_ret_col], errors="coerce").fillna(0.0)
        )
        return p_w / 1000.0
    return pd.Series(0.0, index=df.index, dtype=float)


def compute_time_weighted_pmv_nv_metrics(
    df: pd.DataFrame,
    *,
    occ_threshold: float,
    mode_col: str = "mode_applied",
    occ_col: str = "occFra",
    pmv_col: str = "pmv",
    ppd_col: str = "ppd_pct",
    nv_allowed_col: str = "nv_allowed",
    nv_mode_value: float = 1.0,
    nv_allowed_threshold: float = 0.5,
    pmv_comfort_band: float = 0.5,
    pmv_severe_band: float = 1.0,
) -> dict[str, float]:
    dt_s = infer_dt_s(df)
    step_h = dt_s / 3600.0
    dt_min = dt_s / 60.0

    mode = pd.to_numeric(df[mode_col], errors="coerce")
    occ = pd.to_numeric(df[occ_col], errors="coerce").fillna(0.0)
    pmv = pd.to_numeric(df[pmv_col], errors="coerce")
    ppd = (
        pd.to_numeric(df[ppd_col], errors="coerce")
        if ppd_col in df.columns
        else pd.Series(np.nan, index=df.index, dtype=float)
    )
    nv_allowed = (
        pd.to_numeric(df[nv_allowed_col], errors="coerce").fillna(0.0)
        if nv_allowed_col in df.columns
        else pd.Series(0.0, index=df.index, dtype=float)
    )

    occupied_mask = occ >= occ_threshold
    occupied_hours = float(occupied_mask.sum() * step_h)
    pmv_occ = pmv.loc[occupied_mask].dropna()
    ppd_occ = ppd.loc[occupied_mask].dropna()
    pmv_abs_full = pmv.abs()
    pmv_violation_full = (pmv_abs_full - pmv_comfort_band).clip(lower=0.0)
    pmv_hot_violation_full = (pmv - pmv_comfort_band).clip(lower=0.0)
    pmv_cold_violation_full = ((-pmv_comfort_band) - pmv).clip(lower=0.0)

    occupied_nv_mask = occupied_mask & (mode == nv_mode_value)
    comfortable_nv_allowed_mask = (
        occupied_mask
        & (nv_allowed >= nv_allowed_threshold)
        & (pmv_abs_full <= pmv_comfort_band)
    )

    return {
        "dt_s": float(dt_s),
        "step_h": float(step_h),
        "dt_min": float(dt_min),
        "occupied_rows": int(occupied_mask.sum()),
        "occupied_hours": float(occupied_hours),
        "mean_pmv_occ": float(pmv_occ.mean()) if len(pmv_occ) else float("nan"),
        "mean_abs_pmv_occ": float(pmv_occ.abs().mean()) if len(pmv_occ) else float("nan"),
        "mean_ppd_occ_pct": float(ppd_occ.mean()) if len(ppd_occ) else float("nan"),
        "pmv_ok_rate_occ_pct": 100.0 * float((pmv_occ.abs() <= pmv_comfort_band).mean()) if len(pmv_occ) else 0.0,
        "pmv_gt_0p5_rate_occ_pct": 100.0 * float((pmv_occ.abs() > pmv_comfort_band).mean()) if len(pmv_occ) else 0.0,
        "pmv_gt_1p0_rate_occ_pct": 100.0 * float((pmv_occ.abs() > pmv_severe_band).mean()) if len(pmv_occ) else 0.0,
        "pmv_hot_rate_occ_pct": 100.0 * float((pmv_occ > pmv_comfort_band).mean()) if len(pmv_occ) else 0.0,
        "pmv_cold_rate_occ_pct": 100.0 * float((pmv_occ < -pmv_comfort_band).mean()) if len(pmv_occ) else 0.0,
        "pmv_violation_occ_pmv_min": float((pmv_violation_full.loc[occupied_mask] * dt_min).sum()),
        "pmv_hot_violation_occ_pmv_min": float((pmv_hot_violation_full.loc[occupied_mask] * dt_min).sum()),
        "pmv_cold_violation_occ_pmv_min": float((pmv_cold_violation_full.loc[occupied_mask] * dt_min).sum()),
        "pmv_violation_occ_pmv_per_occ_hour": (
            float((pmv_violation_full.loc[occupied_mask] * dt_min).sum()) / occupied_hours
            if occupied_mask.any()
            else 0.0
        ),
        "occupied_nv_hours": float(occupied_nv_mask.sum() * step_h),
        "occupied_nv_share_pct": (
            100.0 * float(occupied_nv_mask.sum()) / float(occupied_mask.sum())
            if occupied_mask.any()
            else 0.0
        ),
        "nv_use_in_comfortable_nv_allowed_pct": (
            100.0 * float((mode.loc[comfortable_nv_allowed_mask] == nv_mode_value).mean())
            if comfortable_nv_allowed_mask.any()
            else 0.0
        ),
    }


def compute_energy_metrics(
    df: pd.DataFrame,
    *,
    occ_threshold: float,
    mode_col: str = "mode_applied",
) -> dict[str, float]:
    dt_s = infer_dt_s(df)
    step_h = dt_s / 3600.0
    p_kw = derive_power_kw(df)
    mode = pd.to_numeric(df[mode_col], errors="coerce")
    occ = pd.to_numeric(df["occFra"], errors="coerce").fillna(0.0)
    occupied_mask = occ >= occ_threshold
    energy_by_mode = (
        pd.DataFrame({"mode_applied": mode, "energy_kwh": p_kw * step_h})
        .groupby("mode_applied", dropna=True)["energy_kwh"]
        .sum()
        .to_dict()
    )
    return {
        "dt_s": float(dt_s),
        "step_h": float(step_h),
        "total_energy_kwh": float((p_kw * step_h).sum()),
        "avg_power_kw": float(p_kw.mean()),
        "peak_power_kw": float(p_kw.max()),
        "occupied_energy_kwh": float((p_kw.loc[occupied_mask] * step_h).sum()),
        "unoccupied_energy_kwh": float((p_kw.loc[~occupied_mask] * step_h).sum()),
        "energy_off_kwh": float(energy_by_mode.get(0.0, 0.0)),
        "energy_nv_kwh": float(energy_by_mode.get(1.0, 0.0)),
        "energy_ac_kwh": float(energy_by_mode.get(2.0, 0.0)),
    }


def mode_name(mode: int | float) -> str:
    m = int(mode)
    if m == 0:
        return "OFF"
    if m == 1:
        return "NV"
    if m == 2:
        return "AC"
    return f"UNK_{m}"


def build_mode_segments(
    df_decision: pd.DataFrame,
    *,
    dt_decision_s: float,
    mode_col: str = "mode_applied",
    time_col: str = "time_s",
) -> list[dict[str, float | int]]:
    if df_decision.empty or mode_col not in df_decision.columns:
        return []

    modes = pd.to_numeric(df_decision[mode_col], errors="coerce").fillna(-1).astype(int).tolist()
    times = pd.to_numeric(df_decision[time_col], errors="coerce").fillna(0.0).tolist()

    segments: list[dict[str, float | int]] = []
    start_idx = 0
    for i in range(1, len(modes) + 1):
        if i == len(modes) or modes[i] != modes[start_idx]:
            length = i - start_idx
            segments.append(
                {
                    "mode": int(modes[start_idx]),
                    "start_t_s": float(times[start_idx]),
                    "end_t_s": float(times[i - 1]) + float(dt_decision_s),
                    "dwell_s": float(length) * float(dt_decision_s),
                    "steps": int(length),
                }
            )
            start_idx = i
    return segments


def rolling_switch_counts(switch_times_s: list[float], *, window_s: float) -> list[int]:
    counts: list[int] = []
    q: deque[float] = deque()
    for t in switch_times_s:
        q.append(float(t))
        while q and (float(t) - q[0]) > float(window_s):
            q.popleft()
        counts.append(len(q))
    return counts


def compute_mode_and_switch_metrics(
    df_decision: pd.DataFrame,
    *,
    occ_threshold: float,
    dt_decision_s: float | None = None,
    mode_col: str = "mode_applied",
    prev_mode_col: str = "prev_mode",
    occ_col: str = "occFra",
    pmv_col: str = "pmv",
    nv_allowed_col: str = "nv_allowed",
    pmv_comfort_band: float = 0.5,
    off_mode_value: float = 0.0,
    nv_mode_value: float = 1.0,
    ac_mode_value: float = 2.0,
    nv_allowed_threshold: float = 0.5,
) -> dict[str, Any]:
    if dt_decision_s is None:
        dt_decision_s = infer_dt_s(df_decision, fallback_dt_s=600.0)

    mode_now = pd.to_numeric(df_decision[mode_col], errors="coerce").fillna(-1)
    mode_prev = pd.to_numeric(df_decision[prev_mode_col], errors="coerce").fillna(-1)
    pmv = pd.to_numeric(df_decision[pmv_col], errors="coerce")
    occ = pd.to_numeric(df_decision[occ_col], errors="coerce").fillna(0.0)
    nv_allowed = (
        pd.to_numeric(df_decision[nv_allowed_col], errors="coerce").fillna(0.0)
        if nv_allowed_col in df_decision.columns
        else pd.Series(0.0, index=df_decision.index, dtype=float)
    )
    switched = mode_now != mode_prev

    off = int((mode_now == off_mode_value).sum())
    nv = int((mode_now == nv_mode_value).sum())
    ac = int((mode_now == ac_mode_value).sum())

    off_to_nv = int(((mode_prev == off_mode_value) & (mode_now == nv_mode_value)).sum())
    nv_to_off = int(((mode_prev == nv_mode_value) & (mode_now == off_mode_value)).sum())
    off_to_ac = int(((mode_prev == off_mode_value) & (mode_now == ac_mode_value)).sum())
    ac_to_off = int(((mode_prev == ac_mode_value) & (mode_now == off_mode_value)).sum())

    discomfort = pmv.abs() > pmv_comfort_band
    occ_mask = occ >= occ_threshold
    discomfort_rate_occ = float(discomfort.loc[occ_mask].mean()) if occ_mask.any() else 0.0

    nv_good = (nv_allowed >= nv_allowed_threshold) & (pmv.abs() <= pmv_comfort_band)
    n_nv_good = int(nv_good.sum())
    if n_nv_good > 0:
        off_when_good = int(((mode_now == off_mode_value) & nv_good).sum())
        nv_when_good = int(((mode_now == nv_mode_value) & nv_good).sum())
        ac_when_good = int(((mode_now == ac_mode_value) & nv_good).sum())
        off_when_good_frac = off_when_good / n_nv_good
        nv_when_good_frac = nv_when_good / n_nv_good
        ac_when_good_frac = ac_when_good / n_nv_good
    else:
        off_when_good = 0
        nv_when_good = 0
        ac_when_good = 0
        off_when_good_frac = 0.0
        nv_when_good_frac = 0.0
        ac_when_good_frac = 0.0

    time_s = pd.to_numeric(
        df_decision.get("time_s", pd.Series(np.arange(len(df_decision)) * dt_decision_s, index=df_decision.index)),
        errors="coerce",
    ).fillna(0.0)
    switch_times_s = time_s.loc[switched].astype(float).tolist()
    total_hours = max(float(len(df_decision)) * float(dt_decision_s) / 3600.0, 1e-9)
    switches_per_hour = float(switched.sum()) / total_hours if len(df_decision) else 0.0
    rolling_1h = rolling_switch_counts(switch_times_s, window_s=3600.0)

    segments = build_mode_segments(df_decision, dt_decision_s=float(dt_decision_s), mode_col=mode_col)
    short_20 = 0
    short_30 = 0
    short_60 = 0
    dwell_by_mode_min: dict[str, list[float]] = {"OFF": [], "NV": [], "AC": []}
    for idx, seg in enumerate(segments):
        dwell_min = float(seg["dwell_s"]) / 60.0
        seg_mode_name = mode_name(int(seg["mode"]))
        if seg_mode_name in dwell_by_mode_min:
            dwell_by_mode_min[seg_mode_name].append(dwell_min)
        if idx < len(segments) - 1:
            if dwell_min < 20.0:
                short_20 += 1
            if dwell_min < 30.0:
                short_30 += 1
            if dwell_min < 60.0:
                short_60 += 1

    reversal_30 = 0
    reversal_60 = 0
    reversal_examples: dict[str, int] = {}
    for i in range(2, len(segments)):
        a = int(segments[i - 2]["mode"])
        b = int(segments[i - 1]["mode"])
        c = int(segments[i]["mode"])
        b_dwell_min = float(segments[i - 1]["dwell_s"]) / 60.0
        if a == c and a != b:
            key = f"{mode_name(a)}->{mode_name(b)}->{mode_name(c)}"
            reversal_examples[key] = reversal_examples.get(key, 0) + 1
            if b_dwell_min < 30.0:
                reversal_30 += 1
            if b_dwell_min < 60.0:
                reversal_60 += 1

    return {
        "dt_decision_s": float(dt_decision_s),
        "decision_steps": int(len(df_decision)),
        "off_steps": int(off),
        "nv_steps": int(nv),
        "ac_steps": int(ac),
        "off_share_pct": 100.0 * (off / len(df_decision)) if len(df_decision) else 0.0,
        "nv_share_pct": 100.0 * (nv / len(df_decision)) if len(df_decision) else 0.0,
        "ac_share_pct": 100.0 * (ac / len(df_decision)) if len(df_decision) else 0.0,
        "switch_rate": float(switched.mean()) if len(df_decision) else 0.0,
        "off_to_nv": int(off_to_nv),
        "nv_to_off": int(nv_to_off),
        "off_nv": int(off_to_nv + nv_to_off),
        "off_to_ac": int(off_to_ac),
        "ac_to_off": int(ac_to_off),
        "off_ac": int(off_to_ac + ac_to_off),
        "discomfort_rate_occ": float(discomfort_rate_occ),
        "n_nv_good": int(n_nv_good),
        "off_when_good": int(off_when_good),
        "nv_when_good": int(nv_when_good),
        "ac_when_good": int(ac_when_good),
        "off_when_good_frac": float(off_when_good_frac),
        "nv_when_good_frac": float(nv_when_good_frac),
        "ac_when_good_frac": float(ac_when_good_frac),
        "switches_per_hour": float(switches_per_hour),
        "max_switches_1h": int(max(rolling_1h) if rolling_1h else 0),
        "p95_switches_1h": float(pd.Series(rolling_1h).quantile(0.95)) if rolling_1h else 0.0,
        "short_dwell_lt20": int(short_20),
        "short_dwell_lt30": int(short_30),
        "short_dwell_lt60": int(short_60),
        "reversal_lt30": int(reversal_30),
        "reversal_lt60": int(reversal_60),
        "dwell_by_mode_min": dwell_by_mode_min,
        "reversal_examples": reversal_examples,
        "segments": segments,
    }

