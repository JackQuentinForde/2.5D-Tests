extends CharacterBody3D

const PATROL_SPEED = 2.5
const CHASE_SPEED = 3.0
const ROT_SPEED = 18.0
const WAYPOINT_MIN_DIST = 0.075
const TARGET_MIN_DIST = 4.0
const ATTACK_TIME = 1.0
const SEARCH_END_WAIT_TIME = 1.5
const STARTLE_TIME = 0.5
const CALL_TIME = 2.0

@export var cameraPivot : Node3D
@export var waypointsNode : Node3D
@export var patrolRouteNode : Node3D
@export var alertStatusNode : Node3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
enum {PATROL_STATE, WAIT_STATE, STARTLED_STATE, ALERTING_STATE, CALLING_STATE, CHASE_STATE, SEARCH_STATE, SEARCH_OVER_STATE, RETURN_STATE, ATTACK_STATE}

var speed = PATROL_SPEED
var patrolRoute = []
var lastPatrolPointIndex = 0
var currentRoute = []
var target
var player
var state = PATROL_STATE
var heading = Vector3.BACK
var targetRotation = 0
var playerInFOV = false

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
	match state:
		PATROL_STATE, RETURN_STATE:
			Navigate()
		SEARCH_STATE:
			Search()
		STARTLED_STATE:
			React()
		ALERTING_STATE:
			Alerting()
		CALLING_STATE:
			CallingForBackUp()
		CHASE_STATE:
			Chase()
		ATTACK_STATE:
			Attack()
		WAIT_STATE, SEARCH_OVER_STATE:
			Wait()
	CheckFOV()

func Search():
	if alertStatusNode.IsAlert():
		UpdateSearch()
	Navigate()

func Startled():
	$Timer.wait_time = STARTLE_TIME
	$Timer.start()
	$Exclamation.visible = true
	$StartledTimer.start()
	state = STARTLED_STATE
	$FOVCone.call_deferred("SetToRed")

func React():
	if not $Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		var currentPos = Vector3(global_position.x, 0, global_position.z)
		var targetPos = Vector3(player.global_position.x, 0, player.global_position.z)
		if currentPos.distance_to(targetPos) > TARGET_MIN_DIST:
			BeginAlerting()
		else:
			BeginAttack()

func BeginAlerting():
	speed = CHASE_SPEED
	state = ALERTING_STATE
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = waypointsNode.GetClosestCoverPoint(currentPos)
	CalculatePath(currentPos, targetPos)

func Alerting():
	Navigate()

func StartCallForBackup():
	state = CALLING_STATE
	velocity.x = 0
	velocity.z = 0
	$Timer.wait_time = CALL_TIME
	$Timer.start()

func CallingForBackUp():
	if not $Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		state = CHASE_STATE
		alertStatusNode.HostileEncountered(self)
		$FOVCone.call_deferred("SetToRed")

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
		PatrolPause()
		ChangeLookDirection(target.heading)
	else:
		GetNextWaypoint()

func GetNextWaypoint():
	var index = currentRoute.find(target)
	if index == currentRoute.size() - 1:
		if state == SEARCH_STATE:
			SearchPause()
		elif state == ALERTING_STATE:
			StartCallForBackup()
		else:
			if state == PATROL_STATE:
				lastPatrolPointIndex = 0
			StartPatrol()
	else:
		target = currentRoute[index + 1]
		if state == PATROL_STATE:
			lastPatrolPointIndex += 1

func SearchPause():
	Pause(SEARCH_END_WAIT_TIME)
	state = SEARCH_OVER_STATE
	$FOVCone.call_deferred("SetToYellow")

func PatrolPause():
	Pause(target.pauseTime)
	state = WAIT_STATE

func Pause(pauseTime):
	velocity.x = 0
	velocity.z = 0
	$Timer.wait_time = pauseTime
	$Timer.start()

func Wait():
	if not $Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		if state == SEARCH_OVER_STATE:
			SearchEnded()
		else:
			WaitOver()

func Chase():
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = Vector3(player.global_position.x, 0, player.global_position.z)
	if currentPos.distance_to(targetPos) > TARGET_MIN_DIST:
		var direction = (targetPos - currentPos).normalized()
		velocity.x = direction.x * CHASE_SPEED
		velocity.z = direction.z * CHASE_SPEED
	else:
		velocity.x = 0
		velocity.z = 0
		BeginAttack()

	if !playerInFOV:
		alertStatusNode.HostileLost(self)
		StartSearch()

func WaitOver():
	speed = PATROL_SPEED
	state = PATROL_STATE
	currentRoute = patrolRoute
	GetNextWaypoint()

func BeginAttack():
	$Timer.wait_time = ATTACK_TIME
	$Timer.start()
	state = ATTACK_STATE

func Attack():
	if not $Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		if alertStatusNode.IsAlert():
			state = CHASE_STATE
			alertStatusNode.HostileEncountered(self)
			$FOVCone.call_deferred("SetToRed")
		else:
			BeginAlerting()

func StartSearch():
	speed = CHASE_SPEED
	state = SEARCH_STATE
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = Vector3(player.global_position.x, 0, player.global_position.z)
	CalculatePath(currentPos, targetPos)

func UpdateSearch():
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = Vector3(player.global_position.x, 0, player.global_position.z)
	CalculatePath(currentPos, targetPos)

func SearchEnded():
	speed = CHASE_SPEED
	state = RETURN_STATE
	$FOVCone.call_deferred("SetToGreen")
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	target = patrolRoute[lastPatrolPointIndex]
	var targetPos = Vector3(target.global_position.x, 0, target.global_position.z)
	CalculatePath(currentPos, targetPos, false)

func StartPatrol():
	currentRoute = patrolRoute
	target = currentRoute[lastPatrolPointIndex]
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
					player = collider
					if !AlreadyStartled():
						Startled()
					elif !AlreadyEngaged():
						target = player
						state = CHASE_STATE
						alertStatusNode.HostileEncountered(self)
						$FOVCone.call_deferred("SetToRed")
				else:
					playerInFOV = false

func AlreadyStartled():
	return state == STARTLED_STATE or state == ATTACK_STATE or state == ALERTING_STATE or state == CHASE_STATE or state == SEARCH_STATE or state == CALLING_STATE

func AlreadyEngaged():
	return state == ATTACK_STATE or state == STARTLED_STATE or state == ALERTING_STATE or state == CALLING_STATE

func AnimLogic(delta):
	var angle = GetCameraAngle(delta)
	if velocity.x != 0 or velocity.z != 0:
		if angle <= 45 or angle >= 315:
			$AnimatedSprite3D.play("WalkBack")
		elif angle < 135:
			$AnimatedSprite3D.play("WalkRight")
		elif angle < 225:
			$AnimatedSprite3D.play("WalkFront")
		else:
			$AnimatedSprite3D.play("WalkLeft")
	else:
		if angle <= 45 or angle >= 315:
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
	#print("Calculating path")
	var route = waypointsNode.CalculatePath(start, end, fullRoute)
	if route and route.size() > 0:
		currentRoute = route
		target = currentRoute[0]
	else:
		StartPatrol()

func Alert(body):
	if AlreadyStartled() or AlreadyEngaged():
		return
	player = body
	$FOVCone.call_deferred("SetToRed")
	StartSearch()

func _on_detect_area_area_entered(area:Area3D):
	if area.is_in_group("Player"):
		playerInFOV = true

func _on_detect_area_area_exited(area:Area3D):
	if area.is_in_group("Player"):
		playerInFOV = false

func _on_startled_timer_timeout():
	$Exclamation.visible = false
