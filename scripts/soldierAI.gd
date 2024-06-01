extends CharacterBody3D

const PATROL_SPEED = 2.5
const CHASE_SPEED = 5
const ROT_SPEED = 6
const WAYPOINT_MIN_DIST = 0.075

@export var cameraPivot : Node3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

enum {PATROL_STATE, CHASE_STATE, WAIT_STATE, DYING_STATE}

var state
var heading
var waypoints = []
var activeWayPoint

func _ready():
	waypoints = get_node("Waypoints").get_children()
	activeWayPoint = waypoints[0]
	state = PATROL_STATE
	heading = Vector3.BACK

func _physics_process(delta):
	ApplyGravity(delta)
	BrainLogic()
	AnimLogic()
	move_and_slide()

func ApplyGravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func BrainLogic():
	if state == PATROL_STATE:
		Patrol()
	else:
		Wait()

func Patrol():
	var direction = (activeWayPoint.global_position - global_position).normalized()
	velocity.x = direction.x * PATROL_SPEED
	velocity.z = direction.z * PATROL_SPEED
	if global_position.distance_to(activeWayPoint.global_position) < WAYPOINT_MIN_DIST:
		WaypointHit()

func WaypointHit():
	if activeWayPoint.is_in_group("PausePoints"):
		$WaitTimer.start()
		state = WAIT_STATE
	else:
		GetNextWaypoint()

func GetNextWaypoint():
	var index = waypoints.find(activeWayPoint)
	if index == waypoints.size() - 1:
		activeWayPoint = waypoints[0]
	else:
		activeWayPoint = waypoints[index + 1]

func Wait():
	if not $WaitTimer.is_stopped():
		velocity.x = 0
		velocity.z = 0
	else:
		GetNextWaypoint()
		state = PATROL_STATE

func AnimLogic():
	var angle = GetCameraAngle()
	if state == PATROL_STATE:
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

func GetCameraAngle():
	SetHeading()
	var cameraBasis = -cameraPivot.global_transform.basis.z.normalized()
	var angle = rad_to_deg(atan2(cameraBasis.x * heading.z - cameraBasis.z * heading.x, cameraBasis.x * heading.x + cameraBasis.z * heading.z))
	if angle < 0:
		angle += 360
	return angle

func SetHeading():
	if abs(velocity.x) > abs(velocity.z):
		if velocity.x > 0:
			heading = Vector3.RIGHT
			$"Vision Cone".rotation_degrees.y = -90
		elif velocity.x < 0:
			heading = Vector3.LEFT
			$"Vision Cone".rotation_degrees.y = 90
	else:
		if velocity.z > 0:
			heading = Vector3.BACK
			$"Vision Cone".rotation_degrees.y = 180
		elif velocity.z < 0:
			heading = Vector3.FORWARD
			$"Vision Cone".rotation_degrees.y = 0