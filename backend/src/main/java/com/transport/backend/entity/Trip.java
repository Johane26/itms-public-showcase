package com.transport.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "trips")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Trip {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long driverId;

    @Column(nullable = false, length = 50)
    private String route;

    @Column(nullable = false)
    private String status; // "ACTIVE" or "COMPLETED"

    @Column(nullable = false)
    private LocalDateTime startTime;

    private LocalDateTime endTime;

    // Start location (when shift starts)
    private Double startLatitude;
    private Double startLongitude;

    // End location (when shift ends)
    private Double endLatitude;
    private Double endLongitude;
}