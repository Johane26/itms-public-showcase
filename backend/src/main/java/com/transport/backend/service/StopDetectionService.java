package com.transport.backend.service;

import com.transport.backend.entity.Stop;
import com.transport.backend.entity.StopVisit;
import com.transport.backend.repository.StopRepository;
import com.transport.backend.repository.StopVisitRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class StopDetectionService {

    @Autowired
    private StopRepository stopRepository;

    @Autowired
    private StopVisitRepository stopVisitRepository;

    // In-memory cache: driverId -> active StopVisit (null if not at a stop)
    private final Map<Long, StopVisit> activeVisits = new HashMap<>();

    // Called whenever we receive a new location from a driver
    public void processLocation(Long driverId, Double lat, Double lng, Long tripId) {
        // Find nearest stop within 30 meters
        Stop nearestStop = findNearestStop(lat, lng);
        if (nearestStop == null) {
            // If the driver was at a stop but moved away, finalize the visit
            if (activeVisits.containsKey(driverId)) {
                endVisit(driverId);
            }
            return;
        }

        StopVisit current = activeVisits.get(driverId);
        if (current != null && current.getStopId().equals(nearestStop.getId())) {
            // Already at this stop – do nothing
            return;
        }

        // If they were at a different stop, end that visit
        if (current != null) {
            endVisit(driverId);
        }

        // Start new visit
        StopVisit visit = new StopVisit();
        visit.setDriverId(driverId);
        visit.setStopId(nearestStop.getId());
        visit.setTripId(tripId);
        visit.setArrivalTime(LocalDateTime.now());
        activeVisits.put(driverId, visit);
        stopVisitRepository.save(visit);
    }

    private void endVisit(Long driverId) {
        StopVisit visit = activeVisits.remove(driverId);
        if (visit != null) {
            visit.setDepartureTime(LocalDateTime.now());
            visit.setDurationSeconds((int) java.time.Duration.between(visit.getArrivalTime(), visit.getDepartureTime()).getSeconds());
            stopVisitRepository.save(visit);
        }
    }

    public Stop findNearestStop(Double lat, Double lng) {
        // For simplicity, we'll use a placeholder logic: return the first stop within 30m.
        // In production, use a geospatial query (PostGIS).
        List<Stop> allStops = stopRepository.findAll();
        Stop nearest = null;
        double minDist = Double.MAX_VALUE;
        for (Stop s : allStops) {
            double dist = haversine(lat, lng, s.getLatitude(), s.getLongitude());
            if (dist < 30 && dist < minDist) {
                minDist = dist;
                nearest = s;
            }
        }
        return nearest;
    }

    private double haversine(double lat1, double lon1, double lat2, double lon2) {
        // Standard Haversine formula (returns distance in meters)
        double R = 6371000;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(dLon/2) * Math.sin(dLon/2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }
}