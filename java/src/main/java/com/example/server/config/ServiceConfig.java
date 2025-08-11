package com.example.server.config;

import com.example.server.service.user.UserService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ServiceConfig {

    @Bean
    UserService userService() {
        return new UserService();
    }

}
