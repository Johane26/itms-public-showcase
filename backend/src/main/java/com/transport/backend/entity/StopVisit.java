package com.transport.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "stop_visits")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StopVisit {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long driverId;

    @Column(nullable = false)
    private Long stopId;

    @Column(nullable = false)
    private Long tripId;           // Reference to the current trip

    @Column(nullable = false)
    private LocalDateTime arrivalTime;

    private LocalDateTime departureTime;

    private Integer durationSeconds; // Computed when they leave
}