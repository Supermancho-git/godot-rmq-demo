package com.example.server.client.http;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.Timer;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import lombok.Setter;
import lombok.extern.log4j.Log4j2;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.UnknownHttpStatusCodeException;

@Log4j2
public abstract class RestClient {

    RestTemplate restTemplate;

    @Value("${application.headerfield.requestId}")
    String requestIdheader;

    Timer.Sample startTimer;

    @Setter
    String authorization = "";

    public RestClient(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public final <R, T> Object getResponseSync(
        HttpMethod method, String url, List<Param> queryParams, T requestBody,
        Map<String, String> headers, Class<R> responseType, ObjectMapper mapper
    ) {
        if (headers == null) {
            headers = new HashMap<>();
        }

        ResponseEntity<?> response = this.executeRequest(method, url, queryParams, requestBody, headers, responseType, mapper);
        return this.parseResponse(response);
    }

    HttpHeaders createHttpHeaders(Map<String, String> headers) {
        HttpHeaders requestHeaders = new HttpHeaders();
        getCommonHeaders().forEach(requestHeaders::add);
        headers.forEach(requestHeaders::add);
        if (authorization != null && !authorization.isEmpty()) {
            requestHeaders.set(HttpHeaders.AUTHORIZATION, authorization);
        }
        return requestHeaders;
    }

    <R, T> ResponseEntity<?> executeRequest(
        HttpMethod method, String url, List<Param> params, T requestBody,
        Map<String, String> headers, Class<R> responseType, ObjectMapper mapper
    ) {
        HttpHeaders httpHeaders = createHttpHeaders(headers);
        Map<String, String> queryParams = Param.paramList2Map(params);
        StringBuilder urlBuilder = new StringBuilder(url);
        String[] values = new String[queryParams.size()];
        int i = 0;

        for (Iterator<Map.Entry<String, String>> it = queryParams.entrySet().iterator(); it.hasNext(); ++i) {
            Map.Entry<String, String> entry = it.next();
            if (i == 0) {
                urlBuilder.append("?");
            } else {
                urlBuilder.append("&");
            }

            urlBuilder.append(entry.getKey()).append("=").append("{").append(entry.getKey()).append("}");
            values[i] = entry.getValue();
        }

        long startTime = System.currentTimeMillis();
        startTimer = Timer.start();

        ResponseEntity<?> result;
        try {
            result = restTemplate.exchange(
                urlBuilder.toString(), method, createHttpEntity(httpHeaders, requestBody),
                responseType, (Object[]) values
            );
        } catch (HttpServerErrorException | HttpClientErrorException e) {
            JsonNode errorNode = mapper.createObjectNode();

            try {
                String responseBody = e.getResponseBodyAsString();
                errorNode = mapper.createObjectNode().put("value", responseBody);
            } catch (Exception ex1) {
                log.warn("Caught error while parsing errorResponse from http call" + ex1.getMessage(), ex1);
            }

            result = new ResponseEntity<>(errorNode, e.getStatusCode());
        } catch (UnknownHttpStatusCodeException e1) {
            log.error("Unknown HTTP status code: " + e1.getStatusCode(), e1);
            throw e1;
        } catch (Exception e2) {
            log.error("Unknown exception from http call: " + e2.getMessage(), e2);
            throw e2;
        } finally {
            log.info("Time taken for http call {} is {} ms", url.split("\\?")[0], System.currentTimeMillis() - startTime);
        }

        return result;
    }

    <T> HttpEntity<T> createHttpEntity(HttpHeaders headers, T requestBody) {
        return requestBody != null ? new HttpEntity<>(requestBody, headers) : new HttpEntity<>(headers);
    }

    String getRequestIdValue() {
        String requestIdFromMdc = MDC.get(requestIdheader);
        if (requestIdFromMdc == null) {
            String rID = UUID.randomUUID().toString();
            log.warn("No rID in MDC. Created new request ID: " + rID);
            return rID;
        }

        return requestIdFromMdc;
    }

    Map<String, String> getCommonHeaders() {
        Map<String, String> headers = new HashMap<>();
        headers.put(HttpHeaders.ACCEPT, "application/json");
        headers.put(HttpHeaders.CONTENT_TYPE, "application/json");
        headers.put(requestIdheader, getRequestIdValue());
        return headers;
    }

    <R> R parseResponse(ResponseEntity<R> response) {
        if (response == null) {
            throw new RuntimeException("null response from Client");
        } else if (!response.getStatusCode().is2xxSuccessful()) {
            log.warn("Unsuccessful response code: " + response.getStatusCode());
            return handleErrorResponse(response);
        }

        return handleSuccessResponse(response);
    }

    public abstract <T> T handleSuccessResponse(ResponseEntity<T> responseEntity);

    public abstract <T> T handleErrorResponse(ResponseEntity<T> response);

}
