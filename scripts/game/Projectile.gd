extends Area3D

@export var speed: float = 22.0
@export var lifetime: float = 3.0
@export var damage: int = 34
var owner_peer_id: int = -1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += -global_transform.basis.z * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is Player and body.peer_id != owner_peer_id:
		if multiplayer.is_server():
			body.health -= damage
		queue_free()
