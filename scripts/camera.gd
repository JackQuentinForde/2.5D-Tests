extends Node3D

const ROT_SPEED = 7.5
const LOOK_SENSITIVITY = 2.0
const FOLLOW_SPEED = 5.0
const ZOOM_SPEED = 50.0
const MAX_FOV = 15
const MIN_FOV = 4

var player
var playerPos = Vector3()
var targetRotation = 0
var firstPersonMode = false

func _ready():
	player = get_parent()
	global_transform.origin = player.global_transform.origin

func _physics_process(delta):
	if Input.is_action_just_pressed("view_toggle"):
		ChangeCameraMode()

	playerPos = player.global_transform.origin

	if firstPersonMode and $"1stPersonCam".current == false:
		FirstPersonTransitionLogic(delta)
	elif firstPersonMode:
		FirstPersonLogic()
	else:
		ThirdPersonLogic(delta)

func FirstPersonTransitionLogic(delta):
	$"3rdPersonCam".fov -= delta * ZOOM_SPEED
	global_transform.origin = playerPos
	if $"3rdPersonCam".fov <= MIN_FOV:
		$"3rdPersonCam".current = false
		$"1stPersonCam".current = true
		rotation_degrees.y = targetRotation
		SetLookDirection()
		$"3rdPersonCam".fov = MIN_FOV

func ThirdPersonLogic(delta):
	if $"3rdPersonCam".fov < MAX_FOV:
		$"3rdPersonCam".fov += delta * ZOOM_SPEED
		if $"3rdPersonCam".fov > MAX_FOV:
			$"3rdPersonCam".fov = MAX_FOV

	if Input.is_action_just_pressed("camera_left"):
		targetRotation -= 90
		player.call_deferred("RotateLeft")
	elif Input.is_action_just_pressed("camera_right"):
		targetRotation += 90
		player.call_deferred("RotateRight")

	if rotation_degrees.y != targetRotation:
		var newRotation = MathFunctions.Lerp(rotation_degrees.y, targetRotation, ROT_SPEED * delta)
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
	if !firstPersonMode:
		firstPersonMode = true
	else:
		firstPersonMode = false
		targetRotation = MathFunctions.RoundToNearestDegrees(rotation_degrees.y, 90.0)
		player.call_deferred("ResetPosition")
		$"1stPersonCam".current = false
		$"3rdPersonCam".current = true

func SetLookDirection():
	var lastAnim = player.get("lastAnim")
	if lastAnim == "WalkFront":
		rotate_y(deg_to_rad(180))
	elif lastAnim == "WalkLeft":
		rotate_y(deg_to_rad(90))
	elif lastAnim == "WalkRight":
		rotate_y(deg_to_rad(-90))
	$"1stPersonCam".rotation_degrees.x = 0
