package com.example.server.service.datahub;

import static com.example.server.helper.Constants.MSG_HEARTBEAT_PING;
import static com.example.server.helper.Constants.MTYPE;
import static com.example.server.helper.Constants.RECEIVED_FROM_CLIENT;

import com.example.server.dao.DbDao;
import com.example.server.dao.record.UserRecord;
import com.example.server.service.BaseService;
import com.example.server.service.datahub.consumer.HeartbeatPingHandler;
import com.google.gson.Gson;
import java.util.Optional;
import lombok.extern.log4j.Log4j2;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.json.JSONObject;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.rabbit.listener.AbstractMessageListenerContainer;
import org.springframework.amqp.rabbit.listener.RabbitListenerEndpointRegistry;
import org.springframework.amqp.support.AmqpHeaders;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Service;

@Log4j2
@Service
public class AmqConsumerService extends BaseService {

    @Autowired
    DbDao dbDao;

    @SuppressWarnings("SpringJavaInjectionPointsAutowiringInspection")
    @Autowired
    RabbitListenerEndpointRegistry registry;

    @Autowired
    HeartbeatPingHandler heartbeatPingHandler;

    // Dynamic queue names
    @RabbitListener(id = RECEIVED_FROM_CLIENT, autoStartup = "true")
    public void consumeUserMessage(String message, @Header(AmqpHeaders.CONSUMER_QUEUE) String queue) {
        log.info("Heard message: " + message + " from queue: " + queue);
        JSONObject jsonObject = new JSONObject(message);
        if (!jsonObject.has(MTYPE)) {
            log.error("consumeUserMessage, no mtype found: " + jsonObject);
            return;
        }
        String userId = parseUserIdFromPublishingToQueue(queue);
        if (userId == null) {
            return;
        }

        UserRecord userData = getUserData(userId);
        if (userData == null) {
            log.error(String.format("Received message from a user that was not found. UserId: %s", userId));
            return;
        }

        String clientConsumingFromQueueRk = userData.client_consuming_from_queue_rk();

        String mtype = jsonObject.getString(MTYPE);
        log.info("AMQ Consumer Heard Mtype: " + mtype + " from " + queue, message);
        switch (mtype) {
            case MSG_HEARTBEAT_PING:
                heartbeatPingHandler.handle(jsonObject, clientConsumingFromQueueRk);
                break;
            default:
                log.error("Could not handle mtype: " + mtype + " from " + queue, message);
                break;
        }
    }

    public void addUserQueueToListener(String listenerId, String queueName) {
        if (queueName.isEmpty() || listenerId.isEmpty()) {
            log.info("invalid params rejected for adding user queue");
            return;
        }

        log.info("adding queue : " + queueName + " to listener : " + listenerId);
        if (!checkQueueExistOnListener(listenerId, queueName)) {
            getMessageListenerContainerById(listenerId).addQueueNames(queueName);
            log.info("queue " + queueName + " added to listener : " + listenerId);
        } else {
            log.info("queue : " + queueName + " not added; already exists on listener : " + listenerId);
        }
    }

    public void removeUserQueueFromListener(String listenerId, String queueName) {
        if (queueName.isEmpty() || listenerId.isEmpty()) {
            log.info("invalid params rejected for adding user queue");
            return;
        }
        log.info("removing queue : " + queueName + " from listener : " + listenerId);
        if (checkQueueExistOnListener(listenerId, queueName)) {
            getMessageListenerContainerById(listenerId).removeQueueNames(queueName);
            log.info("queue " + queueName + " removed from listener : " + listenerId);
        } else {
            log.info("given queue name : " + queueName + " not removed; does not exist on listener : " + listenerId);
        }
    }

    Boolean checkQueueExistOnListener(String listenerId, String queueName) {
        try {
            log.info("checking if queueName : " + queueName + " exists on listener id : " + listenerId);

            AbstractMessageListenerContainer container = getMessageListenerContainerById(listenerId);
            String[] queueNames;

            if (container != null) {
                queueNames = container.getQueueNames();
            } else {
                log.info("Listener id : " + listenerId + " does not exist");
                return Boolean.FALSE;
            }

            if (queueNames.length == 0) {
                log.info("There are no existing queues on Listener (yet) : " + listenerId);
                return Boolean.FALSE;
            } else {
                log.info("queueNames are: " + new Gson().toJson(queueNames));
                log.info("checking " + queueName + " exist on active queues");
                for (String name : queueNames) {
                    log.info("checking if name : " + name + " is " + queueName);
                    if (name.equals(queueName)) {
                        log.info("queue name exists on listener");
                        return Boolean.TRUE;
                    }
                }
                log.info("queue name does not exist on listener");
            }
        } catch (Exception e) {
            log.error("Error on checking queue exist on listener");
            log.error("error message : " + ExceptionUtils.getMessage(e));
            log.error("trace : " + ExceptionUtils.getStackTrace(e));
        }
        return Boolean.FALSE;
    }

    AbstractMessageListenerContainer getMessageListenerContainerById(String listenerId) {
        log.info("getting message listener container by id : " + listenerId);
        return ((AbstractMessageListenerContainer) registry.getListenerContainer(listenerId));
    }

    String parseUserIdFromPublishingToQueue(String publishingToQueue) {
        String[] underscoreParts = publishingToQueue.split("_");
        String[] dotParts = underscoreParts[0].split("\\.");
        if (dotParts.length < 1) {
            log.error("Could not parse userId from publishingToQueue: {}", publishingToQueue);
            return null;
        }
        return dotParts[dotParts.length - 1];
    }

    UserRecord getUserData(String userId) {
        Optional<UserRecord> dbValue = dbDao.getUserById(userId);
        return dbValue.orElse(null);
    }

}
