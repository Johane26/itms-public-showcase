package com.transport.backend.controller;

import com.transport.backend.entity.Driver;
import com.transport.backend.entity.Location;
import com.transport.backend.repository.DriverRepository;
import com.transport.backend.repository.LocationRepository;
import com.transport.backend.service.AccountAccessService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/locations")
public class LocationController {

    private final LocationRepository locationRepository;
    private final DriverRepository driverRepository;
    private final AccountAccessService accountAccessService;

    public LocationController(LocationRepository locationRepository,
                              DriverRepository driverRepository,
                              AccountAccessService accountAccessService) {
        this.locationRepository = locationRepository;
        this.driverRepository = driverRepository;
        this.accountAccessService = accountAccessService;
    }

    @PostMapping
    public ResponseEntity<?> saveLocation(@RequestBody Map<String, Object> payload,
                                          Authentication authentication) {
        Long driverId = ((Number) payload.get("driverId")).longValue();
        if (!accountAccessService.isCurrentDriver(authentication, driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        Location location = new Location();
        location.setDriverId(driverId);
        location.setLatitude(((Number) payload.get("latitude")).doubleValue());
        location.setLongitude(((Number) payload.get("longitude")).doubleValue());
        location.setTimestamp(LocalDateTime.now());
        return ResponseEntity.ok(locationRepository.save(location));
    }

    @GetMapping("/driver/{driverId}/latest")
    public ResponseEntity<?> getLatestLocation(@PathVariable Long driverId, Authentication authentication) {
        if (!accountAccessService.canReadDriverData(authentication, driverId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        List<Location> locations = locationRepository.findTopByDriverIdOrderByTimestampDesc(driverId);
        return locations.isEmpty()
                ? ResponseEntity.notFound().build()
                : ResponseEntity.ok(locations.get(0));
    }

    @GetMapping("/active")
    public ResponseEntity<?> getActiveDriversLocations(Authentication authentication) {
        if (!accountAccessService.isActiveOwner(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        List<Driver> activeDrivers = driverRepository.findByStatus("ON_TRIP");
        List<Map<String, Object>> result = new ArrayList<>();
        for (Driver driver : activeDrivers) {
            List<Location> locations = locationRepository.findTopByDriverIdOrderByTimestampDesc(driver.getId());
            if (!locations.isEmpty()) {
                Location latest = locations.get(0);
                Map<String, Object> data = new HashMap<>();
                data.put("driverId", driver.getId());
                data.put("fullName", driver.getFullName());
                data.put("vehicleRegistration", driver.getVehicleRegistration());
                data.put("latitude", latest.getLatitude());
                data.put("longitude", latest.getLongitude());
                data.put("lastUpdated", latest.getTimestamp());
                result.add(data);
            }
        }
        return ResponseEntity.ok(result);
    }
}
