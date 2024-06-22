extends CharacterBody3D

const PATROL_SPEED = 2.5
const CHASE_SPEED = 3
const ROT_SPEED = 18
const WAYPOINT_MIN_DIST = 0.075
const TARGET_MIN_DIST = 2
const ATTACK_TIME = 1.5
const SEARCH_END_WAIT_TIME = 1.5

@export var cameraPivot : Node3D
@export var waypointsNode : Node3D
@export var patrolRouteNode : Node3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
enum {PATROL_STATE, WAIT_STATE, CHASE_STATE, SEARCH_STATE, RETURN_STATE, ATTACK_STATE}

var speed = PATROL_SPEED
var patrolRoute = []
var currentRoute = []
var target
var state = PATROL_STATE
var heading = Vector3.BACK
var targetRotation = 0
var checkFOV = false

func _ready():
	patrolRoute = patrolRouteNode.get_children()
	currentRoute = patrolRoute
	target = currentRoute[0]

func _physics_process(delta):
	ApplyGravity(delta)
	BrainLogic()
	AnimLogic(delta)
	move_and_slide()

func ApplyGravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func BrainLogic():
	if state == PATROL_STATE or state == SEARCH_STATE or state == RETURN_STATE:
		Navigate()
	elif state == CHASE_STATE:
		Chase()
	elif state == ATTACK_STATE:
		Attack()
	else:
		Wait()
	if checkFOV:
		CheckFOV()

func Navigate():
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = Vector3(target.global_position.x, 0, target.global_position.z)
	if currentPos.distance_to(targetPos) < WAYPOINT_MIN_DIST:
		WaypointHit()
		return
	var direction = (targetPos - currentPos).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func WaypointHit():
	if state == PATROL_STATE and target.pausePoint:
		velocity.x = 0
		velocity.z = 0
		$Timer.wait_time = target.pauseTime
		$Timer.start()
		state = WAIT_STATE
		ChangeLookDirection(target.heading)
	else:
		GetNextWaypoint()

func GetNextWaypoint():
	var index = currentRoute.find(target)
	if index == currentRoute.size() - 1:
		if state == SEARCH_STATE:
			velocity.x = 0
			velocity.z = 0
			$Timer.wait_time = SEARCH_END_WAIT_TIME
			$Timer.start()
			state = WAIT_STATE
		else:
			StartPatrol()
	else:
		target = currentRoute[index + 1]

func Wait():
	if not $Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		if patrolRoute.has(target):
			GetNextWaypoint()
			state = PATROL_STATE
		else:
			SearchEnded()

func Chase():
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = Vector3(target.global_position.x, 0, target.global_position.z)
	if currentPos.distance_to(targetPos) > TARGET_MIN_DIST:
		var direction = (targetPos - currentPos).normalized()
		velocity.x = direction.x * CHASE_SPEED
		velocity.z = direction.z * CHASE_SPEED
	else:
		velocity.x = 0
		velocity.z = 0
		$Timer.wait_time = ATTACK_TIME
		$Timer.start()
		state = ATTACK_STATE

	if !checkFOV:
		StartSearch()

func Attack():
	if not $Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		state = CHASE_STATE

func StartSearch():
	speed = CHASE_SPEED
	state = SEARCH_STATE
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = Vector3(target.global_position.x, 0, target.global_position.z)
	CalculatePath(currentPos, targetPos)

func SearchEnded():
	speed = CHASE_SPEED
	state = RETURN_STATE
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var patrolStart = patrolRoute[0]
	var targetPos = Vector3(patrolStart.global_position.x, 0, patrolStart.global_position.z)
	CalculatePath(currentPos, targetPos, false)

func StartPatrol():
	currentRoute = patrolRoute
	target = currentRoute[0]
	speed = PATROL_SPEED
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
					if state != ATTACK_STATE:
						state = CHASE_STATE
				else:
					checkFOV = false

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
		var targetPos = Vector3(target.global_position.x, 0, target.global_position.z)
		heading = (targetPos - global_transform.origin).normalized()
	SetRotation(delta)
	var cameraBasis = -cameraPivot.global_transform.basis.z.normalized()
	var angle = rad_to_deg(atan2(cameraBasis.x * heading.z - cameraBasis.z * heading.x, cameraBasis.x * heading.x + cameraBasis.z * heading.z))
	if angle < 0:
		angle += 360
	return angle

func SetRotation(delta):
	targetRotation = rad_to_deg(atan2(-heading.x, -heading.z))
	var currentRotation = $FOVCone.rotation_degrees.y
	$FOVCone.rotation_degrees.y = MathFunctions.Lerp(currentRotation, targetRotation, ROT_SPEED * delta)

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

func CalculatePath(start, end, fullRoute = true):
	var route = waypointsNode.CalculatePath(start, end, fullRoute)
	if route and route.size() > 0:
		currentRoute = route
		target = currentRoute[0]
	else:
		StartPatrol()

func _on_detect_area_area_entered(area:Area3D):
	if area.is_in_group("Player"):
		checkFOV = true

func _on_detect_area_area_exited(area:Area3D):
	if area.is_in_group("Player"):
		checkFOV = false
