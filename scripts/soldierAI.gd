extends CharacterBody3D

const PATROL_SPEED = 2.5
const CHASE_SPEED = 3
const ROT_SPEED = 18
const WAYPOINT_MIN_DIST = 0.075
const TARGET_MIN_DIST = 3
const ATTACK_TIME = 1.5

@export var cameraPivot : Node3D
@export var patrolRoute : Node3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

enum {PATROL_STATE, WAIT_STATE, CHASE_STATE, ATTACK_STATE}

var state
var heading
var targetRotation = 0
var waypoints = []
var checkFOV = false
var target

func _ready():
	waypoints = patrolRoute.get_children()
	target = waypoints[0]
	state = PATROL_STATE
	heading = Vector3.BACK

func _physics_process(delta):
	ApplyGravity(delta)
	BrainLogic()
	AnimLogic(delta)
	move_and_slide()

func ApplyGravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func BrainLogic():
	if state == PATROL_STATE:
		Patrol()
	elif state == CHASE_STATE:
		Chase()
	elif state == ATTACK_STATE:
		Attack()
	else:
		Wait()
	if checkFOV and state != ATTACK_STATE:
		CheckFOV()

func Patrol():
	var direction = (target.global_position - global_position).normalized()
	velocity.x = direction.x * PATROL_SPEED
	velocity.z = direction.z * PATROL_SPEED
	if global_position.distance_to(target.global_position) < WAYPOINT_MIN_DIST:
		WaypointHit()

func WaypointHit():
	velocity.x = 0
	velocity.z = 0
	if target.pausePoint:
		$Timer.wait_time = target.pauseTime
		$Timer.start()
		state = WAIT_STATE
		ChangeLookDirection(target.heading)
	else:
		GetNextWaypoint()

func GetNextWaypoint():
	var index = waypoints.find(target)
	if index == waypoints.size() - 1:
		target = waypoints[0]
	else:
		target = waypoints[index + 1]

func Wait():
	if not $Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		GetNextWaypoint()
		state = PATROL_STATE

func Chase():
	if global_position.distance_to(target.global_position) > TARGET_MIN_DIST:
		var direction = (target.global_position - global_position).normalized()
		velocity.x = direction.x * CHASE_SPEED
		velocity.z = direction.z * CHASE_SPEED
	else:
		velocity.x = 0
		velocity.z = 0
		$Timer.wait_time = ATTACK_TIME
		$Timer.start()
		state = ATTACK_STATE

	if !checkFOV:
		RestartPatrol()

func Attack():
	if not $Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		state = CHASE_STATE

func RestartPatrol():
	target = waypoints[0]
	state = PATROL_STATE

func CheckFOV():
	var objects = $FOVCone/DetectArea.get_overlapping_areas()
	if objects.size() == 0:
		return

	for object in objects:
		if object.is_in_group("Player"):
			$LineOfSight.look_at(object.global_transform.origin, Vector3.UP)
			$LineOfSight.force_raycast_update()
			if $LineOfSight.is_colliding():
				var collider = $LineOfSight.get_collider()
				if collider.is_in_group("Player"):
					target = collider
					state = CHASE_STATE

func AnimLogic(delta):
	var angle = GetCameraAngle(delta)
	if velocity.x != 0 or velocity.z != 0:
		if angle < 45 or angle > 315:
			$AnimatedSprite3D.play("WalkBack")
		elif angle < 135:
			$AnimatedSprite3D.play("WalkRight")
		elif angle < 225:
			$AnimatedSprite3D.play("WalkFront")
		else:
			$AnimatedSprite3D.play("WalkLeft")
	else:
		if angle < 45 or angle > 315:
			$AnimatedSprite3D.play("IdleBack")
		elif angle < 135:
			$AnimatedSprite3D.play("IdleRight")
		elif angle < 225:
			$AnimatedSprite3D.play("IdleFront")
		else:
			$AnimatedSprite3D.play("IdleLeft")

func GetCameraAngle(delta):
	if state != WAIT_STATE:
		heading = (target.global_transform.origin - global_transform.origin).normalized()
	SetRotation(delta)
	var cameraBasis = -cameraPivot.global_transform.basis.z.normalized()
	var angle = rad_to_deg(atan2(cameraBasis.x * heading.z - cameraBasis.z * heading.x, cameraBasis.x * heading.x + cameraBasis.z * heading.z))
	if angle < 0:
		angle += 360
	return angle

func SetRotation(delta):
	targetRotation = rad_to_deg(atan2(-heading.x, -heading.z))
	var currentRotation = $FOVCone.rotation_degrees.y
	$FOVCone.rotation_degrees.y = Lerp(currentRotation, targetRotation, ROT_SPEED * delta)

func ChangeLookDirection(waypointHeading):
	if waypointHeading == "RIGHT":
		heading = Vector3.RIGHT
		targetRotation = -90
	elif waypointHeading == "LEFT":
		heading = Vector3.LEFT
		targetRotation = 90
	elif waypointHeading == "DOWN":
		heading = Vector3.BACK
		targetRotation = 180
	elif waypointHeading == "UP":
		heading = Vector3.FORWARD
		targetRotation = 0

func Lerp(from, to, weight):
	var difference = Wrapf(to - from, -180, 180)
	return from + difference * weight

func Wrapf(value, minimum, maximum):
	var degrees = maximum - minimum
	return minimum + fmod((value - minimum), degrees) + (degrees if value < minimum else 0)

func _on_detect_area_area_entered(area:Area3D):
	if area.is_in_group("Player"):
		checkFOV = true

func _on_detect_area_area_exited(area:Area3D):
	if area.is_in_group("Player"):
		checkFOV = false
