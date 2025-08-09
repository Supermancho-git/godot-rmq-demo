class_name RMQValidatedConfig

const _requiredFields:Array[String] = ["vhost", "username", "cipher", "publishingToExchange", "publishingToQueueRk", "consumingFromQueue", "host", "port", "connectTimeoutSec", "pingJson", "pongJson"]
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
var pingJson:Dictionary
var pongJson:Dictionary

var valid:bool = false
#-----
func _init(config:Dictionary) -> void:
	Util.assertRequiredFields(config, _className, _requiredFields)
	for field in config:
		self[field] = config[field]
	if connectTimeoutSec < 1 or port < 1:
		return
	valid = true
	return
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
		"pingJson": pingJson,
		"pongJson": pongJson,
	}
#-----
