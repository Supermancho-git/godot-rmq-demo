class_name RMQUtil

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
static func awaitAnySignal(signalVals:Array[Signal], timeoutVal:float, sceneTree:SceneTree, _timeoutPayload="timeout") -> Promise:
	var allPromises:Array[Promise] = []
	for signalVal in signalVals:
		allPromises.append(Promise.from(signalVal))

	var timerPromise:Promise = Promise.new(
		func(resolve: Callable, _reject: Callable):
			await sceneTree.create_timer(timeoutVal).timeout
			resolve.call(_timeoutPayload)
	)
	allPromises.append(timerPromise)
	return Promise.any(allPromises)
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
#----
