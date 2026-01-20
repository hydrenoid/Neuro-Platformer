extends CharacterBody2D

# --- CONFIGURATION ---
# 0 = Runner (Evade), 1 = Chaser (Attack)
@export var role: int = 0 
# Drag the OTHER player node into this slot in the Inspector
@export var opponent_path: NodePath

var opponent: Node2D

# --- PHYSICS SETTINGS ---
const CHASER_SPEED = 300.0
const RUNNER_SPEED = 330.0 # 10% faster
const JUMP_VELOCITY = -400.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- AI INTERFACE ---
# These variables are written to by the AIController
var ai_move_right = 0.0
var ai_jump = false
# Set to true for training, false for manual debugging
var is_controlled_by_ai = true 

func _ready():
	# Cache the opponent node so we don't look it up every frame
	if opponent_path:
		opponent = get_node(opponent_path)

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Handle Input (AI vs Human)
	var direction = 0.0
	var jump_input = false

	if is_controlled_by_ai:
		direction = ai_move_right
		jump_input = ai_jump
	else:
		# Manual fallback for testing
		direction = Input.get_axis("ui_left", "ui_right")
		jump_input = Input.is_action_just_pressed("ui_accept")

	# 3. Move Logic
	if jump_input and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# DETERMINE SPEED BASED ON ROLE
	var current_speed = CHASER_SPEED
	if role == 0: # Runner
		current_speed = RUNNER_SPEED

	# USE current_speed instead of constant SPEED
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	move_and_slide()
	
	# 4. Fall Penalty (Reset if they fall off the map)
	if position.y > 1000:
		reset_game()

func reset_game():
	velocity = Vector2.ZERO
	
	# Randomize horizontal position by +/- 100 pixels
	var random_offset = randf_range(-100.0, 100.0)
	
	if role == 1: # Chaser (Left side)
		position = Vector2(150 + random_offset, 300)
	else:         # Runner (Right side)
		position = Vector2(800 + random_offset, 300)
