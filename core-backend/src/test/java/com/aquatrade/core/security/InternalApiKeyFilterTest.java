package com.aquatrade.core.security;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

class InternalApiKeyFilterTest {

    @Test
    void internalRealtimeEndpointRequiresSecretHeader() throws Exception {
        InternalApiKeyFilter filter = new InternalApiKeyFilter();
        ReflectionTestUtils.setField(filter, "expectedApiKey", "secret");
        MockHttpServletRequest request = new MockHttpServletRequest(
                "GET",
                "/api/v1/internal/realtime/orders/order-001/access"
        );
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        assertThat(response.getStatus()).isEqualTo(403);
        verify(chain, never()).doFilter(request, response);
    }
    @Test
    void internalEndpointRejectsEmptyConfiguredSecret() throws Exception {
        InternalApiKeyFilter filter = new InternalApiKeyFilter();
        ReflectionTestUtils.setField(filter, "expectedApiKey", "");
        MockHttpServletRequest request = new MockHttpServletRequest(
                "GET", "/api/v1/internal/realtime/orders/order-001/access");
        request.addHeader("X-Internal-Secret", "");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        assertThat(response.getStatus()).isEqualTo(403);
        verify(chain, never()).doFilter(request, response);
    }

    @Test
    void internalEndpointAcceptsMatchingConfiguredSecret() throws Exception {
        InternalApiKeyFilter filter = new InternalApiKeyFilter();
        ReflectionTestUtils.setField(filter, "expectedApiKey", "test-internal-secret");
        MockHttpServletRequest request = new MockHttpServletRequest(
                "GET", "/api/v1/internal/realtime/orders/order-001/access");
        request.addHeader("X-Internal-Secret", "test-internal-secret");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        verify(chain).doFilter(request, response);
    }
}
