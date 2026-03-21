extends CharacterBody3D

var sitting = false

var strength = 0.0

var isMain = false

var multipliers = {
	"speed":{"changes":[],"value":1.0,"particles":"Node3D/SpeedParticles"},
	"gravity":{"changes":[],"value":1.0,"particles":"Node3D/GravityParticles"},
	"scale":{"changes":[],"value":1.0,"particles":null},
	"knockback":{"changes":[],"value":1.0,"particles":null}
}

var statuses:Array[StatusEffect] = []

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var savedVelocity : Vector3

func _enter_tree() -> void:
	if Globals.isMultiplayer:
		set_multiplayer_authority(str(name).to_int())
		if not is_multiplayer_authority():
			return
		var camera = preload("res://Scenes/camera_3d.tscn").instantiate()
		camera.position = Vector3(0,0.414,-0.339)
		add_child(camera)
	
	Globals.playerRef = self

func _ready() -> void:
	if (not is_multiplayer_authority()) and Globals.isMultiplayer: return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if not Globals.isMultiplayer:
		$BoxSprite.visible = false
	
	position = Globals.respawnPoint
	
	for i in Globals.VARS_TO_SAVE:
		Globals.set(i,Globals.get(i))
	
	if Globals.isArchipelago:
		if not Archipelago.conn.deathlink.is_connected(Globals.recieveDeathlink): Archipelago.conn.deathlink.connect(Globals.recieveDeathlink)
	
	Globals.player_ready.emit()

func _physics_process(delta: float) -> void:
	if (not is_multiplayer_authority()) and Globals.isMultiplayer: return
	
	velocity += savedVelocity
	savedVelocity = Vector3(0,0,0)
	
	var joystick_axis = Input.get_vector("look_left", "look_right", "look_up", "look_down") * 0.02
	if joystick_axis.length() > 0:
		rotation.y -= joystick_axis.x
		
		_camera_rotation_x -= joystick_axis.y
		_camera_rotation_x = clamp(_camera_rotation_x, pitch_limit.x, pitch_limit.y)
		
		$Camera3D.rotation.x = _camera_rotation_x
	
	# Add the gravity.
	if not (is_on_floor() if multipliers.gravity.value > 0 else is_on_ceiling()):
		var gravity = get_gravity()
		velocity += gravity * multipliers.gravity.value * delta
	elif Input.is_action_just_pressed("plr_jump"):
		velocity.y = JUMP_VELOCITY / multipliers.gravity.value
	
	if position.y < -Globals.maxHeight:
		Globals.reset()
	
	var input_dir := Input.get_vector("plr_left", "plr_right", "plr_up", "plr_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x += direction.x * SPEED * multipliers.speed.value / 75
		velocity.z += direction.z * SPEED * multipliers.speed.value / 75
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED / 60)
		velocity.z = move_toward(velocity.z, 0, SPEED / 60)
	
	if has_node("OmniLight3D"):
		$OmniLight3D.visible = Globals.currentTool == Globals.tools.BULB
	
	if sitting:
		velocity = Vector3(0,0,0)
	
	if Input.is_action_just_pressed("unstuck"):
		position.y = Globals.maxHeight + 10
	
	move_and_slide()

func _process(_delta: float) -> void:
	if (get_tree().get_frame()) % 240 == 0:
		processStatuses()

@export var mouse_sensitivity := 0.002
@export var pitch_limit := Vector2(deg_to_rad(-90), deg_to_rad(90))
var _camera_rotation_x := 0.0

func _input(event):
	if (not is_multiplayer_authority()) and Globals.isMultiplayer: return
	
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
		Globals.reset()

func updateMultipliers():
	for multiplier in multipliers:
		multipliers[multiplier].value = 1.0
		for i in multipliers[multiplier].changes:
			match i[0]:
				"+":
					multipliers[multiplier].value += i[1]
				"-":
					multipliers[multiplier].value -= i[1]
				"*":
					multipliers[multiplier].value *= i[1]
				"/":
					multipliers[multiplier].value /= i[1]
		
		if multipliers[multiplier].particles != null:
			if multipliers[multiplier].value > 1.0:
				get_node(multipliers[multiplier].particles).amount_ratio = clamp(multipliers[multiplier].value / 200.0,0,1.0)
				get_node(multipliers[multiplier].particles).emitting = true
			else:
				get_node(multipliers[multiplier].particles).emitting = false
	
	scale = Vector3.ONE * multipliers.scale.value

func addStatus(status:Globals.allStatuses,time:float) -> void:
	var statusResource:StatusEffect = StatusEffect.new(status,time)
	statusResource.finished.connect(removeStatus)
	statuses.append(statusResource)

func removeStatus(statusResource:StatusEffect) -> void:
	statuses.erase(statusResource)

func processStatuses() -> void:
	for status in statuses:
		match status.status:
			Globals.allStatuses.SPEED:
				Globals.gridRef.multiplyAttribute("speed",["*",1.1],3)

func takeKnockback(knockback:int) -> void:
	savedVelocity = - ((position - (Globals.respawnPoint)).normalized() * 20 * knockback * multipliers.knockback.value)
	savedVelocity.y *= -1
