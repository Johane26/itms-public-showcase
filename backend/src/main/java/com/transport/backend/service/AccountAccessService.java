package com.transport.backend.service;

import com.transport.backend.repository.DriverRepository;
import com.transport.backend.repository.OwnerRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

@Service
public class AccountAccessService {

    private final DriverRepository driverRepository;
    private final OwnerRepository ownerRepository;

    public AccountAccessService(DriverRepository driverRepository, OwnerRepository ownerRepository) {
        this.driverRepository = driverRepository;
        this.ownerRepository = ownerRepository;
    }

    public boolean isActiveAccount(String username, String role) {
        if (username == null || role == null) {
            return false;
        }
        return switch (role) {
            case "DRIVER" -> driverRepository.findByPhoneNumber(username)
                    .map(driver -> Boolean.TRUE.equals(driver.getIsActive())).orElse(false);
            case "OWNER" -> ownerRepository.findByEmail(username)
                    .map(owner -> Boolean.TRUE.equals(owner.getIsActive())).orElse(false);
            default -> false;
        };
    }

    public boolean isActiveOwner(Authentication authentication) {
        return hasRole(authentication, "ROLE_OWNER")
                && ownerRepository.findByEmail(authentication.getName())
                .map(owner -> Boolean.TRUE.equals(owner.getIsActive())).orElse(false);
    }

    public boolean isCurrentDriver(Authentication authentication, Long driverId) {
        if (!hasRole(authentication, "ROLE_DRIVER") || driverId == null) {
            return false;
        }
        return driverRepository.findByPhoneNumber(authentication.getName())
                .map(driver -> Boolean.TRUE.equals(driver.getIsActive())
                        && driverId.equals(driver.getId()))
                .orElse(false);
    }

    public boolean canReadDriverData(Authentication authentication, Long driverId) {
        return isActiveOwner(authentication) || isCurrentDriver(authentication, driverId);
    }

    private boolean hasRole(Authentication authentication, String role) {
        return authentication != null
                && authentication.isAuthenticated()
                && authentication.getAuthorities().stream()
                .anyMatch(authority -> role.equals(authority.getAuthority()));
    }
}
