import os
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO

# --- CONFIGURATION ---
# "None" means we will run the game manually in the Godot Editor to train it.
# If you exported the game, you would put the path to the .exe here.
ENV_PATH = None

# 1. Initialize the Environment
# This opens a port and waits for Godot to connect to it.
# speedup=8 is usually a safe limit.
# Going higher (like 20) might break physics calculations (tunneling).
env = StableBaselinesGodotEnv(env_path=None, show_window=True, speedup=20)

# 2. Define the Brain (The PPO Model)
# We use "MultiInputPolicy" because we are sending a Dictionary of data (raycasts, velocity, etc.)
model = PPO(
    "MultiInputPolicy",
    env,
    ent_coef=0.0001, # Entropy coefficient (encourages exploration)
    verbose=2,       # Print progress to console
    tensorboard_log="logs/results" # Where to save stats
)

# 3. The Training Loop
# 50,000 steps is enough to learn basic movement.
# For complex jumping, you might need 200,000+.
print("🧠 Training started! Press 'Play' in Godot now...")
model.learn(total_timesteps=200_000)

# 4. Save the Result
print("✅ Training finished. Saving model...")
model.save("my_platformer_brain.zip")
env.close()