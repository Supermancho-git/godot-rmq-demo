package com.example.server;

import lombok.extern.log4j.Log4j2;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

@Log4j2
@SpringBootApplication(scanBasePackages = {"com.example.server", "org.springframework.amqp.rabbit.listener"})
public class Application extends SpringBootServletInitializer {

    public static void main(String[] args) {
        log.info("Application started");
        new SpringApplicationBuilder(Application.class)
            .run(args);
    }

}
