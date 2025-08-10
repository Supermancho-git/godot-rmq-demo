package com.example.server.endpoint.user;

import com.example.server.endpoint.dto.request.user.UserUpdateRequestDto;
import com.example.server.endpoint.BaseEndpoint;
import com.example.server.endpoint.dto.response.BadRequestResponseDto;
import com.example.server.helper.ValidationVariant;
import com.example.server.model.User;
import com.example.server.service.user.UserService;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@Log4j2
@ControllerAdvice("")
@RestController("UserUpdate")
@RequestMapping("server/api/v1")
public class UserUpdate extends BaseEndpoint {

    @Autowired
    UserService userService;

    @RequestMapping(
        value = "/user/update",
        method = RequestMethod.POST,
        produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<Object> userUpdate(
        @RequestBody UserUpdateRequestDto userUpdateRequestDto
    ) {
        log.info("request: {}", gson.toJson(userUpdateRequestDto));
        // validate
        ValidationVariant variant = userService.getValidation().validateUpdateUser(userUpdateRequestDto);
        if (!variant.getViolationMessages().isEmpty()) {
            log.warn("invalidation response: {}", variant.getViolationMessages());
            return new ResponseEntity<>(
                gson.toJson(new BadRequestResponseDto(variant.getViolationMessages())),
                HttpStatus.BAD_REQUEST
            );
        }

        // call service
        User user = userService.updateUser(userUpdateRequestDto);

        // return response
        log.info("response: {}", user);
        return new ResponseEntity<>(
            gson.toJson(user),
            HttpStatus.OK
        );
    }
}
