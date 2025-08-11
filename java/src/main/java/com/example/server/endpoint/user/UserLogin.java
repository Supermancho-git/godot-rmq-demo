package com.example.server.endpoint.user;

import com.example.server.endpoint.BaseEndpoint;
import com.example.server.endpoint.dto.request.user.UserLoginRequestDto;
import com.example.server.endpoint.dto.response.BadRequestResponseDto;
import com.example.server.endpoint.dto.response.user.UserLoginResponseDto;
import com.example.server.service.user.UserService;
import java.util.ArrayList;
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
@RestController("UserLogin")
@RequestMapping("server/api/v1")
public class UserLogin extends BaseEndpoint {

    @Autowired
    UserService userService;

    @RequestMapping(
        value = "/user/login",
        method = RequestMethod.POST,
        produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<Object> userLogin(
        @RequestBody UserLoginRequestDto userLoginRequestDto
    ) {
        log.info("request: {}", gson.toJson(userLoginRequestDto));
        // validate data
        ArrayList<String> violationMessages = userService.getValidation().validateLoginUser(userLoginRequestDto);
        if (!violationMessages.isEmpty()) {
            log.warn("invalidation response: {}", violationMessages);
            return new ResponseEntity<>(
                gson.toJson(new BadRequestResponseDto(violationMessages)),
                HttpStatus.BAD_REQUEST
            );
        }

        // call service
        UserLoginResponseDto userLoginResponseDto = userService.loginUser(userLoginRequestDto);

        // return response
        if (userLoginResponseDto == null) {
            log.warn("endpoint response empty");
            return new ResponseEntity<>(
                null,
                HttpStatus.UNAUTHORIZED
            );
        }
        log.info("endpoint response: {}", gson.toJson(userLoginResponseDto));
        return new ResponseEntity<>(
            gson.toJson(userLoginResponseDto),
            HttpStatus.OK
        );
    }

}
