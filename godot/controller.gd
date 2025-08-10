extends Node

@onready var status:Label = $HBoxContainer/Status
@onready var rmq:Node = $RmqClientNode
@onready var end2end:CheckBox = $End2End

#-----
func _ready() -> void:
	rmq.sConnected.connect(_on_server_connection)
	rmq.sDisconnected.connect(_on_server_disconnected)
	rmq.sMessage.connect(_on_server_message)
	return
#-----
func _on_connect_pressed() -> void: # example data
	Log.info("clicked")
	status.text = "Waiting to Connect"

	var confirmEnd2End:RMQClientConfig.RMQEnd2EndSettings = null
	if end2end.button_pressed:
		confirmEnd2End = RMQClientConfig.RMQEnd2EndSettings.new({
			"timeoutSec": 2,
			"pingJson": {"mtype": "ping"},
			"pongJson": {"mtype": "pong"},
		})

	# There's an assumption that you have allocated a VHOST and PUBLISH exhange that applies a filter by permissions and regex
	# That's where the publishingToQueueRk comes in, to route to the server queue, as RMQ has validated the transport
	var result:Error = await rmq.doConnect(RMQClientConfig.new({
		"host": "localhost",
		"port": 5672,
		"vhost": "my_vhost",
		"publishingToExchange": "my.external.topic",
		"connectTimeoutSec": 2,
		"username": "uuser_5212f6e1-a239-4d5f-96c7-fa756bfe9236",
		"cipher":  "upass_password",

		"publishingToQueueRk": "rk_user_publish_queue_5212f6e1-a239-4d5f-96c7-fa756bfe9236_-774881100357448360",
		"consumingFromQueue": "user.receive.queue.5212f6e1-a239-4d5f-96c7-fa756bfe9236_-774881100357448360",

		"confirmEnd2End": confirmEnd2End,
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
	Log.info("Server DISCONNECTED (%)", [reason])
	status.text = "Disconnected"
	return
#-----
func _on_server_message(json:Dictionary) -> void:
	Log.info("sMessage received with payload: %", [json])
	return
#-----
func _on_send_pressed() -> void:
	if status.text != "Connected":
		Log.warn("not connected")
		return
	rmq.publish({"mtype":"ping"})
	return
#-----
func _on_disconnect_pressed() -> void:
	rmq.doDisconnect()
	return
#-----
