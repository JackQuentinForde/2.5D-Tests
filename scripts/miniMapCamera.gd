extends Camera3D

@export var player: CharacterBody3D
var cameraPivot

func _ready():
	cameraPivot = player.get_node("CameraPivot")

func _physics_process(_delta):
	var playerPos = player.global_position
	global_position.x = playerPos.x
	global_position.z = playerPos.z

	rotation_degrees.y = cameraPivot.rotation_degrees.y
