from __future__ import annotations

import argparse
import sys
from pathlib import Path

_THIS_FILE = Path(__file__).resolve()
_PKG_ROOT = _THIS_FILE.parents[1]
_REPO_ROOT = _THIS_FILE.parents[2]
for _path in (_PKG_ROOT, _REPO_ROOT):
    if str(_path) not in sys.path:
        sys.path.insert(0, str(_path))

import pandas as pd

from mmv_env.signals import OCC_ON_THRESHOLD
from shared_eval.metrics import (
    compute_energy_metrics,
    compute_mode_and_switch_metrics,
    compute_time_weighted_pmv_nv_metrics,
)

# run in terminal
# python baseline_rl/scripts/analyze_eval_metrics.py baseline_rl/scripts/mmv_rl_out/eval_rl_minute_true_sp-all-6.csv

def fmt_pct(x: float) -> str:
    return f"{100.0 * float(x):.1f}%"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Analyze MMV eval CSV and report decision-step behavior metrics."
    )
    parser.add_argument(
        "csv_path",
        type=str,
        help="Path to eval CSV (minute-log format).",
    )
    parser.add_argument(
        "--decision-stride",
        type=int,
        default=10,
        help="Row stride to sample decision rows from minute logs (default: 10).",
    )
    args = parser.parse_args()

    csv_path = Path(args.csv_path)
    if not csv_path.exists():
        raise FileNotFoundError(f"CSV not found: {csv_path}")
    if args.decision_stride <= 0:
        raise ValueError("--decision-stride must be > 0")

    df = pd.read_csv(csv_path, low_memory=False)
    s = df.iloc[:: args.decision_stride].copy()

    required = [
        "mode_applied",
        "prev_mode",
        "mode_requested",
        "nv_allowed",
        "overridden",
        "override_reason",
        "pmv",
        "occFra",
    ]
    missing = [c for c in required if c not in s.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    pmv_nv_metrics = compute_time_weighted_pmv_nv_metrics(
        df,
        occ_threshold=OCC_ON_THRESHOLD,
    )
    energy_metrics = compute_energy_metrics(
        df,
        occ_threshold=OCC_ON_THRESHOLD,
    )
    decision_metrics = compute_mode_and_switch_metrics(
        s,
        occ_threshold=OCC_ON_THRESHOLD,
    )

    override_rate = (s["overridden"] >= 0.5).mean()
    override_counts = s.loc[s["overridden"] >= 0.5, "override_reason"].value_counts()

    req_nv_blocked = int(((s["mode_requested"] == 1) & (s["nv_allowed"] < 0.5)).sum())

    print(f"Decision steps: {decision_metrics['decision_steps']}")
    print(
        "Mode distribution: "
        f"OFF {decision_metrics['off_steps']}, "
        f"NV {decision_metrics['nv_steps']}, "
        f"AC {decision_metrics['ac_steps']}"
    )
    print(f"Total switch rate: {fmt_pct(decision_metrics['switch_rate'])}")
    print(
        f"OFF<->NV transitions: {decision_metrics['off_nv']} "
        f"({decision_metrics['off_to_nv']} OFF->NV, {decision_metrics['nv_to_off']} NV->OFF)"
    )
    print(
        f"OFF<->AC transitions: {decision_metrics['off_ac']} "
        f"({decision_metrics['off_to_ac']} OFF->AC, {decision_metrics['ac_to_off']} AC->OFF)"
    )

    if len(override_counts) == 0:
        override_txt = "none"
    else:
        override_txt = ", ".join([f"{k}: {int(v)}" for k, v in override_counts.items()])
    print(f"Overrides: {fmt_pct(override_rate)} ({override_txt})")

    print(
        "Policy still requests NV while blocked a lot: "
        f"{req_nv_blocked} requests with nv_allowed=0"
    )
    print(
        "In NV-viable PMV-comfort states (nv_allowed=1 & |pmv|<=0.5), "
        f"mode selection is {fmt_pct(decision_metrics['off_when_good_frac'])} OFF, "
        f"{fmt_pct(decision_metrics['nv_when_good_frac'])} NV, "
        f"{fmt_pct(decision_metrics['ac_when_good_frac'])} AC"
    )
    print(f"Discomfort present on {fmt_pct(decision_metrics['discomfort_rate_occ'])} of occupied decision steps")
    print(
        "Accumulated PMV violation during occupied time: "
        f"{pmv_nv_metrics['pmv_violation_occ_pmv_min']:.2f} PMV-min "
        f"(hot {pmv_nv_metrics['pmv_hot_violation_occ_pmv_min']:.2f}, "
        f"cold {pmv_nv_metrics['pmv_cold_violation_occ_pmv_min']:.2f})"
    )
    print(
        "NV usage metrics: "
        f"occupied_nv_hours={pmv_nv_metrics['occupied_nv_hours']:.2f} h, "
        f"occupied_nv_share={pmv_nv_metrics['occupied_nv_share_pct']:.1f}%, "
        f"nv_use_in_comfortable_nv_allowed={pmv_nv_metrics['nv_use_in_comfortable_nv_allowed_pct']:.1f}%"
    )
    print(
        "Energy use (from P_sys_kW): "
        f"total={energy_metrics['total_energy_kwh']:.2f} kWh, "
        f"avg={energy_metrics['avg_power_kw']:.2f} kW, "
        f"peak={energy_metrics['peak_power_kw']:.2f} kW"
    )
    print(
        "Energy by applied mode: "
        f"OFF {energy_metrics['energy_off_kwh']:.2f} kWh, "
        f"NV {energy_metrics['energy_nv_kwh']:.2f} kWh, "
        f"AC {energy_metrics['energy_ac_kwh']:.2f} kWh"
    )
    print(f"Decision-step interval: {decision_metrics['dt_decision_s'] / 60.0:.1f} min")
    print(f"Switches per hour: {decision_metrics['switches_per_hour']:.2f}")
    print(
        "Rolling 1h switch count: "
        f"max={decision_metrics['max_switches_1h']}, "
        f"p95={decision_metrics['p95_switches_1h']:.1f}"
    )
    print(
        "Short-dwell switch count: "
        f"<20min={decision_metrics['short_dwell_lt20']}, "
        f"<30min={decision_metrics['short_dwell_lt30']}, "
        f"<60min={decision_metrics['short_dwell_lt60']}"
    )
    print(
        "Reversal-like patterns (A->B->A): "
        f"<30min={decision_metrics['reversal_lt30']}, "
        f"<60min={decision_metrics['reversal_lt60']}"
    )
    reversal_examples = decision_metrics["reversal_examples"]
    if reversal_examples:
        top_rev = sorted(reversal_examples.items(), key=lambda kv: kv[1], reverse=True)[:6]
        print("[ANALYZE] Top reversal patterns: " + ", ".join([f"{k}: {v}" for k, v in top_rev]))
    dwell_by_mode_min = decision_metrics["dwell_by_mode_min"]
    dwell_parts = []
    for mode_name in ("OFF", "NV", "AC"):
        vals = dwell_by_mode_min.get(mode_name, [])
        if vals:
            series = pd.Series(vals)
            dwell_parts.append(
                f"{mode_name} median={series.median():.1f} min, p90={series.quantile(0.9):.1f} min"
            )
    if dwell_parts:
        print("Mode dwell stats: " + "; ".join(dwell_parts))


if __name__ == "__main__":
    main()

