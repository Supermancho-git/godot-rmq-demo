package com.example.server.endpoint.dto.request.user;

import java.util.Optional;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class UserUpdateRequestDto {

    @NotNull
    String id;

    @JsonProperty("username")
    @Size(min = 5, max = 50, message = "requires username to be 5-50 characters")
    String username;

    @JsonProperty("email")
    @Email(message = "requires valid email")
    String email;

    @JsonIgnore
    public Optional<String> getUsername() {
        return Optional.of(username);
    }

    @JsonIgnore
    public Optional<String> getEmail() {
        return Optional.ofNullable(email);
    }

}
