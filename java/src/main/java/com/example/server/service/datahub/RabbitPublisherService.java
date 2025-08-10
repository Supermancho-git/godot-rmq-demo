package com.example.server.service.datahub;

import com.example.server.client.rabbit.publish.HeartbeatPong;
import com.example.server.service.BaseService;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Log4j2
@Service
public class RabbitPublisherService extends BaseService {

    @Autowired
    AmqProducerService amqProducerService;

    public void sendPong(String clientConsumingFromQueueRk) {
        HeartbeatPong event = new HeartbeatPong();
        amqProducerService.sendEvent(clientConsumingFromQueueRk, event.toMessage());
        log.info("sent pong to queueRk {}", clientConsumingFromQueueRk);
    }

}
