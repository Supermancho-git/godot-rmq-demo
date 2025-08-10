package com.example.server.client.rabbit.publish.message;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.example.server.helper.Util;

public interface IRMQMessageSerializer {

    default RMQMessage toMessage() {
        try {
            return new RMQMessage(Util.mapper.writeValueAsString(this));
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
    }

}
