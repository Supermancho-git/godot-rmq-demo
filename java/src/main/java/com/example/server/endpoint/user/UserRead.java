package com.example.server.endpoint.user;

import com.example.server.endpoint.dto.request.user.UserReadRequestDto;
import com.example.server.endpoint.BaseEndpoint;
import com.example.server.endpoint.dto.response.BadRequestResponseDto;
import com.example.server.helper.ValidationVariant;
import com.example.server.service.user.UserService;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@Log4j2
@RestController("UserRead")
@RequestMapping("server/api/v1")
public class UserRead extends BaseEndpoint {

    @Autowired
    UserService userService;

    @RequestMapping(
        value = "/user/read",
        method = RequestMethod.POST,
        produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<Object> userRead(
        @RequestBody UserReadRequestDto userReadRequestDto
    ) {
        log.info("request: {}", gson.toJson(userReadRequestDto));
        // validate data
        ValidationVariant variant = userService.getValidation().validateReadUser(userReadRequestDto);
        if (!variant.getViolationMessages().isEmpty()) {
            log.warn("invalidation response: {}", variant.getViolationMessages());
            return new ResponseEntity<>(
                gson.toJson(new BadRequestResponseDto(variant.getViolationMessages())),
                HttpStatus.BAD_REQUEST
            );
        }

        // call service

        // return response
        log.info("response: {}", gson.toJson(variant.getUser()));
        return new ResponseEntity<>(
            gson.toJson(variant.getUser()),
            HttpStatus.OK
        );
    }

}
