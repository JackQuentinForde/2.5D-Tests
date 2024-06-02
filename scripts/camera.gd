extends Node3D

const ROT_SPEED = 7.5
const FOLLOW_SPEED = 5.0

var player
var playerPos = Vector3()
var targetRotation = 0
var firstPersonMode = false

func _ready():
	player = get_parent()
	global_transform.origin = player.global_transform.origin

func _physics_process(delta):
	if Input.is_action_just_pressed("view_toggle"):
		firstPersonMode = !firstPersonMode
		ChangeCameraMode()

	playerPos = player.global_transform.origin

	if firstPersonMode:
		FirstPersonLogic()
	else:
		ThirdPersonLogic(delta)

func ThirdPersonLogic(delta):
	if Input.is_action_just_pressed("camera_left"):
		if targetRotation == -180:
			rotation_degrees.y = 180
			targetRotation = 90
		else:
			targetRotation -= 90
		player.call_deferred("RotateLeft")
	elif Input.is_action_just_pressed("camera_right"):
		if targetRotation == 180:
			rotation_degrees.y = -180
			targetRotation = -90
		else:
			targetRotation += 90
		player.call_deferred("RotateRight")

	var currentRotation = rotation_degrees.y
	var newRotation = Lerp(currentRotation, targetRotation, ROT_SPEED * delta)
	rotation_degrees.y = newRotation

	var targetPos = Vector3(playerPos.x, playerPos.y, playerPos.z)
	global_transform.origin = global_transform.origin.lerp(targetPos, FOLLOW_SPEED * delta)

func FirstPersonLogic():
	#var input_dir = Input.get_vector("first_person_camera_left", "first_person_camera_right", "first_person_camera_up", "first_person_camera_down")
	pass

func ChangeCameraMode(): 
	if firstPersonMode:
		$"3rdPersonCam".current = false
		$"1stPersonCam".current = true
	else:
		$"1stPersonCam".current = false
		$"3rdPersonCam".current = true

func Lerp(a, b, t):
	return a + (b - a) * t
