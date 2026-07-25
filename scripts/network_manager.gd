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
