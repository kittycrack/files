extends CharacterBody3D
class_name Player

@export var speed: float = 8.0
@export var accel: float = 20.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 18.0
@export var cast_cooldown: float = 0.45
@export var projectile_scene: PackedScene

var peer_id: int
var cooldown_left: float = 0.0
var health: int = 100
var input_dir: Vector2
var desired_jump: bool
var cached_transform: Transform3D

@onready var model: MeshInstance3D = $Model
@onready var cast_point: Marker3D = $CastPoint

func _ready() -> void:
	cached_transform = global_transform

func setup(id: int) -> void:
	peer_id = id
	set_multiplayer_authority(id)
	name = "Player_%d" % id

func _physics_process(delta: float) -> void:
	cooldown_left = max(0.0, cooldown_left - delta)
	if is_multiplayer_authority():
		_collect_input()
		rpc_unreliable_id(1, "server_receive_input", input_dir, desired_jump, global_position)
	_apply_movement(delta)
	cached_transform = global_transform

func _collect_input() -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	desired_jump = Input.is_action_just_pressed("jump")
	if Input.is_action_just_pressed("cast_orb"):
		rpc_id(1, "server_try_cast", cast_point.global_transform)

func _apply_movement(delta: float) -> void:
	var move := Vector3(input_dir.x, 0.0, input_dir.y)
	move = move.normalized()
	var target := transform.basis * move * speed
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif desired_jump:
		velocity.y = jump_velocity
	move_and_slide()

@rpc("any_peer", "unreliable", 1)
func server_receive_input(dir: Vector2, jump: bool, reported_position: Vector3) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	if reported_position.distance_to(global_position) > 5.0:
		return
	input_dir = dir.limit_length(1.0)
	desired_jump = jump

@rpc("any_peer", "reliable", 0)
func server_try_cast(origin: Transform3D) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != peer_id or cooldown_left > 0.0:
		return
	cooldown_left = cast_cooldown
	var projectile: Node3D = projectile_scene.instantiate()
	projectile.global_transform = origin
	projectile.set("owner_peer_id", peer_id)
	get_tree().current_scene.add_child(projectile, true)
