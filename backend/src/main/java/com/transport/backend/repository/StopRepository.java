package com.transport.backend.repository;

import com.transport.backend.entity.Stop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StopRepository extends JpaRepository<Stop, Long> {

    // Find all stops for a specific route (e.g., "Route 6")
    List<Stop> findByRoute(String route);

    // (Optional) You can add more custom queries if needed, e.g.:
    // List<Stop> findByLatitudeBetweenAndLongitudeBetween(Double latMin, Double latMax, Double lngMin, Double lngMax);
}