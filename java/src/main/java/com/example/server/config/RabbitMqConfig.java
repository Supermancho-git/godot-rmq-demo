package com.example.server.config;

import com.example.server.service.datahub.RabbitMqAdminService;
import com.example.server.service.datahub.RabbitPublisherService;
import jakarta.validation.constraints.NotNull;
import org.springframework.amqp.rabbit.connection.CachingConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMqConfig {

    @Value("${rabbitmq.host}")
    String rabbitMqHost;

    @Value("${rabbitmq.port}")
    String rabbitMqPort;

    @Value("${rabbitmq.virtualhost}")
    String rabbitMqVirtualhost;

    @Value("${rabbitmq.admin.username}")
    String rabbitMqUsername;

    @Value("${rabbitmq.admin.password}")
    String rabbitMqPassword;

    @Value("${rabbitmq.exchange.external}")
    String rabbitMqExternalExchange;

    @Value("${rabbitmq.exchange.internal}")
    String rabbitMqInternalExchange;

    @Bean
    public CachingConnectionFactory cachingConnectionFactory() {
        CachingConnectionFactory connectionFactory = new CachingConnectionFactory();
        connectionFactory.setHost(rabbitMqHost);
        connectionFactory.setPort(Integer.parseInt(rabbitMqPort));
        connectionFactory.setVirtualHost(rabbitMqVirtualhost);
        connectionFactory.setUsername(rabbitMqUsername);
        connectionFactory.setPassword(rabbitMqPassword);
        return connectionFactory;
    }

    @Bean
    public RabbitTemplate externalExchangeRabbitTemplate(@NotNull CachingConnectionFactory cachingConnectionFactory) {
        RabbitTemplate rabbitTemplate = new RabbitTemplate(cachingConnectionFactory);
        rabbitTemplate.setExchange(rabbitMqExternalExchange);
        return rabbitTemplate;
    }

    @Bean
    public RabbitTemplate internalExchangeRabbitTemplate(@NotNull CachingConnectionFactory cachingConnectionFactory) {
        RabbitTemplate rabbitTemplate = new RabbitTemplate(cachingConnectionFactory);
        rabbitTemplate.setExchange(rabbitMqInternalExchange);
        return rabbitTemplate;
    }

    @Bean
    public RabbitPublisherService getRabbitPublisherService() {
        return new RabbitPublisherService();
    }

    @Bean
    public RabbitMqAdminService getRabbitMqAdminService() {
        return new RabbitMqAdminService();
    }

}
