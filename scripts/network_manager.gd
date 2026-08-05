extends Node

const PORT: int = 7000
const MAX_PLAYERS: int = 2
const PLAYER_SCENE = preload("res://scenes/shared/player.tscn")

var players_node: Node3D = null
var game_started: bool = false


func _ready() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_setup_controller_inputs()


func _get_players_node() -> Node3D:
	# Looked up fresh (not cached at startup) since the game now starts on
	# the main menu scene, which has no "Players" node — this only resolves
	# correctly once we've transitioned into the actual game scene.
	if players_node == null or not is_instance_valid(players_node):
		players_node = get_tree().current_scene.get_node("Players")
	return players_node


func host_game() -> void:
	if game_started:
		return
	game_started = true

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Failed to host: ", error)
		game_started = false
		return
	multiplayer.multiplayer_peer = peer
	print("Hosting on port ", PORT)
	_spawn_player(multiplayer.get_unique_id())


func join_game(ip_address: String) -> void:
	if game_started:
		return
	game_started = true

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip_address, PORT)
	if error != OK:
		print("Failed to join: ", error)
		game_started = false
		return
	multiplayer.multiplayer_peer = peer
	print("Joining ", ip_address)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("host_game"):
		host_game()
	elif event.is_action_pressed("join_game"):
		join_game("127.0.0.1")


func _on_peer_connected(id: int) -> void:
	print("_on_peer_connected fired for id: ", id, " | is_server: ", multiplayer.is_server())
	if multiplayer.is_server():
		_spawn_player(id)


func _on_peer_disconnected(id: int) -> void:
	var player_node = _get_players_node().get_node_or_null(str(id))
	if player_node:
		player_node.queue_free()


func _spawn_player(id: int) -> void:
	print("_spawn_player called for id: ", id, " | is_server: ", multiplayer.is_server())

	var players := _get_players_node()

	# Guard: don't spawn if this player already exists
	if players.has_node(str(id)):
		print("Player ", id, " already spawned, skipping")
		return

	var player_instance = PLAYER_SCENE.instantiate()
	player_instance.name = str(id)
	player_instance.set_multiplayer_authority(id)
	player_instance.position = Vector3(randf_range(-2.0, 2.0), 1.0, randf_range(-2.0, 2.0))
	players.add_child(player_instance, true)

	# Re-apply any persisted "opened" doors once the world has a player in it,
	# so a session that rejoins finds previously-solved doors already open.
	PuzzleState.call_deferred("apply_persisted_doors")


@rpc("any_peer", "call_local")
func receive_chat_message(formatted_text: String) -> void:
	var local_player = _get_local_player()
	if local_player:
		local_player.call_deferred("_append_chat_line", formatted_text)


func _get_local_player() -> Node:
	for child in _get_players_node().get_children():
		if child.is_multiplayer_authority():
			return child
	return null
	
func request_host() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	host_game()


func request_join(ip: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	join_game(ip)
	
@rpc("any_peer", "call_local")
func unlock_door(door_path: NodePath) -> void:
	var door = get_tree().current_scene.get_node_or_null(door_path)
	if door:
		door.opened = true


@rpc("any_peer", "call_local")
func lock_door(door_path: NodePath) -> void:
	# Used by simultaneous-action puzzles: the shared door re-closes the moment
	# either pressure plate is released.
	var door = get_tree().current_scene.get_node_or_null(door_path)
	if door:
		door.opened = false


## Player-initiated door toggle — press E on a freely openable door to flip it
## open or closed. Unlike unlock_door / lock_door (which set absolute state for
## puzzle-driven doors), this mirrors what the player sees and intends.
@rpc("any_peer", "call_local")
func toggle_door(door_path: NodePath) -> void:
	var door = get_tree().current_scene.get_node_or_null(door_path)
	if door and "opened" in door:
		door.opened = not door.opened


## Relays a completed glyph stroke to the OTHER player's sketch pad. Same
## routing pattern as chat: the RPC runs on every peer, but each peer only
## applies it to a pad that ISN'T its own local player's — i.e. the sender sees
## their own stroke locally (already drawn), the partner sees it as "remote".
@rpc("any_peer", "call_remote")
func send_glyph_stroke(stroke: PackedVector2Array) -> void:
	var local_player = _get_local_player()
	if local_player and local_player.has_method("receive_glyph_stroke"):
		local_player.receive_glyph_stroke(stroke)


@rpc("any_peer", "call_local")
func clear_glyphs() -> void:
	var local_player = _get_local_player()
	if local_player and local_player.has_method("clear_glyph_pad"):
		local_player.clear_glyph_pad()


@rpc("any_peer", "call_local")
func stun_drone(drone_path: NodePath, tool_type: String) -> void:
	var drone = get_node_or_null(drone_path)
	if drone and drone.has_method("stun"):
		drone.stun(tool_type)


@rpc("any_peer", "call_local")
func reset_all_drones() -> void:
	for drone in get_tree().get_nodes_in_group("drones"):
		if drone.has_method("reset_drone"):
			drone.reset_drone()


# ============================================================================
#  CONTROLLER INPUT INJECTION
# ============================================================================

func _setup_controller_inputs() -> void:
	# Register movement axis mappings (Left stick)
	_add_joy_axis_action("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis_action("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis_action("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis_action("move_back", JOY_AXIS_LEFT_Y, 1.0)
	
	# Register button actions
	_add_joy_button_action("jump", JOY_BUTTON_A)
	_add_joy_button_action("interact", JOY_BUTTON_X)
	_add_joy_button_action("toggle_chat", JOY_BUTTON_Y)
	_add_joy_button_action("toggle_glyph", JOY_BUTTON_BACK)
	
	# Register custom look actions for the right stick
	var look_actions = ["look_left", "look_right", "look_up", "look_down"]
	for action in look_actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	
	_add_joy_axis_action("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_joy_axis_action("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_joy_axis_action("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_joy_axis_action("look_down", JOY_AXIS_RIGHT_Y, 1.0)


func _add_joy_axis_action(action: String, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	# Prevent duplicate inputs if loaded multiple times
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadMotion and existing.axis == axis and sign(existing.axis_value) == sign(value):
			return
	InputMap.action_add_event(action, event)


func _add_joy_button_action(action: String, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and existing.button_index == button:
			return
	InputMap.action_add_event(action, event)
