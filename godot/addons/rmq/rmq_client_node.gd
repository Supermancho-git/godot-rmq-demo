extends Node

signal sPong
signal sCancelled
signal sMessage(message:Dictionary)
signal sConnected
signal sDisconnected

@onready var _timeoutTimer:Timer = $Timeout

var _configured:bool = false

var _client:RMQClient
var _channel:RMQChannel
var _testPromiseResult:Promise.PromiseResult
var _confirmEnd2End:bool

var username:String
var cipher:String
var vhost:String
var consumingFromQueue:String
var publishingToExchange:String
var publishingToQueueRk:String
var host:String
var port:int
var connectTimeoutSec:int
var confirmEnd2End:RMQEnd2EndSettings
var useConfirmEnd2End:bool

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
		Log.warn("start() failed: %", [startupErr])
		if _client != null: # already removed due to a disconnect, before connection finished
			_on_client_disconnected("startup failure")
		return startupErr
	return OK
#-----
func doDisconnect(reason:String = "application disconnected") -> void:
	if _client == null:
		Log.warn("no client to close")
		return
	_client.close(reason)
	return
#-----
func configure(rmqConfig:RMQValidatedConfig) -> Error:
	if _client != null:
		Log.warn("configured client in use")
		return ERR_ALREADY_IN_USE

	if _configured:
		Log.warn("reconfiguring")

	if not rmqConfig.valid:
		Log.warn("invalid config")
		return FAILED

	for field in rmqConfig.getConfigured():
		#Log.debug("Config.%: %", [field, rmqConfig[field]])
		self[field] = rmqConfig[field]

	_configured = true
	return OK
#-----
func start() -> Error:
	if not _configured:
		Log.warn("Not configured")
		return FAILED

	if _client != null:
		Log.warn("waiting to connect...")
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
		Log.warn("Error opening rmqClient: %", [client_open_error])
		return FAILED

	# most amqp interactions are conducted through channels, which multiplex a connection
	Log.debug("getting channel")
	_channel = await _client.channel()

	# set up a consumer with a function callback
	Log.debug("setting consume with consumableQueue: %", [consumingFromQueue])
	var consume:Array = await _channel.basic_consume(consumingFromQueue, _on_consume_message)
	Log.debug("checking consume err")
	if consume[0] != OK:
		Log.warn("Consume error from: %", [consumingFromQueue])
		return FAILED
	Log.debug("checking if channel is open bidirectionally")
	if _channel and useConfirmEnd2End:
		var result:bool = await _confirmBidirectional(confirmEnd2End.timeoutSec)
		Log.debug("heartbeat test result: %", [result])
		if not result:
			return FAILED
		Log.debug("bidirectional connection confirmed")
	Log.debug("configuration of connection complete")
	sConnected.emit()
	return OK
#-----
func publish(message:Dictionary) -> Error:
	if _client == null:
		Log.warn("client is not connected")
		return FAILED

	Log.debug("publishing: %", [message])
	var publishing_error:Error = await _channel.basic_publish(publishingToExchange, publishingToQueueRk, JSON.stringify(message).to_utf8_buffer())
	return publishing_error
#-----
func _confirmBidirectional(timeout:int=5) -> bool:
	Log.debug("publishing message: %", [confirmEnd2End.pingJson])
	Log.debug("publishingToExchange: ", [publishingToExchange])
	Log.debug("publishingToQueueRk: ", [publishingToQueueRk])
	var publishing_error:Error = await _channel.basic_publish(publishingToExchange, publishingToQueueRk, JSON.stringify(confirmEnd2End.pingJson).to_utf8_buffer())
	Log.debug("checking publishing err")
	if publishing_error != OK:
		Log.warn("Error publishing: %", [publishing_error])
		return false
	Log.debug("awaiting pong, cancel, or timeout")
	_testPromiseResult = await RMQUtil.awaitAnySignal([sCancelled, sPong], timeout, get_tree()).wait()
	if _testPromiseResult.payload == "timeout":
		Log.warn("pong timeout")
		return false
	if _testPromiseResult.payload == sCancelled.get_name():
		return false
	Log.debug("heardpong", [_testPromiseResult.payload])
	return true
#-----
# this serves as a kind of destructor, letting the broker know that we want to shut down gracefully
func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE and _client:
		Log.warn("Notification PREDELETE")
		_client.close("predelete")
	return
#-----
# Only here to filter pong
func _on_message_read(json:Dictionary) -> void:
	if useConfirmEnd2End and json == confirmEnd2End.pongJson:
		Log.debug("Message: heard pong message, emitting sPong")
		sPong.emit()
	return
#-----
func _on_consume_message(channel:RMQChannel, method:RMQBasicClass.Deliver, _properties:RMQBasicClass.Properties, body:PackedByteArray) -> void:
	Log.debug("read message from channel with body: ", [body.get_string_from_utf8()])
	var json:Dictionary
	if body:
		json = RMQUtil.parse_json_packedbytearray(body)
		if json && json.size() > 0:
			Log.debug("parsed incoming message is: %", [json])
			sMessage.emit(json)
		else:
			Log.warn("Got invalid json as message: %", [body.get_string_from_utf8()])
	else:
		Log.warn("Got invalid body as message: %", [body.get_string_from_utf8()])
	Log.debug("basic_ack for hearing msg")
	channel.basic_ack(method.delivery_tag)
	return
#-----
func _on_client_disconnected(reason:String) -> void:
	sCancelled.emit()
	_timeoutTimer.stop()
	if _client:
		_client.sClientDisconnected.disconnect(_on_client_disconnected)
		_client.close()
	_client = null
	sDisconnected.emit(reason)
	return
#-----
