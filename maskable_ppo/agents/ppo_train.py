"""
Stable-Baselines3 PPO training for the PMV MMV environment.
"""

from __future__ import annotations

import os
import random
from typing import Optional

import numpy as np
from sb3_contrib import MaskablePPO
import torch
from stable_baselines3.common.monitor import Monitor
from stable_baselines3.common.vec_env import DummyVecEnv, VecNormalize

from mmv_env.env import MMVEnv


def set_global_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def make_env(
    month: Optional[int],
    w_energy: float,
    w_pmv: float,
    w_nv_blocked: float,
    w_min_ac_hold: float,
    w_unocc_ac: float,
    w_switch: float,
    w_sp_jump: float,
    nv_bonus_beta: float,
    nv_bonus_unocc_beta: float,
    w_nv_unbenefit: float,
    seed: int,
):
    def _init():
        env = MMVEnv(
            month=month,
            w_energy=w_energy,
            w_pmv=w_pmv,
            w_nv_blocked=w_nv_blocked,
            w_min_ac_hold=w_min_ac_hold,
            w_unocc_ac=w_unocc_ac,
            w_switch=w_switch,
            w_sp_jump=w_sp_jump,
            nv_bonus_beta=nv_bonus_beta,
            nv_bonus_unocc_beta=nv_bonus_unocc_beta,
            w_nv_unbenefit=w_nv_unbenefit,
            seed=seed,
        )
        return Monitor(env)

    return _init


def train_ppo(
    month: Optional[int] = None,
    total_timesteps: int = 300_000,
    w_energy: float = 1.0,
    w_pmv: float = 1.0,
    w_nv_blocked: float = 0.08,
    w_min_ac_hold: float = 0.08,
    w_unocc_ac: float = 0.02,
    w_switch: float = 0.02,
    w_sp_jump: float = 0.05,
    nv_bonus_beta: float = 0.10,
    nv_bonus_unocc_beta: float = 0.05,
    w_nv_unbenefit: float = 0.01,
    ent_coef: float = 0.01,
    model_dir: str = "models",
    model_name: str = "ppo_mmv_pmv",
    tensorboard_log: Optional[str] = None,
    seed: int = 42,
):
    set_global_seed(seed)
    os.makedirs(model_dir, exist_ok=True)

    venv = DummyVecEnv(
        [
            make_env(
                month,
                w_energy,
                w_pmv,
                w_nv_blocked,
        w_min_ac_hold,
        w_unocc_ac,
        w_switch,
        w_sp_jump,
        nv_bonus_beta,
                nv_bonus_unocc_beta,
                w_nv_unbenefit,
                seed,
            )
        ]
    )
    venv.seed(seed)

    env = VecNormalize(
        venv,
        norm_obs=True,
        norm_reward=True,
        clip_obs=10.0,
    )
    env.reset()

    model = MaskablePPO(
        policy="MlpPolicy",
        env=env,
        verbose=1,
        device="cpu",
        learning_rate=lambda p: 5e-5 + (3e-4 - 5e-5) * p,
        n_steps=2048,
        batch_size=64,
        gamma=0.99,
        gae_lambda=0.95,
        clip_range=0.2,
        ent_coef=ent_coef,
        tensorboard_log=tensorboard_log,
        seed=seed,
    )

    model.learn(total_timesteps=total_timesteps, tb_log_name=model_name)
    model.save(os.path.join(model_dir, model_name))
    env.save(os.path.join(model_dir, model_name + "_vecnorm.pkl"))

    print("Training complete. Model saved.")
    return model
