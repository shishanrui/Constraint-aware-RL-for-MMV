from __future__ import annotations

import argparse
import sys
from collections import deque
from pathlib import Path

_THIS_FILE = Path(__file__).resolve()
_REPO_ROOT = _THIS_FILE.parents[1]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

import numpy as np
import pandas as pd

OCC_ON_THRESHOLD = 0.05

from shared_eval.metrics import (
    compute_energy_metrics,
    compute_mode_and_switch_metrics,
    compute_time_weighted_pmv_nv_metrics,
    derive_power_kw,
)

DEFAULT_CSV = (
    Path(__file__).resolve().parent
    / "mmv_rulebased_out"
    / "rulebased_outdoor_temp_fixed_sp_30p0C_nv_enter_29p5C_exit_30p0C_dtcomm_1s.csv"
)
SAVE_ENRICHED_CSV = True


def fmt_pct(x: float) -> str:
    return f"{100.0 * float(x):.1f}%"


def _parse_datetime(series: pd.Series) -> pd.Series:
    dt = pd.to_datetime(series, format="%Y/%m/%d %H:%M", errors="coerce")
    if dt.notna().sum() == 0:
        dt = pd.to_datetime("2013-" + series.astype(str), format="%Y-%m-%d %H:%M", errors="coerce")
    if dt.notna().sum() == 0:
        dt = pd.to_datetime(series, errors="coerce")
    return dt


def _infer_dt_s(df: pd.DataFrame) -> float:
    if "time_s" in df.columns and len(df) >= 2:
        t = pd.to_numeric(df["time_s"], errors="coerce")
        dt = t.diff().dropna()
        if dt.size > 0:
            median_dt = float(dt.median())
            if median_dt > 0.0:
                return median_dt
    return 60.0


def _ensure_col(df: pd.DataFrame, name: str, default) -> None:
    if name not in df.columns:
        df[name] = default


def _derive_mode_applied(df: pd.DataFrame) -> None:
    if "mode_applied" in df.columns:
        df["mode_applied"] = pd.to_numeric(df["mode_applied"], errors="coerce")
        return

    if "mode_num" in df.columns:
        df["mode_applied"] = pd.to_numeric(df["mode_num"], errors="coerce")
        return

    if "mode" in df.columns:
        mode_map = {"OFF": 0.0, "NV": 1.0, "AC": 2.0}
        df["mode_applied"] = df["mode"].map(mode_map)
        return

    raise ValueError("Missing mode columns. Need one of: mode_applied, mode_num, mode")


def _derive_power_kw(df: pd.DataFrame) -> pd.Series:
    if "P_sys_kW" in df.columns:
        return pd.to_numeric(df["P_sys_kW"], errors="coerce").fillna(0.0)

    needed = ["PASHP_W", "PFanSup_W", "PFanRet_W"]
    if all(c in df.columns for c in needed):
        p_w = (
            pd.to_numeric(df["PASHP_W"], errors="coerce").fillna(0.0)
            + pd.to_numeric(df["PFanSup_W"], errors="coerce").fillna(0.0)
            + pd.to_numeric(df["PFanRet_W"], errors="coerce").fillna(0.0)
        )
        return p_w / 1000.0

    return pd.Series(0.0, index=df.index, dtype=float)


def _prepare_eval_df(df: pd.DataFrame) -> tuple[pd.DataFrame, str]:
    work = df.copy()

    _derive_mode_applied(work)
    _ensure_col(work, "mode_requested", work["mode_applied"])
    _ensure_col(work, "prev_mode", work["mode_applied"].shift(1).fillna(work["mode_applied"]))
    if "overridden" not in work.columns:
        work["overridden"] = (work["mode_requested"] != work["mode_applied"]).astype(float)
    _ensure_col(work, "override_reason", "")
    _ensure_col(work, "nv_allowed", float("nan"))
    _ensure_col(work, "occFra", 0.0)
    _ensure_col(work, "TRoo_C", pd.to_numeric(work.get("TRoo_K", np.nan), errors="coerce") - 273.15)

    work["mode_requested"] = pd.to_numeric(work["mode_requested"], errors="coerce")
    work["prev_mode"] = pd.to_numeric(work["prev_mode"], errors="coerce")
    work["overridden"] = pd.to_numeric(work["overridden"], errors="coerce").fillna(0.0)
    work["nv_allowed"] = pd.to_numeric(work["nv_allowed"], errors="coerce")
    work["occFra"] = pd.to_numeric(work["occFra"], errors="coerce").fillna(0.0)
    work["TRoo_C"] = pd.to_numeric(work["TRoo_C"], errors="coerce")

    if "pmv" not in work.columns:
        raise ValueError("Missing required column 'pmv' in RBC CSV.")
    work["pmv"] = pd.to_numeric(work["pmv"], errors="coerce")
    if work["pmv"].notna().sum() == 0:
        raise ValueError("Column 'pmv' is present but contains no numeric values.")
    if "ppd_pct" in work.columns:
        work["ppd_pct"] = pd.to_numeric(work["ppd_pct"], errors="coerce")
    else:
        work["ppd_pct"] = np.nan

    work["pmv_abs"] = pd.to_numeric(work["pmv"], errors="coerce").abs()
    work["pmv_comfort_ok"] = work["pmv_abs"] <= 0.5
    work["pmv_severe"] = work["pmv_abs"] > 1.0
    work["pmv_hot"] = pd.to_numeric(work["pmv"], errors="coerce") > 0.5
    work["pmv_cold"] = pd.to_numeric(work["pmv"], errors="coerce") < -0.5
    return work, "logged"


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


def _default_summary_path(csv_path: Path) -> Path:
    return csv_path.with_name(f"{csv_path.stem}_pmv_energy_summary.csv")


def _default_monthly_path(csv_path: Path) -> Path:
    return csv_path.with_name(f"{csv_path.stem}_pmv_energy_monthly.csv")


def _default_enriched_path(csv_path: Path) -> Path:
    return csv_path.with_name(f"{csv_path.stem}_pmv_enriched.csv")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Evaluate RBC PMV year CSV with RL-aligned decision-step metrics."
    )
    parser.add_argument("csv_path", nargs="?", default=str(DEFAULT_CSV), help="Path to RBC minute CSV.")
    parser.add_argument("--decision-stride", type=int, default=10, help="Row stride for decision sampling.")
    parser.add_argument("--summary-csv", type=Path, default=None, help="Optional summary CSV output path.")
    parser.add_argument("--monthly-csv", type=Path, default=None, help="Optional monthly summary CSV output path.")
    parser.add_argument("--enriched-csv", type=Path, default=None, help="Optional enriched minute CSV output path.")
    parser.add_argument("--no-save-enriched", action="store_true", help="Skip writing the enriched minute CSV.")
    args = parser.parse_args()

    csv_path = Path(args.csv_path)
    if not csv_path.exists():
        raise FileNotFoundError(f"CSV not found: {csv_path}")
    if args.decision_stride <= 0:
        raise ValueError("--decision-stride must be > 0")

    summary_csv = args.summary_csv if args.summary_csv is not None else _default_summary_path(csv_path)
    monthly_csv = args.monthly_csv if args.monthly_csv is not None else _default_monthly_path(csv_path)
    enriched_csv = args.enriched_csv if args.enriched_csv is not None else _default_enriched_path(csv_path)

    df = pd.read_csv(csv_path, low_memory=False)
    df_eval, pmv_source = _prepare_eval_df(df)

    pmv_nv_metrics = compute_time_weighted_pmv_nv_metrics(
        df_eval,
        occ_threshold=OCC_ON_THRESHOLD,
    )
    energy_metrics = compute_energy_metrics(
        df_eval,
        occ_threshold=OCC_ON_THRESHOLD,
    )

    s = df_eval.iloc[:: args.decision_stride].copy()
    decision_metrics = compute_mode_and_switch_metrics(
        s,
        occ_threshold=OCC_ON_THRESHOLD,
    )
    dt_s = float(pmv_nv_metrics["dt_s"])
    step_h = float(pmv_nv_metrics["step_h"])
    dt_min = float(pmv_nv_metrics["dt_min"])
    off = int(decision_metrics["off_steps"])
    nv = int(decision_metrics["nv_steps"])
    ac = int(decision_metrics["ac_steps"])
    switch_rate = float(decision_metrics["switch_rate"])
    off_to_nv = int(decision_metrics["off_to_nv"])
    nv_to_off = int(decision_metrics["nv_to_off"])
    off_nv = int(decision_metrics["off_nv"])
    off_to_ac = int(decision_metrics["off_to_ac"])
    ac_to_off = int(decision_metrics["ac_to_off"])
    off_ac = int(decision_metrics["off_ac"])
    off_when_good_frac = float(decision_metrics["off_when_good_frac"])
    nv_when_good_frac = float(decision_metrics["nv_when_good_frac"])
    discomfort_rate_occ = float(decision_metrics["discomfort_rate_occ"])
    dt_decision_s = float(decision_metrics["dt_decision_s"])
    switches_per_hour = float(decision_metrics["switches_per_hour"])
    max_switches_1h = int(decision_metrics["max_switches_1h"])
    p95_switches_1h = float(decision_metrics["p95_switches_1h"])
    short_20 = int(decision_metrics["short_dwell_lt20"])
    short_30 = int(decision_metrics["short_dwell_lt30"])
    short_60 = int(decision_metrics["short_dwell_lt60"])
    reversal_30 = int(decision_metrics["reversal_lt30"])
    reversal_60 = int(decision_metrics["reversal_lt60"])
    pmv_violation_occ_pmv_min = float(pmv_nv_metrics["pmv_violation_occ_pmv_min"])
    pmv_hot_violation_occ_pmv_min = float(pmv_nv_metrics["pmv_hot_violation_occ_pmv_min"])
    pmv_cold_violation_occ_pmv_min = float(pmv_nv_metrics["pmv_cold_violation_occ_pmv_min"])
    occupied_nv_hours = float(pmv_nv_metrics["occupied_nv_hours"])
    occupied_nv_share_pct = float(pmv_nv_metrics["occupied_nv_share_pct"])
    nv_use_in_comfortable_nv_allowed_pct = float(pmv_nv_metrics["nv_use_in_comfortable_nv_allowed_pct"])
    total_energy_kwh = float(energy_metrics["total_energy_kwh"])
    avg_power_kw = float(energy_metrics["avg_power_kw"])
    peak_power_kw = float(energy_metrics["peak_power_kw"])

    override_rate = float((pd.to_numeric(s["overridden"], errors="coerce").fillna(0.0) >= 0.5).mean()) if len(s) else 0.0
    override_counts = s.loc[pd.to_numeric(s["overridden"], errors="coerce").fillna(0.0) >= 0.5, "override_reason"].value_counts()

    req_nv_blocked = int(((pd.to_numeric(s["mode_requested"], errors="coerce") == 1) & (pd.to_numeric(s["nv_allowed"], errors="coerce") < 0.5)).sum())

    dwell_by_mode_min = decision_metrics["dwell_by_mode_min"]
    reversal_examples = decision_metrics["reversal_examples"]

    summary = {
        "csv_path": str(csv_path),
        "pmv_source": pmv_source,
        "rows": int(len(df_eval)),
        "decision_steps": int(decision_metrics["decision_steps"]),
        "decision_stride": int(args.decision_stride),
        "dt_s": float(pmv_nv_metrics["dt_s"]),
        "dt_decision_s": float(decision_metrics["dt_decision_s"]),
        "occupied_threshold": float(OCC_ON_THRESHOLD),
        "occupied_rows": int(pmv_nv_metrics["occupied_rows"]),
        "occupied_hours": float(pmv_nv_metrics["occupied_hours"]),
        "mean_pmv_occ": float(pmv_nv_metrics["mean_pmv_occ"]),
        "mean_abs_pmv_occ": float(pmv_nv_metrics["mean_abs_pmv_occ"]),
        "mean_ppd_occ_pct": float(pmv_nv_metrics["mean_ppd_occ_pct"]),
        "pmv_ok_rate_occ_pct": float(pmv_nv_metrics["pmv_ok_rate_occ_pct"]),
        "pmv_gt_0p5_rate_occ_pct": 100.0 * float(decision_metrics["discomfort_rate_occ"]),
        "pmv_gt_1p0_rate_occ_pct": float(pmv_nv_metrics["pmv_gt_1p0_rate_occ_pct"]),
        "pmv_hot_rate_occ_pct": float(pmv_nv_metrics["pmv_hot_rate_occ_pct"]),
        "pmv_cold_rate_occ_pct": float(pmv_nv_metrics["pmv_cold_rate_occ_pct"]),
        "pmv_violation_occ_pmv_min": float(pmv_nv_metrics["pmv_violation_occ_pmv_min"]),
        "pmv_hot_violation_occ_pmv_min": float(pmv_nv_metrics["pmv_hot_violation_occ_pmv_min"]),
        "pmv_cold_violation_occ_pmv_min": float(pmv_nv_metrics["pmv_cold_violation_occ_pmv_min"]),
        "pmv_violation_occ_pmv_per_occ_hour": float(pmv_nv_metrics["pmv_violation_occ_pmv_per_occ_hour"]),
        "occupied_nv_hours": float(pmv_nv_metrics["occupied_nv_hours"]),
        "occupied_nv_share_pct": float(pmv_nv_metrics["occupied_nv_share_pct"]),
        "nv_use_in_comfortable_nv_allowed_pct": float(pmv_nv_metrics["nv_use_in_comfortable_nv_allowed_pct"]),
        "switch_rate_pct": 100.0 * float(decision_metrics["switch_rate"]),
        "off_to_nv": int(decision_metrics["off_to_nv"]),
        "nv_to_off": int(decision_metrics["nv_to_off"]),
        "off_to_ac": int(decision_metrics["off_to_ac"]),
        "ac_to_off": int(decision_metrics["ac_to_off"]),
        "override_rate_pct": 100.0 * override_rate,
        "req_nv_blocked": int(req_nv_blocked),
        "off_when_nv_good_frac_pct": 100.0 * float(decision_metrics["off_when_good_frac"]),
        "nv_when_nv_good_frac_pct": 100.0 * float(decision_metrics["nv_when_good_frac"]),
        "switches_per_hour": float(decision_metrics["switches_per_hour"]),
        "max_switches_1h": int(decision_metrics["max_switches_1h"]),
        "p95_switches_1h": float(decision_metrics["p95_switches_1h"]),
        "short_dwell_lt20": int(decision_metrics["short_dwell_lt20"]),
        "short_dwell_lt30": int(decision_metrics["short_dwell_lt30"]),
        "short_dwell_lt60": int(decision_metrics["short_dwell_lt60"]),
        "reversal_lt30": int(decision_metrics["reversal_lt30"]),
        "reversal_lt60": int(decision_metrics["reversal_lt60"]),
        "annual_energy_kwh": float(energy_metrics["total_energy_kwh"]),
        "avg_power_kw": float(energy_metrics["avg_power_kw"]),
        "peak_power_kw": float(energy_metrics["peak_power_kw"]),
        "occupied_energy_kwh": float(energy_metrics["occupied_energy_kwh"]),
        "unoccupied_energy_kwh": float(energy_metrics["unoccupied_energy_kwh"]),
        "energy_off_kwh": float(energy_metrics["energy_off_kwh"]),
        "energy_nv_kwh": float(energy_metrics["energy_nv_kwh"]),
        "energy_ac_kwh": float(energy_metrics["energy_ac_kwh"]),
        "off_share_pct": float(decision_metrics["off_share_pct"]),
        "nv_share_pct": float(decision_metrics["nv_share_pct"]),
        "ac_share_pct": float(decision_metrics["ac_share_pct"]),
    }

    print(f"CSV: {csv_path}")
    print(
        f"Rows: {len(df_eval)}  | Decision steps: {decision_metrics['decision_steps']}  | "
        f"dt={pmv_nv_metrics['dt_s']:.1f}s  | pmv_source={pmv_source}"
    )
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

    override_txt = "none" if len(override_counts) == 0 else ", ".join([f"{k}: {int(v)}" for k, v in override_counts.items()])
    print(f"Overrides: {fmt_pct(override_rate)} ({override_txt})")
    print(f"Policy still requests NV while blocked a lot: {req_nv_blocked} requests with nv_allowed=0")
    print(
        "In NV-viable PMV-comfort states (nv_allowed=1 & |pmv|<=0.5), "
        f"mode selection is {fmt_pct(decision_metrics['off_when_good_frac'])} OFF, "
        f"{fmt_pct(decision_metrics['nv_when_good_frac'])} NV, "
        f"{fmt_pct(decision_metrics['ac_when_good_frac'])} AC"
    )
    print(f"Discomfort present on {fmt_pct(decision_metrics['discomfort_rate_occ'])} of occupied decision steps")
    print(
        "Accumulated PMV violation during occupied time: "
        f"{pmv_violation_occ_pmv_min:.2f} PMV·min "
        f"(hot {pmv_hot_violation_occ_pmv_min:.2f}, cold {pmv_cold_violation_occ_pmv_min:.2f})"
    )
    print(
        "NV usage metrics: "
        f"occupied_nv_hours={occupied_nv_hours:.2f} h, "
        f"occupied_nv_share={occupied_nv_share_pct:.1f}%, "
        f"nv_use_in_comfortable_nv_allowed={nv_use_in_comfortable_nv_allowed_pct:.1f}%"
    )
    print(
        "NV metric definitions: occupied_nv_hours and occupied_nv_share count only occupied NV time; "
        "nv_use_in_comfortable_nv_allowed is the fraction of occupied timesteps with nv_allowed=1 "
        "and |pmv|<=0.5 for which the applied mode is NV."
    )
    print(
        "Energy use (from P_sys_kW): "
        f"total={total_energy_kwh:.2f} kWh, avg={avg_power_kw:.2f} kW, peak={peak_power_kw:.2f} kW"
    )
    print(
        "Energy by applied mode: "
        f"OFF {summary['energy_off_kwh']:.2f} kWh, NV {summary['energy_nv_kwh']:.2f} kWh, AC {summary['energy_ac_kwh']:.2f} kWh"
    )
    print(f"Decision-step interval: {dt_decision_s / 60.0:.1f} min")
    print(f"Switches per hour: {switches_per_hour:.2f}")
    print(f"Rolling 1h switch count: max={max_switches_1h}, p95={p95_switches_1h:.1f}")
    print(f"Short-dwell switch count: <20min={short_20}, <30min={short_30}, <60min={short_60}")
    print(f"Reversal-like patterns (A->B->A): <30min={reversal_30}, <60min={reversal_60}")
    if reversal_examples:
        top_rev = sorted(reversal_examples.items(), key=lambda kv: kv[1], reverse=True)[:6]
        rev_txt = ", ".join([f"{k}: {v}" for k, v in top_rev])
        print(f"Top reversal patterns: {rev_txt}")
    dwell_parts = []
    for mode_name in ("OFF", "NV", "AC"):
        vals = dwell_by_mode_min.get(mode_name, [])
        if vals:
            series = pd.Series(vals)
            dwell_parts.append(f"{mode_name} median={series.median():.1f} min, p90={series.quantile(0.9):.1f} min")
    if dwell_parts:
        print("Mode dwell stats: " + "; ".join(dwell_parts))

    monthly_df = pd.DataFrame()
    if "datetime_mdHM" in df_eval.columns:
        dt = _parse_datetime(df_eval["datetime_mdHM"])
        valid = dt.notna()
        if valid.any():
            dfa = df_eval.loc[valid].copy()
            dfa["dt"] = dt.loc[valid]
            dfa["month"] = dfa["dt"].dt.month

            monthly_energy = (_derive_power_kw(dfa) * step_h).groupby(dfa["month"]).sum()
            print("Monthly energy (kWh):")
            print(monthly_energy.round(2).to_string())

            ds = dfa.iloc[:: args.decision_stride].copy()
            occ_mask_month = pd.to_numeric(ds["occFra"], errors="coerce").fillna(0.0) >= OCC_ON_THRESHOLD
            discomfort_month = pd.to_numeric(ds["pmv"], errors="coerce").abs() > 0.5
            monthly_discomfort = discomfort_month.loc[occ_mask_month].groupby(ds.loc[occ_mask_month, "month"]).mean() * 100.0
            print("Monthly discomfort rate (% occupied decision steps):")
            print(monthly_discomfort.round(2).to_string())

            mode_share = (
                ds.assign(mode=pd.to_numeric(ds["mode_applied"], errors="coerce"))
                .groupby(["month", "mode"])
                .size()
                .unstack(fill_value=0)
            )
            mode_share = mode_share.div(mode_share.sum(axis=1), axis=0) * 100.0
            print("Monthly mode share (%):")
            print(mode_share.round(1).to_string())

            monthly_rows = []
            months = sorted(set(dfa["month"].astype(int).tolist()))
            for month in months:
                g_full = dfa.loc[dfa["month"] == month]
                g_dec = ds.loc[ds["month"] == month]
                g_occ_full = g_full.loc[pd.to_numeric(g_full["occFra"], errors="coerce").fillna(0.0) >= OCC_ON_THRESHOLD]
                g_occ_dec = g_dec.loc[pd.to_numeric(g_dec["occFra"], errors="coerce").fillna(0.0) >= OCC_ON_THRESHOLD]
                pmv_occ_month = pd.to_numeric(g_occ_dec["pmv"], errors="coerce").dropna()
                pmv_occ_full_month = pd.to_numeric(g_occ_full["pmv"], errors="coerce")
                pmv_violation_occ_month = (pmv_occ_full_month.abs() - 0.5).clip(lower=0.0)
                mode_dec = pd.to_numeric(g_dec["mode_applied"], errors="coerce")
                monthly_rows.append(
                    {
                        "month": int(month),
                        "rows": int(len(g_full)),
                        "decision_steps": int(len(g_dec)),
                        "occupied_hours": float((pd.to_numeric(g_full["occFra"], errors="coerce").fillna(0.0) >= OCC_ON_THRESHOLD).sum() * step_h),
                        "energy_kwh": float((_derive_power_kw(g_full) * step_h).sum()),
                        "discomfort_rate_occ_pct": float(monthly_discomfort.get(month, np.nan)),
                        "mean_pmv_occ": float(pmv_occ_month.mean()) if len(pmv_occ_month) else float("nan"),
                        "mean_abs_pmv_occ": float(pmv_occ_month.abs().mean()) if len(pmv_occ_month) else float("nan"),
                        "pmv_violation_occ_pmv_min": float((pmv_violation_occ_month * dt_min).sum()),
                        "pmv_violation_occ_pmv_per_occ_hour": (
                            float((pmv_violation_occ_month * dt_min).sum()) / float(len(g_occ_full) * step_h)
                            if len(g_occ_full)
                            else 0.0
                        ),
                        "off_share_pct": 100.0 * float((mode_dec == 0.0).mean()) if len(g_dec) else 0.0,
                        "nv_share_pct": 100.0 * float((mode_dec == 1.0).mean()) if len(g_dec) else 0.0,
                        "ac_share_pct": 100.0 * float((mode_dec == 2.0).mean()) if len(g_dec) else 0.0,
                    }
                )
            monthly_df = pd.DataFrame(monthly_rows).sort_values("month")

    summary_csv.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame([summary]).to_csv(summary_csv, index=False)
    print(f"Saved summary CSV: {summary_csv}")

    if not monthly_df.empty:
        monthly_csv.parent.mkdir(parents=True, exist_ok=True)
        monthly_df.to_csv(monthly_csv, index=False)
        print(f"Saved monthly CSV: {monthly_csv}")

    if SAVE_ENRICHED_CSV and not args.no_save_enriched:
        enriched_csv.parent.mkdir(parents=True, exist_ok=True)
        df_eval.to_csv(enriched_csv, index=False)
        print(f"Saved enriched CSV: {enriched_csv}")


if __name__ == "__main__":
    main()
