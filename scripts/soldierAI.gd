extends CharacterBody3D

const PATROL_SPEED = 2.5
const CHASE_SPEED = 3.0
const ROT_SPEED = 18.0
const WAYPOINT_MIN_DIST = 0.075
const TARGET_MIN_DIST = 4.0
const SEARCH_END_WAIT_TIME = 1.5
const STARTLE_TIME = 0.5
const CALL_TIME = 2.0
const ATTACK_TIME = 1.0
const WAIT_FOR_LEADER_TIME = 0.5

@export var cameraPivot : Node3D
@export var waypointsNode : Node3D
@export var patrolRouteNode : Node3D
@export var alertStatusNode : Node3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
enum {PATROL_STATE, WAIT_STATE, STARTLED_STATE, ALERT_STATE, CALLING_STATE, CHASE_STATE, SEARCH_STATE, SEARCH_OVER_STATE, RETURN_STATE, ATTACK_STATE}

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
var playerVisible = false
var inMyPersonalSpace = false

func _ready():
	patrolRoute = patrolRouteNode.get_children()
	currentRoute = patrolRoute
	target = currentRoute[0]

func _physics_process(delta):
	ApplyGravity(delta)
	StateMachine()
	AnimLogic(delta)
	move_and_slide()

func ApplyGravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func StateMachine():
	match state:
		PATROL_STATE, RETURN_STATE, ALERT_STATE, SEARCH_STATE:
			Navigate()
		STARTLED_STATE:
			React()
		CALLING_STATE:
			CallingForBackUp()
		CHASE_STATE:
			Chase()
		ATTACK_STATE:
			Attack()
		WAIT_STATE, SEARCH_OVER_STATE:
			Wait()
			
	if playerInFOV:
		CheckFOV()

func React():
	if not $StartledTimer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		var currentPos = Vector3(global_position.x, 0, global_position.z)
		var targetPos = Vector3(player.global_position.x, 0, player.global_position.z)
		if currentPos.distance_to(targetPos) > TARGET_MIN_DIST:
			BeginAlerting()
		else:
			ChangeState(ATTACK_STATE)

func BeginAlerting():
	ChangeState(ALERT_STATE)
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = waypointsNode.GetClosestCoverPoint(currentPos)
	CalculatePath(currentPos, targetPos)

func StartCallForBackup():
	velocity.x = 0
	velocity.z = 0
	$SpeechBubble.visible = true
	ChangeState(CALLING_STATE)

func CallingForBackUp():
	if not $Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		$SpeechBubble.visible = false
		ChangeState(CHASE_STATE)
		alertStatusNode.HostileEncountered(self)

func Navigate():
	if not $Timer.is_stopped() or inMyPersonalSpace:
		return

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
			if alertStatusNode.IsAlert():
				UpdateSearch()
			else:
				SearchPause()
		elif state == ALERT_STATE:
			StartCallForBackup()
		elif state == PATROL_STATE:
			StartPatrol()
		elif state == RETURN_STATE:
			ResumePatrol()
	else:
		target = currentRoute[index + 1]
		if state == PATROL_STATE:
			lastPatrolPointIndex += 1
		elif state == SEARCH_STATE and alertStatusNode.IsAlert():
			UpdateSearch()

func SearchPause():
	Pause(SEARCH_END_WAIT_TIME)
	ChangeState(SEARCH_OVER_STATE)

func PatrolPause():
	Pause(target.pauseTime)
	ChangeState(WAIT_STATE)

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
			alertStatusNode.EndPursuit()
		elif state == WAIT_STATE:
			WaitOver()

func Chase():
	if not $Timer.is_stopped() or inMyPersonalSpace:
		return

	if !playerVisible:
		alertStatusNode.HostileLost(self)
		StartSearch()
		return

	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = Vector3(player.global_position.x, 0, player.global_position.z)
	if currentPos.distance_to(targetPos) > TARGET_MIN_DIST:
		var direction = (targetPos - currentPos).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		ChangeState(ATTACK_STATE)

func WaitOver():
	ChangeState(PATROL_STATE)
	GetNextWaypoint()

func Attack():
	if !$Timer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		if alertStatusNode.IsAlert():
			ChangeState(CHASE_STATE)
		else:
			BeginAlerting()

func StartSearch():
	ChangeState(SEARCH_STATE)
	UpdateSearch()

func UpdateSearch():
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	var targetPos = Vector3(player.global_position.x, 0, player.global_position.z)
	CalculatePath(currentPos, targetPos)

func SearchEnded():
	ChangeState(RETURN_STATE)
	var currentPos = Vector3(global_position.x, 0, global_position.z)
	target = patrolRoute[lastPatrolPointIndex]
	var targetPos = Vector3(target.global_position.x, 0, target.global_position.z)
	CalculatePath(currentPos, targetPos, false)

func StartPatrol():
	lastPatrolPointIndex = 0
	ResumePatrol()

func ResumePatrol():
	currentRoute = patrolRoute
	target = currentRoute[lastPatrolPointIndex]
	ChangeState(PATROL_STATE)

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
					playerVisible = true
					if !AlreadyStartled():
						ChangeState(STARTLED_STATE)
					elif !AlreadyEngaged():
						target = player
						ChangeState(CHASE_STATE)
						alertStatusNode.HostileEncountered(self)
				else:
					playerVisible = false

func AlreadyStartled():
	return state == STARTLED_STATE or state == ATTACK_STATE or state == ALERT_STATE or state == CHASE_STATE or state == SEARCH_STATE or state == CALLING_STATE or state == SEARCH_OVER_STATE

func AlreadyEngaged():
	return state == ATTACK_STATE or state == STARTLED_STATE or state == ALERT_STATE or state == CALLING_STATE

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
	var route = waypointsNode.CalculatePath(start, end, fullRoute)
	currentRoute = route
	target = currentRoute[0]

func Alert(body):
	if AlreadyStartled() or AlreadyEngaged():
		UpdateSearch()
		return
	$Timer.stop()
	player = body
	StartSearch()

func ChangeState(newState):
	if newState == ATTACK_STATE:
		$Timer.wait_time = ATTACK_TIME
		$Timer.start()
	elif newState == STARTLED_STATE:
		$Timer.stop()
		$StartledTimer.start()
		$Exclamation.visible = true
	elif newState == CALLING_STATE:
		$Timer.wait_time = CALL_TIME
		$Timer.start()
	state = newState
	UpdateSpeed()
	UpdateFOVColour()

func UpdateSpeed():
	if state == PATROL_STATE:
		speed = PATROL_SPEED
	elif state == CHASE_STATE or state == SEARCH_STATE or state == ALERT_STATE or state == RETURN_STATE:
		speed = CHASE_SPEED

func UpdateFOVColour():
	match state:
		PATROL_STATE:
			$FOVCone.call_deferred("SetToGreen")
		CHASE_STATE, SEARCH_STATE, ALERT_STATE, STARTLED_STATE:
			$FOVCone.call_deferred("SetToRed")
		SEARCH_OVER_STATE, RETURN_STATE:
			$FOVCone.call_deferred("SetToYellow")

func _on_detect_area_area_entered(area:Area3D):
	if area.is_in_group("Player"):
		playerInFOV = true

func _on_detect_area_area_exited(area:Area3D):
	if area.is_in_group("Player"):
		playerInFOV = false
		playerVisible = false

func _on_startled_timer_timeout():
	$Exclamation.visible = false

func _on_personal_space_area_entered(area:Area3D):
	if AlreadyEngaged() or AlreadyStartled():
		var currentPos = Vector3(global_position.x, 0, global_position.z)
		var otherSoldierPos = Vector3(area.global_position.x, 0, area.global_position.z)
		var targetPos = Vector3(player.global_position.x, 0, player.global_position.z)
		var distToPlayer = currentPos.distance_to(targetPos)
		var otherSoldierDistToPlayer = otherSoldierPos.distance_to(targetPos)
		if otherSoldierDistToPlayer < distToPlayer:
			inMyPersonalSpace = true
			Pause(WAIT_FOR_LEADER_TIME)

func _on_personal_space_area_exited(_area:Area3D):
	inMyPersonalSpace = false
