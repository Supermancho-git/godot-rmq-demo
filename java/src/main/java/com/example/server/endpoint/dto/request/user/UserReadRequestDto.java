package com.example.server.endpoint.dto.request.user;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class UserReadRequestDto {
    @NotBlank
    String id;
}
