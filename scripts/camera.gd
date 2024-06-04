extends Node3D

const ROT_SPEED = 7.5
const LOOK_SENSITIVITY = 2.0
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

	var newRotation = Lerp(rotation_degrees.y, targetRotation, ROT_SPEED * delta)
	rotation_degrees.y = newRotation
	global_transform.origin = global_transform.origin.lerp(playerPos, FOLLOW_SPEED * delta)

func FirstPersonLogic():
	var look_x = Input.get_action_strength("first_person_camera_right") - Input.get_action_strength("first_person_camera_left")
	var look_y = Input.get_action_strength("first_person_camera_down") - Input.get_action_strength("first_person_camera_up")

	rotate_y(deg_to_rad(-look_x * LOOK_SENSITIVITY))
	$"1stPersonCam".rotate_x(deg_to_rad(-look_y * LOOK_SENSITIVITY))

	var camera_rotation = $"1stPersonCam".rotation_degrees.x
	if camera_rotation > 90:
		$"1stPersonCam".rotation_degrees.x = 90
	elif camera_rotation < -90:
		$"1stPersonCam".rotation_degrees.x = -90

	global_transform.origin = playerPos

func ChangeCameraMode(): 
	if firstPersonMode:
		$"3rdPersonCam".current = false
		$"1stPersonCam".current = true
	else:
		targetRotation = round_to_nearest_90(rotation_degrees.y)
		player.call_deferred("ResetPosition")
		$"1stPersonCam".current = false
		$"3rdPersonCam".current = true

func round_to_nearest_90(angle):
	return round(angle / 90.0) * 90.0

func Lerp(a, b, t):
	return a + (b - a) * t
