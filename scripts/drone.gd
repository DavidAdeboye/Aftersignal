extends CharacterBody3D
class_name PatrolDrone

## Server-authoritative drone AI with State Machine.
## Syncs position, rotation, and state to all clients.

enum State { PATROL, CHASE, STUNNED }

@export var speed: float = 1.8
@export var chase_speed: float = 3.6
@export var vision_range: float = 14.0
@export var stun_duration: float = 6.0
@export var patrol_path_node: NodePath

@export var current_state: State = State.PATROL
@export var disrupt_code: String = "VENT"
@export var drones_active: bool = false ## Toggle to false to pause all drone attacks & movement for exploration/testing

# Replication variables
@export var sync_position: Vector3
@export var sync_rotation: Vector3

var waypoints: Array[Vector3] = []
var current_waypoint_idx: int = 0
var target_player: CharacterBody3D = null
var chase_lost_timer: float = 0.0
var spawn_pos: Vector3
var spawn_rot: Vector3
var current_stun_timer: float = 0.0

@onready var eye_light: OmniLight3D = $EyeLight
@onready var eye_mesh: MeshInstance3D = $EyeMesh
@onready var spark_particles: CPUParticles3D = $SparkParticles

const CODES = ["CORE", "VENT", "COIL", "WAVE", "GRID", "LINK", "NODE", "PORT", "CELL", "BEAM"]

func _ready() -> void:
	add_to_group("drones")
	spawn_pos = global_position
	spawn_rot = global_rotation
	
	randomize()
	disrupt_code = CODES.pick_random()

	# Initialize waypoints
	if patrol_path_node:
		var path_parent = get_node_or_null(patrol_path_node)
		if path_parent:
			for child in path_parent.get_children():
				if child is Node3D:
					waypoints.append(child.global_position)
	
	if waypoints.is_empty():
		waypoints.append(spawn_pos)

	if multiplayer.is_server():
		sync_position = global_position
		sync_rotation = global_rotation


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_server_physics_process(delta)
		sync_position = global_position
		sync_rotation = global_rotation
	else:
		# Interpolate positions on clients for smooth networking
		global_position = global_position.lerp(sync_position, 0.2)
		global_rotation = global_rotation.lerp(sync_rotation, 0.2)
	
	# Update visual states locally on both server and clients
	_update_visuals(delta)


func _server_physics_process(delta: float) -> void:
	if not drones_active:
		velocity = Vector3.ZERO
		return

	match current_state:
		State.PATROL:
			_patrol_state(delta)
		State.CHASE:
			_chase_state(delta)
		State.STUNNED:
			_stunned_state(delta)


func _patrol_state(delta: float) -> void:
	if waypoints.is_empty():
		return

	var target = waypoints[current_waypoint_idx]
	# Ignore Y difference for horizontal movement
	var target_flat = Vector3(target.x, global_position.y, target.z)
	
	if global_position.distance_to(target_flat) < 0.5:
		current_waypoint_idx = (current_waypoint_idx + 1) % waypoints.size()
		target = waypoints[current_waypoint_idx]
		target_flat = Vector3(target.x, global_position.y, target.z)

	var dir = (target_flat - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	# Rotate towards movement direction
	if velocity.length_squared() > 0.01:
		var target_look = global_position + velocity
		look_at(Vector3(target_look.x, global_position.y, target_look.z), Vector3.UP)

	# 360-degree Player Detection Check
	_check_for_players()


func _chase_state(delta: float) -> void:
	if not is_instance_valid(target_player):
		current_state = State.PATROL
		return

	# Move towards player
	var player_pos = target_player.global_position
	# Float height adjustment (keep drone slightly hovering above player floor)
	var target_pos = Vector3(player_pos.x, player_pos.y + 1.2, player_pos.z)
	
	var dir = (target_pos - global_position).normalized()
	velocity = dir * chase_speed
	move_and_slide()

	# Face the player
	look_at(Vector3(player_pos.x, global_position.y, player_pos.z), Vector3.UP)

	# Check range to player for KO trigger
	if global_position.distance_to(player_pos) < 1.6:
		if target_player.has_method("knockout"):
			target_player.knockout()
			# Teleport/knockout will reset drones, so stop chase
			return

	# Line-of-sight raycast check to maintain chase
	var has_los = _has_line_of_sight(target_player)
	if has_los:
		chase_lost_timer = 0.0
	else:
		chase_lost_timer += delta
		if chase_lost_timer >= 3.0:
			# Lost player! Go back to patrol
			target_player = null
			current_state = State.PATROL


func _stunned_state(delta: float) -> void:
	velocity = Vector3.ZERO
	current_stun_timer -= delta
	if current_stun_timer <= 0.0:
		# Recover from stun and return to nearest patrol point
		current_state = State.PATROL
		_find_nearest_waypoint()


func _check_for_players() -> void:
	# Scan all players in the wing
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		# Try looking inside "Players" node if group isn't setup yet
		var players_parent = get_tree().current_scene.get_node_or_null("Players")
		if players_parent:
			for child in players_parent.get_children():
				if child is CharacterBody3D:
					players.append(child)

	var closest_player: CharacterBody3D = null
	var min_dist: float = vision_range

	for player in players:
		if not is_instance_valid(player):
			continue
		
		# Check range
		var dist = global_position.distance_to(player.global_position)
		if dist < min_dist:
			# Raycast vision check (obstacle collision check)
			if _has_line_of_sight(player):
				closest_player = player
				min_dist = dist

	if closest_player:
		target_player = closest_player
		current_state = State.CHASE
		chase_lost_timer = 0.0


func _has_line_of_sight(player: CharacterBody3D) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position, 
		player.global_position + Vector3(0, 0.5, 0) # point slightly above center
	)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		# Check if it hit the player directly
		if collider == player or collider.is_ancestor_of(player):
			return true
	return false


func _find_nearest_waypoint() -> void:
	if waypoints.is_empty():
		return
	var nearest_idx = 0
	var min_dist = 999999.0
	for i in range(waypoints.size()):
		var dist = global_position.distance_to(waypoints[i])
		if dist < min_dist:
			min_dist = dist
			nearest_idx = i
	current_waypoint_idx = nearest_idx


# Stun method (called via RPC on server)
func stun(tool_type: String) -> void:
	var duration = stun_duration
	if tool_type == "welding_torch":
		duration = 12.0 # Higher risk, higher reward
	else:
		duration = 6.0 # Ranged disruptor
		
	if current_state == State.STUNNED:
		current_stun_timer = max(current_stun_timer, duration)
		return
		
	current_state = State.STUNNED
	current_stun_timer = duration
	target_player = null
	
	# Play particles on all clients
	if spark_particles:
		spark_particles.emitting = true


# Reset method (called via RPC when player is knocked out)
func reset_drone() -> void:
	global_position = spawn_pos
	global_rotation = spawn_rot
	current_state = State.PATROL
	target_player = null
	current_waypoint_idx = 0
	current_stun_timer = 0.0
	disrupt_code = CODES.pick_random()
	velocity = Vector3.ZERO


func _update_visuals(delta: float) -> void:
	if not eye_light or not eye_mesh:
		return
		
	# Adjust eye color and light properties based on state
	var target_color := Color.GREEN
	var energy_mult := 1.0
	var is_flickering := false
	
	match current_state:
		State.PATROL:
			target_color = Color(0.1, 0.8, 0.2) # Electric Green
		State.CHASE:
			target_color = Color(1.0, 0.05, 0.05) # Aggressive Red
			# Pulse light intensity in chase mode
			energy_mult = 1.0 + sin(Time.get_ticks_msec() * 0.015) * 0.4
		State.STUNNED:
			target_color = Color(1.0, 0.7, 0.0) # Warning Amber/Yellow
			is_flickering = true
			
	# Update light and material emissive color
	if is_flickering:
		# Flicker between yellow and off
		var flicker = randf() > 0.4
		eye_light.light_color = target_color
		eye_light.light_energy = 1.5 if flicker else 0.1
		
		var mat = eye_mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.emission = target_color if flicker else Color.BLACK
	else:
		eye_light.light_color = target_color
		eye_light.light_energy = 1.8 * energy_mult
		
		var mat = eye_mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.emission = target_color
			mat.emission_energy_multiplier = 1.2 * energy_mult
