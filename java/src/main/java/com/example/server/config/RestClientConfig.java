package com.example.server.config;

import com.example.server.client.http.RabbitMqAdminRestClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class RestClientConfig {

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @Bean
    public RabbitMqAdminRestClient rabbitMqAdminRestClient() {
        return new RabbitMqAdminRestClient(new RestTemplate());
    }

}
