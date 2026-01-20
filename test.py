import os
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO

# 1. Load the Environment
env = StableBaselinesGodotEnv(env_path=None, show_window=True)

# 2. Load the Trained Brain
model_path = "my_platformer_brain.zip"
if not os.path.exists(model_path):
    print("❌ Error: Could not find the trained model file!")
    exit()

model = PPO.load(model_path, env=env)

print("🎮 Inference Mode: Watching the AI play...")

# --- FIXED SECTION BELOW ---

# FIX 1: VecEnv reset() returns ONLY 'obs'
obs = env.reset()

while True:
    action, _states = model.predict(obs, deterministic=False)

    # FIX 2: VecEnv step() returns 4 values (obs, rewards, dones, infos)
    # It does NOT return 'truncated' separately.
    obs, rewards, dones, infos = env.step(action)

    # VecEnv automatically resets the environment when 'dones' is True,
    # so we don't need to manually call env.reset() inside the loop.