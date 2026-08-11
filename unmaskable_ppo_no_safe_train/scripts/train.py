"""
Run PPO training for the PMV MMV pipeline.
"""

import sys
import argparse
import json
import socket
import subprocess
from dataclasses import asdict
from pathlib import Path

_THIS_FILE = Path(__file__).resolve()
_ROOT = _THIS_FILE.parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from agents.ppo_train import train_ppo
from scripts.run_config import (
    DEFAULT_RUN_CONFIG,
    make_model_name,
    model_dir,
    resolve_model_name,
    tensorboard_log_dir,
    with_overrides,
)


def _port_in_use(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


def start_tensorboard(logdir: Path, port: int = 6018) -> None:
    logdir = logdir.resolve()
    python_dir = Path(sys.executable).resolve().parent
    tb_candidates = (
        python_dir / "Scripts" / "tensorboard.exe",
        python_dir / "tensorboard.exe",
    )
    tb_exe = next((path for path in tb_candidates if path.exists()), tb_candidates[0])
    logdir.mkdir(parents=True, exist_ok=True)

    if _port_in_use(port):
        print(f"TensorBoard already running at http://localhost:{port}/")
        print(f"TensorBoard logdir: {logdir}")
        return

    if not tb_exe.exists():
        print(f"TensorBoard exe not found at: {tb_exe}")
        print("Install TensorBoard in the active Python environment or use --no-tb.")
        return

    subprocess.Popen(
        [str(tb_exe), "--logdir", str(logdir), "--port", str(port)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        creationflags=subprocess.CREATE_NEW_PROCESS_GROUP,
    )
    print(f"TensorBoard started at http://localhost:{port}/")
    print(f"TensorBoard logdir: {logdir}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Train no-safety flat PPO for PMV MMV with optional per-run overrides."
    )
    parser.add_argument("--run-tag", type=str, default="", help="Tag appended to model name.")
    parser.add_argument("--model-name", type=str, default="", help="Base model name override.")
    parser.add_argument("--seed", type=int, default=None, help="Seed override.")
    parser.add_argument("--month", type=int, default=None, help="Month override (1-12).")
    parser.add_argument("--total-timesteps", type=int, default=None, help="Training timesteps override.")
    parser.add_argument("--w-energy", type=float, default=None, help="Reward weight override.")
    parser.add_argument("--w-pmv", type=float, default=None, help="PMV comfort penalty weight.")
    parser.add_argument("--w-invalid-request", type=float, default=None, help="Must remain zero for the NoSafeTrain v2 negative control.")
    parser.add_argument("--w-switch", type=float, default=None, help="Switch penalty weight override.")
    parser.add_argument("--w-sp-jump", type=float, default=None, help="Large AC setpoint jump penalty weight override.")
    parser.add_argument("--nv-bonus-beta", type=float, default=None, help="Occupied NV bonus override.")
    parser.add_argument("--nv-bonus-unocc-beta", type=float, default=None, help="Unoccupied beneficial-NV bonus override.")
    parser.add_argument("--w-nv-unbenefit", type=float, default=None, help="Penalty for allowed but unbeneficial NV requests.")
    parser.add_argument("--ent-coef", type=float, default=None, help="PPO entropy coefficient override.")
    parser.add_argument("--tb-port", type=int, default=6018, help="TensorBoard port.")
    parser.add_argument("--no-tb", action="store_true", help="Disable TensorBoard auto-start.")
    args = parser.parse_args()

    overrides = {}
    if args.seed is not None:
        overrides["seed"] = args.seed
    if args.month is not None:
        overrides["month"] = args.month
    if args.total_timesteps is not None:
        overrides["total_timesteps"] = args.total_timesteps
    if args.w_energy is not None:
        overrides["w_energy"] = args.w_energy
    if args.w_pmv is not None:
        overrides["w_pmv"] = args.w_pmv
    if args.w_invalid_request is not None:
        overrides["w_invalid_request"] = args.w_invalid_request
    if args.w_switch is not None:
        overrides["w_switch"] = args.w_switch
    if args.w_sp_jump is not None:
        overrides["w_sp_jump"] = args.w_sp_jump
    if args.nv_bonus_beta is not None:
        overrides["nv_bonus_beta"] = args.nv_bonus_beta
    if args.nv_bonus_unocc_beta is not None:
        overrides["nv_bonus_unocc_beta"] = args.nv_bonus_unocc_beta
    if args.w_nv_unbenefit is not None:
        overrides["w_nv_unbenefit"] = args.w_nv_unbenefit
    if args.ent_coef is not None:
        overrides["ent_coef"] = args.ent_coef
    if args.model_name:
        overrides["model_name"] = args.model_name

    cfg = with_overrides(DEFAULT_RUN_CONFIG, **overrides)
    if float(cfg.w_invalid_request) != 0.0:
        raise ValueError("NoSafeTrain v2 requires --w-invalid-request 0")
    base_model_name = resolve_model_name(cfg)
    model_name = make_model_name(
        base_model_name,
        run_tag=args.run_tag if args.run_tag else None,
        seed=cfg.seed,
    )
    print(f"[TRAIN] model_name={model_name}")
    print(f"[TRAIN] Using dt_comm_s={cfg.dt_comm_s}")
    print("[TRAIN] training_constraint_mode=raw_actions_no_penalty")
    print("[TRAIN] train_invalid_nv_fallback=none")

    tb_logdir = tensorboard_log_dir()
    models_dir = model_dir()
    model_path = models_dir / f"{model_name}.zip"
    if model_path.exists():
        raise FileExistsError(f"Refusing to overwrite existing model: {model_path}")

    if not args.no_tb:
        start_tensorboard(tb_logdir, port=args.tb_port)

    train_ppo(
        month=cfg.month,
        total_timesteps=cfg.total_timesteps,
        dt_comm_s=cfg.dt_comm_s,
        w_energy=cfg.w_energy,
        w_pmv=cfg.w_pmv,
        w_invalid_request=cfg.w_invalid_request,
        w_switch=cfg.w_switch,
        w_sp_jump=cfg.w_sp_jump,
        nv_bonus_beta=cfg.nv_bonus_beta,
        nv_bonus_unocc_beta=cfg.nv_bonus_unocc_beta,
        w_nv_unbenefit=cfg.w_nv_unbenefit,
        ent_coef=cfg.ent_coef,
        model_dir=str(models_dir),
        model_name=model_name,
        tensorboard_log=str(tb_logdir),
        seed=cfg.seed,
    )
    manifest = {
        "experiment": "flat_nosafety_v2",
        "training_constraint_mode": "raw_actions_no_penalty",
        "train_invalid_nv_fallback": "none",
        "model_name": model_name,
        "config": asdict(cfg),
    }
    (models_dir / f"{model_name}_config.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
