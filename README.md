# Constraint-aware-RL-for-MMV

This repository contains the experiment code for comparing three reinforcement-learning formulations and an outdoor-temperature rule-based reference for single-zone mixed-mode ventilation (MMV) supervisory control. The RL controller selects an operating mode (`OFF`, natural ventilation, or air conditioning) and an air-conditioning setpoint in a calibrated Modelica/FMU testbed.

The comparison focuses on where known operational constraints are enforced in the RL loop:

| Directory | Controller | Feasibility handling |
| --- | --- | --- |
| `maskable_ppo/` | MaskablePPO | Removes infeasible modes from the policy distribution before sampling. |
| `unmaskable_ppo_safe_train/` | Standard PPO | Applies a training-time safety shield and penalizes corrected invalid requests. |
| `unmaskable_ppo_no_safe_train/` | Standard PPO | Applies requested actions without a training-time safety shield or invalid-request penalty; the common deployment shield is used during evaluation. |
| `rbc/` | Outdoor-temperature rule-based controller | Uses fixed MMV switching rules and fixed AC setpoints as a deterministic reference. |

The algorithms themselves are established methods. The repository implements their application and controlled comparison for the modeled MMV system.

## Platform and requirements

The included FMUs contain `binaries/win64` executables and therefore require 64-bit Windows. Rebuilding the FMUs with binaries for another platform would be necessary for Linux or macOS.

The current FMUs also require a valid Dymola runtime license at instantiation. Set `DYMOLA_RUNTIME_LICENSE` to the local license-file path before starting training, evaluation, or the RBC simulation:

```powershell
$env:DYMOLA_RUNTIME_LICENSE = 'C:\path\to\dymola.lic'
```

Do not commit the license file. Users without a compatible Dymola runtime license will need FMUs re-exported without that runtime dependency.

The bundle was smoke-tested with:

- Windows x86-64
- Python 3.11.14
- the package versions in `requirements.txt`

Create an isolated environment from the repository root:

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

PyTorch installation can depend on the desired CPU or CUDA build. If the pinned `torch` package is unsuitable for the target computer, install the appropriate PyTorch build first and then install the remaining requirements.

## Quick checks

The following commands import the complete training and evaluation surfaces without starting a long simulation:

```powershell
python .\maskable_ppo\scripts\train.py --help
python .\maskable_ppo\year_eval\evaluate_year.py --help
python .\unmaskable_ppo_safe_train\scripts\train.py --help
python .\unmaskable_ppo_no_safe_train\scripts\train.py --help
python .\rbc\outdoor_temp_rule_based_control.py --help
```

## Run an RL experiment

Training is computationally expensive. The default training budget is 1.5 million timesteps and each reset includes a seven-day FMU warm-up.

For the MaskablePPO configuration used in the matched manuscript comparison:

```powershell
python .\maskable_ppo\scripts\train.py `
  --seed 42 `
  --total-timesteps 1500000 `
  --w-energy 1.2 `
  --nv-bonus-beta 0.15
```

The two unmasked experiment folders already default to the matched base reward weights. Run one seed with:

```powershell
python .\unmaskable_ppo_safe_train\scripts\train.py --seed 42 --total-timesteps 1500000
python .\unmaskable_ppo_no_safe_train\scripts\train.py --seed 42 --total-timesteps 1500000
```

Add `--no-tb` to any training command to disable automatic TensorBoard startup. Models, normalization statistics, and TensorBoard logs are written within the selected experiment's `scripts/` directory.

Training embeds the main configuration values and seed in the model filename. For a multi-seed experiment, repeat the commands with the intended seed list while keeping all other options fixed.

## Evaluate a trained policy

Pretrained models are not included. After training, pass the saved model and matching `VecNormalize` file to the relevant evaluator:

```powershell
python .\maskable_ppo\year_eval\evaluate_year.py `
  --model-path .\maskable_ppo\scripts\models\MODEL_NAME.zip `
  --vecnorm-path .\maskable_ppo\scripts\models\MODEL_NAME_vecnorm.pkl
```

For either unmasked policy, evaluation applies the common deployment-oriented shield. Its default behavior maps weather-infeasible occupied NV requests to AC at 29 degrees C and unoccupied invalid requests to `OFF`:

```powershell
python .\unmaskable_ppo_safe_train\year_eval\evaluate_year.py `
  --model-path .\unmaskable_ppo_safe_train\scripts\models\MODEL_NAME.zip `
  --vecnorm-path .\unmaskable_ppo_safe_train\scripts\models\MODEL_NAME_vecnorm.pkl
```

Use `--horizon-hours` for a shorter diagnostic evaluation. Full-year evaluation uses 8,760 input hours, writes 60-second CSV records, and retains a 600-second supervisory decision interval.

## Run the rule-based reference

```powershell
python .\rbc\outdoor_temp_rule_based_control.py `
  --ac-sp-c 29.0 `
  --nv-enter-c 29.5 `
  --nv-exit-c 30.0
```

The RBC runner performs a full-year simulation by default. Its output is written under `rbc/mmv_rulebased_out/`. Use `--horizon-hours` for a shorter diagnostic run.

## Analyze outputs

Each RL folder contains year-evaluation analysis and representative-week plotting scripts. Shared metric definitions live in `shared_eval/` so the RL and RBC results use the same comfort, energy, mode, and switching calculations.

## Repository layout

```text
.
|-- maskable_ppo/
|-- unmaskable_ppo_safe_train/
|-- unmaskable_ppo_no_safe_train/
|-- rbc/
|-- shared_eval/
|-- README_SCRIPTS.md
`-- requirements.txt
```

Each RL experiment is intentionally self-contained and includes its own environment implementation, training/evaluation FMUs, weather and schedule input data, run configuration, and output directories. Do not interchange saved models or `VecNormalize` files between experiment folders.

## Reproducibility notes

- Training and evaluation use separate FMUs (`HCDLabPMVPITrain.fmu` and `HCDLabPMVPIEval.fmu`).
- The input CSV files contain 8,760 hourly records and are identical across the four controller folders.
- The RL control interval is 600 seconds. Training uses a 10-second FMU communication step; annual evaluation uses a 1-second communication step and 60-second logging.
- Saved normalization statistics must match the corresponding trained policy.
- The reported manuscript comparison uses ten independently trained seeds. This repository provides per-seed commands rather than a batch scheduler.


## Citation

If you find this repository useful, please cite:

> [Citation to be added]
