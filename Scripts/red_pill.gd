extends CharacterBody3D

@export var knockbackMultiplier = 1

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

@export var isBird = false
@export var birdHeight = 0

@export var statusReward : StatusEffect

var paralyzed = false
var i_frames = 0.0

var savedVelocity : Vector3

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		var gravity = get_gravity()
		if isBird: gravity /= 10
		velocity += (gravity if $AntigravityTimer.is_stopped() else -gravity) * delta
	
	if not paralyzed:
		velocity += savedVelocity
		savedVelocity = Vector3(0,0,0)
	
	if i_frames <= 0:
		i_frames = 0
		$CollisionShape3D.disabled = false
	else: i_frames -= delta
	
	
	
	if randi_range(0,5) == 3 and (is_on_floor() or (isBird and position.y < birdHeight)):
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Vector2(randf_range(-1,1),randf_range(-1,1))
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x += direction.x * SPEED / 100
		velocity.z += direction.z * SPEED / 100
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED / 60)
		velocity.z = move_toward(velocity.z, 0, SPEED / 60)
	
	
	if position.y < -200:
		if statusReward != null:
			Globals.playerRef.addStatus(statusReward.status,statusReward.initialTime)
		queue_free()
	
	if paralyzed: velocity = Vector3.ZERO
	move_and_slide()


func _on_area_3d_body_entered(_body: Node3D) -> void:
	if i_frames > 0: return
	i_frames = 3.0
	Globals.playerRef.takeKnockback(knockbackMultiplier)

func paralyze(time:float) -> void:
	paralyzed = true
	var vel = velocity
	await get_tree().create_timer(time).timeout
	paralyzed = false
	velocity = vel
