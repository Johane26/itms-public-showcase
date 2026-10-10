package com.transport.backend.controller;

import com.transport.backend.entity.Driver;
import com.transport.backend.repository.DriverRepository;
import com.transport.backend.repository.TripRepository;
import com.transport.backend.service.AccountAccessService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final DriverRepository driverRepository;
    private final TripRepository tripRepository;
    private final AccountAccessService accountAccessService;

    public DashboardController(DriverRepository driverRepository,
                               TripRepository tripRepository,
                               AccountAccessService accountAccessService) {
        this.driverRepository = driverRepository;
        this.tripRepository = tripRepository;
        this.accountAccessService = accountAccessService;
    }

    @GetMapping("/stats")
    public ResponseEntity<?> getStats(Authentication authentication) {
        if (!accountAccessService.isActiveOwner(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        List<Driver> all = driverRepository.findAll();
        long total = all.size();
        long active = all.stream().filter(d -> Boolean.TRUE.equals(d.getIsActive())).count();
        long available = all.stream().filter(d -> "AVAILABLE".equals(d.getStatus())).count();
        long onTrip = all.stream().filter(d -> "ON_TRIP".equals(d.getStatus())).count();

        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = LocalDate.now().plusDays(1).atStartOfDay();
        long actualTripsToday = tripRepository.countByStartTimeBetween(startOfDay, endOfDay);

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalVehicles", total);
        stats.put("activeVehicles", active);
        stats.put("availableVehicles", available);
        stats.put("onTripVehicles", onTrip);
        stats.put("todayTrips", actualTripsToday);
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/alerts")
    public ResponseEntity<?> getAlerts(Authentication authentication) {
        if (!accountAccessService.isActiveOwner(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(List.of(
                Map.of("type", "info", "message", "Shift completed for B123ABC"),
                Map.of("type", "warning", "message", "Vehicle B456DEF stopped for 15 minutes"),
                Map.of("type", "error", "message", "GPS disconnected for B789GHI")
        ));
    }
}
