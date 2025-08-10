package com.example.server.client.rabbit.publish;

import static com.example.server.helper.Constants.MSG_HEARTBEAT_PONG;

import com.example.server.client.rabbit.publish.message.IRMQMessageSerializer;

public class HeartbeatPong implements IRMQMessageSerializer {

    public String mtype = MSG_HEARTBEAT_PONG;

    public HeartbeatPong() {}

}
