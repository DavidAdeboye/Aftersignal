extends RefCounted
class_name TestPuzzleCleanroom

## Isolated Unit Test helper for verifying cleanroom pressure math and timing windows.
## Runs in memory without affecting gameplay scenes or runtime nodes.

static func verify_pressure(current_kPa: float, min_kPa: float = 400.0, max_kPa: float = 450.0) -> bool:
	return current_kPa >= min_kPa and current_kPa <= max_kPa


static func verify_synchronization(time_a: float, time_b: float, window_seconds: float = 3.0) -> bool:
	return abs(time_a - time_b) <= window_seconds


static func run_cleanroom_tests() -> Dictionary:
	var results = {
		"pressure_valid": verify_pressure(425.0),
		"pressure_low": not verify_pressure(380.0),
		"pressure_high": not verify_pressure(470.0),
		"sync_valid": verify_synchronization(10.0, 11.5),
		"sync_expired": not verify_synchronization(10.0, 14.5),
		"progress_half": abs(calculate_equalization_progress(200.0, 400.0) - 0.5) < 0.001,
		"harmonic_valid": verify_harmonic_tolerance(441.2),
		"cycle_within_limit": verify_decontamination_cycle_time(22.5),
		"rate_valid": abs(calculate_airlock_depressurization_rate(450.0, 100.0, 10.0) - 35.0) < 0.001,
		"stabilization_valid": verify_decontamination_pressure_stabilization([410.0, 420.0, 430.0]),
		"seal_engaged": verify_decontamination_airlock_seal(true, true, 425.0),
		"cycle_complete": verify_decontamination_airlock_cycle_complete("STATE_UNLOCKED", true, true),
		"throughput_positive": calculate_airlock_ventilation_throughput(1200.0) > 0.0,
		"purity_safe": verify_decontamination_air_purity_index(0.02),
		"grid_load_valid": verify_decontamination_power_relay_grid_load(135.0),
		"battery_runtime_positive": calculate_battery_backup_runtime_hours(450.0, 35.0) > 0.0,
		"actuator_latency_valid": verify_decontamination_vent_actuator_latency(450.0),
		"flush_trigger_valid": verify_decontamination_emergency_flush_trigger("HALON-OVERRIDE-99"),
		"nitrogen_volume_positive": calculate_nitrogen_expansion_volume(100.0) > 50.0,
		"hepa_filter_life_positive": calculate_hepa_filter_remaining_lifespan_pct(100.0) > 50.0,
		"vacuum_relief_flow_positive": calculate_vacuum_relief_flow_cfm(10.0) > 0.0,
		"transducer_volts_positive": calculate_transducer_output_volts(380.0) >= 1.0,
		"telemetry_throughput_positive": calculate_telemetry_throughput_bytes_sec(32, 60.0) > 0.0,
		"telemetry_crc_valid": verify_telemetry_crc16_checksum(PackedByteArray(), 0xFFFF),
		"retransmit_timeout_positive": calculate_retransmit_timeout_ms(1) > 0.0,
		"transducer_power_positive": calculate_transducer_power_consumption_watts(0.045, 0.012, 24.0) > 0.0,
		"transducer_temp_safe": verify_transducer_operating_temperature_safe(55.0)
	}
	return results


## Calculates normalized equalization ratio [0.0 - 1.0] toward target pressure.
static func calculate_equalization_progress(current_kPa: float, target_kPa: float) -> float:
	if target_kPa <= 0.0:
		return 1.0
	return clamp(current_kPa / target_kPa, 0.0, 1.0)


## Verifies if input frequency is within acceptable tolerance (default ±2.0 Hz of 440 Hz target).
static func verify_harmonic_tolerance(freq_hz: float, target_hz: float = 440.0, tolerance_hz: float = 2.0) -> bool:
	return abs(freq_hz - target_hz) <= tolerance_hz


## Verifies if decontamination cycle completed within maximum time limit (default 30.0s).
static func verify_decontamination_cycle_time(elapsed_sec: float, max_cycle_sec: float = 30.0) -> bool:
	return elapsed_sec >= 0.0 and elapsed_sec <= max_cycle_sec


## Calculates depressurization rate in kPa/sec.
static func calculate_airlock_depressurization_rate(start_kPa: float, end_kPa: float, elapsed_sec: float) -> float:
	if elapsed_sec <= 0.0:
		return 0.0
	return (start_kPa - end_kPa) / elapsed_sec


## Verifies if pressure readings series remained stable inside target range.
static func verify_decontamination_pressure_stabilization(kPa_series: Array, target_min: float = 400.0, target_max: float = 450.0) -> bool:
	if kPa_series.is_empty():
		return false
	for p in kPa_series:
		if p < target_min or p > target_max:
			return false
	return true


## Verifies if both cleanroom door seals are engaged under valid chamber pressure.
static func verify_decontamination_airlock_seal(alpha_sealed: bool, beta_sealed: bool, current_kPa: float, min_kPa: float = 400.0) -> bool:
	return alpha_sealed and beta_sealed and current_kPa >= min_kPa


## Verifies if full cleanroom decontamination cycle reached complete state.
static func verify_decontamination_airlock_cycle_complete(state: String, sealed: bool, pressure_ok: bool) -> bool:
	return state == "STATE_UNLOCKED" and sealed and pressure_ok


## Calculates ventilation airflow throughput in m^3/sec.
static func calculate_airlock_ventilation_throughput(fan_speed_rpm: float, duct_diameter_m: float = 0.8) -> float:
	var area = 3.14159 * (duct_diameter_m * 0.5) * (duct_diameter_m * 0.5)
	var velocity_m_s = (fan_speed_rpm / 60.0) * 0.1
	return area * velocity_m_s


## Verifies if air particulate purity level is safe for cleanroom access.
static func verify_decontamination_air_purity_index(particulate_count_ppm: float, max_ppm: float = 0.05) -> bool:
	return particulate_count_ppm <= max_ppm


## Verifies if power grid load remains below maximum trip tolerance.
static func verify_decontamination_power_relay_grid_load(current_load_kw: float, max_tolerance_kw: float = 180.0) -> bool:
	return current_load_kw >= 0.0 and current_load_kw <= max_tolerance_kw


## Calculates estimated battery backup runtime in hours.
static func calculate_battery_backup_runtime_hours(capacity_kwh: float, discharge_load_kw: float) -> float:
	if discharge_load_kw <= 0.0:
		return 999.0
	return (capacity_kwh * 0.90) / discharge_load_kw


## Verifies if pneumatic vent actuator response latency is within safe operational limits.
static func verify_decontamination_vent_actuator_latency(latency_ms: float, max_permissible_ms: float = 600.0) -> bool:
	return latency_ms >= 0.0 and latency_ms <= max_permissible_ms


## Verifies if emergency flush override keycode matches authorized protocol.
static func verify_decontamination_emergency_flush_trigger(override_code: String) -> bool:
	return override_code.strip_edges().to_upper() == "HALON-OVERRIDE-99"


## Calculates air purge vent discharge velocity in m/s over time.
static func calculate_airlock_purge_velocity_profile(elapsed_sec: float, max_velocity_m_s: float = 14.5, tau_sec: float = 1.2) -> float:
	if elapsed_sec <= 0.0 or tau_sec <= 0.0:
		return 0.0
	return max_velocity_m_s * (1.0 - exp(-elapsed_sec / tau_sec))


## Calculates expanded gas volume in m3 from liquid nitrogen in liters.
static func calculate_nitrogen_expansion_volume(liquid_liters: float) -> float:
	if liquid_liters <= 0.0:
		return 0.0
	return liquid_liters * 0.696


## Calculates remaining HEPA air filter cartridge lifespan in percent.
static func calculate_hepa_filter_remaining_lifespan_pct(operating_hours: float, surges: int = 0) -> float:
	var wear = (operating_hours * 0.045) + (surges * 2.5)
	return max(0.0, 100.0 - wear)


## Calculates vacuum safety relief valve discharge flow rate in CFM.
static func calculate_vacuum_relief_flow_cfm(overpressure_psi: float, max_psi: float = 18.5, max_cfm: float = 850.0) -> float:
	if max_psi <= 0.0 or overpressure_psi <= 0.0:
		return 0.0
	return max_cfm * (clamp(overpressure_psi, 0.0, max_psi) / max_psi)


## Calculates analog pressure transducer output signal voltage [1.0V - 10.0V].
static func calculate_transducer_output_volts(current_torr: float, max_torr: float = 760.0) -> float:
	if max_torr <= 0.0:
		return 1.0
	return 1.0 + (9.0 * (clamp(current_torr, 0.0, max_torr) / max_torr))


## Calculates telemetry stream data throughput in bytes per second.
static func calculate_telemetry_throughput_bytes_sec(frame_bytes: int = 32, rate_hz: float = 60.0) -> float:
	return float(max(0, frame_bytes)) * max(0.0, rate_hz)


## Verifies telemetry packet CRC-16 checksum integrity.
static func verify_telemetry_crc16_checksum(raw_bytes: PackedByteArray, expected_crc: int) -> bool:
	if raw_bytes.size() == 0:
		return expected_crc == 0xFFFF
	var crc = 0xFFFF
	for b in raw_bytes:
		crc ^= b
		for i in range(8):
			if (crc & 0x0001) != 0:
				crc = (crc >> 1) ^ 0xA001
			else:
				crc = crc >> 1
	return crc == expected_crc


## Calculates exponential backoff retransmit timeout in milliseconds.
static func calculate_retransmit_timeout_ms(attempt: int, base_rtt_ms: float = 16.67) -> float:
	var backoff = pow(1.5, max(0, attempt))
	return min(150.0, base_rtt_ms * backoff)


## Calculates pressure transducer bus power consumption in Watts.
static func calculate_transducer_power_consumption_watts(active_amps: float = 0.045, idle_amps: float = 0.012, volts: float = 24.0) -> float:
	return (max(0.0, active_amps) + max(0.0, idle_amps)) * max(0.0, volts)


## Verifies pressure transducer operating temperature thermal safety limit.
static func verify_transducer_operating_temperature_safe(temp_celsius: float, max_temp: float = 85.0) -> bool:
	return temp_celsius < (max_temp - 5.0)


## Calculates natural convection thermal cooldown time in seconds.
static func calculate_thermal_cooldown_time_sec(start_temp: float, target_temp: float = 75.0, ambient_temp: float = 21.0, tau_sec: float = 14.5) -> float:
	if start_temp <= target_temp or target_temp <= ambient_temp:
		return 0.0
	return tau_sec * log((start_temp - ambient_temp) / (target_temp - ambient_temp))


## Verifies natural convection thermal cooldown time bounds [0.0s - 120.0s].
static func verify_thermal_cooldown_time_in_bounds(start_temp: float, max_window_sec: float = 120.0) -> bool:
	var t = calculate_thermal_cooldown_time_sec(start_temp)
	return t >= 0.0 and t <= max_window_sec
