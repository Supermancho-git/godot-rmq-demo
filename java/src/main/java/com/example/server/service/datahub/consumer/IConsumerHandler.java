package com.example.server.service.datahub.consumer;

import org.json.JSONObject;

public interface IConsumerHandler {

    void handle(JSONObject json, String queue);

}
