package com.transport.backend.controller;

import com.transport.backend.entity.Trip;
import com.transport.backend.entity.Driver;
import com.transport.backend.repository.TripRepository;
import com.transport.backend.repository.DriverRepository;
import com.transport.backend.service.AccountAccessService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/trips")
public class TripController {

    @Autowired
    private TripRepository tripRepository;

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private AccountAccessService accountAccessService;

    @PostMapping("/start")
    public ResponseEntity<?> startTrip(@RequestBody Map<String, Object> payload, Authentication authentication) {
        Long driverId = ((Number) payload.get("driverId")).longValue();
        if (!accountAccessService.isCurrentDriver(authentication, driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        String route = (String) payload.get("route");
        Double latitude = (Double) payload.get("latitude");
        Double longitude = (Double) payload.get("longitude");

        Optional<Driver> driverOpt = driverRepository.findById(driverId);
        if (driverOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Driver not found");
        }

        if (tripRepository.existsByDriverIdAndStatus(driverId, "ACTIVE")) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("Driver already has an active trip");
        }

        Trip trip = new Trip();
        trip.setDriverId(driverId);
        trip.setRoute(route);
        trip.setStatus("ACTIVE");
        trip.setStartTime(LocalDateTime.now());
        trip.setStartLatitude(latitude);
        trip.setStartLongitude(longitude);

        Driver driver = driverOpt.get();
        driver.setStatus("ON_TRIP");
        driver.setLatitude(latitude);
        driver.setLongitude(longitude);
        driver.setLastUpdated(LocalDateTime.now());
        driverRepository.save(driver);

        Trip savedTrip = tripRepository.save(trip);

        Map<String, Object> response = new HashMap<>();
        response.put("tripId", savedTrip.getId());
        response.put("status", "Shift started successfully");
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{tripId}/end")
    public ResponseEntity<?> endTrip(@PathVariable Long tripId, @RequestBody Map<String, Double> payload,
                                     Authentication authentication) {
        Optional<Trip> tripOpt = tripRepository.findById(tripId);
        if (tripOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Trip not found");
        }

        Trip trip = tripOpt.get();
        if (!accountAccessService.isCurrentDriver(authentication, trip.getDriverId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        if (!"ACTIVE".equals(trip.getStatus())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Trip is not active");
        }

        trip.setStatus("COMPLETED");
        trip.setEndTime(LocalDateTime.now());
        trip.setEndLatitude(payload.get("latitude"));
        trip.setEndLongitude(payload.get("longitude"));
        tripRepository.save(trip);

        Optional<Driver> driverOpt = driverRepository.findById(trip.getDriverId());
        if (driverOpt.isPresent()) {
            Driver driver = driverOpt.get();
            driver.setStatus("AVAILABLE");
            driver.setLastUpdated(LocalDateTime.now());
            driverRepository.save(driver);
        }

        Map<String, String> response = new HashMap<>();
        response.put("status", "Shift ended successfully");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/driver/{driverId}")
    public ResponseEntity<?> getDriverTrips(@PathVariable Long driverId, Authentication authentication) {
        if (!accountAccessService.canReadDriverData(authentication, driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(tripRepository.findByDriverId(driverId));
    }

    @GetMapping("/driver/{driverId}/active")
    public ResponseEntity<?> getActiveTrip(@PathVariable Long driverId, Authentication authentication) {
        if (!accountAccessService.canReadDriverData(authentication, driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        List<Trip> activeTrips = tripRepository.findByDriverIdAndStatus(driverId, "ACTIVE");
        if (activeTrips.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("No active trip");
        }
        return ResponseEntity.ok(activeTrips.get(0));
    }
}
