class_name RMQClientConfig

const _requiredFields:Array[String] = ["vhost", "username", "cipher", "publishingToExchange", "publishingToQueueRk", "consumingFromQueue", "host", "port", "connectTimeoutSec"]
const _className:String = "RMQConfig"

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

var valid:bool = false
#-----
func _init(config:Dictionary) -> void:
	Util.assertRequiredFields(config, _className, _requiredFields)
	for field in config:
		self[field] = config[field]

	useConfirmEnd2End = (config.has("confirmEnd2End") and confirmEnd2End != null)

	if not validation(config):
		Log.warn("failed validation")
		return

	valid = true
	return
#-----
func validation(config:Dictionary) -> bool:
	if connectTimeoutSec < 1 or port < 1:
		return false
	return true
#-----
func getConfigured() -> Dictionary:
	return {
		"username": username,
		"cipher": cipher,
		"vhost": vhost,
		"consumingFromQueue": consumingFromQueue,
		"publishingToExchange": publishingToExchange,
		"publishingToQueueRk": publishingToQueueRk,
		"host": host,
		"port": port,
		"connectTimeoutSec": connectTimeoutSec,
		"confirmEnd2End": confirmEnd2End,
		"useConfirmEnd2End": useConfirmEnd2End,
	}
#-----
#=====
class RMQEnd2EndSettings:

	const _requiredFields:Array[String] = ["timeoutSec", "pingJson", "pongJson"]
	const _className:String = "RMQEnd2EndSettings"

	var timeoutSec:int
	var pingJson:Dictionary
	var pongJson:Dictionary

	var valid:bool = false
	#-----
	func _init(config:Dictionary) -> void:
		Util.assertRequiredFields(config, _className, _requiredFields)
		for field in config:
			self[field] = config[field]

		if not validation(config):
			Log.warn("failed validation")
			return

		valid = true
		return
	#-----
	func validation(config) -> bool:
		if JSON.parse_string(JSON.stringify(config["pingJson"])) == null:
			return false
		if JSON.parse_string(JSON.stringify(config["pongJson"])) == null:
			return false
		if config["timeoutSec"] < 1:
			return false
		return true
	#-----
