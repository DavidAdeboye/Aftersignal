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

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_interactable: Interactable = null

var spawn_points: Array = [Vector3(-2, 1, 0), Vector3(2, 1, 0)]
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

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	if event.is_action_pressed("interact") and current_interactable:
		current_interactable.interact()


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
	else:
		in_chat_range = false
		signal_quality = 0.0


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
