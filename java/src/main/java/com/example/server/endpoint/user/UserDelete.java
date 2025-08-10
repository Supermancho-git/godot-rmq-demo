package com.example.server.endpoint.user;

import com.example.server.endpoint.BaseEndpoint;
import com.example.server.endpoint.dto.request.user.UserDeleteRequestDto;
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
@RestController("UserDelete")
@RequestMapping("server/api/v1")
public class UserDelete extends BaseEndpoint {

    @Autowired
    UserService userService;

    @RequestMapping(
        value = "/user/delete",
        method = RequestMethod.POST,
        produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<Object> userDelete(
        @RequestBody UserDeleteRequestDto userDeleteRequestDto
    ) {
        log.info("request: {}", gson.toJson(userDeleteRequestDto));
        // validate data
        ValidationVariant variant = userService.getValidation().validateDeleteUser(userDeleteRequestDto);
        if (!variant.getViolationMessages().isEmpty()) {
            log.warn("invalidation response: {}", variant.getViolationMessages());
            return new ResponseEntity<>(
                gson.toJson(new BadRequestResponseDto(variant.getViolationMessages())),
                HttpStatus.BAD_REQUEST
            );
        }

        // call service
        int success = userService.deleteUser(variant.getUser());

        // return response
        if (success == 0) {
            log.warn("endpoint response empty");
            return new ResponseEntity<>(
                null,
                HttpStatus.NOT_FOUND
            );
        }
        log.info("endpoint response: {}", success);
        return new ResponseEntity<>(
            success,
            HttpStatus.OK
        );
    }

}
