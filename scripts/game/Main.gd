extends Node3D

@onready var manager: MultiplayerManager = $MultiplayerManager
@onready var players_root: Node3D = $Players
@onready var ui: CanvasLayer = $UI
@onready var debug_label: Label = $UI/DebugPanel/DebugLabel

var player_scene: PackedScene = preload("res://scenes/Player.tscn")

func _ready() -> void:
	manager.peer_spawned.connect(_spawn_player)
	manager.peer_removed.connect(_remove_player)
	manager.match_started.connect(_on_match_started)
	manager.round_restarted.connect(_on_round_restarted)

func _process(_delta: float) -> void:
	manager.update_stats()
	if Input.is_action_just_pressed("host_game"):
		manager.host_game()
	if Input.is_action_just_pressed("join_game"):
		manager.join_game("127.0.0.1")
	if Input.is_action_just_pressed("disconnect_game"):
		manager.disconnect_game()
	if Input.is_action_just_pressed("toggle_debug"):
		$UI/DebugPanel.visible = not $UI/DebugPanel.visible
	_update_debug()

func _spawn_player(peer_id: int) -> void:
	if players_root.has_node("Player_%d" % peer_id):
		return
	var player: Player = player_scene.instantiate()
	players_root.add_child(player, true)
	player.setup(peer_id)
	player.global_position = Vector3(peer_id % 4 * 2.0, 2.0, peer_id / 4 * 2.0)

func _remove_player(peer_id: int) -> void:
	var node := players_root.get_node_or_null("Player_%d" % peer_id)
	if node:
		node.queue_free()

func _on_match_started() -> void:
	print("match started")

func _on_round_restarted() -> void:
	for child in players_root.get_children():
		(child as Node3D).global_position = Vector3(0, 2, 0)

func _update_debug() -> void:
	debug_label.text = "authority: %s\npos: %s\nvel: %s\npeers: %s\npackets: %s" % [
		str(multiplayer.get_unique_id()),
		str(_local_player_position()),
		str(_local_player_velocity()),
		str(manager.connected_peers),
		str(manager.stats)
	]

func _local_player_position() -> Vector3:
	for c in players_root.get_children():
		var p := c as Player
		if p and p.is_multiplayer_authority():
			return p.global_position
	return Vector3.ZERO

func _local_player_velocity() -> Vector3:
	for c in players_root.get_children():
		var p := c as Player
		if p and p.is_multiplayer_authority():
			return p.velocity
	return Vector3.ZERO
