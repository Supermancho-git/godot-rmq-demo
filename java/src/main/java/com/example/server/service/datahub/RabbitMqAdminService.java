package com.example.server.service.datahub;

import com.fasterxml.jackson.databind.JsonNode;
import com.example.server.client.http.RabbitMqAdminRestClient;
import com.example.server.service.BaseService;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Log4j2
@Service
public class RabbitMqAdminService extends BaseService {

    @Value("${rabbitmq.management.user.create}")
    String rabbitMqCreateUserEndpoint;

    @Value("${rabbitmq.management.vhost.permissions}")
    String rabbitMqVhostPermissionsEndpoint;

    @Value("${rabbitmq.management.vhost.topic.permissions}")
    String rabbitMqVhostTopicPermissionsEndpoint;

    @Value("${rabbitmq.management.queue.create}")
    String rabbitMqCreateQueueEndpoint;

    @Value("${rabbitmq.management.binding.create}")
    String rabbitMqCreateBindingEndpoint;

    @Value("${rabbitmq.exchange.external}")
    String externalExchange;

    // Patterns

    @Value("${rabbitmq.management.public.pattern}")
    String rabbitMqPublicPattern;

    @Autowired
    RabbitMqAdminRestClient rabbitMqAdminRestClient;

    @SuppressWarnings("UnusedReturnValue")
    public JsonNode createRabbitMqUser(String messageUsername, String messageCipher) {
        log.info("Creating rabbit mq messageUsername: " + messageUsername + ", messageCipher: " + messageCipher);
        return rabbitMqAdminRestClient.put(
            rabbitMqCreateUserEndpoint + messageUsername,
            "{\"password\": \"" + messageCipher + "\", \"tags\": \"\"}"
        );
    }

    @SuppressWarnings("UnusedReturnValue")
    public JsonNode createRabbitMqQueue(String queueName) {
        return rabbitMqAdminRestClient.put(
            rabbitMqCreateQueueEndpoint + queueName,
            "{\"durable\": true, \"auto_delete\": false, \"arguments\": {\"x-queue-type\": \"classic\"}}"
        );
    }

    @SuppressWarnings("UnusedReturnValue")
    public JsonNode createRabbitMqBinding(String exchange, String queue, String routingKey) {
        return rabbitMqAdminRestClient.post(
            rabbitMqCreateBindingEndpoint + "e/" + exchange + "/q/" + queue,
            "{\"routing_key\":\"" + routingKey + "\", \"arguments\":{\"x-arg\": \"value\"}}"
        );
    }

    @SuppressWarnings("UnusedReturnValue")
    public JsonNode setDefaultPermissionsRabbitMqUser(String messageUsername, String userReceiverQueueName) {
        return rabbitMqAdminRestClient.put(
            rabbitMqVhostPermissionsEndpoint + messageUsername,
            "{" +
                "\"configure\":\"\"," +
                "\"write\":\"" + rabbitMqPublicPattern + "\"," +
                "\"read\":\"^" + userReceiverQueueName + "$\"" +
                "}"
        );
    }

    @SuppressWarnings("UnusedReturnValue")
    public JsonNode setTopicPermissionsRabbitMqUser(String messageUsername, String userPublishingQueueRk) {
        return rabbitMqAdminRestClient.put(
            rabbitMqVhostTopicPermissionsEndpoint + messageUsername,
            "{" +
                "\"exchange\":\"^" + externalExchange + "$\"," +
                "\"write\":\"^" + userPublishingQueueRk + "$\"," +
                "\"read\":\"\"" +
                "}"
        );
    }

}
