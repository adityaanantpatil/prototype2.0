extends CharacterBody3D

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

var game_started = false
const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.002
const JUMP_VELOCITY = 2.5

var velocity_y = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func start_game():
	game_started = true
	print("✅ Player game started!")

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x - event.relative.y * MOUSE_SENSITIVITY,
			deg_to_rad(-90),
			deg_to_rad(90)
		)

	# Start game when Space or Enter is pressed
	if event.is_action_pressed("ui_accept") and not game_started:
		start_game()

func _physics_process(delta):
	if not game_started:
		return  # Prevent movement before game starts

	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x

	input_dir = input_dir.normalized()

	# Apply gravity
	if not is_on_floor():
		velocity_y -= 9.8 * delta
	else:
		velocity_y = 0
		if Input.is_action_just_pressed("jump"):
			velocity_y = JUMP_VELOCITY

	# Final velocity
	velocity = input_dir * SPEED
	velocity.y = velocity_y
	move_and_slide()
