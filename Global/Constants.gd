extends Node

const MSG_HEARTBEAT_PING:Dictionary = {
	"mtype": "ping"
}
const MSG_HEARTBEAT_PONG:String = "pong"

const MSG_DISCONNECTED:String = "disconnected"

const RMQ_VHOST:String = "ccc_vhost"
const RMQ_PUBLISHING_TO_EXCHANGE:String = "ccc.external.topic"
const RMQ_HOST:String = "localhost"
const RMQ_PORT:int = 5672
