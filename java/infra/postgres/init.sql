--
-- PostgreSQL database dump
--
CREATE SCHEMA IF NOT EXISTS my;

DROP TABLE IF EXISTS my.users;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

CREATE TABLE IF NOT EXISTS my.users
(
    id character varying COLLATE pg_catalog."default" NOT NULL,
    username character varying COLLATE pg_catalog."default" NOT NULL,
    cipher character varying COLLATE pg_catalog."default" NOT NULL,
    email character varying COLLATE pg_catalog."default" NOT NULL,
    created_at bigint NOT NULL DEFAULT 0,
    modified_at bigint NOT NULL DEFAULT 0,
    active boolean NOT NULL DEFAULT false,
    message_username character varying COLLATE pg_catalog."default" NOT NULL,
    message_cipher character varying COLLATE pg_catalog."default" NOT NULL,
    client_publishing_to_queue character varying COLLATE pg_catalog."default" NOT NULL,
    client_publishing_to_queue_rk character varying COLLATE pg_catalog."default" NOT NULL,
    client_consuming_from_queue character varying COLLATE pg_catalog."default" NOT NULL,
    client_consuming_from_queue_rk character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT user_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS my.users
    OWNER to admin;
