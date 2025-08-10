package com.example.server.endpoint.dto.request.user;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class UserLoginRequestDto {
    @Size(min = 5, max = 50, message = "requires username to be 5-50 characters")
    @Pattern(regexp = "^[A-Za-z0-9_\\-=|]*$")
    String username;

    @Size(min = 5, max = 20, message = "requires password to be 5-20 characters")
    @Pattern(regexp = "^[A-Za-z0-9!@#$%^&*()_+\\-=\\[\\]{};':\"|,.<>/?]*$")
    String cipher;
}
