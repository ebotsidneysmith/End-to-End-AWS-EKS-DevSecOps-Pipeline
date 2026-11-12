package com.example.store;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    @GetMapping("/")
    public Map<String, String> home() {
        return Map.of("service", "store-api", "status", "running");
    }

    @GetMapping("/api/v1/status")
    public Map<String, String> status() {
        return Map.of("status", "ok", "environment", System.getenv().getOrDefault("APP_ENV", "local"));
    }
}
