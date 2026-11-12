package com.aquatrade.realtime.security;

import java.security.Principal;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;

public class RealtimePrincipal implements Principal {

    private final String userId;
    private final Set<String> roles;

    public RealtimePrincipal(String userId, Set<String> roles) {
        this.userId = userId;
        this.roles = Collections.unmodifiableSet(new LinkedHashSet<>(roles));
    }

    @Override
    public String getName() {
        return userId;
    }

    public Set<String> getRoles() {
        return roles;
    }

    public boolean hasRole(String role) {
        return roles.contains(role) || roles.contains("ROLE_" + role);
    }
}
