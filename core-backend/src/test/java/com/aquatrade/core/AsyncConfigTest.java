package com.aquatrade.core;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.test.context.ActiveProfiles;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
public class AsyncConfigTest {

    @Autowired
    @Qualifier("aiTaskExecutor")
    private Executor aiTaskExecutor;

    @Test
    @DisplayName("Verify that aiTaskExecutor bean is configured correctly and names its threads appropriately")
    void testAiTaskExecutorConfigurationAndThreadNaming() throws InterruptedException {
        // Assert the executor class type
        assertThat(aiTaskExecutor).isInstanceOf(ThreadPoolTaskExecutor.class);
        ThreadPoolTaskExecutor threadPoolExecutor = (ThreadPoolTaskExecutor) aiTaskExecutor;

        // Verify pool size configs
        assertThat(threadPoolExecutor.getCorePoolSize()).isEqualTo(5);
        assertThat(threadPoolExecutor.getMaxPoolSize()).isEqualTo(20);
        assertThat(threadPoolExecutor.getQueueCapacity()).isEqualTo(50);
        assertThat(threadPoolExecutor.getThreadNamePrefix()).isEqualTo("AI-Thread-");

        // Submit a task to verify thread naming
        CountDownLatch latch = new CountDownLatch(1);
        AtomicReference<String> threadNameRef = new AtomicReference<>();

        aiTaskExecutor.execute(() -> {
            threadNameRef.set(Thread.currentThread().getName());
            latch.countDown();
        });

        // Wait for thread execution
        boolean completed = latch.await(2, TimeUnit.SECONDS);
        assertThat(completed).isTrue();
        assertThat(threadNameRef.get()).startsWith("AI-Thread-");
    }
}
