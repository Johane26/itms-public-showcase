package com.transport.backend.controller;

import com.transport.backend.entity.Driver;
import com.transport.backend.entity.Owner;
import com.transport.backend.repository.DriverRepository;
import com.transport.backend.repository.OwnerRepository;
import com.transport.backend.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private OwnerRepository ownerRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    // ===========================
    // DRIVER LOGIN
    // ===========================
    @PostMapping("/driver/login")
    public ResponseEntity<?> driverLogin(@RequestBody Map<String, String> request) {

        String phoneNumber = request.get("phoneNumber");
        String password = request.get("password");

        Optional<Driver> driverOpt = driverRepository.findByPhoneNumber(phoneNumber);

        if (driverOpt.isEmpty()) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        Driver driver = driverOpt.get();

        if (!Boolean.TRUE.equals(driver.getIsActive())) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        if (!passwordEncoder.matches(password, driver.getPassword())) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        String token = jwtUtil.generateToken(driver.getPhoneNumber(), "DRIVER");

        Map<String, Object> response = new HashMap<>();
        response.put("token", token);
        response.put("driverId", driver.getId());
        response.put("fullName", driver.getFullName());
        response.put("phoneNumber", driver.getPhoneNumber());
        response.put("route", driver.getRoute());
        response.put("status", driver.getStatus());
        response.put("vehicleRegistration", driver.getVehicleRegistration());

        return ResponseEntity.ok(response);
    }

    // ===========================
    // OWNER LOGIN
    // ===========================
    @PostMapping("/owner/login")
    public ResponseEntity<?> ownerLogin(@RequestBody Map<String, String> request) {

        String email = request.get("email");
        String password = request.get("password");

        Optional<Owner> ownerOpt = ownerRepository.findByEmail(email);

        if (ownerOpt.isEmpty()) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        Owner owner = ownerOpt.get();

        if (!Boolean.TRUE.equals(owner.getIsActive())) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        if (!passwordEncoder.matches(password, owner.getPassword())) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        String token = jwtUtil.generateToken(owner.getEmail(), "OWNER");

        Map<String, Object> response = new HashMap<>();
        response.put("token", token);
        response.put("ownerId", owner.getId());
        response.put("fullName", owner.getFullName());
        response.put("email", owner.getEmail());

        return ResponseEntity.ok(response);
    }
}
