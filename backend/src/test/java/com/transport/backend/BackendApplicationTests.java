package com.transport.backend;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import com.transport.backend.entity.Driver;
import com.transport.backend.repository.DriverRepository;
import com.transport.backend.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class BackendApplicationTests {

	private static final String TEST_JWT_SECRET =
			UUID.randomUUID().toString() + UUID.randomUUID().toString();

	@Autowired
	private MockMvc mockMvc;

	@Autowired
	private DriverRepository driverRepository;

	@Autowired
	private PasswordEncoder passwordEncoder;

	@Autowired
	private JwtUtil jwtUtil;

	@DynamicPropertySource
	static void testConfiguration(DynamicPropertyRegistry registry) {
		registry.add("spring.datasource.url", () -> "jdbc:h2:mem:itms-test;DB_CLOSE_DELAY=-1");
		registry.add("spring.datasource.username", () -> "sa");
		registry.add("spring.datasource.password", () -> "");
		registry.add("spring.datasource.driver-class-name", () -> "org.h2.Driver");
		registry.add("spring.jpa.database-platform", () -> "org.hibernate.dialect.H2Dialect");
		registry.add("jwt.secret", () -> TEST_JWT_SECRET);
	}

	@Test
	void contextLoads() {
	}

	@BeforeEach
	void clearDrivers() {
		driverRepository.deleteAll();
	}

	@Test
	void driverCannotReadAnotherDriversTrip() throws Exception {
		Driver owner = driver("+26771000001", "B100AAA");
		Driver other = driver("+26771000002", "B200BBB");
		driverRepository.save(owner);
		other = driverRepository.save(other);

		String token = jwtUtil.generateToken(owner.getPhoneNumber(), "DRIVER");
		mockMvc.perform(get("/api/trips/driver/{driverId}/active", other.getId())
					.header("Authorization", "Bearer " + token))
				.andExpect(status().isForbidden());
	}

	@Test
	void driverProfileResponseDoesNotExposePasswordHash() throws Exception {
		Driver driver = driverRepository.save(driver("+26771000003", "B300CCC"));
		String token = jwtUtil.generateToken(driver.getPhoneNumber(), "DRIVER");
		mockMvc.perform(get("/api/drivers/{driverId}", driver.getId())
					.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.password").doesNotExist());
	}

	private Driver driver(String phoneNumber, String vehicleRegistration) {
		Driver driver = new Driver();
		driver.setFullName("Test Driver");
		driver.setPhoneNumber(phoneNumber);
		driver.setVehicleRegistration(vehicleRegistration);
		driver.setRoute("Test Route");
		driver.setStatus("AVAILABLE");
		driver.setLastUpdated(java.time.LocalDateTime.now());
		driver.setIsActive(true);
		driver.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
		return driver;
	}

}
