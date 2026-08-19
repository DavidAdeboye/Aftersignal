extends Interactable

## A physical item the player can pick up. Removes itself from the world
## and reports what was collected on the player's HUD. Stores the item in
## the player's inventory so locked doors and other scripts can check for it.

@export var item_name: String = "an item"
@export var item_id: String = ""


func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to pick up"
	if item_id == "":
		item_id = item_name.to_snake_case()
	call_deferred("_simplify_pickup_collision")


func _simplify_pickup_collision() -> void:
	var local_bounds := AABB()
	var has_bounds := false
	for node in find_children("", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var bounds := global_transform.affine_inverse() * (mesh_instance.global_transform * mesh_instance.get_aabb())
		local_bounds = bounds if not has_bounds else local_bounds.merge(bounds)
		has_bounds = true
	_disable_detailed_collision(self)
	if not has_bounds:
		return
	var body := StaticBody3D.new()
	body.name = "PickupCollisionProxy"
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = local_bounds.size.max(Vector3(0.12, 0.12, 0.12))
	shape_node.shape = box
	shape_node.position = local_bounds.get_center()
	body.add_child(shape_node)
	add_child(body)


func _disable_detailed_collision(node: Node) -> void:
	if node is CollisionShape3D:
		var collision := node as CollisionShape3D
		if collision.shape is ConcavePolygonShape3D or collision.shape is ConvexPolygonShape3D:
			collision.disabled = true
	for child in node.get_children():
		_disable_detailed_collision(child)


func interact(player: Node = null) -> void:
	if get_meta("collected", false):
		return
	if player == null or not player.has_method("add_item"):
		return
	_notify(player, "Picked up: " + item_name)
	if multiplayer.is_server():
		NetworkManager.collect_pickup.rpc(get_path(), item_id, player.get_path())
	else:
		NetworkManager.request_collect_pickup.rpc_id(1, get_path(), item_id, player.get_path())
