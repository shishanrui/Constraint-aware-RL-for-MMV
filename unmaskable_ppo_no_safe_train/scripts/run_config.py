"""
Shared configuration for PMV training and evaluation scripts.
"""

from __future__ import annotations

import re
from dataclasses import asdict, dataclass, replace
from pathlib import Path
from typing import Any, Optional

from mmv_env.signals import AC_SP_C_MAX, AC_SP_C_MIN, AC_SP_STEP_C


@dataclass(frozen=True)
class SharedRunConfig:
    month: Optional[int] = None
    dt_comm_s: float = 10.0
    w_energy: float = 1.2
    w_pmv: float = 1.0
    w_invalid_request: float = 0.0
    w_switch: float = 0.15
    w_sp_jump: float = 0.05
    nv_bonus_beta: float = 0.15
    nv_bonus_unocc_beta: float = 0.05
    w_nv_unbenefit: float = 0.01

    total_timesteps: int = 1_500_000
    seed: int = 42
    ent_coef: float = 0.007

    model_name: str = ""


DEFAULT_RUN_CONFIG = SharedRunConfig()


def _slug(v: float) -> str:
    return str(v).replace(".", "p")


def action_space_tag() -> str:
    return f"sp{_slug(AC_SP_C_MIN)}to{_slug(AC_SP_C_MAX)}by{_slug(AC_SP_STEP_C)}_rbfan_spobs"


def resolve_model_name(cfg: SharedRunConfig = DEFAULT_RUN_CONFIG) -> str:
    if str(cfg.model_name).strip():
        return str(cfg.model_name).strip()
    return (
        f"ppo_mmv_pmv_flat_nosafety_v2_{action_space_tag()}"
        f"_wpmv{_slug(cfg.w_pmv)}"
        f"_we{_slug(cfg.w_energy)}"
        f"_winv{_slug(cfg.w_invalid_request)}"
        f"_ws{_slug(cfg.w_switch)}"
        f"_wspj{_slug(cfg.w_sp_jump)}"
        f"_nv{_slug(cfg.nv_bonus_beta)}"
        f"_nvu{_slug(cfg.nv_bonus_unocc_beta)}"
        f"_wnvu{_slug(cfg.w_nv_unbenefit)}"
        f"_ent{_slug(cfg.ent_coef)}"
        f"_s{int(cfg.seed)}"
    )


def resolve_eval_csv_name(cfg: SharedRunConfig = DEFAULT_RUN_CONFIG, *, eval_mode: str = "fixed_jan1") -> str:
    return f"{resolve_model_name(cfg)}_{str(eval_mode).strip().lower()}.csv"


def resolve_year_eval_csv_name(cfg: SharedRunConfig = DEFAULT_RUN_CONFIG) -> str:
    return f"{resolve_model_name(cfg)}_eval_year_minute.csv"


def scripts_dir() -> Path:
    return Path(__file__).resolve().parent


def model_dir() -> Path:
    return scripts_dir() / "models"


def tensorboard_log_dir() -> Path:
    return scripts_dir() / "logs"


def eval_output_dir() -> Path:
    return scripts_dir() / "mmv_rl_out"


def model_zip_path(cfg: SharedRunConfig = DEFAULT_RUN_CONFIG) -> Path:
    return model_dir() / f"{resolve_model_name(cfg)}.zip"


def vecnorm_path(cfg: SharedRunConfig = DEFAULT_RUN_CONFIG) -> Path:
    return model_dir() / f"{resolve_model_name(cfg)}_vecnorm.pkl"


def env_kwargs(cfg: SharedRunConfig = DEFAULT_RUN_CONFIG, *, seed: Optional[int] = None) -> dict:
    return {
        "month": cfg.month,
        "dt_comm_s": cfg.dt_comm_s,
        "w_energy": cfg.w_energy,
        "w_pmv": cfg.w_pmv,
        "w_invalid_request": cfg.w_invalid_request,
        "w_switch": cfg.w_switch,
        "w_sp_jump": cfg.w_sp_jump,
        "nv_bonus_beta": cfg.nv_bonus_beta,
        "nv_bonus_unocc_beta": cfg.nv_bonus_unocc_beta,
        "w_nv_unbenefit": cfg.w_nv_unbenefit,
        "seed": cfg.seed if seed is None else int(seed),
    }


def with_overrides(cfg: SharedRunConfig = DEFAULT_RUN_CONFIG, **overrides: Any) -> SharedRunConfig:
    valid = set(asdict(cfg).keys())
    invalid = [k for k in overrides if k not in valid]
    if invalid:
        raise ValueError(f"Unknown config override keys: {invalid}")
    return replace(cfg, **overrides)


def make_model_name(base_name: str, *, run_tag: Optional[str] = None, seed: Optional[int] = None) -> str:
    name = base_name
    if run_tag:
        name = f"{name}_{str(run_tag).strip()}"
    if seed is not None and re.search(r"(?:^|_)s\d+$", name) is None:
        name = f"{name}_s{int(seed)}"
    return name
