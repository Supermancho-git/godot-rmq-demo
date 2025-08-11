package com.example.server.client.http;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Log4j2
@Component
public class RabbitMqAdminRestClient extends RestClient {

    @Value("${rabbitmq.admin.httpauth}")
    String rabbitMqAdminHttpauth;

    @PostConstruct
    public void init() {
        setAuthorization(rabbitMqAdminHttpauth);
    }

    public RabbitMqAdminRestClient(RestTemplate restTemplate) {
        super(restTemplate);
    }

    @Override
    public <T> T handleSuccessResponse(ResponseEntity<T> responseEntity) {
        return responseEntity.getBody();
    }

    @Override
    public <T> T handleErrorResponse(ResponseEntity<T> response) {
        log.warn("Unsuccessful response: " + response.getBody());
        return null;
    }

    public JsonNode put(String uri, String body) {
        return (JsonNode) this.getResponseSync(HttpMethod.PUT, uri, null, body, null, JsonNode.class, new ObjectMapper());
    }

    public JsonNode post(String uri, String body) {
        return (JsonNode) this.getResponseSync(HttpMethod.POST, uri, null, body, null, JsonNode.class, new ObjectMapper());
    }

}
