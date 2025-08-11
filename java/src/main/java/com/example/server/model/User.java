package com.example.server.model;

import com.example.server.dao.record.UserRecord;
import com.example.server.endpoint.dto.request.user.UserCreateRequestDto;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.UUID;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@Data
public class User {

    String id;
    String username;
    String cipher;
    String email;
    boolean active;
    long createdAt;
    long modifiedAt;

    String messageUsername;
    String messageCipher;
    String clientPublishingToQueue;
    String clientPublishingToQueueRk;
    String clientConsumingFromQueue;
    String clientConsumingFromQueueRk;

    public User(UserCreateRequestDto userCreateRequestDto) {
        this.id = UUID.randomUUID().toString();
        this.username = userCreateRequestDto.getUsername();
        this.email = userCreateRequestDto.getEmail();
        this.cipher = userCreateRequestDto.getCipher();
        this.active = true;
        this.createdAt = LocalDateTime.now().toEpochSecond(ZoneOffset.UTC);
        this.modifiedAt = LocalDateTime.now().toEpochSecond(ZoneOffset.UTC);
        this.messageUsername = "";
        this.messageCipher = "";
        this.clientPublishingToQueue = "";
        this.clientPublishingToQueueRk = "";
        this.clientConsumingFromQueue = "";
        this.clientConsumingFromQueueRk = "";
    }

    public User(UserRecord user) {
        this.id = user.id();
        this.username = user.username();
        this.email = user.email();
        this.cipher = user.cipher();
        this.active = user.active();
        this.createdAt = user.created_at();
        this.modifiedAt = user.modified_at();
        this.messageUsername = user.message_username();
        this.messageCipher = user.message_cipher();
        this.clientPublishingToQueue = user.client_publishing_to_queue();
        this.clientPublishingToQueueRk = user.client_publishing_to_queue_rk();
        this.clientConsumingFromQueue = user.client_consuming_from_queue();
        this.clientConsumingFromQueueRk = user.client_consuming_from_queue_rk();
    }

}
