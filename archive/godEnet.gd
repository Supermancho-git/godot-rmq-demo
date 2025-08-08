extends Node

#signal player_connected(peer_id, player_info)
#signal player_disconnected(peer_id)
#signal server_disconnected
@onready var status:Label = $HBoxContainer/Status
@onready var client_connection_timeout_timer = Timer.new()

var _serverPort:int = 9090
var _serverHost:String = "localhost"
var peer:ENetMultiplayerPeer
#-----
func _ready() -> void:
	peer = ENetMultiplayerPeer.new()

	# multiplayer is a globally available, built-in multiplayer API
	multiplayer.connected_to_server.connect(_on_server_connection)
	multiplayer.connection_failed.connect(_on_server_disconnection)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	return
#-----
func _on_send_pressed() -> void:
	print("clicked")
	peer.close()
	peer.create_client(_serverHost, _serverPort)
	# we want to know what happens with this client creation, so we assign the client into it.
	# The connections in _ready(), will catch any signals the client fires off,
	# once multiplayer knows about it.
	multiplayer.multiplayer_peer = peer
	return
#-----
func _on_server_connection() -> void:
	print("Client CONNECTED")
	status.text = "Connected"
	return
#-----
func _on_server_disconnection() -> void:
	print("Client DISCONNECTED")
	status.text = "Disconnected"
	return
#-----
func _on_server_disconnected() -> void:
	print("Server DISCONNECTED")
	status.text = "Got Disconnected"
	return
#-----
