package com.example.server.service.datahub.consumer;

import com.example.server.service.BaseService;
import com.example.server.service.datahub.RabbitPublisherService;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class HeartbeatPingHandler extends BaseService implements IConsumerHandler {

    @Autowired
    RabbitPublisherService rabbitPublisherService;

    public void handle(JSONObject _jsonObj, String clientConsumingFromQueueRk) {
        rabbitPublisherService.sendPong(clientConsumingFromQueueRk);
    }

}
