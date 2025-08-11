package com.example.server.endpoint.user;

import com.example.server.endpoint.BaseEndpoint;
import com.example.server.endpoint.dto.request.user.UserCreateRequestDto;
import com.example.server.endpoint.dto.response.BadRequestResponseDto;
import com.example.server.endpoint.dto.response.user.UserCreateResponseDto;
import com.example.server.model.User;
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
@RestController("UserCreate")
@RequestMapping("server/api/v1")
public class UserCreate extends BaseEndpoint {

    @Autowired
    UserService userService;

    @RequestMapping(
        value = "/user/create",
        method = RequestMethod.POST,
        produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<Object> userCreate(
        @RequestBody UserCreateRequestDto userCreateRequestDto
    ) {
        log.info("request: {}", gson.toJson(userCreateRequestDto));
        // validate input
        ArrayList<String> violationMessages = userService.getValidation().validateCreateUser(userCreateRequestDto);
        if (!violationMessages.isEmpty()) {
            log.warn("invalidation response: {}", violationMessages);
            return new ResponseEntity<>(
                gson.toJson(new BadRequestResponseDto(violationMessages)),
                HttpStatus.BAD_REQUEST
            );
        }

        // call service
        User user = userService.createUser(userCreateRequestDto);

        // format response
        UserCreateResponseDto userCreateResponseDto = new UserCreateResponseDto();
        userCreateResponseDto.setId(user.getId());
        userCreateResponseDto.setUsername(user.getUsername());
        userCreateResponseDto.setEmail(user.getEmail());
        userCreateResponseDto.setCipher(user.getCipher());
        userCreateResponseDto.setCreatedAt(user.getCreatedAt());
        userCreateResponseDto.setModifiedAt(user.getModifiedAt());

        // return response
        log.info("endpoint response: {}", gson.toJson(userCreateResponseDto));
        return new ResponseEntity<>(
            gson.toJson(userCreateResponseDto),
            HttpStatus.OK
        );
    }

}
