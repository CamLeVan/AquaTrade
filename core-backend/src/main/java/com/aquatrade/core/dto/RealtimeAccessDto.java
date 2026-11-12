package com.aquatrade.core.dto;

public final class RealtimeAccessDto {

    private RealtimeAccessDto() {
    }

    public record OrderAccessResponse(boolean allowed, String roleInOrder) {
        public static OrderAccessResponse denied() {
            return new OrderAccessResponse(false, null);
        }

        public static OrderAccessResponse allowed(String roleInOrder) {
            return new OrderAccessResponse(true, roleInOrder);
        }
    }
}
