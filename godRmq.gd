extends Node

@onready var status:Label = $HBoxContainer/Status
@onready var rmq:Node = $RmqClientNode

#-----
func _ready() -> void:
	rmq.sConnected.connect(_on_server_connection)
	rmq.sDisconnected.connect(_on_server_disconnected)
	rmq.sRmqMsg.connect(_on_rmq_msg_heard)
	return
#-----
func _on_connect_pressed() -> void: # example data
	var messageUsername:String = "uuser_1d6dc366-6936-4045-9599-a33f8f6ef1a9"
	var messageCipher:String = "upass_password"
	var publishingToQueueRk:String = "rk_user_publish_queue_1d6dc366-6936-4045-9599-a33f8f6ef1a9_5340245953529765175"
	var consumingFromQueue:String = "user.receive.queue.1d6dc366-6936-4045-9599-a33f8f6ef1a9_5340245953529765175"
	Log.info("clicked")
	await rmq.rmqConnect(RMQValidatedConfig.new({
		"rmqUsername": messageUsername,
		"rmqCipher":  messageCipher,
		"rmqVhost": C.RMQ_VHOST,
		"rmqPublishingToExchange": C.RMQ_PUBLISHING_TO_EXCHANGE,
		"rmqPublishingToQueueRk": publishingToQueueRk,
		"rmqConsumingFromQueue": consumingFromQueue,
		"rmqHost": C.RMQ_HOST,
		"rmqPort": C.RMQ_PORT,
		"rmqConnectTimeoutSec": 5
	}))
	return
#-----
func _on_server_connection() -> void:
	print("Client CONNECTED")
	status.text = "Connected"
	return
#-----
func _on_server_disconnected(reason:String) -> void:
	print("Server DISCONNECTED because " + reason)
	status.text = "Got Disconnected"
	return
#-----
func _on_rmq_msg_heard(json:String) -> void:
	print("heard:" + json)
	return
#-----
func _on_send_pressed() -> void:
	if status.text == "Connected":
		rmq.publish({"something":"special"})
	return
#-----
