extends Node3D

@onready var greenFOV = load("res://materials/greenFOV.tres")
@onready var yellowFOV = load("res://materials/yellowFOV.tres")
@onready var redFOV = load("res://materials/redFOV.tres")

func _ready():
	SetToGreen()

func SetToGreen():
	$FOVCone.material_override = greenFOV

func SetToYellow():
	$FOVCone.material_override = yellowFOV

func SetToRed():
	$FOVCone.material_override = redFOV