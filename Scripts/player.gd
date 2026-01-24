extends CharacterBody3D

var sitting = false

var floating = false

var strength = 0.0

var speedMultiplier = 1.0
var speedMultipliers = []
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var savedVelocity : Vector3

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Globals.playerRef = self
	
	if not Globals.isMultiplayer:
		$BoxSprite.visible = false

func _physics_process(delta: float) -> void:
	
	speedMultiplier = 1.0
	for i in speedMultipliers:
		match i[0]:
			"+":
				speedMultiplier += i[1]
			"-":
				speedMultiplier -= i[1]
			"*":
				speedMultiplier *= i[1]
			"/":
				speedMultiplier /= i[1]
	
	velocity += savedVelocity
	savedVelocity = Vector3(0,0,0)
	
	# Add the gravity.
	if not is_on_floor():
		var gravity = get_gravity()
		if floating: gravity /= 10
		velocity += (gravity if $AntigravityTimer.is_stopped() else -gravity) * delta
	
	if position.y < -500:
		position = Globals.respawnPoint
		velocity = Vector3(0,0,0)
	
	
	# Handle jump.
	if Input.is_action_just_pressed("plr_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("plr_left", "plr_right", "plr_up", "plr_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x += direction.x * SPEED * speedMultiplier / 75
		velocity.z += direction.z * SPEED * speedMultiplier / 75
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED / 60)
		velocity.z = move_toward(velocity.z, 0, SPEED / 60)
	
	$OmniLight3D.visible = Globals.currentTool == Globals.tools.BULB
	
	if sitting:
		velocity = Vector3(0,0,0)
	
	if Input.is_action_just_pressed("unstuck"):
		position.y = 80
	
	move_and_slide()

@export var mouse_sensitivity : float = 0.002
@export var pitch_limit : Vector2 = Vector2(deg_to_rad(-90), deg_to_rad(90))
var _camera_rotation_x: float = 0.0

func _input(event):
	if event is InputEventMouseMotion:
		# Rotate the pivot horizontally (yaw)
		rotation.y -= event.relative.x * mouse_sensitivity
		
		# Rotate the camera vertically (pitch) and clamp it
		_camera_rotation_x -= event.relative.y * mouse_sensitivity
		_camera_rotation_x = clamp(_camera_rotation_x, pitch_limit.x, pitch_limit.y)
		
		$Camera3D.rotation.x = _camera_rotation_x
	else:
		sitting = false
	if Input.is_action_just_pressed("plr_restart"):
		position = Globals.respawnPoint
		velocity = Vector3(0,0,0)
		strength = 0.0
