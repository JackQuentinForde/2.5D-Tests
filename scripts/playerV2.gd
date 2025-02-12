extends CharacterBody3D

const SPEED = 5.0

var direction = Vector3()
var lastAnim = "WalkBack"

var attacking = false

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _physics_process(delta):
	ApplyGravity(delta)
	MoveLogic()
	AnimLogic()
	move_and_slide()
	if Input.is_action_pressed("QuitGame"):
		get_tree().quit()

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
	elif lastAnim == "WalkBack":
		lastAnim = "WalkLeft"
	elif lastAnim == "WalkFrontRight":
		lastAnim = "WalkBackRight"
	elif lastAnim == "WalkBackRight":
		lastAnim = "WalkBackLeft"
	elif lastAnim == "WalkBackLeft":
		lastAnim = "WalkFrontLeft"
	elif lastAnim == "WalkFrontLeft":
		lastAnim = "WalkFrontRight"
	elif lastAnim == "WalkRight":
		lastAnim = "WalkBack"
	else:
		lastAnim = "WalkFront"

func RotateRight():
	if lastAnim == "WalkFront":
		lastAnim = "WalkLeft"
	elif lastAnim == "WalkFrontLeft":

		lastAnim = "WalkBackLeft"
	elif lastAnim == "WalkFrontRight":
		lastAnim = "WalkFrontLeft"
	elif lastAnim == "WalkBackLeft":
		lastAnim = "WalkBackRight"
	elif lastAnim == "WalkBack":
		lastAnim = "WalkRight"
	elif lastAnim == "WalkLeft":
		lastAnim = "WalkBack"
	elif lastAnim == "WalkBackRight":
		lastAnim = "WalkFrontRight"
	else:
		lastAnim = "WalkFront"

func HalfRotateLeft():
	if lastAnim == "WalkFront":
		lastAnim = "WalkFrontRight"
	elif lastAnim == "WalkFrontRight":
		lastAnim = "WalkRight"
	elif lastAnim == "WalkRight":
		lastAnim = "WalkBackRight"
	elif lastAnim == "WalkBackLeft":
		lastAnim = "WalkLeft"
	elif lastAnim == "WalkBack":
		lastAnim = "WalkBackLeft"
	elif lastAnim == "WalkBackRight":
		lastAnim = "WalkBack"
	elif lastAnim == "WalkLeft":
		lastAnim = "WalkFrontLeft"
	else:
		lastAnim = "WalkFront"

func HalfRotateRight():
	if lastAnim == "WalkFront":
		lastAnim = "WalkFrontLeft"
	elif lastAnim == "WalkRight":
		lastAnim = "WalkFrontRight"
	elif lastAnim == "WalkBack":
		lastAnim = "WalkBackRight"
	elif lastAnim == "WalkLeft":
		lastAnim = "WalkBackLeft"
	elif lastAnim == "WalkBackLeft":
		lastAnim = "WalkBack"
	elif lastAnim == "WalkFrontRight":
		lastAnim = "WalkFront"
	elif lastAnim == "WalkFrontLeft":
		lastAnim = "WalkLeft"
	elif lastAnim == "WalkBackRight":
		lastAnim = "WalkRight"
	elif lastAnim == "WalkBackRight":
		lastAnim = "WalkFrontLeft"
	else:
		lastAnim = "WalkFront"

func ResetPosition():
	lastAnim = "WalkBack"
	$AnimatedSprite3D.play("IdleBack")
