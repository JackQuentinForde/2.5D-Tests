extends CharacterBody3D

const SPEED = 5.0

var direction = Vector3()
var lastAnim = "WalkBack"

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	ApplyGravity(delta)
	MoveLogic()
	AnimLogic()
	move_and_slide()

func ApplyGravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func MoveLogic():
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

func AnimLogic():
	if Input.is_action_pressed("ui_up"):
		$AnimatedSprite3D.play("WalkBack")
		lastAnim = "WalkBack"
	elif Input.is_action_pressed("ui_down"):
		$AnimatedSprite3D.play("WalkFront")
		lastAnim = "WalkFront"
	elif Input.is_action_pressed("ui_right"):
		$AnimatedSprite3D.play("WalkRight")
		lastAnim = "WalkRight"
	elif Input.is_action_pressed("ui_left"):
		$AnimatedSprite3D.play("WalkLeft")
		lastAnim = "WalkLeft"
	else:
		match lastAnim:
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
