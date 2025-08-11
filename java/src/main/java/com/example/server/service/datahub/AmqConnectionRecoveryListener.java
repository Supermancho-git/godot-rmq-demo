package com.example.server.service.datahub;

import static com.example.server.helper.Constants.RECEIVED_FROM_CLIENT;

import com.example.server.dao.DbDao;
import com.example.server.dao.record.UserRecord;
import java.nio.charset.StandardCharsets;
import java.util.List;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.connection.ConnectionListener;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.stereotype.Component;

@Log4j2
@Component
public class AmqConnectionRecoveryListener implements ConnectionListener, ApplicationListener<ContextRefreshedEvent> {

    @Autowired
    DbDao dbDao;

    @Autowired
    AmqConsumerService amqConsumerService;

    @Autowired
    ConnectionFactory connectionFactory;

    @Autowired
    RabbitTemplate internalExchangeRabbitTemplate;

    @PostConstruct
    void registerConnectionListener() {
        try {
            connectionFactory.addConnectionListener(this);
            log.info("Registered ConnectionListener with RabbitMQ ConnectionFactory");
        } catch (Exception e) {
            log.warn("Unable to register ConnectionListener: {}", e.getMessage());
        }
    }

    @Override
    public void onCreate(org.springframework.amqp.rabbit.connection.Connection connection) {
        rebuildDynamicQueues();
    }

    @Override
    public void onClose(org.springframework.amqp.rabbit.connection.Connection connection) {

    }

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        rebuildDynamicQueues();
    }

    private void rebuildDynamicQueues() {
        try {
            log.info("Rebuilding dynamic listener queues after connection/context event");

            List<UserRecord> users = dbDao.getAllActiveUsers();
            if (users == null || users.isEmpty()) {
                log.info("No active users found to re-register queues for");
                return;
            }

            users.forEach(user -> {
                String queue = user.client_publishing_to_queue();
                if (queue != null && !queue.isBlank()) {
                    try {
                        amqConsumerService.addUserQueueToListener(RECEIVED_FROM_CLIENT, queue);
                    } catch (Exception e) {
                        log.warn("Failed to add queue '{}' to listener '{}': {}", queue, RECEIVED_FROM_CLIENT, e.getMessage());
                    }
                }
            });
        } catch (Exception e) {
            log.error("Error during dynamic queue rebuild: {}", e.getMessage(), e);
        }
    }
}
