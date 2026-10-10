package com.transport.backend.repository;

import com.transport.backend.entity.StopVisit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StopVisitRepository extends JpaRepository<StopVisit, Long> {
    List<StopVisit> findByDriverIdAndTripId(Long driverId, Long tripId);
    List<StopVisit> findByStopId(Long stopId);
}