@tool
class_name QuaterniusDoor
extends Node3D

## Door opened signal
signal door_opened
## Door closed signal
signal door_closed

## Time taken to open or close the door
@export var open_time: float = 1.0

## Door opened state
@export var opened: bool = false:
	set(new_value):
		var old_opened := opened
		opened = new_value

		if opened and not old_opened:
			door_opened.emit()
			$DoorSound.play()
		elif not opened and old_opened:
			door_closed.emit()
			$DoorSound.play()

		if is_inside_tree():
			_update_opened()

## Generic user game data (e.g for locked or key-name)
@export var user_data = {}

# Tween for moving door
var _tween: Tween
# Current door position [0 = closed, 1 = open]
var _position: float
# Array of doors
var _doors := []


func _ready() -> void:
	# Get all child doors
	for child in get_children():
		if child.is_in_group("door"):
			_doors.append(child)
	# Perform initial updates
	_update_opened(true)


# Called to update the opened state
func _update_opened(initial: bool = false) -> void:
	# Get the target
	var target: float = 1.0 if opened else 0.0

	# Handle initial update
	if initial:
		_move_doors(target)
		return

	# Kill existing tween
	if _tween:
		_tween.kill()

	# Launch tween to move door
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_method(_move_doors, _position, target, open_time)


# Called to move the door
func _move_doors(position: float) -> void:
	_position = position
	for door in _doors:
		door.position = door.distance * position
