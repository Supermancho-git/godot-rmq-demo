package com.example.server.service.user;

import com.example.server.dao.DbDao;
import com.example.server.dao.record.UserRecord;
import com.example.server.endpoint.dto.request.user.UserCreateRequestDto;
import com.example.server.endpoint.dto.request.user.UserDeleteRequestDto;
import com.example.server.endpoint.dto.request.user.UserLoginRequestDto;
import com.example.server.endpoint.dto.request.user.UserReadRequestDto;
import com.example.server.endpoint.dto.request.user.UserUpdateRequestDto;
import com.example.server.helper.ValidationVariant;
import com.example.server.model.User;
import com.example.server.service.BaseService;
import jakarta.validation.ConstraintViolation;
import java.util.ArrayList;
import java.util.Optional;
import java.util.Set;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserValidationService extends BaseService {

    @Autowired
    DbDao dbDao;

    public ArrayList<String> validateCreateUser(UserCreateRequestDto userCreateRequestDto) {
        ArrayList<String> violationMessages = new ArrayList<>();
        Set<ConstraintViolation<UserCreateRequestDto>> violations = validator.validate(userCreateRequestDto);
        if (!violations.isEmpty()) {
            for (ConstraintViolation<UserCreateRequestDto> violation : violations) {
                violationMessages.add(violation.getMessage());
            }
        }

        if (dbDao.findUserByUsername(userCreateRequestDto.getUsername()).isPresent()) {
            violationMessages.add("User already exists");
        }

        if (dbDao.findUserByEmail(userCreateRequestDto.getEmail()).isPresent()) {
            violationMessages.add("Email already exists");
        }

        return violationMessages;
    }

    public ValidationVariant validateDeleteUser(UserDeleteRequestDto userDeleteRequestDto) {
        ValidationVariant variant = new ValidationVariant();
        ArrayList<String> violationMessages = new ArrayList<>();
        Set<ConstraintViolation<UserDeleteRequestDto>> violations = validator.validate(userDeleteRequestDto);
        if (!violations.isEmpty()) {
            for (ConstraintViolation<UserDeleteRequestDto> violation : violations) {
                violationMessages.add(violation.getMessage());
            }
        }

        Optional<UserRecord> maybeUserRecord = dbDao.getUserById(userDeleteRequestDto.getId());
        if (maybeUserRecord.isEmpty()) {
            violationMessages.add("User does not exist.");
            variant.setViolationMessages(violationMessages);
            return variant;
        }

        User user = new User(maybeUserRecord.get());
        variant.setUser(user);
        variant.setViolationMessages(violationMessages);
        return variant;
    }

    public ValidationVariant validateUpdateUser(UserUpdateRequestDto userUpdateRequestDto) {
        ValidationVariant variant = new ValidationVariant();
        ArrayList<String> violationMessages = new ArrayList<>();
        Set<ConstraintViolation<UserUpdateRequestDto>> violations = validator.validate(userUpdateRequestDto);
        if (!violations.isEmpty()) {
            for (ConstraintViolation<UserUpdateRequestDto> violation : violations) {
                violationMessages.add(violation.getMessage());
            }
        }

        Optional<UserRecord> maybeUserRecord = dbDao.getUserById(userUpdateRequestDto.getId());
        if (maybeUserRecord.isEmpty()) {
            violationMessages.add("User does not exist.");
            variant.setViolationMessages(violationMessages);
            return variant;
        }

        User user = new User(maybeUserRecord.get());
        variant.setUser(user);
        variant.setViolationMessages(violationMessages);
        return variant;
    }

    public ValidationVariant validateReadUser(UserReadRequestDto userReadRequestDto) {
        ValidationVariant variant = new ValidationVariant();
        ArrayList<String> violationMessages = new ArrayList<>();
        Set<ConstraintViolation<UserReadRequestDto>> violations = validator.validate(userReadRequestDto);
        if (!violations.isEmpty()) {
            for (ConstraintViolation<UserReadRequestDto> violation : violations) {
                violationMessages.add(violation.getMessage());
            }
        }

        Optional<UserRecord> maybeUserRecord = dbDao.getUserById(userReadRequestDto.getId());
        if (maybeUserRecord.isEmpty()) {
            violationMessages.add("User does not exist.");
            variant.setViolationMessages(violationMessages);
            return variant;
        }

        User user = new User(maybeUserRecord.get());
        variant.setUser(user);
        variant.setViolationMessages(violationMessages);
        return variant;
    }

    public ArrayList<String> validateLoginUser(UserLoginRequestDto userLoginRequestDto) {
        ArrayList<String> violationMessages = new ArrayList<>();
        Set<ConstraintViolation<UserLoginRequestDto>> violations = validator.validate(userLoginRequestDto);
        if (!violations.isEmpty()) {
            for (ConstraintViolation<UserLoginRequestDto> violation : violations) {
                violationMessages.add(violation.getMessage());
            }
        }

        return violationMessages;
    }

}
