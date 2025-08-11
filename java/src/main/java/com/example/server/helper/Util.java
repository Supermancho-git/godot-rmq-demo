package com.example.server.helper;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.security.SecureRandom;
import lombok.extern.log4j.Log4j2;

@Log4j2
public class Util {

    public static SecureRandom random;

    public static ObjectMapper mapper;

    public static String parseUserIdFromConsumingRk(String clientConsumingRk) {
        // clientConsumingFromQueueRk = rk_user_receive_queue_<userId>_<queueSalt>
        String[] parts = clientConsumingRk.split("_");
        if (parts.length < 2) {
            return null;
        }
        return parts[parts.length - 2];
    }

}
