class_name RMQClient
extends RefCounted

var _connection : StreamPeer

signal _on_inbound_data(buffer : PackedByteArray)
signal _handshake_ok
signal _tick_signal
signal sClientDisconnected(reason:String)

var _active_channels : Dictionary = {}
var _next_channel_num: int = 1
var _frame_max : int
var _channel_max : int
var _reason:String

# tick the client to have it collect inbound data from the tcp connection, and send outbound data.
func tick():
	_tick_signal.emit()
	return

# Connect to RabbitMQ using TCP and PLAIN authorization.
# host is the rabbitmq server hostname, port its port.
# username and password required for basic auth.
# virtual_host defaults to /.
func open(
	host:String,
	port:int,
	username:String,
	password:String,
	virtual_host:String="/",
	timeout:Timer=null
	) -> Error:
	var tcp := StreamPeerTCP.new()
	_connection = tcp
	_connection.big_endian = true
	var connect_err := tcp.connect_to_host(host, port)
	if connect_err != OK:
		Log.error("[rabbitmq] Failed to connect to " + host + ":" + str(port))
		return connect_err

	if timeout != null:
		timeout.start()

	while tcp.get_status() == StreamPeerTCP.Status.STATUS_CONNECTING and not timeout.is_stopped():
		await _tick_signal
		var poll_err := tcp.poll()
		if poll_err != OK:
			Log.error("[rabbitmq] Failed to poll " + host + ":" + str(port) + " error: " + str(poll_err))
			return poll_err
	if timeout != null and timeout.is_stopped():
		Log.debug("[rabbitmq] Connection timed out: %", [_connection.get_status()])
		return ERR_TIMEOUT
	timeout.stop()
	if _connection.get_status() != StreamPeerTCP.Status.STATUS_CONNECTED:
		Log.debug("[rabbitmq] Connection error status: %", [_connection.get_status()])
		return ERR_CONNECTION_ERROR
	_start_receiving()
	_start_parsing()
	var handshake_err = await _connect_rabbitmq(username,password,virtual_host)
	if handshake_err != OK:
		return handshake_err
	#Log.debug("[rabbitmq] Connected to " + host + ":" + str(port))
	return OK

func open_tls(
	host:String,
	port:int,
	username:String,
	password:String,
	common_name:String,
	tls_options:TLSOptions=null,
	virtual_host:String="/",
) -> Error:
	_connection = StreamPeerTLS.new()
	#_connection.big_endian = true
	var tcp := StreamPeerTCP.new()
	#tcp.big_endian = true
	var tcp_connect_err := tcp.connect_to_host(host, port)
	if tcp_connect_err != OK:
		Log.error("[rabbitmq] Failed to connect to " + host + ":" + str(port))
		return tcp_connect_err

	while tcp.get_status() == StreamPeerTCP.Status.STATUS_CONNECTING:
		await _tick_signal
		var poll_err := tcp.poll()
		if poll_err != OK:
			Log.error("[rabbitmq] Failed to poll " + host + ":" + str(port) + " error: " + str(poll_err))
			return poll_err
	if tcp.get_status() != StreamPeerTCP.Status.STATUS_CONNECTED:
		Log.error("[rabbitmq] TCP Connection error status: " + _connection.get_status())
		return ERR_CONNECTION_ERROR

	var tls_connect_err : Error = _connection.connect_to_stream(tcp, common_name, tls_options)
	if tls_connect_err != OK:
		Log.error("[rabbitmq] Failed to tls connect to " + host + ":" + str(port) + " got error code " + str(tls_connect_err))
		return tls_connect_err
	while _connection.get_status() == StreamPeerTLS.Status.STATUS_HANDSHAKING:
		await _tick_signal
		_connection.poll()
	if _connection.get_status() != StreamPeerTLS.Status.STATUS_CONNECTED:
		Log.error("[rabbitmq] TLS Connection error status: " + _connection.get_status())
		return ERR_CONNECTION_ERROR
	_start_receiving()
	_start_parsing()
	var handshake_err = await _connect_rabbitmq(username,password,virtual_host)
	if handshake_err != OK:
		return handshake_err
	#Log.debug("[rabbitmq] Connected to " + host + ":" + str(port))
	return OK

# internal function, announces protocol and performs rmq handshake
func _connect_rabbitmq(username:String,password:String,virtual_host:String):
	var proto_err = await _announce_protocol()
	if proto_err != OK:
		Log.error("[rabbitmq] could not send protocol info: " + str(proto_err))
		_connection.disconnect_from_host()
		_connection = null
		return proto_err
	var handshake_error = await _handshake(username, password, virtual_host)
	if handshake_error != OK:
		Log.error("[rabbitmq] error during handshake: " + str(handshake_error))
		return handshake_error
	return OK

# internal coroutine continuosly waiting for inbound bytes to be available from the tcp peer.
func _start_receiving():
	while true:
		_connection.poll()
		if _connection.get_status() != 2: # 2 means CONNECTED in both StreamPeerTLS and StreamPeerTCP
			Log.debug("[rabbitmq] client receiver disconnected, got status " + str(_connection.get_status()))
			_reason = ""
			return
		var available_bytes = _connection.get_available_bytes()
		while available_bytes > 0:
			var pdata := _connection.get_partial_data(available_bytes)
			var error = pdata[0]
			if error != OK:
				Log.error("[rabbitmq] error ticking: " + str(error))
				close()
				return
			var data : PackedByteArray = pdata[1]
			_on_inbound_data.emit(data)

			# in case get_partial_data returned less than expected
			available_bytes -= data.size()
			if available_bytes > 0:
				_connection.poll()
				if _connection.get_status() != 2: # 2 means CONNECTED in both StreamPeerTLS and StreamPeerTCP
					Log.warn("[rabbitmq] client disconnected, got status " + str(_connection.get_status()))
					return
				await _tick_signal
		await _tick_signal

# internal coroutine continuosly waiting for inbound data and parsing it into frames, delegating these frames to the respective consumers.
func _start_parsing():
	var remaining_bytes := PackedByteArray()
	while true:
		var frame_parse_result := await RMQFrame.forward(
			remaining_bytes,
			_on_inbound_data,
			func(err):
				Log.error("[rabbitmq] error reading frame: " + str(err))
				pass
		)
		remaining_bytes = frame_parse_result.remaining_bytes

		var received_frame : RMQFrame = frame_parse_result.data

		if received_frame.frame_type == RMQFrame.FrameType.HEARTBEAT:
			if received_frame.channel_number != 0:
				Log.warn("heartbeat may only be sent on channel 0")
			await _heartbeat()
		elif received_frame.channel_number == 0:
			var close_frame := await RMQConnectionClass.Close.from_frame(received_frame)
			if close_frame != null:
				Log.debug("[rabbitmq] closing with reply code %d and text \"%s\" because of class id %d and method id %d" % [close_frame.reply_code, close_frame.reply_text, close_frame.class_id, close_frame.method_id])
				_reason = close_frame.reply_text
				await _close_ok("remote disconnected")
		elif received_frame.channel_number > 0:
			var channel : RMQChannel = _active_channels.get(received_frame.channel_number, null)
			if channel:
				channel._receive_frame(received_frame)
			else:
				Log.warn("[rabbitmq] received packet for channel %d but client doesnt know of the channel" % received_frame.channel_number)
			pass
		pass

# internal function, announces clients' amqp version to broker.
func _announce_protocol() -> Error:
	# AMQP header frame: protocol identifier
	var announce_buffer = PackedByteArray()
	announce_buffer.append_array("AMQP".to_utf8_buffer())
	announce_buffer.append(0)
	# protocol version
	for d in [0,9,1]:
		announce_buffer.append(d)
	return await _send(announce_buffer)

# internal function doing the amqp handshake.
# hard-coded to plain auth and en_US locale for now.
func _handshake(username:String,password:String,virtual_host:String) -> Error:
	var connection_start_frame_parse_result := await RMQFrame.forward(
		PackedByteArray(),
		_on_inbound_data,
		func(err): Log.error("[rabbitmq] error reading start frame: " + str(err))
	)
	var connection_start_method := await RMQConnectionClass.Start.from_frame(connection_start_frame_parse_result.data)
	var start_ok_err := await _send(RMQConnectionClass.StartOk.new(username,password).to_frame().to_wire())
	if start_ok_err != OK:
		Log.error("[rabbitmq] could not send start-ok: " + str(start_ok_err))
		return start_ok_err

	var connection_tune_frame_parse_result := await RMQFrame.forward(
		connection_start_frame_parse_result.remaining_bytes,
		_on_inbound_data,
		func(err): Log.error("[rabbitmq] error reading tune frame: " + str(err))
	)
	var connection_tune_method := await RMQConnectionClass.Tune.from_frame(connection_tune_frame_parse_result.data)
	_frame_max = connection_tune_method.frame_max
	_channel_max = connection_tune_method.channel_max

	var channel_max := connection_tune_method.channel_max
	var frame_max := connection_tune_method.frame_max
	var heartbeat := connection_tune_method.heartbeat
	var tune_ok_err := await _send(RMQConnectionClass.TuneOk.new(channel_max, frame_max, heartbeat).to_frame().to_wire())
	if tune_ok_err != OK:
		Log.error("[rabbitmq] could not send tune-ok: " + str(tune_ok_err))
		return tune_ok_err
	var open_err := await _send(RMQConnectionClass.Open.new(virtual_host).to_frame().to_wire())
	if open_err != OK:
		Log.error("[rabbitmq] could not send open: " + str(open_err))
		return open_err

	var connection_openok_frame_parse_result := await RMQFrame.forward(
		connection_tune_frame_parse_result.remaining_bytes,
		_on_inbound_data,
		func(err): Log.error("[rabbitmq] error reading openok frame: " + str(err))
	)
	var connection_openok_method := await RMQConnectionClass.OpenOk.from_frame(connection_openok_frame_parse_result.data)
	return OK

# internal function used to send data by coroutine should not all bytes be written into the tcp peer in a single invocation
func _send(data: PackedByteArray) -> Error:
	var send_response = _connection.put_partial_data(data)
	if send_response[0] != OK:
		return send_response[0]
	var sent_size = send_response[1]

	while sent_size < data.size():
		await _tick_signal
		data = data.slice(sent_size)
		send_response = _connection.put_partial_data(data)
		if send_response[0] != OK:
			Log.error("[rabbitmq] error sending: " + str(send_response[0]))
			return send_response[0]
		sent_size = send_response[1]
	return OK

# Open a new RMQ Channel.
# The coroutine waits for the channel opening to be confirmed.
func channel() -> RMQChannel:
	if _active_channels.size() < _channel_max:
		var channel_num = _next_channel_num
		_next_channel_num += 1
		await _send(RMQChannelClass.Open.new().to_frame(channel_num).to_wire())

		var channel = RMQChannel.new(_send, _tick_signal, channel_num, _frame_max)
		_active_channels[channel_num] = channel
		channel.closed.connect(func(): _active_channels.erase(channel_num))

		await channel._wait_open()
		return channel
	else:
		Log.error("[rabbitmq] too many channels! maximum channel count supported by the broker is %d" % _channel_max)
		return null

# immediately responds to a heartbeat frame
func _heartbeat() -> void:
	var error = await _send(RMQFrame.new(RMQFrame.FrameType.HEARTBEAT, 0, PackedByteArray()).to_wire())
	if error != OK:
		Log.error("[rabbitmq] error sending heartbeat: " + str(error))

# close connection gracefully from our end.
# internal function for sending a close confirmation to upstream.
# disconnects the tcp peer and closes all active channels.
func close(reason:String = "") -> Error:
	if _connection:
		for channel in _active_channels.values():
			await channel.close()

		var close_error := await _send(RMQConnectionClass.Close.new(200,"",0,0).to_frame().to_wire())
		if close_error != OK:
			Log.warn("[rabbitmq] Closing error, closing rmq connection: " + str(close_error))
			_close_connection(reason)
			return close_error
		var connection_closeok_frame_parse_result := await RMQFrame.forward(
			PackedByteArray(),
			_on_inbound_data,
			func(err): Log.error("[rabbitmq] error reading closeok frame: " + str(err))
		)
		await RMQConnectionClass.CloseOk.from_frame(connection_closeok_frame_parse_result.data)
	_close_connection(reason)
	return OK

# internal function when the connection is closed from the remote end.
# confirms connection closing.
# disconnects the tcp peer and closes all active channels.
func _close_ok(reason:String = "") -> Error:
	var close_error = await _send(RMQConnectionClass.CloseOk.new().to_frame().to_wire())
	for channel in _active_channels.values():
		channel._set_closed()
	if close_error != OK:
		Log.warn("[rabbitmq] Closing error, closing rmq connection:" + str(close_error))
		_close_connection(reason)
		return close_error
	_close_connection(reason)
	return OK

func _close_connection(reason:String) -> void:
	if _connection is StreamPeerTCP:
		_connection.disconnect_from_host()
	elif _connection is StreamPeerTLS:
		_connection.disconnect_from_stream()
	Log.debug("[rabbitmq] Closed gracefully")
	sClientDisconnected.emit(reason)
	return
