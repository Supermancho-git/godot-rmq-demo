package com.example.server.service;

import com.google.gson.Gson;
import jakarta.validation.Validator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class BaseService {

    @Autowired
    protected Gson gson;

    @Autowired
    protected Validator validator;

}
