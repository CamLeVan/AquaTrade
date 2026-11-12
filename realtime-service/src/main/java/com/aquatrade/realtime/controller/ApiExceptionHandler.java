package com.aquatrade.realtime.controller;

import java.util.LinkedHashMap;
import java.util.Map;

import com.aquatrade.realtime.support.InvalidRealtimeEventException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(InvalidRealtimeEventException.class)
    public ResponseEntity<Map<String, Object>> invalidRealtimeEvent(InvalidRealtimeEventException ex) {
        return ResponseEntity.badRequest().body(Map.of(
                "error", "invalid_realtime_event",
                "message", ex.getMessage()
        ));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> validationError(MethodArgumentNotValidException ex) {
        Map<String, String> fields = new LinkedHashMap<>();
        for (FieldError fieldError : ex.getBindingResult().getFieldErrors()) {
            fields.put(fieldError.getField(), fieldError.getDefaultMessage());
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "error", "validation_failed",
                "fields", fields
        ));
    }
}
