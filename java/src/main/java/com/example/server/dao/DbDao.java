package com.example.server.dao;

import com.example.server.dao.record.UserRecord;
import com.example.server.model.User;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;

@Service
public class DbDao {

    @Autowired
    public JdbcClient jdbcClient;

    public Optional<UserRecord> getUserById(String id) {
        return jdbcClient.sql("SELECT " +
                "id, username, cipher, email, " +
                "created_at, modified_at, active, message_username, message_cipher, " +
                "client_publishing_to_queue, client_publishing_to_queue_rk, " +
                "client_consuming_from_queue, client_consuming_from_queue_rk " +
                "FROM example.users WHERE id = ? and active = true")
            .param(id)
            .query(UserRecord.class)
            .optional();
    }

    public Optional<String> findUserById(String id) {
        return jdbcClient.sql("SELECT id FROM example.users WHERE id = :id and active = true")
            .param("id", id)
            .query(String.class)
            .optional();
    }

    public Optional<String> findUserByUsername(String username) {
        return jdbcClient.sql("SELECT id FROM example.users WHERE username = :username")
            .param("username", username)
            .query(String.class)
            .optional();
    }

    public Optional<String> findUserByEmail(String email) {
        return jdbcClient.sql("SELECT id FROM example.users WHERE email = :email")
            .param("email", email)
            .query(String.class)
            .optional();
    }

    @SuppressWarnings("UnusedReturnValue")
    public int insertUser(User user) {
        return jdbcClient.sql("INSERT INTO example.users (" +
                "id, username, cipher, email, " +
                "created_at, modified_at, active, message_username, message_cipher, " +
                "client_publishing_to_queue, client_publishing_to_queue_rk, " +
                "client_consuming_from_queue, client_consuming_from_queue_rk " +
                ") VALUES (" +
                ":id, :username, :cipher, :email, " +
                ":createdAt, :modifiedAt, :active, :messageUsername, :messageCipher, " +
                ":clientPublishingToQueue, :clientPublishingToQueueRk, " +
                ":clientConsumingFromQueue, :clientConsumingFromQueueRk " +
                ")")
            .param("id", user.getId())
            .param("username", user.getUsername())
            .param("cipher", user.getCipher())
            .param("email", user.getEmail())
            .param("createdAt", user.getCreatedAt())
            .param("modifiedAt", user.getModifiedAt())
            .param("active", user.isActive())
            .param("messageUsername", user.getMessageUsername())
            .param("messageCipher", user.getMessageCipher())
            .param("clientPublishingToQueue", user.getClientPublishingToQueue())
            .param("clientPublishingToQueueRk", user.getClientPublishingToQueueRk())
            .param("clientConsumingFromQueue", user.getClientConsumingFromQueue())
            .param("clientConsumingFromQueueRk", user.getClientConsumingFromQueueRk())
            .update();

    }

    public int deleteUser(String id) {
        return jdbcClient.sql("DELETE FROM example.users WHERE id = :id")
            .param("id", id)
            .update();
    }

    @SuppressWarnings("UnusedReturnValue")
    public int updateUserByRecord(UserRecord record) {
        return jdbcClient.sql("UPDATE example.users SET " +
                "username = :username, " +
                "email = :email, " +
                "message_username = :messageUsername, " +
                "message_cipher = :messageCipher, " +
                "client_publishing_to_queue = :clientPublishingToQueue, " +
                "client_publishing_to_queue_rk = :clientPublishingToQueueRk, " +
                "client_consuming_from_queue = :clientConsumingFromQueue, " +
                "client_consuming_from_queue_rk = :clientConsumingFromQueueRk " +
                "WHERE id = :id")
            .param("username", record.username())
            .param("email", record.email())
            .param("messageUsername", record.message_username())
            .param("messageCipher", record.message_cipher())
            .param("clientPublishingToQueue", record.client_publishing_to_queue())
            .param("clientPublishingToQueueRk", record.client_publishing_to_queue_rk())
            .param("clientConsumingFromQueue", record.client_consuming_from_queue())
            .param("clientConsumingFromQueueRk", record.client_consuming_from_queue_rk())
            .param("id", record.id())
            .update();
    }

    public Optional<UserRecord> findUserByUsernameAndPassword(String username, String cipher) {
        return jdbcClient.sql("SELECT " +
                "id, username, cipher, email, " +
                "created_at, modified_at, active, message_username, message_cipher, " +
                "client_publishing_to_queue, client_publishing_to_queue_rk, " +
                "client_consuming_from_queue, client_consuming_from_queue_rk " +
                "FROM example.users WHERE " +
                "username = :username AND " +
                "cipher = :cipher")
            .param("username", username)
            .param("cipher", cipher)
            .query(UserRecord.class)
            .optional();
    }

}
