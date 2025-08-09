class_name RMQEnd2EndSettings

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
