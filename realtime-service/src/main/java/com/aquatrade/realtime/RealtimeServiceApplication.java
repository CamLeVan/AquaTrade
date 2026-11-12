package com.aquatrade.realtime;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class RealtimeServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(RealtimeServiceApplication.class, args);
    }
}
