extends Node
class_name MultiplayerManager

signal peer_spawned(peer_id: int)
signal peer_removed(peer_id: int)
signal match_started
signal round_restarted

#region Constants
const PORT: int = 42042
const MAX_CLIENTS: int = 16
#endregion

#region Runtime state
var is_host: bool = false
var connected_peers: Array[int] = []
var stats := {
	"in_packets": 0,
	"out_packets": 0,
	"dropped_packets": 0,
	"rtt_ms": 0.0
}
#endregion

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game() -> void:
	disconnect_game()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to host: %s" % error_string(err))
		return
	is_host = true
	multiplayer.multiplayer_peer = peer
	_set_authority_local()
	spawn_player(multiplayer.get_unique_id())

func join_game(ip: String) -> void:
	disconnect_game()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		push_error("Failed to join: %s" % error_string(err))
		return
	is_host = false
	multiplayer.multiplayer_peer = peer

func disconnect_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	for peer_id in connected_peers.duplicate():
		remove_player(peer_id)
	connected_peers.clear()

func spawn_player(peer_id: int) -> void:
	if not connected_peers.has(peer_id):
		connected_peers.append(peer_id)
	peer_spawned.emit(peer_id)

func remove_player(peer_id: int) -> void:
	connected_peers.erase(peer_id)
	peer_removed.emit(peer_id)

func start_match() -> void:
	if not multiplayer.is_server():
		return
	rpc("rpc_start_match")

func restart_round() -> void:
	if not multiplayer.is_server():
		return
	rpc("rpc_restart_round")

func update_stats() -> void:
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer == null:
		return
	# Godot ENet peer statistics are limited from script; these are safe approximations.
	stats.rtt_ms = float(peer.get_peer(1).get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)) if not multiplayer.is_server() else 0.0

@rpc("authority", "call_local", "reliable", 0)
func rpc_start_match() -> void:
	match_started.emit()

@rpc("authority", "call_local", "reliable", 0)
func rpc_restart_round() -> void:
	round_restarted.emit()

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		spawn_player(peer_id)
		rpc_id(peer_id, "rpc_spawn_existing", connected_peers)

@rpc("authority", "reliable", 0)
func rpc_spawn_existing(peers: Array[int]) -> void:
	for peer_id in peers:
		spawn_player(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	remove_player(peer_id)

func _on_server_disconnected() -> void:
	disconnect_game()

func _set_authority_local() -> void:
	set_multiplayer_authority(multiplayer.get_unique_id())
