package com.example.server.client.rabbit.publish.message;

import org.springframework.amqp.core.Message;

public class RMQMessage extends Message {

    public RMQMessage(String message) {
        super((message).getBytes());
    }

}
