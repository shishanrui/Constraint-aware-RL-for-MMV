from __future__ import annotations

import argparse
import csv
import re
import statistics
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable


_THIS_FILE = Path(__file__).resolve()
_ROOT = _THIS_FILE.parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from mmv_env.signals import (  # noqa: E402
    DT_CONTROL_S,
    DT_LOG_S,
    MIN_AC_ON_S,
    MODE_AC,
    MODE_NV,
    MODE_OFF,
    OCC_ON_THRESHOLD,
)


_DEFAULT_INPUT_DIR = _THIS_FILE.parent / "out" / "we1p2_nv0p15"
_DEFAULT_GLOB = "*_eval_year_minute.csv"
_DEFAULT_OUTPUT_NAME = "mask_activity_10seed_summary.csv"
_SEED_RE = re.compile(r"_s(?P<seed>\d+)_eval_year_minute\.csv$")

DECISION_ROW_OFFSET = 1
DECISION_ROW_STRIDE = int(round(DT_CONTROL_S / DT_LOG_S))

CONFIG_LABELS = {
    "111": "all_modes_available",
    "101": "nv_masked_only",
    "110": "ac_masked_only",
    "100": "nv_and_ac_masked_only_off_available",
    "001": "minimum_ac_hold_only_ac_available",
}


def _as_int(value: str) -> int:
    return int(round(float(value)))


def _seed_from_path(csv_path: Path) -> int:
    match = _SEED_RE.search(csv_path.name)
    if match is None:
        raise ValueError(f"Could not parse seed from filename: {csv_path.name}")
    return int(match.group("seed"))


def _add_count_rate_duration(row: dict[str, float | int | str], prefix: str, count: int, decisions: int) -> None:
    row[f"{prefix}_count"] = int(count)
    row[f"{prefix}_rate_pct"] = 100.0 * float(count) / float(decisions)
    row[f"{prefix}_duration_h"] = float(count) * DT_CONTROL_S / 3600.0


def analyze_csv(csv_path: Path) -> dict[str, float | int | str]:
    config_counts: Counter[str] = Counter()
    mask_entry_counts: Counter[str] = Counter()
    rule_counts: Counter[str] = Counter()
    total_rows = 0
    decisions = 0
    current_mode = MODE_OFF
    time_since_ac_on_s = 0.0
    prev_mode_mismatches = 0
    disallowed_requests = 0
    requested_applied_mismatches = 0

    with csv_path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        required = {
            "time_s",
            "mode_requested",
            "mode_applied",
            "nv_allowed",
            "prev_mode",
            "occFra",
        }
        missing = required.difference(reader.fieldnames or [])
        if missing:
            raise ValueError(f"{csv_path.name}: missing required columns {sorted(missing)}")

        for row_index, source_row in enumerate(reader):
            total_rows += 1
            # Row 0 is written before the first decision. Rows 1, 11, 21, ...
            # are the first one-minute samples after each 10-minute decision.
            if row_index % DECISION_ROW_STRIDE != DECISION_ROW_OFFSET:
                continue

            decisions += 1
            recorded_prev_mode = _as_int(source_row["prev_mode"])
            if recorded_prev_mode != current_mode:
                prev_mode_mismatches += 1

            ac_hold = current_mode == MODE_AC and time_since_ac_on_s < MIN_AC_ON_S
            nv_allowed = float(source_row["nv_allowed"]) >= 0.5
            occupied = float(source_row["occFra"]) >= OCC_ON_THRESHOLD

            if ac_hold:
                mode_mask = (False, False, True)
            else:
                mode_mask = (True, nv_allowed, occupied)

            mask_key = "".join("1" if allowed else "0" for allowed in mode_mask)
            config_counts[mask_key] += 1
            mask_entry_counts["off_masked"] += int(not mode_mask[MODE_OFF])
            mask_entry_counts["nv_masked"] += int(not mode_mask[MODE_NV])
            mask_entry_counts["ac_masked"] += int(not mode_mask[MODE_AC])
            mask_entry_counts["any_mode_restriction"] += int(mode_mask != (True, True, True))
            rule_counts["minimum_ac_hold"] += int(ac_hold)
            rule_counts["nv_unavailable_outside_hold"] += int((not ac_hold) and (not nv_allowed))
            rule_counts["unoccupied_ac_mask_outside_hold"] += int((not ac_hold) and (not occupied))

            requested_mode = _as_int(source_row["mode_requested"])
            applied_mode = _as_int(source_row["mode_applied"])
            if requested_mode not in (MODE_OFF, MODE_NV, MODE_AC):
                raise ValueError(f"{csv_path.name}: unexpected requested mode {requested_mode}")
            if not mode_mask[requested_mode]:
                disallowed_requests += 1
            if requested_mode != applied_mode:
                requested_applied_mismatches += 1

            if applied_mode == MODE_AC:
                if current_mode == MODE_AC:
                    time_since_ac_on_s += DT_CONTROL_S
                else:
                    time_since_ac_on_s = DT_CONTROL_S
            else:
                time_since_ac_on_s = 0.0
            current_mode = applied_mode

    if total_rows < 2:
        raise ValueError(f"{csv_path.name}: expected annual rows, found {total_rows}")
    if (total_rows - 1) % DECISION_ROW_STRIDE != 0:
        raise ValueError(
            f"{csv_path.name}: row count {total_rows} is incompatible with one initial row "
            f"plus {DECISION_ROW_STRIDE} log rows per decision"
        )
    expected_decisions = (total_rows - 1) // DECISION_ROW_STRIDE
    if decisions != expected_decisions:
        raise AssertionError(f"{csv_path.name}: reconstructed {decisions}, expected {expected_decisions} decisions")
    unexpected_configs = sorted(set(config_counts).difference(CONFIG_LABELS))
    if unexpected_configs:
        raise ValueError(f"{csv_path.name}: unexpected mask configurations {unexpected_configs}")
    if sum(config_counts.values()) != decisions:
        raise AssertionError(f"{csv_path.name}: mask configuration counts do not sum to decisions")
    if prev_mode_mismatches or disallowed_requests or requested_applied_mismatches:
        raise ValueError(
            f"{csv_path.name}: validation failed: prev_mode_mismatches={prev_mode_mismatches}, "
            f"disallowed_requests={disallowed_requests}, "
            f"requested_applied_mismatches={requested_applied_mismatches}"
        )

    result: dict[str, float | int | str] = {
        "row_type": "seed",
        "seed": _seed_from_path(csv_path),
        "source_file": csv_path.name,
        "minute_rows_including_initial": total_rows,
        "control_decisions": decisions,
        "prev_mode_mismatches": prev_mode_mismatches,
        "disallowed_requests": disallowed_requests,
        "requested_applied_mismatches": requested_applied_mismatches,
    }
    for mask_key, label in CONFIG_LABELS.items():
        _add_count_rate_duration(result, label, config_counts[mask_key], decisions)
    for label in ("off_masked", "nv_masked", "ac_masked", "any_mode_restriction"):
        _add_count_rate_duration(result, label, mask_entry_counts[label], decisions)
    for label in ("minimum_ac_hold", "nv_unavailable_outside_hold", "unoccupied_ac_mask_outside_hold"):
        _add_count_rate_duration(result, label, rule_counts[label], decisions)
    return result


def _numeric_columns(rows: list[dict[str, float | int | str]]) -> list[str]:
    excluded = {"row_type", "seed", "source_file"}
    return [key for key, value in rows[0].items() if key not in excluded and isinstance(value, (int, float))]


def _aggregate_row(
    rows: list[dict[str, float | int | str]],
    numeric_columns: Iterable[str],
    statistic: str,
) -> dict[str, float | int | str]:
    result: dict[str, float | int | str] = {
        "row_type": statistic,
        "seed": statistic,
        "source_file": "",
    }
    for column in numeric_columns:
        values = [float(row[column]) for row in rows]
        if statistic == "mean":
            result[column] = statistics.mean(values)
        elif statistic == "std":
            result[column] = statistics.stdev(values)
        else:
            raise ValueError(f"Unknown aggregate statistic: {statistic}")
    return result


def write_summary(rows: list[dict[str, float | int | str]], output_csv: Path) -> None:
    numeric_columns = _numeric_columns(rows)
    output_rows = [*rows]
    if len(rows) >= 2:
        output_rows.append(_aggregate_row(rows, numeric_columns, "mean"))
        output_rows.append(_aggregate_row(rows, numeric_columns, "std"))

    output_csv.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = list(rows[0].keys())
    with output_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output_rows)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Reconstruct MaskablePPO annual mode-mask activity from minute CSVs. "
            "The initial pre-decision row is excluded and one row per 10-minute decision is analyzed."
        )
    )
    parser.add_argument(
        "input_dir",
        nargs="?",
        default=str(_DEFAULT_INPUT_DIR),
        help=f"Directory containing annual minute CSVs (default: {_DEFAULT_INPUT_DIR}).",
    )
    parser.add_argument(
        "--glob",
        default=_DEFAULT_GLOB,
        help=f"Input filename glob (default: {_DEFAULT_GLOB}).",
    )
    parser.add_argument(
        "--output-csv",
        default="",
        help=f"Output summary CSV (default: <input_dir>/{_DEFAULT_OUTPUT_NAME}).",
    )
    parser.add_argument(
        "--expected-files",
        type=int,
        default=10,
        help="Expected number of seed CSVs; use 0 to disable this check (default: 10).",
    )
    args = parser.parse_args()

    input_dir = Path(args.input_dir).resolve()
    output_csv = Path(args.output_csv).resolve() if args.output_csv else input_dir / _DEFAULT_OUTPUT_NAME
    if not input_dir.is_dir():
        raise NotADirectoryError(f"Input directory not found: {input_dir}")

    csv_paths = sorted(input_dir.glob(args.glob), key=_seed_from_path)
    csv_paths = [path for path in csv_paths if path.resolve() != output_csv.resolve()]
    if not csv_paths:
        raise FileNotFoundError(f"No files matched '{args.glob}' under {input_dir}")
    if args.expected_files > 0 and len(csv_paths) != args.expected_files:
        raise ValueError(f"Expected {args.expected_files} files, found {len(csv_paths)} under {input_dir}")

    seeds = [_seed_from_path(path) for path in csv_paths]
    if len(seeds) != len(set(seeds)):
        raise ValueError(f"Duplicate seeds found: {seeds}")

    rows: list[dict[str, float | int | str]] = []
    for index, csv_path in enumerate(csv_paths, start=1):
        print(f"[MASK-ACTIVITY] {index}/{len(csv_paths)} seed={_seed_from_path(csv_path)} file={csv_path.name}")
        rows.append(analyze_csv(csv_path))

    write_summary(rows, output_csv)
    mean_row = _aggregate_row(rows, _numeric_columns(rows), "mean")
    std_row = _aggregate_row(rows, _numeric_columns(rows), "std")
    print(f"[MASK-ACTIVITY] saved: {output_csv}")
    print(
        "[MASK-ACTIVITY] mean +/- sample SD: "
        f"any restriction={mean_row['any_mode_restriction_rate_pct']:.2f} +/- "
        f"{std_row['any_mode_restriction_rate_pct']:.2f}%, "
        f"NV masked={mean_row['nv_masked_rate_pct']:.2f} +/- {std_row['nv_masked_rate_pct']:.2f}%, "
        f"AC masked={mean_row['ac_masked_rate_pct']:.2f} +/- {std_row['ac_masked_rate_pct']:.2f}%, "
        f"minimum-AC hold={mean_row['minimum_ac_hold_rate_pct']:.2f} +/- "
        f"{std_row['minimum_ac_hold_rate_pct']:.2f}%"
    )


if __name__ == "__main__":
    main()
