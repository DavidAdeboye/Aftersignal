extends CharacterBody3D
## First-person controller — Aftersignal
## Attach this script to a CharacterBody3D root that has:
##   - CollisionShape3D (capsule, matching a human-ish height)
##   - A Node3D called "Head" as a child, with a Camera3D as its child
##   - Camera3D should have a RayCast3D child pointed forward (Z: -3)
##   - A MeshInstance3D (capsule) for the visible body
##   - A MultiplayerSynchronizer syncing position and rotation
## Head handles vertical look (pitch); the body handles horizontal look (yaw).

@export var walk_speed: float = 3.5
@export var mouse_sensitivity: float = 0.0025
@export var jump_velocity: float = 4.5
@export var clear_range: float = 2.0
@export var chat_range: float = 5.0
var in_chat_range: bool = false
var signal_quality: float = 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var interact_prompt: Label = $CanvasLayer/InteractPrompt
@onready var chat_input: LineEdit = $CanvasLayer/ChatInput
@onready var chat_log: RichTextLabel = $CanvasLayer/ChatLog
@onready var signal_indicator: Label = $CanvasLayer/SignalIndicator
@onready var keypad_input: LineEdit = $CanvasLayer/KeypadInput
@onready var message_panel: PanelContainer = $CanvasLayer/MessagePanel
@onready var message_label: Label = $CanvasLayer/MessagePanel/MessageLabel
@onready var glyph_pad: Control = $CanvasLayer/GlyphPad

var _message_timer: SceneTreeTimer = null

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_interactable: Interactable = null
var active_keypad: Node = null

var spawn_points: Array = [Vector3(-2, 1, 13), Vector3(2, 1, 13)]
var spawn_colors: Array = [Color(0.15, 0.55, 0.95), Color(0.95, 0.45, 0.15)]
var spawn_index: int = 0
var chat_lines: Array[String] = []


func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))


func _ready() -> void:
	spawn_index = 0 if int(str(name)) == 1 else 1
	position = spawn_points[spawn_index]

	var mesh_instance: MeshInstance3D = $MeshInstance3D
	var material := StandardMaterial3D.new()
	material.albedo_color = spawn_colors[spawn_index]
	mesh_instance.set_surface_override_material(0, material)

	if not is_multiplayer_authority():
		$CanvasLayer.visible = false

	keypad_input.text_submitted.connect(_on_keypad_submitted)

	call_deferred("_setup_local_player")


func _setup_local_player() -> void:
	if not is_multiplayer_authority():
		return
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event.is_action_pressed("toggle_chat") and in_chat_range and not chat_input.visible:
		chat_input.visible = true
		chat_input.grab_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Glyph sketch pad — toggle the shared drawing device on/off.
	if event.is_action_pressed("toggle_glyph") and not chat_input.visible and not keypad_input.visible:
		_toggle_glyph_pad()

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	if event.is_action_pressed("interact") and current_interactable:
		if current_interactable.has_method("check_code"):
			active_keypad = current_interactable
			keypad_input.visible = true
			keypad_input.grab_focus()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			current_interactable.interact(self)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)

	move_and_slide()
	_update_interactable()
	_update_chat_range()

	if global_position.y < -20:
		global_position = spawn_points[spawn_index]
		velocity = Vector3.ZERO


func _update_chat_range() -> void:
	if not is_multiplayer_authority():
		return
	var other := _get_other_player()
	if other:
		var distance := global_position.distance_to(other.global_position)
		in_chat_range = distance <= chat_range

		if distance <= clear_range:
			signal_quality = 1.0
		elif distance <= chat_range:
			signal_quality = 1.0 - ((distance - clear_range) / (chat_range - clear_range))
		else:
			signal_quality = 0.0

		# Radio dead-zones (SignalJammer nodes) further degrade the signal while
		# either player stands inside them — forcing the pair to relocate for a
		# clean channel. We apply the worst jam affecting EITHER player, since a
		# radio link is only as good as its weakest end.
		var jam := _worst_jam_multiplier(global_position)
		jam = min(jam, _worst_jam_multiplier(other.global_position))
		signal_quality *= jam
		if signal_quality <= 0.0:
			in_chat_range = false
	else:
		in_chat_range = false
		signal_quality = 0.0

	_update_signal_indicator()


## Returns the strongest jam multiplier (lowest value) affecting a world point,
## by polling every registered SignalJammer. 1.0 = no jamming here.
func _worst_jam_multiplier(world_pos: Vector3) -> float:
	var worst := 1.0
	for jammer in get_tree().get_nodes_in_group("signal_jammers"):
		if jammer.has_method("signal_multiplier_for"):
			worst = min(worst, jammer.signal_multiplier_for(world_pos))
	return worst


func _update_signal_indicator() -> void:
	if not in_chat_range:
		signal_indicator.text = ""
	elif signal_quality > 0.75:
		signal_indicator.text = "Signal: Strong"
	elif signal_quality > 0.35:
		signal_indicator.text = "Signal: Weak"
	else:
		signal_indicator.text = "Signal: Static"


func _update_interactable() -> void:
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is Interactable:
			current_interactable = collider
			interact_prompt.visible = true
			return

	current_interactable = null
	interact_prompt.visible = false


func _get_other_player() -> Node3D:
	var players_node := get_parent()
	for child in players_node.get_children():
		if child != self and child is CharacterBody3D:
			return child
	return null


func _on_chat_submitted(text: String) -> void:
	chat_input.visible = false
	chat_input.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if text.strip_edges() != "":
		var garbled: String = _garble_text(text, signal_quality)
		var player_label: String = "Player " + str(spawn_index + 1)
		var color: Color = spawn_colors[spawn_index]
		var hex: String = color.to_html(false)
		NetworkManager.receive_chat_message.rpc("[color=#" + hex + "]" + player_label + ":[/color] " + garbled)


func _append_chat_line(formatted_text: String) -> void:
	chat_lines.append(formatted_text)
	if chat_lines.size() > 8:
		chat_lines.pop_front()
	chat_log.text = "\n".join(chat_lines)


func _garble_text(text: String, quality: float) -> String:
	if quality >= 1.0:
		return text
	var result: String = ""
	for character in text:
		if character == " " or randf() <= quality:
			result += character
		else:
			result += "-"
	return result


func _on_keypad_submitted(text: String) -> void:
	if active_keypad and not active_keypad.check_code(text.strip_edges()):
		keypad_input.modulate = Color.RED
		await get_tree().create_timer(0.3).timeout
		keypad_input.modulate = Color.WHITE
		keypad_input.text = ""
		return
	keypad_input.visible = false
	keypad_input.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	active_keypad = null
	show_message("Access granted. Door unlocked.")


# ============================================================================
#  GLYPH SKETCH PAD (shared drawing relay)
# ============================================================================

## Opens/closes the handheld sketch pad. While open the mouse is freed so the
## player can draw; closing it recaptures the mouse for look controls.
func _toggle_glyph_pad() -> void:
	if glyph_pad == null:
		return
	var show := not glyph_pad.visible
	glyph_pad.visible = show
	if show:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Called by NetworkManager when the partner draws a stroke on their pad.
func receive_glyph_stroke(stroke: PackedVector2Array) -> void:
	if glyph_pad and glyph_pad.has_method("receive_remote_stroke"):
		glyph_pad.receive_remote_stroke(stroke)


## Called by NetworkManager when a shared "clear" is broadcast.
func clear_glyph_pad() -> void:
	if glyph_pad and glyph_pad.has_method("clear_all"):
		glyph_pad.clear_all()


## Shows a message on this player's HUD for a few seconds. Called by
## interactables (logs, code displays, pickups) and by puzzle feedback.
## Safe to call on non-authoritative instances — it just no-ops there.
func show_message(text: String, duration: float = 4.0) -> void:
	if not is_multiplayer_authority():
		return
	if message_label == null or message_panel == null:
		return
	message_label.text = text
	message_panel.visible = true
	_message_timer = get_tree().create_timer(duration)
	var timer_ref := _message_timer
	await timer_ref.timeout
	# Only hide if no newer message replaced this one in the meantime.
	if _message_timer == timer_ref:
		message_panel.visible = false
