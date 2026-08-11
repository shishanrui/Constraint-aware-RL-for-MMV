from __future__ import annotations

import argparse
import subprocess
import sys
from collections import deque
from pathlib import Path

_THIS_FILE = Path(__file__).resolve()
_PKG_ROOT = _THIS_FILE.parents[1]
_REPO_ROOT = _THIS_FILE.parents[2]
for _path in (_PKG_ROOT, _REPO_ROOT):
    if str(_path) not in sys.path:
        sys.path.insert(0, str(_path))
_BASE_ANALYZE_SCRIPT = _PKG_ROOT / "scripts" / "analyze_eval_metrics.py"

import pandas as pd

from mmv_env.signals import OCC_ON_THRESHOLD
from shared_eval.metrics import (
    compute_energy_metrics,
    compute_mode_and_switch_metrics,
    compute_time_weighted_pmv_nv_metrics,
    derive_power_kw,
    infer_dt_s,
)
from year_eval.eval_config import CFG


def _compute_energy_kwh(df: pd.DataFrame) -> float:
    if "P_sys_kW" not in df.columns:
        return float("nan")
    p_kw = pd.to_numeric(df["P_sys_kW"], errors="coerce").fillna(0.0)
    if "time_s" in df.columns and len(df) >= 2:
        t = pd.to_numeric(df["time_s"], errors="coerce")
        dt = t.diff().dropna()
        dt_s = float(dt.median()) if dt.size > 0 else 60.0
    else:
        dt_s = 60.0
    if dt_s <= 0:
        dt_s = 60.0
    return float((p_kw * (dt_s / 3600.0)).sum())


def _mode_name(mode: int | float) -> str:
    m = int(mode)
    if m == 0:
        return "OFF"
    if m == 1:
        return "NV"
    if m == 2:
        return "AC"
    return f"UNK_{m}"


def _build_mode_segments(ds: pd.DataFrame, dt_decision_s: float) -> list[dict[str, float | int]]:
    if ds.empty or "mode_applied" not in ds.columns:
        return []

    modes = pd.to_numeric(ds["mode_applied"], errors="coerce").fillna(-1).astype(int).tolist()
    times = pd.to_numeric(ds["time_s"], errors="coerce").fillna(0.0).tolist()

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


def _rolling_switch_counts(switch_times_s: list[float], window_s: float) -> list[int]:
    counts: list[int] = []
    q: deque[float] = deque()
    for t in switch_times_s:
        q.append(float(t))
        while q and (float(t) - q[0]) > float(window_s):
            q.popleft()
        counts.append(len(q))
    return counts


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Year-eval wrapper: run baseline analyzer + year-specific monthly KPIs."
    )
    parser.add_argument(
        "csv_path",
        nargs="?",
        default=str(CFG.output_csv),
        help="Path to year-eval CSV (default: eval_config.CFG.output_csv).",
    )
    parser.add_argument(
        "--decision-stride",
        type=int,
        default=CFG.decision_stride,
        help="Row stride for decision-step sampling.",
    )
    args = parser.parse_args()

    csv_path = Path(args.csv_path)
    if not csv_path.exists():
        raise FileNotFoundError(f"CSV not found: {csv_path}")
    if args.decision_stride <= 0:
        raise ValueError("--decision-stride must be > 0")

    print("[YEAR-KPI] Running baseline analyzer:")
    subprocess.run(
        [
            sys.executable,
            str(_BASE_ANALYZE_SCRIPT),
            str(csv_path),
            "--decision-stride",
            str(args.decision_stride),
        ],
        check=True,
    )

    df = pd.read_csv(csv_path, low_memory=False)
    if "datetime_mdHM" not in df.columns:
        print("[YEAR-KPI] Skipped monthly KPIs: missing 'datetime_mdHM' column.")
        return

    dt = pd.to_datetime(df["datetime_mdHM"], format="%Y/%m/%d %H:%M", errors="coerce")
    valid = dt.notna()
    if not valid.any():
        print("[YEAR-KPI] Skipped monthly KPIs: datetime parsing failed for all rows.")
        return

    dfa = df.loc[valid].copy()
    dfa["dt"] = dt.loc[valid]
    dfa["month"] = dfa["dt"].dt.month

    pmv_nv_metrics = compute_time_weighted_pmv_nv_metrics(
        dfa,
        occ_threshold=OCC_ON_THRESHOLD,
    )
    energy_metrics = compute_energy_metrics(
        dfa,
        occ_threshold=OCC_ON_THRESHOLD,
    )
    print(f"[YEAR-KPI] Annual HVAC energy from P_sys_kW: {energy_metrics['total_energy_kwh']:.2f} kWh")
    print(
        "[YEAR-KPI] Accumulated occupied PMV violation: "
        f"{pmv_nv_metrics['pmv_violation_occ_pmv_min']:.2f} PMV-min "
        f"(hot {pmv_nv_metrics['pmv_hot_violation_occ_pmv_min']:.2f}, "
        f"cold {pmv_nv_metrics['pmv_cold_violation_occ_pmv_min']:.2f})"
    )
    print(
        "[YEAR-KPI] NV usage metrics: "
        f"occupied_nv_hours={pmv_nv_metrics['occupied_nv_hours']:.2f} h, "
        f"occupied_nv_share={pmv_nv_metrics['occupied_nv_share_pct']:.1f}%, "
        f"nv_use_in_comfortable_nv_allowed={pmv_nv_metrics['nv_use_in_comfortable_nv_allowed_pct']:.1f}%"
    )

    if "P_sys_kW" in dfa.columns and "time_s" in dfa.columns and len(dfa) >= 2:
        step_h = infer_dt_s(dfa) / 3600.0
        monthly_energy = (
            (derive_power_kw(dfa) * step_h)
            .groupby(dfa["month"])
            .sum()
        )
        print("[YEAR-KPI] Monthly energy (kWh):")
        print(monthly_energy.round(2).to_string())

    ds = dfa.iloc[:: args.decision_stride].copy()
    decision_metrics = compute_mode_and_switch_metrics(
        ds,
        occ_threshold=OCC_ON_THRESHOLD,
    )
    if {"pmv", "occFra"}.issubset(ds.columns):
        discomfort = pd.to_numeric(ds["pmv"], errors="coerce").abs() > 0.5
        occ_mask = pd.to_numeric(ds["occFra"], errors="coerce") >= OCC_ON_THRESHOLD
        monthly_discomfort = (discomfort.loc[occ_mask].groupby(ds.loc[occ_mask, "month"]).mean() * 100.0)
        print("[YEAR-KPI] Monthly discomfort rate (% occupied decision steps):")
        print(monthly_discomfort.round(2).to_string())

    if "mode_applied" in ds.columns:
        mode_share = (
            ds.assign(mode=pd.to_numeric(ds["mode_applied"], errors="coerce"))
            .groupby(["month", "mode"])
            .size()
            .unstack(fill_value=0)
        )
        mode_share = mode_share.div(mode_share.sum(axis=1), axis=0) * 100.0
        print("[YEAR-KPI] Monthly mode share (%):")
        print(mode_share.round(1).to_string())

    if {"mode_applied", "prev_mode", "time_s"}.issubset(ds.columns):
        print(f"[YEAR-KPI] Decision-step interval: {decision_metrics['dt_decision_s'] / 60.0:.1f} min")
        print(f"[YEAR-KPI] Switches per hour: {decision_metrics['switches_per_hour']:.2f}")
        print(
            "[YEAR-KPI] Rolling 1h switch count: "
            f"max={decision_metrics['max_switches_1h']}, p95={decision_metrics['p95_switches_1h']:.1f}"
        )
        print(
            "[YEAR-KPI] Short-dwell switch count: "
            f"<20min={decision_metrics['short_dwell_lt20']}, "
            f"<30min={decision_metrics['short_dwell_lt30']}, "
            f"<60min={decision_metrics['short_dwell_lt60']}"
        )
        print(
            "[YEAR-KPI] Reversal-like patterns (A->B->A): "
            f"<30min={decision_metrics['reversal_lt30']}, "
            f"<60min={decision_metrics['reversal_lt60']}"
        )
        reversal_examples = decision_metrics["reversal_examples"]
        if reversal_examples:
            top_rev = sorted(reversal_examples.items(), key=lambda kv: kv[1], reverse=True)[:6]
            rev_txt = ", ".join([f"{k}: {v}" for k, v in top_rev])
            print(f"[YEAR-KPI] Top reversal patterns: {rev_txt}")

        dwell_by_mode_min = decision_metrics["dwell_by_mode_min"]
        dwell_parts = []
        for mode_label in ("OFF", "NV", "AC"):
            vals = dwell_by_mode_min.get(mode_label, [])
            if vals:
                s = pd.Series(vals)
                dwell_parts.append(
                    f"{mode_label} median={s.median():.1f} min, p90={s.quantile(0.9):.1f} min"
                )
        if dwell_parts:
            print("[YEAR-KPI] Mode dwell stats: " + "; ".join(dwell_parts))


if __name__ == "__main__":
    main()
