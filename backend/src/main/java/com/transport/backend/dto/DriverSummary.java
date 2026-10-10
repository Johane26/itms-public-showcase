package com.transport.backend.dto;

import com.transport.backend.entity.Driver;

public record DriverSummary(
        Long id,
        String fullName,
        String vehicleRegistration,
        String route,
        String status,
        Double latitude,
        Double longitude) {

    public static DriverSummary from(Driver driver) {
        return new DriverSummary(
                driver.getId(),
                driver.getFullName(),
                driver.getVehicleRegistration(),
                driver.getRoute(),
                driver.getStatus(),
                driver.getLatitude(),
                driver.getLongitude());
    }
}
