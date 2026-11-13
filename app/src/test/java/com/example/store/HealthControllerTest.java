
package com.example.store;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.resttestclient.TestRestTemplate;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureTestRestTemplate;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
class HealthControllerTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void healthEndpointShouldReturnSuccess() {

        ResponseEntity<String> response =
                restTemplate.getForEntity(
                        "/actuator/health",
                        String.class
                );

        assertEquals(200, response.getStatusCode().value());
        assertNotNull(response.getBody());
    }
}
