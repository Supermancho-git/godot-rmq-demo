package com.example.server.endpoint.dto.response.user;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import lombok.Data;

@Data
@JsonSerialize
public class UserCreateResponseDto {

    String id;
    String username;
    String email;
    String cipher;

    long createdAt;
    long modifiedAt;

}
