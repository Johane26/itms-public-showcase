package com.transport.backend.service;

import com.transport.backend.entity.StopVisit;
import com.transport.backend.repository.StopVisitRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class AnalyticsService {

    @Autowired
    private StopVisitRepository stopVisitRepository;

    // Run daily at 3 AM
    @Scheduled(cron = "0 0 3 * * *")
    public void computeAverageWaitTimes() {
        List<StopVisit> visits = stopVisitRepository.findAll();

        // Group by stop_id and hour of day (arrival hour)
        Map<Long, Map<Integer, List<StopVisit>>> grouped = visits.stream()
                .filter(v -> v.getDurationSeconds() != null)
                .collect(Collectors.groupingBy(
                        StopVisit::getStopId,
                        Collectors.groupingBy(v -> v.getArrivalTime().getHour())
                ));

        grouped.forEach((stopId, hourMap) -> {
            hourMap.forEach((hour, list) -> {
                double avg = list.stream()
                        .mapToInt(StopVisit::getDurationSeconds)
                        .average()
                        .orElse(0.0);
                // For now, print the result (or store in a cache)
                System.out.println("Stop " + stopId + ", Hour " + hour + ": Avg wait = " + avg + " seconds");
                // TODO: store this in a cache table (e.g., stop_avg_wait)
            });
        });
    }

    // Utility method to retrieve the average wait time for a stop (current hour)
    public int getAverageWaitForStop(Long stopId) {
        // In production, fetch from a cached table. For now, return a default.
        // You can implement a real query here if you want on-the-fly calculation.
        int currentHour = LocalDateTime.now().getHour();
        // Placeholder – replace with cache lookup later
        return 240; // 4 minutes
    }
}