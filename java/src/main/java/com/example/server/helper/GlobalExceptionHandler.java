package com.example.server.helper;

import com.google.gson.JsonParseException;
import io.netty.handler.codec.UnsupportedMessageTypeException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import lombok.extern.log4j.Log4j2;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageConversionException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.lang.NonNull;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.ServletRequestBindingException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.ServletWebRequest;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import org.springframework.web.util.ContentCachingRequestWrapper;

@Log4j2
@ControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    public static String GENERIC_CLIENT_ERROR = "Malformed request";
    public static String GENERIC_SERVER_ERROR = "Internal error";
    public static String MALFORMED_INVALID_JSON = "Malformed request, invalid json (Message Not Readable)";
    public static String MALFORMED_INVALID_MEDIA_TYPE = "Malformed request, invalid Media Type";

    @ExceptionHandler({
        //ConstraintViolationException.class,
        HttpMessageConversionException.class,
        IllegalArgumentException.class,
        IOException.class,
        JsonParseException.class,
        MethodArgumentTypeMismatchException.class,
        UnsupportedMessageTypeException.class
    })
    public ResponseEntity<Object> handleClientException(Exception ex, ContentCachingRequestWrapper request) {
        String requestBody = new String(request.getContentAsByteArray());
        return this.handleClientError(GENERIC_CLIENT_ERROR, ex, requestBody);
    }

    @ExceptionHandler({Exception.class})
    public ResponseEntity<Object> handleOtherException(Exception ex, ContentCachingRequestWrapper request) {
        String requestBody = new String(request.getContentAsByteArray());
        return this.handleServerError(GENERIC_SERVER_ERROR, ex, requestBody);
    }

    @Override
    protected ResponseEntity<Object> handleHttpMessageNotReadable(@NonNull HttpMessageNotReadableException ex,
                                                                  @NonNull HttpHeaders headers,
                                                                  @NonNull HttpStatusCode statusCode,
                                                                  @NonNull WebRequest request
    ) {
        String requestBody = extractRequestBody(request);

        return this.handleClientError(MALFORMED_INVALID_JSON, ex, requestBody);
    }

    @Override
    public ResponseEntity<Object> handleHttpMediaTypeNotSupported(@NonNull HttpMediaTypeNotSupportedException ex,
                                                                  @NonNull HttpHeaders headers,
                                                                  @NonNull HttpStatusCode statusCode,
                                                                  @NonNull WebRequest request
    ) {
        String requestBody = extractRequestBody(request);

        return this.handleClientError(MALFORMED_INVALID_MEDIA_TYPE, ex, requestBody);
    }

    @Override
    public ResponseEntity<Object> handleMethodArgumentNotValid(@NonNull MethodArgumentNotValidException ex,
                                                               @NonNull HttpHeaders headers,
                                                               @NonNull HttpStatusCode statusCode,
                                                               @NonNull WebRequest request
    ) {
        List<String> errors = new ArrayList<>();
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            var fieldName = error.getObjectName();
            var errorMessage = error.getDefaultMessage();
            errors.add(fieldName + ":" + errorMessage);
        });

        String requestBody = extractRequestBody(request);

        return this.handleClientError("Malformed request, " +
            String.join(", ", errors), ex, requestBody);
    }

    @Override
    protected ResponseEntity<Object> handleServletRequestBindingException(@NonNull ServletRequestBindingException ex,
                                                                          @NonNull HttpHeaders headers,
                                                                          @NonNull HttpStatusCode statusCode,
                                                                          @NonNull WebRequest request
    ) {
        String requestBody = extractRequestBody(request);

        return this.handleClientError("Malformed request, " + ex.getMessage(), ex, requestBody);
    }

    public ResponseEntity<Object> handleClientError(String responseMessage, Exception ce, String requestBody) {
        log.info("Malformed request details for body > " + requestBody + " > " +
            ce.getMessage());

        return new ResponseEntity<>(
            responseMessage,
            HttpStatus.BAD_REQUEST
        );
    }

    public ResponseEntity<Object> handleServerError(String responseMessage, Exception se, String requestBody) {
        log.error("Service Exception for body > " +
            requestBody + " > " + se.getMessage(), se);

        return new ResponseEntity<>(
            responseMessage,
            HttpStatus.INTERNAL_SERVER_ERROR
        );
    }

    public String extractRequestBody(WebRequest request) {
        String requestBody = "MISSING";
        try {
            ContentCachingRequestWrapper nativeRequest = (ContentCachingRequestWrapper) ((ServletWebRequest) request)
                .getNativeRequest();
            requestBody = new String(nativeRequest.getContentAsByteArray());
        } catch (Exception e) {
            log.warn("Could not extract body from request");
        }
        return requestBody;
    }
}
