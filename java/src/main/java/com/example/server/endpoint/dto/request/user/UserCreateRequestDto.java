package com.example.server.endpoint.dto.request.user;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class UserCreateRequestDto {
    @Size(min = 5, max = 50, message = "requires username to be 5-50 characters")
    String username;

    @Email(message = "requires valid email")
    String email;

    @Size(min = 5, max = 20, message = "requires password to be 5-20 characters")
    String cipher;
}
