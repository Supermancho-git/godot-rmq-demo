extends Node

@onready var httpUserLogin = $HttpUserLogin
@onready var httpUserCreate = $HttpUserCreate

@onready var rmq:Node = $RmqClientNode

@onready var loginController:Control = $LoginController
@onready var assertUserButton:Button = $LoginController/AssertUser
@onready var loginButton:Button = $LoginController/Login

@onready var connectionController:Control = $ConnectionController
@onready var status:Label = $ConnectionController/HBoxContainer/Status
@onready var end2end:CheckBox = $ConnectionController/End2End
#-----
func _ready() -> void:
	rmq.sConnected.connect(_on_server_connection)
	rmq.sDisconnected.connect(_on_server_disconnected)
	rmq.sMessage.connect(_on_server_message)

	httpUserLogin.request_completed.connect(on_httpUserLogin_completed)
	httpUserCreate.request_completed.connect(on_httpUserCreate_completed)
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
		"username": "uuser_86eee2ad-d367-4e8d-bc2d-cd41c538bd42",
		"cipher":  "upass_password",

		"publishingToQueueRk": "rk_user_publish_queue_86eee2ad-d367-4e8d-bc2d-cd41c538bd42_-6313342781865142006",
		"consumingFromQueue": "user.receive.queue.86eee2ad-d367-4e8d-bc2d-cd41c538bd42_-6313342781865142006",

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
func _on_assert_user_pressed() -> void:
	var userCreateDto:Dictionary = {
		"username": "myname",
		"email": "myemail@nowhere.com",
		"cipher": "testtest"
	}
	httpUserCreate.request(Constants.ServiceUrl.UserCreate, [Constants.contentTypeJson], HTTPClient.METHOD_POST, JSON.stringify(userCreateDto))
	return
#-----
func _on_login_pressed() -> void:
	var userLoginDto:Dictionary = {
		"username": "myname",
		"cipher": "testtest"
	}
	httpUserLogin.request(Constants.ServiceUrl.UserLogin, [Constants.contentTypeJson], HTTPClient.METHOD_POST, JSON.stringify(userLoginDto))
	return
#----
func on_httpUserCreate_completed(_result:int, response_code:int, _headers:PackedStringArray, body:PackedByteArray) -> void:
	var json:Dictionary
	if body:
		json = RMQUtil.parse_json_packedbytearray(body)
	if json and json.size() > 0:
		if response_code == 200 or (response_code == 400 and json.has("reasons") and json.reasons[0] == "User already exists"):
			loginButton.disabled = false
			return
	Log.error("Assert User failed.")
	return
#----
func on_httpUserLogin_completed(_result:int, response_code:int, _headers:PackedStringArray, body:PackedByteArray) -> void:
	var json:Dictionary
	if body:
		json = RMQUtil.parse_json_packedbytearray(body)
	if (json && response_code == 200 && json.size() > 0):
		loginController.hide()
		connectionController.show()
		return
	Log.error("Login failed.")
	return
#----
func _on_back_pressed() -> void:
	connectionController.hide()
	loginController.show()
	return
#-----
func _on_exit_pressed() -> void:
	get_tree().quit()
#-----

class Constants:
	class ServiceUrl:
		const UserLogin:String = "http://localhost:8080/server/api/v1/user/login"
		const UserCreate:String = "http://localhost:8080/server/api/v1/user/create"
	const contentTypeJson:String = "Content-Type: application/json"
