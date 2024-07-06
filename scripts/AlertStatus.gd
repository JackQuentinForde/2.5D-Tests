extends Node3D

@export var player : Node3D
@export var soldiersNode : Node3D
@onready var allUnits = soldiersNode.get_children()

enum {NORMAL_STATUS, HIGHTENED_STATUS, ALERT_STATUS}
var currentStatus = NORMAL_STATUS
var engagedUnits = []

func HostileEncountered(engagedUnit):
	if engagedUnit not in engagedUnits:
		engagedUnits.append(engagedUnit)
	currentStatus = ALERT_STATUS
	if !$AlertTimer.is_stopped():
		$AlertTimer.stop()

	for unit in allUnits:
		if !engagedUnits.has(unit):
			unit.Alert(player)

func HostileLost(unit):
	if unit in engagedUnits:
		engagedUnits.erase(unit)
		if engagedUnits.size() == 0 and currentStatus == ALERT_STATUS:
			$AlertTimer.start()

func IsAlert():
	return currentStatus == ALERT_STATUS

func _on_alert_timer_timeout():
	if engagedUnits.size() == 0:
		currentStatus = HIGHTENED_STATUS
