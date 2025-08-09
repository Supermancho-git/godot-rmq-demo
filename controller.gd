extends Node

@onready var status:Label = $HBoxContainer/Status
@onready var rmq:Node = $RmqClientNode

#-----
func _ready() -> void:
	rmq.sConnected.connect(_on_server_connection)
	rmq.sDisconnected.connect(_on_server_disconnected)
	rmq.sMessage.connect(_on_server_message)
	return
#-----
func _on_connect_pressed() -> void: # example data
	var messageUsername:String = "uuser_1d6dc366-6936-4045-9599-a33f8f6ef1a9"
	var messageCipher:String = "upass_password"
	var publishingToQueueRk:String = "rk_user_publish_queue_1d6dc366-6936-4045-9599-a33f8f6ef1a9_5340245953529765175"
	var consumingFromQueue:String = "user.receive.queue.1d6dc366-6936-4045-9599-a33f8f6ef1a9_5340245953529765175"
	Log.info("clicked")
	status.text = "Waiting to Connect"
	# There's an assumption that you have allocated a VHOST and PUBLISH exhange that applies a filter by permissions and regex
	# That's where the publishingToQueueRk comes in, to route to the server queue, as RMQ has validated the transport
	var result:Error = await rmq.doConnect(RMQValidatedConfig.new({
		"username": messageUsername,
		"cipher":  messageCipher,
		"vhost": C.RMQ_VHOST,
		"publishingToExchange": C.RMQ_PUBLISHING_TO_EXCHANGE,
		"publishingToQueueRk": publishingToQueueRk,
		"consumingFromQueue": consumingFromQueue,
		"host": C.RMQ_HOST,
		"port": C.RMQ_PORT,
		"connectTimeoutSec": 2,
		"pingJson": C.MSG_HEARTBEAT_PING,
		"pongJson": C.MSG_HEARTBEAT_PONG
	}))
	if result != OK and result != ERR_ALREADY_IN_USE:
		Log.warn("RMQ Connection failed", [result])
		status.text = "Failed"
	return
#-----
func _on_server_connection() -> void:
	Log.info("Client CONNECTED")
	status.text = "Connected"
	return
#-----
func _on_server_disconnected(reason:String) -> void:
	Log.info("Server DISCONNECTED because %", [reason])
	status.text = "Disconnected"
	return
#-----
func _on_server_message(json:Dictionary) -> void:
	Log.info("Message signal: %", [json])
	return
#-----
func _on_send_pressed() -> void:
	if status.text == "Connected":
		rmq.publish({"something":"special"})
	return
#-----
func _on_disconnect_pressed() -> void:
	rmq.doDisconnect()
	return
#-----
