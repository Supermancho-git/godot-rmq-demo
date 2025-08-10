package com.example.server.config;

import com.example.server.helper.CachedWebRequestFilter;
import com.example.server.helper.Util;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.google.gson.Gson;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import java.security.SecureRandom;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Scope;

@Configuration
public class ApplicationConfig {

    @Bean
    public Gson gson() {
        return new Gson();
    }

    @Bean
    public FilterRegistrationBean<CachedWebRequestFilter> cachedWebRequestBean() {
        FilterRegistrationBean<CachedWebRequestFilter> registrationBean = new FilterRegistrationBean<>();
        registrationBean.setFilter(new CachedWebRequestFilter());
        registrationBean.setOrder(Integer.MAX_VALUE - 1);
        return registrationBean;
    }

    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        mapper.configure(SerializationFeature.FAIL_ON_EMPTY_BEANS, false);
        mapper.registerModule(new JavaTimeModule());
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        Util.mapper = mapper;
        return mapper;
    }

    @Bean
    public SecureRandom secureRandom() {
        SecureRandom random = new SecureRandom();
        Util.random = random;
        return random;
    }

    @Scope("prototype")
    @Bean
    public Validator validator() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        return factory.getValidator();
    }

}
