extends Node

signal sPong
signal sRmqMsg
signal sConnected
signal sDisconnected

@onready var _timeoutTimer:Timer = $Timeout

var _configured:bool = false

var _client:RMQClient
var _channel:RMQChannel

var eventQueue:Array = []

var rmqUsername:String
var rmqCipher:String
var rmqVhost:String
var rmqConsumingFromQueue:String
var rmqPublishingToExchange:String
var rmqPublishingToQueueRk:String
var rmqHost:String
var rmqPort:int
var rmqConnectTimeoutSec:int

#-----
#  Network effectively polling every tick, if ready by waiting for tick signal. No tick, no polling.
func _process(_delta:float) -> void:
	if _client != null:
		_client.tick()
	return
#-----
func startListening() -> void:
	sRmqMsg.connect(_on_rabbitMq_message)
	return
#-----
func stopListening() -> void:
	sRmqMsg.disconnect(_on_rabbitMq_message)
	return
#-----
func _on_rabbitMq_message(json:Dictionary) -> void:
	Log.info("queueing rabbitMqSignal: %", [json.mtype])
	return
#-----
func _on_client_disconnect(reason:String) -> void:
	Log.warn("Got disconnected because: %", [reason])
	sDisconnected.emit(reason)
	return
#-----
func sendAck(message:Dictionary) -> void:
	var publishing_error:Error = await publish(message)
	if publishing_error != OK:
		Log.error("Error publishing: %", [publishing_error])
		eventQueue.append({
			"mtype": C.MSG_DISCONNECTED
		})
	return
#-----
func rmqConnect(rmqConfig:RMQValidatedConfig) -> Error:
	rmqConfigure(rmqConfig)
	var startupErr:Error = await self.start()
	if startupErr != OK:
		Log.error("RMQClientNode.start() failed: %", [startupErr])
		return startupErr
	return OK
#-----
func rmqConfigure(rmqConfig:RMQValidatedConfig) -> Error:
	if not rmqConfig.valid:
		return FAILED

	for field in rmqConfig._requiredFields:
		Log.async("RMQ Config." + field + ": %", [rmqConfig[field]])

	rmqUsername = rmqConfig.rmqUsername
	rmqCipher = rmqConfig.rmqCipher
	rmqVhost = rmqConfig.rmqVhost
	rmqConsumingFromQueue = rmqConfig.rmqConsumingFromQueue
	rmqPublishingToExchange = rmqConfig.rmqPublishingToExchange
	rmqPublishingToQueueRk = rmqConfig.rmqPublishingToQueueRk
	rmqHost = rmqConfig.rmqHost
	rmqPort = rmqConfig.rmqPort
	rmqConnectTimeoutSec = rmqConfig.rmqConnectTimeoutSec

	_configured = true
	return OK
#-----
func start() -> Error:
	if not _configured:
		Log.error("RMQClientNode not configured")
		return FAILED

	_client = RMQClient.new()

	_timeoutTimer.set_wait_time(rmqConnectTimeoutSec)

	# DO NOT IGNORE THIS
	# Make sure that _client.tick() is invoked regularly or it will hang
	# asynchronously opens the connection.
	Log.async("opening connection")
	var client_open_error:Error = await _client.open(
			rmqHost,
			rmqPort,
			rmqUsername,
			rmqCipher,
			rmqVhost,
			_timeoutTimer
			)
	Log.async("checking connection err")
	if client_open_error != OK:
		Log.error("Error opening rmqClient: %", [client_open_error])
		return FAILED

	# most amqp interactions are conducted through channels, which multiplex a connection
	Log.async("getting channel")
	_channel = await _client.channel()

	# set up a consumer with a function callback
	Log.async("setting consume with RMQ consumableQueue: %", [rmqConsumingFromQueue])
	var consume = await _channel.basic_consume(rmqConsumingFromQueue, on_consume_message)
	Log.async("checking consume err")
	if consume[0] != OK:
		Log.error("Consume error from: %", [rmqConsumingFromQueue])
		return FAILED
	Log.async("checking if channel is open")
	if _channel:
		var result:bool = await rmqTest()
		Log.async("heartbeat test result: %", [result])
		if not result:
			return FAILED
	_client.sClientDisconnected.connect(_on_client_disconnect)
	Log.async("configuration complete, connection tested")
	sConnected.emit()
	return OK
#-----
func publish(message:Dictionary) -> Error:
	Log.async("publishing: %", [message])
	var publishing_error:Error = await _channel.basic_publish(rmqPublishingToExchange, rmqPublishingToQueueRk, JSON.stringify(message).to_utf8_buffer())
	return publishing_error
#-----
# we invoke `tick` at any frame through this
func proxyTick() -> void:
	_client.tick()
	pass
#-----
func rmqTest(timeout:int=5) -> bool:
	Log.async("publishing: " + str(C.MSG_HEARTBEAT_PING))
	Log.async("RMQ publishingToExchange: %", [rmqPublishingToExchange])
	Log.async("RMQ publishingToQueueRk: %", [rmqPublishingToQueueRk])
	var publishing_error:Error = await _channel.basic_publish(rmqPublishingToExchange, rmqPublishingToQueueRk, JSON.stringify(C.MSG_HEARTBEAT_PING).to_utf8_buffer())
	Log.async("checking publishing err")
	if publishing_error != OK:
		Log.error("Error publishing: " + str(publishing_error))
		return false
	Log.async("awaiting rmqTest signal")
	var result:Promise.PromiseResult = await awaitSignal(sPong, timeout, get_tree()).wait()
	if result.payload == "timeout":
		Log.warn("pong timeout")
		return false
	Log.async("heardpong")
	return true
#-----
# this serves as a kind of destructor, letting the broker know that we want to shut down gracefully
func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE and _client:
		push_error("RMQClientNode Notification PREDELETE")
		_client.close()
	pass
#-----
func on_consume_message(
	channel:RMQChannel,
	method:RMQBasicClass.Deliver,
	_properties:RMQBasicClass.Properties,
	body:PackedByteArray
) -> void:
	Log.async("On consume called for body: %", [body.get_string_from_utf8()])
	var json:Dictionary
	if body:
		json = parse_json_packedbytearray(body)
		if json && json.size() > 0 && json.has("mtype"):
			match json.mtype:
				C.MSG_HEARTBEAT_PONG:
					Log.async("Message: emit sPong to anyone who cares")
					sPong.emit()
					pass
				var _other:
					Log.async("Message: %", [json.mtype])
					sRmqMsg.emit(json)
					pass
				var _unknownMsg:
					Log.error("unknownMsg: %", [json])
					pass
		else:
			Log.error("Got invalid json as message: %", [body.get_string_from_utf8()])
	else:
		Log.error("Got invalid body as message: %", [body.get_string_from_utf8()])
	Log.async("Returning rmq ack for hearing msg")
	channel.basic_ack(method.delivery_tag)
	return
#-----
static func awaitSignal(signalVal:Signal, timeoutVal:float, sceneTree:SceneTree, _timeoutPayload="timeout") -> Promise:
	var signalPromise:Promise = Promise.from(signalVal)
	var timerPromise:Promise = Promise.new(
		func(resolve: Callable, _reject: Callable):
			await sceneTree.create_timer(timeoutVal).timeout
			resolve.call(_timeoutPayload)
	)
	return Promise.any([signalPromise, timerPromise])
#-----
static func awaitTask(signalVal:Signal, timeoutVal:float, sceneTree:SceneTree, task:Callable, _timeoutPayload="timeout") -> Promise:
	var signalPromise:Promise = Promise.from(signalVal)
	var timerPromise:Promise = Promise.new(
		func(resolve: Callable, _reject: Callable):
			await sceneTree.create_timer(timeoutVal).timeout
			resolve.call(_timeoutPayload)
	)
	task.call()
	return Promise.any([signalPromise, timerPromise])
#-----
static func parse_json_packedbytearray(body:PackedByteArray) -> Dictionary:
	return parse_json_string(body.get_string_from_utf8())
#----
static func parse_json_string(body:String) -> Dictionary:
	var jsonInstance:JSON = JSON.new()
	var jsonErr:Error = jsonInstance.parse(body)
	if (jsonErr == OK):
		var json:Variant = jsonInstance.get_data()
		if (json != null && json.size() > 0):
			return json
		pass
	return {}
