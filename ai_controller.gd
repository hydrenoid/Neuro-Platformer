extends AIController2D

# --- SETTINGS ---
# WAS: 40.0 (Too strict, physics prevents this)
# CHANGE TO: 70.0 (Allows for touching + a little buffer)
const TAG_DISTANCE = 20.0
# Max duration of a round in seconds
const MAX_TIME = 15.0

var time_alive = 0.0

func _physics_process(delta):
	# n_steps timer: Standard PPO requirement
	n_steps += 1
	if n_steps >= reset_after:
		done = true
		needs_reset = true
		
	# GAME LOOP TIMER
	# We force a reset if the Runner survives for 15 seconds
	time_alive += delta
	if time_alive > MAX_TIME:
		end_episode(false) # false means "Nobody died, time ran out"

func get_obs() -> Dictionary:
	var player = get_parent()
	var opponent = player.opponent
	
	if not opponent:
		return {"obs": []}
	
	# --- THE MAGIC FIX ---
	# We calculate the vector between them
	var diff_vector = opponent.global_position - player.global_position
	
	var target_vector = Vector2.ZERO
	
	if player.role == 1: # CHASER
		# I want to go TOWARDS the opponent
		target_vector = diff_vector.normalized()
	else: # RUNNER
		# I want to go AWAY from the opponent
		# We invert the vector!
		target_vector = -diff_vector.normalized() 
		
	# ---------------------
	
	var dist = player.global_position.distance_to(opponent.global_position)
	
	var obs = [
		target_vector.x,        # Now this always points where we WANT to go
		target_vector.y,
		dist / 1000.0,
		player.velocity.x / 1000.0,
		player.velocity.y / 1000.0,
		int(player.is_on_floor()),
		float(player.role)
	]
	
	# Raycast Sensors (Keep existing code)
	var sensors = player.get_node("Sensors").get_children()
	for ray in sensors:
		if ray.is_colliding():
			var d = ray.get_collision_point().distance_to(ray.global_position)
			obs.append(d / 200.0)
		else:
			obs.append(1.0)
			
	return {"obs": obs}

func get_reward() -> float:
	var player = get_parent()
	var opponent = player.opponent
	
	# 1. Calculate Distances
	var dist = player.global_position.distance_to(opponent.global_position)
	
	# Rectangular Collision Check (Fixes Vertical Tags)
	var dist_x = abs(player.global_position.x - opponent.global_position.x)
	var dist_y = abs(player.global_position.y - opponent.global_position.y)
	
	# "is_touching" is TRUE if we are close horizontally AND vertically
	# 50.0 = Width allowance (side-to-side)
	# 85.0 = Height allowance (head-to-head)
	var is_touching = dist_x < 30.0 and dist_y < 50.0

	var reward = 0.0
	
	# --- LOGIC SPLIT ---
	
	if player.role == 1: # I AM CHASER
		# Strategy: Minimize Distance
		# We divide by 1000 to keep the reward small (-0.1 to -1.0 range)
		reward = -dist / 1000.0 
		
		# Win Condition: TAG
		if is_touching:
			reward += 10.0 # Huge Bonus
			end_episode(true) # True = "Game ended by Tag"
			
	else: # I AM RUNNER
		# Strategy: Survival
		
		# 1. Survival Salary (Paid to exist)
		reward += 0.1 
		
		# 2. Camping Penalty (Don't stand still)
		var speed = player.velocity.length()
		if speed < 10.0:
			reward -= 0.05 
			
		# Lose Condition: CAUGHT
		if is_touching:
			reward -= 10.0 # Huge Penalty
			end_episode(true)

	return reward

func end_episode(was_tagged: bool):
	# 1. Standard Reset Logic
	done = true
	needs_reset = true
	time_alive = 0.0
	
	var me = get_parent()
	me.reset_game()
	
	if me.opponent:
		me.opponent.reset_game()
		var opp_ai = me.opponent.get_node_or_null("AIController")
		if opp_ai:
			opp_ai.done = true
			opp_ai.needs_reset = true
			opp_ai.time_alive = 0.0

	# 2. THE JACKPOT LOGIC
	# If was_tagged is FALSE, it means the timer ran out naturally.
	if not was_tagged:
		if me.role == 0: # I am RUNNER
			# "I survived the whole round!"
			reward += 10.0 
		else: # I am CHASER
			# "I failed to catch him in time!"
			reward -= 5.0

# 3. DEFINE INPUTS
func get_action_space() -> Dictionary:
	return {
		"move": {
			"size": 1,
			"action_type": "continuous"
		},
		"jump": {
			"size": 1,
			"action_type": "continuous"
		}
	}

# 4. EXECUTE ACTIONS
func set_action(action) -> void:
	var player = get_parent()
	player.ai_move_right = action["move"][0]
	player.ai_jump = action["jump"][0] > 0.5
