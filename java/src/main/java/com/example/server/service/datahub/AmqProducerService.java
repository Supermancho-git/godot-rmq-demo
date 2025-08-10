package com.example.server.service.datahub;

import com.example.server.client.rabbit.publish.message.RMQMessage;
import com.example.server.service.BaseService;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AmqProducerService extends BaseService {

    @Autowired
    RabbitTemplate internalExchangeRabbitTemplate;

    public void sendEvent(String rk, RMQMessage message) {
        // send to exchange with player rk
        internalExchangeRabbitTemplate.send(rk, message);
    }

}
