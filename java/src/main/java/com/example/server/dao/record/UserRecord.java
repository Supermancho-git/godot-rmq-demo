package com.example.server.dao.record;

public record UserRecord(
    String id,
    String username,
    String cipher,
    String email,
    long created_at,
    long modified_at,
    boolean active,
    String message_username,
    String message_cipher,
    String client_publishing_to_queue,
    String client_publishing_to_queue_rk,
    String client_consuming_from_queue,
    String client_consuming_from_queue_rk
) {}
