class_name RMQValidatedConfig

const _requiredFields:Array[String] = ["rmqVhost", "rmqUsername", "rmqCipher", "rmqPublishingToExchange", "rmqPublishingToQueueRk", "rmqConsumingFromQueue", "rmqHost", "rmqPort", "rmqConnectTimeoutSec"]
const _className:String = "RMQConfig"

var rmqUsername:String
var rmqCipher:String
var rmqVhost:String
var rmqConsumingFromQueue:String
var rmqPublishingToExchange:String
var rmqPublishingToQueueRk:String
var rmqHost:String
var rmqPort:int
var rmqConnectTimeoutSec:int

var valid:bool = false
#-----
func _init(config:Dictionary) -> void:
	Util.assertRequiredFields(config, _className, _requiredFields)
	for field in config:
		self[field] = config[field]
	if rmqConnectTimeoutSec < 1 or rmqPort < 1:
		return
	valid = true
	return
#-----
