package com.transport.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "drivers")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Driver {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String fullName;

    @Column(unique = true, nullable = false, length = 20)
    private String phoneNumber;

    @Column(unique = true, nullable = false, length = 20)
    private String vehicleRegistration;

    @Column(nullable = false, length = 50)
    private String route;

    @Column(nullable = false)
    private String status; // "AVAILABLE", "ON_TRIP", "OFFLINE"

    private Double latitude;
    private Double longitude;

    @Column(nullable = false)
    private LocalDateTime lastUpdated;

    @Column(nullable = false)
    private Boolean isActive = true;

    //  NEW: Password field (will be hashed with BCrypt)
    @Column(nullable = false, length = 255)
    private String password;
}