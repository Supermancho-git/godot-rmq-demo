package com.example.server.endpoint.dto.response.user;

import lombok.Data;

@Data
public class UserLoginResponseDto {
    String id;
    String username;
    String messageUsername;
    String messageCipher;
    String publishingToQueueRk;
    String consumingFromQueue;
}
