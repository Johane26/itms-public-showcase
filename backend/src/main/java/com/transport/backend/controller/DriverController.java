package com.transport.backend.controller;

import com.transport.backend.dto.DriverSummary;
import com.transport.backend.repository.DriverRepository;
import com.transport.backend.service.AccountAccessService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/drivers")
public class DriverController {

    private final DriverRepository driverRepository;
    private final AccountAccessService accountAccessService;

    public DriverController(DriverRepository driverRepository, AccountAccessService accountAccessService) {
        this.driverRepository = driverRepository;
        this.accountAccessService = accountAccessService;
    }

    @GetMapping
    public ResponseEntity<?> getAllDrivers(Authentication authentication) {
        if (!accountAccessService.isActiveOwner(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(driverRepository.findAll().stream().map(DriverSummary::from).toList());
    }

    @GetMapping("/{driverId}")
    public ResponseEntity<?> getDriver(@PathVariable Long driverId, Authentication authentication) {
        if (!accountAccessService.canReadDriverData(authentication, driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return driverRepository.findById(driverId)
                .<ResponseEntity<?>>map(driver -> ResponseEntity.ok(DriverSummary.from(driver)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/ping")
    public String ping() {
        return "pong";
    }
}
