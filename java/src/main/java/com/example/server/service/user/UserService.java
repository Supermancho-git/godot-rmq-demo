package com.example.server.service.user;

import static com.example.server.helper.Constants.RECEIVED_FROM_CLIENT;

import com.example.server.dao.DbDao;
import com.example.server.dao.record.UserRecord;
import com.example.server.endpoint.dto.request.user.UserCreateRequestDto;
import com.example.server.endpoint.dto.request.user.UserLoginRequestDto;
import com.example.server.endpoint.dto.response.user.UserLoginResponseDto;
import com.example.server.model.User;
import com.example.server.service.BaseService;
import com.example.server.service.datahub.AmqConsumerService;
import com.example.server.service.datahub.RabbitMqAdminService;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Getter
@Service
public class UserService extends BaseService {

    @Autowired
    DbDao dbDao;

    @Autowired
    UserValidationService validation;

    @Autowired
    RabbitMqAdminService rabbitMqAdminService;

    @Autowired
    SecureRandom random;

    @Autowired
    AmqConsumerService amqConsumerService;

    @Value("${rabbitmq.exchange.external}")
    String externalExchange;

    @Value("${rabbitmq.exchange.internal}")
    String internalExchange;

    @Value("${rabbitmq.queue.user.publish.name.pattern}")
    String userPublishingQueueNamePattern;

    @Value("${rabbitmq.queue.user.publish.rk.pattern}")
    String userPublishingQueueRkPattern;

    @Value("${rabbitmq.queue.user.receive.name.pattern}")
    String userReceivingQueueNamePattern;

    @Value("${rabbitmq.queue.user.receive.rk.pattern}")
    String userReceivingQueueRkPattern;

    public User createUser(UserCreateRequestDto userCreateRequestDto) {
        User partialUserObj = new User(userCreateRequestDto);

        // add to postgres with defaults
        User dbUser = createDatabaseRecord(partialUserObj);

        // add user to rabbitmq
        rabbitMqAdminService.createRabbitMqUser(dbUser.getMessageUsername(), dbUser.getMessageCipher());
        String queueSalt = random.nextLong() + "";

        // create dedicated rabbitmq queue for client publishing to server
        String userPublishingQueueName = String.format(userPublishingQueueNamePattern, dbUser.getId(), queueSalt);
        rabbitMqAdminService.createRabbitMqQueue(userPublishingQueueName);
        dbUser.setClientPublishingToQueue(userPublishingQueueName);

        // create rabbitmq binding for client publishing to server
        String userPublishingQueueRk = String.format(userPublishingQueueRkPattern, dbUser.getId(), queueSalt);
        rabbitMqAdminService.createRabbitMqBinding(externalExchange, userPublishingQueueName, userPublishingQueueRk);
        dbUser.setClientPublishingToQueueRk(userPublishingQueueRk);

        // Topic permissions to limit users from publishing to random my.external.topic RKs
        rabbitMqAdminService.setTopicPermissionsRabbitMqUser(dbUser.getMessageUsername(), userPublishingQueueRk);

        // create dedicated rabbitmq queue for client to consume from
        String userReceivingQueueName = String.format(userReceivingQueueNamePattern, dbUser.getId(), queueSalt);
        rabbitMqAdminService.createRabbitMqQueue(userReceivingQueueName);
        dbUser.setClientConsumingFromQueue(userReceivingQueueName);

        // create rabbitmq binding for user receiving? This is for the server to publish to the queue from internal exchange
        String userReceivingQueueRk = String.format(userReceivingQueueRkPattern, dbUser.getId(), queueSalt);
        rabbitMqAdminService.createRabbitMqBinding(internalExchange, userReceivingQueueName, userReceivingQueueRk);
        dbUser.setClientConsumingFromQueueRk(userReceivingQueueRk);

        // set perms
        rabbitMqAdminService.setDefaultPermissionsRabbitMqUser(dbUser.getMessageUsername(), userReceivingQueueName);

        User updatedQueueDbUser = updateUser(dbUser);

        // add queue that the client publishes at, into dynamic listener collection
        amqConsumerService.addUserQueueToListener(RECEIVED_FROM_CLIENT, updatedQueueDbUser.getClientPublishingToQueue());

        return updatedQueueDbUser;
    }

    public int deleteUser(User user) {
        amqConsumerService.removeUserQueueFromListener(RECEIVED_FROM_CLIENT, user.getClientPublishingToQueue());
        return dbDao.deleteUser(user.getId());
    }

    public User updateUser(User user) {
        UserRecord updatedUserRecord = new UserRecord(
            user.getId(),
            user.getUsername(),
            user.getCipher(),
            user.getEmail(),
            user.getCreatedAt(),
            LocalDateTime.now().toEpochSecond(ZoneOffset.UTC),
            user.isActive(),
            user.getMessageUsername(),
            user.getMessageCipher(),
            user.getClientPublishingToQueue(),
            user.getClientPublishingToQueueRk(),
            user.getClientConsumingFromQueue(),
            user.getClientConsumingFromQueueRk()
        );
        dbDao.updateUserByRecord(updatedUserRecord);
        return new User(updatedUserRecord);
    }

    User createDatabaseRecord(User user) {
        // set message username and cipher, generated on server
        String messagePassword = "password";
        user.setMessageUsername("uuser_" + user.getId());
        user.setMessageCipher("upass_" + messagePassword);

        dbDao.insertUser(user);
        return user;
    }

    public UserLoginResponseDto loginUser(UserLoginRequestDto userLoginRequestDto) {
        Optional<UserRecord> maybeUserRecord = dbDao.findUserByUsernameAndPassword(
            userLoginRequestDto.getUsername(),
            userLoginRequestDto.getCipher()
        );

        if (maybeUserRecord.isEmpty()) {
            return null;
        }

        User user = new User(maybeUserRecord.get());

        // add publishing queue to server listener (in case lost from restart or inactivity)
        amqConsumerService.addUserQueueToListener(RECEIVED_FROM_CLIENT, user.getClientPublishingToQueue());

        //// Set Response
        ///
        UserLoginResponseDto loginResponse = new UserLoginResponseDto();
        loginResponse.setId(user.getId());
        loginResponse.setUsername(user.getUsername());

        loginResponse.setMessageUsername(user.getMessageUsername());
        loginResponse.setMessageCipher(user.getMessageCipher());

        loginResponse.setPublishingToQueueRk(user.getClientPublishingToQueueRk());
        loginResponse.setConsumingFromQueue(user.getClientConsumingFromQueue());

        return loginResponse;
    }

}
