package com.transport.backend.controller;

import com.transport.backend.entity.Stop;
import com.transport.backend.entity.StopVisit;
import com.transport.backend.repository.StopVisitRepository;
import com.transport.backend.service.StopDetectionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/stops")
public class StopController {

    @Autowired
    private StopDetectionService stopDetectionService;

    @Autowired
    private StopVisitRepository stopVisitRepository;

    @GetMapping("/insight")
    public ResponseEntity<?> getStopInsight(@RequestParam Double lat, @RequestParam Double lng) {
        // Find nearest stop
        Stop nearestStop = stopDetectionService.findNearestStop(lat, lng);
        if (nearestStop == null) {
            return ResponseEntity.notFound().build();
        }

        // Compute average wait time for this stop in the last 7 days
        // For simplicity, we'll compute a placeholder; you can replace with a real query.
        // Since we don't have a custom query yet, we'll fetch all visits and compute average.
        List<StopVisit> visits = stopVisitRepository.findByStopId(nearestStop.getId());
        int avgWait = 0;
        if (!visits.isEmpty()) {
            long total = visits.stream()
                    .filter(v -> v.getDurationSeconds() != null)
                    .mapToInt(StopVisit::getDurationSeconds)
                    .sum();
            avgWait = (int) (total / visits.size());
        } else {
            avgWait = 240; // default 4 minutes
        }

        // Placeholder for passenger count (can be integrated later)
        int passengerCount = 8; // placeholder

        // Placeholder for next kombi distance (could compute from active drivers)
        double nextKombiDistance = 2.5; // placeholder in km

        Map<String, Object> response = new HashMap<>();
        response.put("stopName", nearestStop.getName());
        response.put("averageWaitSeconds", avgWait);
        response.put("passengerCountEstimate", passengerCount);
        response.put("nextKombiDistance", nextKombiDistance);

        return ResponseEntity.ok(response);
    }
}