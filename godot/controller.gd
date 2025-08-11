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

var userRmqCredentials:UserRmqCredentials
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
			"timeoutSec": 1,
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
		"connectTimeoutSec": 1,
		"username": userRmqCredentials.messageUsername,
		"cipher":  userRmqCredentials.messageCipher,

		"publishingToQueueRk": userRmqCredentials.publishingToQueueRk,
		"consumingFromQueue": userRmqCredentials.consumingFromQueue,

		"confirmEnd2End": confirmEnd2End,
	}))
	if result != OK and result != ERR_ALREADY_IN_USE:
		Log.warn("RMQ Connection failed", [result])
		status.text = "Failed"
	else:
		status.text = "Connected"
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
	httpUserCreate.request(ServiceUrl.UserCreate, [contentTypeJson], HTTPClient.METHOD_POST, JSON.stringify(userCreateDto))
	return
#-----
func _on_login_pressed() -> void:
	var userLoginDto:Dictionary = {
		"username": "myname",
		"cipher": "testtest"
	}
	httpUserLogin.request(ServiceUrl.UserLogin, [contentTypeJson], HTTPClient.METHOD_POST, JSON.stringify(userLoginDto))
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
		userRmqCredentials = UserRmqCredentials.new(json)
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
#=====
class ServiceUrl:
	const UserLogin:String = "http://localhost:8080/server/api/v1/user/login"
	const UserCreate:String = "http://localhost:8080/server/api/v1/user/create"
const contentTypeJson:String = "Content-Type: application/json"
#=====
class UserRmqCredentials:
	const _requiredFields:Array[String] = ["id", "username", "messageUsername", "messageCipher", "publishingToQueueRk", "consumingFromQueue"]
	const _className:String = "UserRmqCredentials"

	var id:String
	var username:String
	var cipher:String
	var messageUsername:String
	var messageCipher:String
	var publishingToQueueRk:String
	var consumingFromQueue:String

	var valid:bool = false

	func _init(config:Dictionary) -> void:
		Util.assertRequiredFields(config, _className, _requiredFields)
		for field in config:
			self[field] = config[field]
		valid = true
		return
#=====
