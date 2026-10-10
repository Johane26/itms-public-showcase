package com.transport.backend.repository;

import com.transport.backend.entity.Trip;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TripRepository extends JpaRepository<Trip, Long> {
    List<Trip> findByDriverId(Long driverId);
    List<Trip> findByDriverIdAndStatus(Long driverId, String status);
    boolean existsByDriverIdAndStatus(Long driverId, String status);

    // 👇 ADD THIS LINE
    long countByStartTimeBetween(LocalDateTime start, LocalDateTime end);
}