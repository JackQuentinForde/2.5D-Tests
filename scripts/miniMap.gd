extends Node3D

@export var player: CharacterBody3D

var camera

func _ready():
	camera = get_node("Camera3D")

func _physics_process(_delta):
	var playerPos = player.global_position
	camera.global_position.x = playerPos.x
	camera.global_position.z = playerPos.z
