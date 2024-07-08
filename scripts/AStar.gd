extends Node3D

const GRID_STEP = 1
const SEARCH_COORDS = [-GRID_STEP, 0, GRID_STEP]

var waypoints = []
var coverPoints = []
var astar = AStar3D.new()

func _ready():
	for waypoint in get_children():
		var waypointPos = Vector3(waypoint.global_position.x, 0, waypoint.global_position.z)
		waypoints.append(waypointPos)
		if waypoint.is_in_group("Cover"):
			coverPoints.append(waypointPos)
	
	for i in range(waypoints.size()):
		astar.add_point(i, waypoints[i], 1)

	for point in waypoints:
		for x in SEARCH_COORDS:
			for z in SEARCH_COORDS:
				var searchOffset = Vector3(x, 0, z)
				if searchOffset == Vector3.ZERO:
					continue
				var potentialNeighbor = point + searchOffset
				if waypoints.has(potentialNeighbor) and !WillCutCorner(point, potentialNeighbor):
					var currentId = astar.get_closest_point(point)
					var neighborId = astar.get_closest_point(potentialNeighbor)
					if currentId != neighborId and not astar.are_points_connected(currentId, neighborId):
						astar.connect_points(currentId, neighborId)

func WillCutCorner(point, potentialNeighbor):
	if point.x != potentialNeighbor.x and point.z != potentialNeighbor.z:
		var corner1 = Vector3(point.x, 0, potentialNeighbor.z)
		var corner2 = Vector3(potentialNeighbor.x, 0, point.z)
		return not (waypoints.has(corner1) and waypoints.has(corner2))
	return false

func CalculatePath(start, end, fullRoute = true):
	var startId = astar.get_closest_point(start)
	var endId = astar.get_closest_point(end)
	var route = astar.get_point_path(startId, endId)
	var routeNodes = []
	var lastIndex = route.size()
	if !fullRoute:
		lastIndex -= 1
	for i in lastIndex:
		if i == 0 and route.size() > 1:
			continue
		var waypointIndex = waypoints.find(route[i])
		var waypoint = get_child(waypointIndex)
		routeNodes.append(waypoint)
	return routeNodes

func GetClosestCoverPoint(pos):
	var closestCover = Vector3.ZERO
	var closestDist = 1000000
	for cover in coverPoints:
		var dist = pos.distance_to(cover)
		if dist < closestDist:
			closestDist = dist
			closestCover = cover
	return closestCover
