extends Interactable
class_name PressurePlate

## One half of a "simultaneous action" puzzle (design doc puzzle type #2).
## Two plates live in different rooms; the shared door only opens while BOTH
## are held down at the same time — forcing the players to coordinate over the
## radio ("okay, step on it... now!"). Step off either plate and it re-locks.
##
## The plate reports its own pressed/unpressed state to the NetworkManager,
## which is the single source of truth for the puzzle (same architectural
## lesson as the chat bug: shared state must be driven from something that
## exists identically on every peer). The plate presses automatically when a
## player stands on it — no interact key needed — so we drive detection from a
## child Area3D on the player body layer.

## A shared id string that pairs this plate with its partner(s) and the door
## they control. All plates with the same group_id must be pressed for the
## linked door to open.
@export var group_id: String = "plates_a"

## The door this plate group controls. Only needs to be set on ONE plate in the
## group, but setting it on all is harmless.
@export var door_path: NodePath

## Visual feedback: the mesh sinks by this much (meters) while pressed.
@export var press_depth: float = 0.08
@export var release_delay: float = 1.2

@onready var _detector: Area3D = $Detector

var _pressed: bool = false
var _rest_y: float = 0.0
var _bodies_on: int = 0
var _release_timer: SceneTreeTimer = null
var _status_label: Label3D
static var _group_counts: Dictionary = {}
static var _last_scene_id: int = 0

func _process(_delta: float) -> void:
	# Fallback for imported collision layers that do not reach the detector.
	var occupied := false
	for player in get_tree().get_nodes_in_group("players"):
		if player is CharacterBody3D and global_position.distance_to(player.global_position) < 1.15:
			occupied = true
	if occupied and not _pressed:
		_set_pressed(true)
	elif not occupied and _pressed and _bodies_on == 0:
		_set_pressed(false)


func _ready() -> void:
	prompt_text = ""  # not an E-to-interact object
	# The landing bay contains one deliberate two-player pair. Normalizing the
	# group here keeps repositioned scene instances linked even if their old
	# inspector group names differ.
	group_id = "act1_pressure_pair"
	var scene := get_tree().current_scene
	if scene and _last_scene_id != scene.get_instance_id():
		_group_counts.clear()
		_last_scene_id = scene.get_instance_id()
	# Act 1 uses one cooperative pair. Older scene revisions contained spare
	# plates; keep the first two registered for a group and hide any extras.
	_group_counts[group_id] = int(_group_counts.get(group_id, 0)) + 1
	if _group_counts[group_id] > 2:
		visible = false
		set_process(false)
		if has_node("Detector"):
			$Detector.monitoring = false
		return
	_rest_y = position.y
	if _detector:
		_detector.body_entered.connect(_on_body_entered)
		_detector.body_exited.connect(_on_body_exited)
	# Register this plate + its door with the puzzle tracker.
	PuzzleState.register_plate(group_id, self, door_path)
	_status_label = Label3D.new()
	_status_label.name = "PlateStatus"
	_status_label.text = "PRESSURE PLATE\nStand here"
	_status_label.position = Vector3(0.0, 0.35, 0.0)
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 32
	_status_label.modulate = Color(1.0, 0.75, 0.25)
	_status_label.outline_size = 8
	_status_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	add_child(_status_label)


func interact(_player: Node = null) -> void:
	pass  # pressure plates activate by standing, not by pressing E


func _on_body_entered(body: Node) -> void:
	if not (body is CharacterBody3D):
		return
	_bodies_on += 1
	_release_timer = null  # Cancel any pending release timer
	if not _pressed:
		_set_pressed(true)


func _on_body_exited(body: Node) -> void:
	if not (body is CharacterBody3D):
		return
	_bodies_on = max(0, _bodies_on - 1)
	if _bodies_on == 0 and _pressed:
		_release_timer = get_tree().create_timer(release_delay)
		var timer_ref := _release_timer
		await timer_ref.timeout
		# Only release if no other bodies have re-entered and this is the active timer.
		if _release_timer == timer_ref and _bodies_on == 0 and _pressed:
			_set_pressed(false)


func _set_pressed(value: bool) -> void:
	_pressed = value
	if _status_label:
		_status_label.text = "PLATE ACTIVE" if value else "PRESSURE PLATE\nStand here"
		_status_label.modulate = Color(0.25, 1.0, 0.45) if value else Color(1.0, 0.75, 0.25)
	# Animate the plate sinking / rising for tactile feedback.
	var target_y := _rest_y - press_depth if value else _rest_y
	var tween := create_tween()
	tween.tween_property(self, "position:y", target_y, 0.12)
	# Tell the shared tracker; it decides whether the door opens.
	PuzzleState.set_plate_pressed(group_id, self, value)


func is_pressed() -> bool:
	return _pressed
