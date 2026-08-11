from __future__ import annotations

from dataclasses import dataclass
import os
import sys
from pathlib import Path

_THIS_FILE = Path(__file__).resolve()
_ROOT = _THIS_FILE.parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import pandas as pd

from year_eval.eval_config import CFG


# -----------------------------
# settings
# -----------------------------
_base_csv = Path(CFG.output_csv)
_default_csv = _base_csv.with_name(
    f"{_base_csv.stem}_shieldv2_uacoff_nvfb-occupied_ac_sp29C{_base_csv.suffix}"
)
CSV_PATH = Path(os.getenv("MMV_YEAR_EVAL_CSV", str(_default_csv)))

MONTH = 5
WEEK_IN_MONTH = 4

# EXPORT_WEEK_DATA = False
EXPORT_WEEK_DATA = True
EXPORT_PATH = Path(CFG.output_dir) / "plot_week_raw.csv"

PRIMARY_LW = 2.0
SECONDARY_LW = 1.2
# SHOW_RH_IN_PMV = True
SHOW_RH_IN_PMV = False
SHOW_OCC_LINE = True

PALETTE = {
    "indoor_temp": "#0072B2",
    "outdoor_temp": "#56B4E9",
    "setpoint": "#7F7F7F",
    "occupied_fill": "#8C7C6D",
    "pmv": "#CC79A7",
    "pmv_band_fill": "#D8EAD3",
    "pmv_band_edge": "#7AA974",
    "rh": "#AFC6D9",
    "mode": "#009E73",
    "occ": "#8C7C6D",
    "fan": "#D55E00",
    "rain": "#B39DDB",
}


@dataclass(frozen=True)
class WeekSelection:
    month: int
    week_in_month: int


def _load_csv(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"CSV not found: {path}")
    df = pd.read_csv(path, low_memory=False)
    if "datetime_mdHM" not in df.columns:
        raise ValueError("Missing required column: datetime_mdHM")
    df["dt"] = pd.to_datetime(df["datetime_mdHM"], format="%Y/%m/%d %H:%M", errors="coerce")
    df = df[df["dt"].notna()].copy()
    if df.empty:
        raise ValueError("No valid datetime rows after parsing datetime_mdHM.")
    if "mode_num" not in df.columns and "mode" in df.columns:
        mode_map = {"OFF": 0.0, "NV": 1.0, "AC": 2.0}
        df["mode_num"] = df["mode"].map(mode_map)
    return df


def _assign_monday_from_jan1_week_keys(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    year_start = pd.Timestamp(year=int(out["dt"].dt.year.iloc[0]), month=1, day=1)
    day_offset = (out["dt"].dt.normalize() - year_start).dt.days
    pseudo_weekday = day_offset % 7
    out["week_start"] = out["dt"].dt.normalize() - pd.to_timedelta(pseudo_weekday, unit="D")
    out["month"] = out["dt"].dt.month
    return out


def _select_week(df: pd.DataFrame, sel: WeekSelection) -> pd.DataFrame:
    if sel.month < 1 or sel.month > 12:
        raise ValueError(f"Invalid month={sel.month}. Use 1..12.")
    if sel.week_in_month < 1:
        raise ValueError(f"Invalid week_in_month={sel.week_in_month}. Use >= 1.")

    work = _assign_monday_from_jan1_week_keys(df)
    month_df = work[work["month"] == sel.month].copy()
    if month_df.empty:
        raise ValueError(f"No rows found for month={sel.month}.")

    week_starts = sorted(month_df["week_start"].drop_duplicates().tolist())
    idx = sel.week_in_month - 1
    if idx >= len(week_starts):
        raise ValueError(
            f"month={sel.month} has only {len(week_starts)} synthetic weeks, "
            f"got week_in_month={sel.week_in_month}."
        )

    target_week_start = week_starts[idx]
    week_end = target_week_start + pd.Timedelta(days=7)
    week_df = work[(work["dt"] >= target_week_start) & (work["dt"] < week_end)].copy()
    if week_df.empty:
        raise ValueError("Selected week has no data rows.")
    return week_df


def _export_week_if_needed(df_week: pd.DataFrame) -> None:
    if not EXPORT_WEEK_DATA:
        return
    EXPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df_week.to_csv(EXPORT_PATH, index=False)
    print(f"[PLOT] Exported week raw data: {EXPORT_PATH}")


def _shade_occupied(ax: plt.Axes, df_week: pd.DataFrame) -> None:
    occ_mask = df_week["occFra"].fillna(0.0) > 0.0
    if not occ_mask.any():
        return

    dt = df_week["dt"].reset_index(drop=True)
    occ_mask = occ_mask.reset_index(drop=True)

    start_idx = None
    for idx, is_occ in enumerate(occ_mask):
        if is_occ and start_idx is None:
            start_idx = idx
        elif (not is_occ) and start_idx is not None:
            ax.axvspan(
                dt.iloc[start_idx],
                dt.iloc[idx],
                color=PALETTE["occupied_fill"],
                alpha=0.12,
                linewidth=0,
                zorder=0,
            )
            start_idx = None

    if start_idx is not None:
        ax.axvspan(
            dt.iloc[start_idx],
            dt.iloc[len(dt) - 1],
            color=PALETTE["occupied_fill"],
            alpha=0.12,
            linewidth=0,
            zorder=0,
        )


def _plot_week(df_week: pd.DataFrame, sel: WeekSelection) -> None:
    rh_col = "RhRoo_pct" if SHOW_RH_IN_PMV and "RhRoo_pct" in df_week.columns else None
    fan_air_speed_col = "indoor_air_speed_m_s"
    needed = [
        "TRoo_C",
        "T_outdoor_C",
        "TRooSet_cmd_C",
        "pmv",
        "rain_mm",
        "mode_num",
        "occFra",
        "ceiling_fan_cmd",
        fan_air_speed_col,
    ]
    missing = [c for c in needed if c not in df_week.columns]
    if missing:
        raise ValueError(f"Missing required columns for plotting: {missing}")

    fig, (ax_main, ax_pmv, ax_fan, ax_sub) = plt.subplots(
        4,
        1,
        figsize=(14, 10.0),
        sharex=True,
        gridspec_kw={"height_ratios": [2.0, 1.05, 0.95, 1.15], "hspace": 0.08},
        constrained_layout=True,
    )

    _shade_occupied(ax_main, df_week)
    ax_main.plot(
        df_week["dt"],
        df_week["TRoo_C"],
        label="TRoo_C",
        linewidth=PRIMARY_LW,
        color=PALETTE["indoor_temp"],
        zorder=3,
    )
    ax_main.plot(
        df_week["dt"],
        df_week["T_outdoor_C"],
        label="T_outdoor_C",
        linewidth=PRIMARY_LW,
        color=PALETTE["outdoor_temp"],
        zorder=2,
    )
    ax_main.plot(
        df_week["dt"],
        df_week["TRooSet_cmd_C"],
        label="TRooSet_cmd_C",
        linewidth=SECONDARY_LW,
        linestyle=(0, (5, 4)),
        color=PALETTE["setpoint"],
        zorder=2,
    )
    ax_main.set_ylabel("Temperature (C)")
    ax_main.grid(True, alpha=0.3)
    ax_main.legend(loc="upper center", ncol=3, frameon=False)

    ax_pmv.axhspan(-0.5, 0.5, color=PALETTE["pmv_band_fill"], alpha=0.5, zorder=0)
    _shade_occupied(ax_pmv, df_week)
    ax_pmv.plot(df_week["dt"], df_week["pmv"], label="pmv", linewidth=PRIMARY_LW, color=PALETTE["pmv"])
    ax_pmv.axhline(0.0, linewidth=SECONDARY_LW, linestyle=(0, (4, 4)), color=PALETTE["setpoint"], alpha=0.9)
    ax_pmv.axhline(0.5, linewidth=SECONDARY_LW, linestyle=(0, (2, 3)), color=PALETTE["pmv_band_edge"], alpha=0.9)
    ax_pmv.axhline(-0.5, linewidth=SECONDARY_LW, linestyle=(0, (2, 3)), color=PALETTE["pmv_band_edge"], alpha=0.9)
    ax_pmv.set_ylim(-2.0, 2.0)
    ax_pmv.set_ylabel("PMV")
    ax_pmv.grid(True, alpha=0.3)

    h_pmv, l_pmv = ax_pmv.get_legend_handles_labels()
    if rh_col is not None:
        ax_rh = ax_pmv.twinx()
        ax_rh.plot(
            df_week["dt"],
            df_week[rh_col],
            label=rh_col,
            linewidth=SECONDARY_LW,
            color=PALETTE["rh"],
            alpha=0.9,
        )
        ax_rh.set_ylabel("RH (%)", color=PALETTE["rh"])
        ax_rh.tick_params(axis="y", colors=PALETTE["rh"])
        ax_rh.set_ylim(0.0, 100.0)
        h_rh, l_rh = ax_rh.get_legend_handles_labels()
        ax_pmv.legend(h_pmv + h_rh, l_pmv + l_rh, loc="upper center", ncol=2, frameon=False)
    else:
        ax_pmv.legend(loc="upper center", ncol=1, frameon=False)

    ax_fan.step(
        df_week["dt"],
        df_week["ceiling_fan_cmd"],
        where="post",
        label="ceiling_fan_cmd",
        linewidth=PRIMARY_LW,
        color=PALETTE["fan"],
    )
    ax_fan.set_ylabel("fan cmd")
    ax_fan.set_ylim(0.0, 0.6)
    ax_fan.set_yticks([0.0, 0.2, 0.4, 0.6])
    ax_fan.grid(True, alpha=0.3)

    ax_fan_air = ax_fan.twinx()
    ax_fan_air.plot(
        df_week["dt"],
        df_week[fan_air_speed_col],
        label=fan_air_speed_col,
        linewidth=SECONDARY_LW,
        color=PALETTE["outdoor_temp"],
        alpha=0.9,
    )
    ax_fan_air.set_ylim(0.0, 1.5)
    ax_fan_air.set_yticks([0.0, 0.5, 1.0, 1.5])
    ax_fan_air.set_ylabel("air speed (m/s)", color=PALETTE["outdoor_temp"])
    ax_fan_air.tick_params(axis="y", colors=PALETTE["outdoor_temp"])

    h3, l3 = ax_fan.get_legend_handles_labels()
    h4, l4 = ax_fan_air.get_legend_handles_labels()
    ax_fan.legend(h3 + h4, l3 + l4, loc="upper center", ncol=2, frameon=False)

    ax_sub.step(
        df_week["dt"],
        df_week["mode_num"],
        where="post",
        label="mode_num",
        linewidth=PRIMARY_LW,
        color=PALETTE["mode"],
    )
    if SHOW_OCC_LINE:
        ax_sub.plot(
            df_week["dt"],
            df_week["occFra"],
            label="occFra",
            linewidth=SECONDARY_LW,
            color=PALETTE["occ"],
        )
    ax_sub.set_ylim(0.0, 2.05)
    ax_sub.set_ylabel("mode / occ")
    ax_sub.grid(True, alpha=0.3)

    ax_rain = ax_sub.twinx()
    ax_rain.plot(
        df_week["dt"],
        df_week["rain_mm"],
        label="rain_mm",
        linewidth=SECONDARY_LW,
        color=PALETTE["rain"],
    )
    ax_rain.set_ylabel("rain (mm)", color=PALETTE["rain"])
    ax_rain.tick_params(axis="y", colors=PALETTE["rain"])
    rain_max = max(2.0, float(df_week["rain_mm"].max()) * 1.2 if len(df_week) else 2.0)
    ax_rain.set_ylim(0.0, rain_max)

    h1, l1 = ax_sub.get_legend_handles_labels()
    h2, l2 = ax_rain.get_legend_handles_labels()
    ax_sub.legend(h1 + h2, l1 + l2, loc="upper center", ncol=3, frameon=False)

    ax_fan.xaxis.set_major_locator(mdates.DayLocator(interval=1))
    ax_fan.xaxis.set_major_formatter(mdates.DateFormatter("%m/%d"))
    ax_fan.set_xlabel("Date")

    week_start = df_week["dt"].min()
    week_end = df_week["dt"].max()
    x_start = week_start.normalize()
    x_end = week_end.normalize() + pd.Timedelta(days=1) - pd.Timedelta(minutes=1)
    ax_fan.set_xlim(x_start, x_end)
    fig.suptitle(
        f"Year Eval Week Plot (month={sel.month}, week={sel.week_in_month}) "
        f"{week_start:%Y-%m-%d} to {week_end:%Y-%m-%d}",
        fontsize=12,
    )
    plt.show()


def main() -> None:
    df = _load_csv(CSV_PATH)
    sel = WeekSelection(month=MONTH, week_in_month=WEEK_IN_MONTH)
    df_week = _select_week(df, sel)
    _export_week_if_needed(df_week)
    _plot_week(df_week, sel)


if __name__ == "__main__":
    main()
