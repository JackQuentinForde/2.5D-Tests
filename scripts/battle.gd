extends Node3D

func _process(_delta):
	if Input.is_action_just_pressed("attack"):
		get_tree().change_scene_to_file("res://scenes/test_scene_3.tscn")
