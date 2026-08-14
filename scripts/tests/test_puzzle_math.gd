extends RefCounted
class_name TestPuzzleMath

## Isolated Unit Test helper for verifying code sequence validation and math utilities.
## Runs in memory without affecting gameplay scenes or runtime nodes.

static func verify_sequence_code(input_code: String, target_code: String) -> bool:
	var clean_input = input_code.strip_edges().to_upper()
	var clean_target = target_code.strip_edges().to_upper()
	return clean_input == clean_target


static func calculate_signal_attenuation(distance: float, base_power: float) -> float:
	if distance <= 0.0:
		return base_power
	var factor = 1.0 / (1.0 + (distance * 0.05))
	return base_power * factor


static func run_all_unit_tests() -> Dictionary:
	var results = {
		"sequence_match": verify_sequence_code("theta-7", "THETA-7"),
		"sequence_mismatch": not verify_sequence_code("alpha-1", "THETA-7"),
		"attenuation_close": abs(calculate_signal_attenuation(0.0, 100.0) - 100.0) < 0.001,
		"attenuation_far": calculate_signal_attenuation(20.0, 100.0) < 100.0,
		"harmonic_exact": abs(calculate_frequency_harmonic_delta(440.0, 440.0)) < 0.001,
		"phase_aligned": abs(calculate_phase_shift_offset(180.0, 180.0)) < 0.001,
		"phase_locked": verify_signal_phase_lock(2.1),
		"ratio_fundamental": abs(calculate_resonant_harmonic_ratio(880.0, 440.0) - 2.0) < 0.001,
		"attenuation_in_bounds": verify_signal_attenuation_bounds(50.0),
		"distortion_calculated": calculate_signal_distortion_vector(Vector3.ONE, 0.5).length() > Vector3.ONE.length(),
		"frequency_matched": verify_signal_resonance_frequency_match(440.0, 441.2),
		"energy_positive": calculate_harmonic_resonance_energy(1.0, 440.0) > 0.0,
		"phase_cancelled": verify_harmonic_phase_cancellation(178.5),
		"antinode_positive": calculate_acoustic_standing_wave_antinode(1) > 0.0,
		"echo_aligned": verify_acoustic_echo_delay_alignment(242.0),
		"doppler_valid": calculate_doppler_pitch_scale(5.0, 0.0) > 1.0,
		"thermal_suit_drain_positive": calculate_thermal_suit_drain_rate(-40.0) > 0.12,
		"drill_penetration_positive": calculate_ice_core_drill_penetration_rate(50.0) > 0.0,
		"mesh_bone_scale_valid": verify_character_mesh_bone_scale(Vector3.ONE),
		"thruster_pitch_valid": verify_thruster_audio_pitch_in_bounds(0.5),
		"thruster_flash_positive": calculate_thruster_flash_light_energy(0.8) > 0.0,
		"thruster_flare_positive": calculate_thruster_lens_flare_scale(0.8).length() > 0.0,
		"thruster_plume_trail_positive": calculate_thruster_plume_trail_length_meters(12.5, 0.45) > 0.0,
		"thruster_plume_bounds_valid": verify_thruster_plume_trail_length_in_bounds(12.5, 0.45),
		"thruster_plume_trail_valid_test": verify_thruster_plume_trail_length_valid(12.5, 0.45),
		"thruster_omni_range_positive": calculate_thruster_light_omni_range_meters(0.8) > 0.0,
		"thruster_omni_range_bounds": verify_thruster_light_omni_range_in_bounds(0.8)
	}
	return results


## Calculates absolute delta between input frequency and target resonant harmonic (default 440 Hz).
static func calculate_frequency_harmonic_delta(input_hz: float, target_hz: float = 440.0) -> float:
	return abs(input_hz - target_hz)


## Calculates normalized phase offset delta in degrees [0 - 180].
static func calculate_phase_shift_offset(phase_a: float, phase_b: float) -> float:
	var diff = abs(phase_a - phase_b)
	return fmod(diff, 180.0)


## Verifies if phase offset angle is within locked tolerance (default ±5.0 deg).
static func verify_signal_phase_lock(phase_offset_deg: float, tolerance_deg: float = 5.0) -> bool:
	return abs(phase_offset_deg) <= tolerance_deg


## Calculates frequency ratio relative to base fundamental harmonic.
static func calculate_resonant_harmonic_ratio(freq_hz: float, base_hz: float = 440.0) -> float:
	if base_hz <= 0.0:
		return 1.0
	return freq_hz / base_hz


## Verifies if attenuated signal power remains within operational threshold bounds.
static func verify_signal_attenuation_bounds(power: float, min_power: float = 10.0, max_power: float = 100.0) -> bool:
	return power >= min_power and power <= max_power


## Calculates distorted signal vector based on crystal proximity factor.
static func calculate_signal_distortion_vector(base_vector: Vector3, distortion_factor: float) -> Vector3:
	return base_vector * (1.0 + clamp(distortion_factor, 0.0, 2.0))


## Calculates phase resonance quality index [0.0 - 1.0].
static func calculate_phase_resonance_index(phase_deg: float, harmonic_ratio: float) -> float:
	var phase_factor = 1.0 - (clamp(abs(phase_deg), 0.0, 180.0) / 180.0)
	var ratio_factor = clamp(harmonic_ratio, 0.5, 2.0)
	return phase_factor * ratio_factor


## Verifies if two signal frequencies match within max delta tolerance.
static func verify_signal_resonance_frequency_match(freq_a: float, freq_b: float, max_delta_hz: float = 2.0) -> bool:
	return abs(freq_a - freq_b) <= max_delta_hz


## Calculates total acoustic resonance energy output.
static func calculate_harmonic_resonance_energy(amplitude: float, frequency_hz: float) -> float:
	return 0.5 * amplitude * (frequency_hz * frequency_hz)


## Verifies if phase offset angle approaches destructive cancellation (~180 deg).
static func verify_harmonic_phase_cancellation(phase_deg: float, tolerance_deg: float = 10.0) -> bool:
	return abs(180.0 - fmod(abs(phase_deg), 360.0)) <= tolerance_deg


## Calculates antinode position along standing wave axis in meters.
static func calculate_acoustic_standing_wave_antinode(node_index: int, wavelength_m: float = 0.777) -> float:
	return (node_index + 0.5) * (wavelength_m * 0.5)


## Verifies if acoustic echo delay matches target node timing within tolerance.
static func verify_acoustic_echo_delay_alignment(delay_ms: float, target_delay_ms: float = 240.0, max_delta_ms: float = 5.0) -> bool:
	return abs(delay_ms - target_delay_ms) <= max_delta_ms


## Calculates Doppler effect audio pitch scale factor.
static func calculate_doppler_pitch_scale(v_listener: float, v_source: float, speed_of_sound: float = 343.0) -> float:
	var denominator = speed_of_sound - v_source
	if abs(denominator) < 0.001:
		return 1.0
	var scale_factor = (speed_of_sound + v_listener) / denominator
	return clamp(scale_factor, 0.5, 2.0)


## Verifies if synthesized crystal fundamental and second harmonic frequency alignment is valid.
static func verify_crystal_resonance_harmonics_within_range(fund_hz: float, second_hz: float) -> bool:
	return abs(fund_hz - 440.0) <= 2.0 and abs(second_hz - 880.0) <= 4.0


## Calculates thermal suit life support power drain rate in MW.
static func calculate_thermal_suit_drain_rate(ambient_temp_c: float, target_temp_c: float = 20.0, baseline_mw: float = 0.12) -> float:
	var delta_t = abs(target_temp_c - ambient_temp_c)
	return baseline_mw * (1.0 + (delta_t * 0.05))


## Calculates sub-surface ice drill penetration rate in mm/sec.
static func calculate_ice_core_drill_penetration_rate(torque_nm: float, rpm: float = 1800.0, hardness_coeff: float = 4.8) -> float:
	if hardness_coeff <= 0.0:
		return 0.0
	return (torque_nm * rpm) / (hardness_coeff * 1000.0)


## Calculates camera shake trauma decay over frame delta.
static func calculate_seismic_shake_trauma_decay(current_trauma: float, delta_sec: float, decay_rate: float = 0.75) -> float:
	return max(0.0, current_trauma - (decay_rate * delta_sec))


## Verifies character mesh normalization scale vector.
static func verify_character_mesh_bone_scale(scale_vec: Vector3) -> bool:
	return scale_vec.x > 0.0 and scale_vec.y > 0.0 and scale_vec.z > 0.0


## Calculates cold-gas thruster jet particle velocity vector.
static func calculate_thruster_jet_particle_impulse(direction_normal: Vector3, thrust_pct: float, base_speed: float = 12.5) -> Vector3:
	var speed = base_speed * (1.0 + (clamp(thrust_pct, 0.0, 1.0) * 0.5))
	return -1.0 * direction_normal.normalized() * speed


## Verifies cold-gas thruster audio pitch scale factor [0.85 - 1.45].
static func verify_thruster_audio_pitch_in_bounds(thrust_pct: float) -> bool:
	var pitch = lerp(0.85, 1.45, clamp(thrust_pct, 0.0, 1.0))
	return pitch >= 0.85 and pitch <= 1.45


## Calculates thruster light flash energy magnitude.
static func calculate_thruster_flash_light_energy(thrust_pct: float, max_energy: float = 2.8) -> float:
	return max_energy * clamp(thrust_pct, 0.0, 1.0)


## Calculates anamorphic thruster lens flare scale vector.
static func calculate_thruster_lens_flare_scale(thrust_pct: float, base_scale: float = 0.35) -> Vector3:
	var s = base_scale * (0.8 + (clamp(thrust_pct, 0.0, 1.0) * 0.7))
	return Vector3(s * 1.8, s * 0.45, s)


## Verifies anamorphic lens flare scale bounds.
static func verify_thruster_lens_flare_scale_in_bounds(thrust_pct: float) -> bool:
	var scale_vec = calculate_thruster_lens_flare_scale(thrust_pct)
	return scale_vec.x > 0.0 and scale_vec.y > 0.0 and scale_vec.z > 0.0


## Calculates cold-gas thruster particle plume trail length in meters.
static func calculate_thruster_plume_trail_length_meters(particle_speed_m_s: float = 12.5, lifetime_sec: float = 0.45) -> float:
	return max(0.0, particle_speed_m_s) * max(0.0, lifetime_sec)


## Verifies cold-gas thruster particle plume trail length bounds [0.0m - 10.0m].
static func verify_thruster_plume_trail_length_in_bounds(speed_m_s: float, lifetime_sec: float) -> bool:
	var len_m = calculate_thruster_plume_trail_length_meters(speed_m_s, lifetime_sec)
	return len_m >= 0.0 and len_m <= 10.0


## Verifies cold-gas thruster particle plume trail length calculation.
static func verify_thruster_plume_trail_length_valid(speed_m_s: float, lifetime_sec: float) -> bool:
	return calculate_thruster_plume_trail_length_meters(speed_m_s, lifetime_sec) > 0.0


## Calculates cold-gas thruster omni light illumination range in meters.
static func calculate_thruster_light_omni_range_meters(thrust_pct: float, base_range: float = 4.5) -> float:
	return base_range * (0.7 + (clamp(thrust_pct, 0.0, 1.0) * 0.8))


## Verifies cold-gas thruster omni light illumination range bounds [0.0m - 12.0m].
static func verify_thruster_light_omni_range_in_bounds(thrust_pct: float) -> bool:
	var r = calculate_thruster_light_omni_range_meters(thrust_pct)
	return r >= 0.0 and r <= 12.0


## Calculates cold-gas thruster screen shockwave ring radius in meters.
static func calculate_thruster_shockwave_radius_meters(age_sec: float, base_radius: float = 0.1, speed: float = 12.5) -> float:
	return base_radius * (1.0 + (max(0.0, age_sec) * speed))
# wakatime_sync
