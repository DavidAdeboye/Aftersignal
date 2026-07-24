extends CharacterBody3D

## First-person controller — Aftersignal
## Attach this script to a CharacterBody3D root that has:
##   - CollisionShape3D (capsule, matching a human-ish height)
##   - A Node3D called "Head" as a child, with a Camera3D as its child
##   - Camera3D should have a RayCast3D child pointed forward (Z: -3)
## Head handles vertical look (pitch); the body handles horizontal look (yaw).

@export var walk_speed: float = 3.5
@export var mouse_sensitivity: float = 0.0025
@export var jump_velocity: float = 4.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var interact_prompt: Label = $CanvasLayer/InteractPrompt

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_interactable: Interactable = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
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


func _update_interactable() -> void:
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is Interactable:
			current_interactable = collider
			interact_prompt.visible = true
			return
	current_interactable = null
	interact_prompt.visible = false
