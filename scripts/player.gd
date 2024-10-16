extends CharacterBody3D

const SPEED = 5.0

var direction = Vector3()
var lastAnim = "WalkBack"

var attacking = false

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	ApplyGravity(delta)
	MoveLogic()
	ActionLogic()
	AnimLogic()
	move_and_slide()

func ApplyGravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func MoveLogic():
	if(attacking):
		return
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		direction = direction.rotated(Vector3.UP, $CameraPivot.rotation.y).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func ActionLogic():
	if !attacking and Input.is_action_just_pressed("attack"):
		velocity.x = 0.0
		velocity.z = 0.0
		attacking = true
		if lastAnim == "WalkRight":
			$AnimatedSprite3D.play("AttackRight")
		elif lastAnim == "WalkLeft":
			$AnimatedSprite3D.play("AttackLeft")
		else:
			$AnimatedSprite3D.play("AttackFront")

func AnimLogic():
	if attacking and $AnimatedSprite3D.is_playing():
		return
	else:
		attacking = false

	if Input.is_action_pressed("ui_up"):
		if Input.is_action_pressed("ui_right"):
			$AnimatedSprite3D.play("WalkBackRight")
			lastAnim = "WalkBackRight"
		elif Input.is_action_pressed("ui_left"):
			$AnimatedSprite3D.play("WalkBackLeft")
			lastAnim = "WalkBackLeft"
		else:
			$AnimatedSprite3D.play("WalkBack")
			lastAnim = "WalkBack"
	elif Input.is_action_pressed("ui_down"):
		if Input.is_action_pressed("ui_right"):
			$AnimatedSprite3D.play("WalkFrontRight")
			lastAnim = "WalkFrontRight"
		elif Input.is_action_pressed("ui_left"):
			$AnimatedSprite3D.play("WalkFrontLeft")
			lastAnim = "WalkFrontLeft"
		else:
			$AnimatedSprite3D.play("WalkFront")
			lastAnim = "WalkFront"	
	elif Input.is_action_pressed("ui_right"):
		$AnimatedSprite3D.play("WalkRight")
		lastAnim = "WalkRight"	
	elif Input.is_action_pressed("ui_left"):
		$AnimatedSprite3D.play("WalkLeft")
		lastAnim = "WalkLeft"
	if !attacking and velocity.x == 0.0 and velocity.z == 0.0:
		match lastAnim:
			"WalkBackRight":
				$AnimatedSprite3D.play("IdleBackRight")
			"WalkBackLeft":
				$AnimatedSprite3D.play("IdleBackLeft")
			"WalkFrontRight":
				$AnimatedSprite3D.play("IdleFrontRight")
			"WalkFrontLeft":
				$AnimatedSprite3D.play("IdleFrontLeft")
			"WalkBack":
				$AnimatedSprite3D.play("IdleBack")
			"WalkFront":
				$AnimatedSprite3D.play("IdleFront")
			"WalkRight":
				$AnimatedSprite3D.play("IdleRight")
			"WalkLeft":
				$AnimatedSprite3D.play("IdleLeft")

func RotateLeft():
	if lastAnim == "WalkFront":
		lastAnim = "WalkRight"
	elif lastAnim == "WalkRight":
		lastAnim = "WalkBack"
	elif lastAnim == "WalkBack":
		lastAnim = "WalkLeft"
	else:
		lastAnim = "WalkFront"

func RotateRight():
	if lastAnim == "WalkFront":
		lastAnim = "WalkLeft"
	elif lastAnim == "WalkLeft":
		lastAnim = "WalkBack"
	elif lastAnim == "WalkBack":
		lastAnim = "WalkRight"
	else:
		lastAnim = "WalkFront"

func ResetPosition():
	lastAnim = "WalkBack"
	$AnimatedSprite3D.play("IdleBack")
