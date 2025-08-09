extends Node

signal sPong
signal sMessage(message:Dictionary)
signal sConnected
signal sDisconnected

@onready var _timeoutTimer:Timer = $Timeout

var _configured:bool = false

var _client:RMQClient
var _channel:RMQChannel

var username:String
var cipher:String
var vhost:String
var consumingFromQueue:String
var publishingToExchange:String
var publishingToQueueRk:String
var host:String
var port:int
var connectTimeoutSec:int
var pingJson:Dictionary
var pongJson:Dictionary

var incomingMessageBuffer:Array = []

#-----
func _ready() -> void:
	sMessage.connect(_on_message_read)
	return
#-----
#  Network effectively polling every tick, if ready by waiting for tick signal. No tick, no polling.
func _process(_delta:float) -> void:
	if _client != null:
		_client.tick()
	return
#----
#  Configure AND Start convenience
func doConnect(rmqConfig:RMQValidatedConfig) -> Error:
	var err:Error = configure(rmqConfig)
	if err != OK:
		return err

	var startupErr:Error = await self.start()
	if startupErr != OK:
		Log.error("start() failed: %", [startupErr])
		_on_client_disconnected("")
		return startupErr
	return OK
#-----
func doDisconnect() -> void:
	if _client == null:
		Log.error("no client to close")
		return
	_client.close()
	return
#-----
func configure(rmqConfig:RMQValidatedConfig) -> Error:
	if _client != null:
		Log.warn("configured client in use")
		return ERR_ALREADY_IN_USE

	if _configured:
		Log.warn("already configured")
		return OK

	if not rmqConfig.valid:
		Log.error("invalid config")
		return FAILED

	for field in rmqConfig.getConfigured():
		#Log.debug("Config.%: %", [field, rmqConfig[field]])
		self[field] = rmqConfig[field]

	_configured = true
	return OK
#-----
func start() -> Error:
	if not _configured:
		Log.error("Not configured")
		return FAILED

	if _client != null:
		Log.error("waiting to connect...")
		return ERR_ALREADY_IN_USE

	_client = RMQClient.new()
	_client.sClientDisconnected.connect(_on_client_disconnected)
	_timeoutTimer.set_wait_time(connectTimeoutSec)
	Log.debug("opening connection")
	var client_open_error:Error = await _client.open(
		host,
		port,
		username,
		cipher,
		vhost,
		_timeoutTimer
	)
	Log.debug("checking connection err")
	if client_open_error != OK:
		Log.error("Error opening rmqClient: %", [client_open_error])
		return FAILED

	# most amqp interactions are conducted through channels, which multiplex a connection
	Log.debug("getting channel")
	_channel = await _client.channel()

	# set up a consumer with a function callback
	Log.debug("setting consume with consumableQueue: %", [consumingFromQueue])
	var consume:Array = await _channel.basic_consume(consumingFromQueue, _on_consume_message)
	Log.debug("checking consume err")
	if consume[0] != OK:
		Log.error("Consume error from: %", [consumingFromQueue])
		return FAILED
	Log.debug("checking if channel is open")
	if _channel:
		var result:bool = await _testConnection()
		Log.debug("heartbeat test result: %", [result])
		if not result:
			return FAILED
	Log.debug("configuration complete, connection tested")
	sConnected.emit()
	return OK
#-----
func publish(message:Dictionary) -> Error:
	if _client == null:
		Log.error("client is not connected")
		return FAILED

	Log.debug("publishing: %", [message])
	var publishing_error:Error = await _channel.basic_publish(publishingToExchange, publishingToQueueRk, JSON.stringify(message).to_utf8_buffer())
	return publishing_error
#-----
func _testConnection(timeout:int=5) -> bool:
	Log.debug("publishing: %", [pingJson])
	Log.debug("RMQ publishingToExchange: %", [publishingToExchange])
	Log.debug("RMQ publishingToQueueRk: %", [publishingToQueueRk])
	var publishing_error:Error = await _channel.basic_publish(publishingToExchange, publishingToQueueRk, JSON.stringify(pingJson).to_utf8_buffer())
	Log.debug("checking publishing err")
	if publishing_error != OK:
		Log.error("Error publishing: %", [publishing_error])
		return false
	Log.debug("awaiting testConnection signal")
	var result:Promise.PromiseResult = await RMQUtil.awaitSignal(sPong, timeout, get_tree()).wait()
	if result.payload == "timeout":
		Log.warn("pong timeout")
		return false
	Log.debug("heardpong")
	return true
#-----
# this serves as a kind of destructor, letting the broker know that we want to shut down gracefully
func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE and _client:
		push_error("RMQClientNode Notification PREDELETE")
		_client.close()
	return
#-----
# Only here to filter pong
func _on_message_read(json:Dictionary) -> void:
	if json == pongJson:
		Log.debug("Message: heard pong message, emitting sPong")
		sPong.emit()
	return
#-----
func _on_consume_message(channel:RMQChannel, method:RMQBasicClass.Deliver, _properties:RMQBasicClass.Properties, body:PackedByteArray) -> void:
	Log.debug("On consume called for body: %", [body.get_string_from_utf8()])
	var json:Dictionary
	if body:
		json = RMQUtil.parse_json_packedbytearray(body)
		if json && json.size() > 0:
			Log.debug("Message: %", [json.mtype])
			sMessage.emit(json)
		else:
			Log.error("Got invalid json as message: %", [body.get_string_from_utf8()])
	else:
		Log.error("Got invalid body as message: %", [body.get_string_from_utf8()])
	Log.debug("basic_ack for hearing msg")
	channel.basic_ack(method.delivery_tag)
	return
#-----
func _on_client_disconnected(_reason:String) -> void:
	_client.sClientDisconnected.disconnect(_on_client_disconnected)
	_client.close()
	_client = null
	return
#-----
