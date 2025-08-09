extends Node

const MSG_HEARTBEAT_PING:Dictionary = {
	"mtype": "ping"
}
const MSG_HEARTBEAT_PONG:Dictionary = {
	"mtype": "pong"
}

const MSG_DISCONNECTED:String = "disconnected"

const RMQ_VHOST:String = "my_vhost"
const RMQ_PUBLISHING_TO_EXCHANGE:String = "my.external.topic"
const RMQ_HOST:String = "localhost"
const RMQ_PORT:int = 5672
