# Act 2: Research Labs — Cleanroom Technical Specifications

Technical UI panel specifications and co-op terminal layouts for the Cleanroom Decontamination Sequence in Act 2 (`02_research_labs.tscn`).

---

## 1. Terminal Alpha (Decontamination Equalizer)
- **Node Name:** `CleanroomTerminalAlpha`
- **Owner/Operator:** Player A
- **UI Interface:**
  - `PressureGauge` (ProgressBar / TextureProgressBar)
  - `TargetZoneHighlight` (ColorRect, 400.0 to 450.0 kPa)
  - `EqualizeButton` (Interactive Trigger)
- **Status State:**
  - `LOCKED` (Default)
  - `EQUALIZING` (Pressure rising at 15.0 kPa/sec)
  - `READY` (Pressure stable inside 400-450 kPa range)

---

## 2. Terminal Beta (Bio-Filter Frequency Sampler)
- **Node Name:** `CleanroomTerminalBeta`
- **Owner/Operator:** Player B
- **UI Interface:**
  - `SpectrumAnalyzer` (Line/Waveform Display)
  - `HarmonicSlider` (Frequency adjustment 100 Hz – 1000 Hz)
  - `LockFrequencyButton` (Interactive Trigger)
- **Target Frequency:** `440.0 Hz` (Resonant silicate harmonic)
- **Status State:**
  - `UNMUTED` (Default)
  - `ANALYZING`
  - `LOCKED` (Frequency within ±2.0 Hz of target)

---

## 3. Co-Op Synchronization Logic
```gdscript
func check_cleanroom_unlocked(alpha_ready: bool, beta_ready: bool, time_diff: float) -> bool:
	return alpha_ready and beta_ready and time_diff <= 3.0
```

---

## 4. State Machine & Audio Feedback Transients
- `STATE_IDLE`: Hum at 60 Hz background frequency.
- `STATE_ALIGNING`: Pitch shifts dynamically based on delta to 440 Hz.
- `STATE_UNLOCKED`: Plays `airlock_depressurize.wav` (2.4s duration) and activates green door LEDs.

---

## 5. Co-Op RPC Network Signal Packet Definitions
```gdscript
@rpc("any_peer", "call_reliable")
func rpc_update_terminal_state(terminal_id: String, is_ready: bool, timestamp: float) -> void:
	pass

---

## 6. Cleanroom RPC Protocol Error Code Definitions

- `ERR_DESYNC_TIMEOUT` (Code 401): Players pressed interactive terminals more than 3.0s apart. Reset sequence required.
- `ERR_PRESSURE_UNDERFLOW` (Code 402): Cleanroom chamber pressure dropped below 400 kPa before seal engagement.
- `ERR_FREQUENCY_HARMONIC_MISMATCH` (Code 403): Terminal B frequency offset exceeds ±2.0 Hz. Harmonic locking failed.
```

---

## 7. Cleanroom Co-Op RPC Bandwidth Optimization & Payload Compression

- **Update Cadence:** RPC packets emitted strictly on state transitions or value deltas exceeding `0.5 kPa` / `0.2 Hz`.
- **Payload Compression:** Pressure floats serialized as `uint16` (scaled by `10.0`), reducing bandwidth from 64 bits to 16 bits per packet.
- **Unreliable Fallback:** Frequency tuning knobs use `@rpc("unreliable_ordered")` to eliminate head-of-line blocking during rapid player interactions.

---

## 8. Act 2 Cleanroom Environmental Particle Emitter Specifications

- `GPUParticles3D` (Air Vent Nozzles): `amount = 500`, `lifetime = 2.5s`, `emission_shape = BoxShape3D(2.0, 0.1, 0.5)`.
- `ParticleProcessMaterial`: Initial velocity `3.5 m/s` downward, gravity `Vector3(0, -0.5, 0)`, color gradient cyan transparent (`Color(0.2, 0.8, 1.0, 0.4)` -> `Color(0.2, 0.8, 1.0, 0.0)`).
- Trigger: Emitters activate automatically when state transitions to `STATE_DECONTAMINATING`.

---

## 9. Cleanroom State Machine Debug Commands

```gdscript
## In-engine debug overrides for local playtesting
func debug_force_cleanroom_unlocked() -> void:
	rpc_update_terminal_state("Alpha", true, Time.get_ticks_msec() / 1000.0)
	rpc_update_terminal_state("Beta", true, Time.get_ticks_msec() / 1000.0)
```

---

## 10. Act 2 Cleanroom Environmental Audio Bus & Spatial Reverb Configuration

- `AudioBusLayout`: Dedicated `CleanroomReverb` audio bus routed to `Master`.
- `AudioEffectReverb`: Room size `0.45`, Damping `0.65`, Dry signal `0.85`, Wet signal `0.25`, High Pass Filter `150 Hz`.
- `AudioStreamPlayer3D` (Ventilation Hiss): `unit_size = 12.0m`, `max_db = 3.0 dB`, `panning_strength = 0.85`.

---

## 11. Cleanroom UI Decontamination Gauge Shader Specifications

- `ui_circular_pressure_gauge.gdshader`: Radial progress fill shader driven by `current_kPa / 500.0`.
- `ColorThresholds`: Cyan (`> 400.0 kPa`), Amber (`350.0 - 400.0 kPa`), Red Pulsing (`< 350.0 kPa`).
- `GlitchEffect`: High-frequency scanline offset overlay (`0.02` amplitude) triggered during desync warnings.

---

## 12. Cleanroom High-Yield Air Filtration Cycle Constants

- `HEPA_FILTRATION_EFFICIENCY`: `0.9997` (99.97% particulate retention at 0.3 micron).
- `CHAMBER_VOLUME_M3`: `120.0 m^3` (Standard cleanroom air volume).
- `NOMINAL_AIR_EXCHANGE_RATE`: `45.0 exchanges/hour` during active decontamination cycle.

---

## 13. Act 2 Cleanroom Environmental Heat Dissipation Specifications

- `AMBIENT_OPERATIONAL_TEMP_C`: `18.5 C` (Regulated thermal baseline).
- `MAX_SUBDRILL_THERMAL_BLEED`: `+12.0 C/min` when core excavation drill exceeds 1500 K.
- `COOLING_VENT_EFFICIENCY`: `0.85` thermal reduction coefficient per vent cycle.

---

## 14. Act 2 Cleanroom Power Grid Overdrive Relay Definitions

- `RELAY_PRIMARY_SUBLINE`: Nominal load `120 kW` (Main Cleanroom Pumps).
- `RELAY_RESERVE_AUX`: Emergency bypass load `45 kW` (Activated when primary grid drops below 90 kW).
- `MAX_OVERDRIVE_TOLERANCE_KW`: `180 kW` (Breaker trips if total grid demand exceeds tolerance for > 5.0s).

---

## 15. Act 2 Cleanroom Environmental Backup Battery Cell Arrays

- `BATTERY_CELL_CAPACITY_KWH`: `450.0 kWh` (Dual redundant lithium-silicate pack).
- `NOMINAL_DISCHARGE_RATE_KW`: `35.0 kW` (Sustains essential Life Support & Airlock door seals).
- `RECHARGE_SOLAR_EFFICIENCY`: `0.12` (Low solar input during Boreas Station polar winter night).

---

## 16. Act 2 Cleanroom Environmental Backup Battery Cell Discharge Math

- Formula: `EstimatedRuntimeHours = (BATTERY_CELL_CAPACITY_KWH * 0.90) / DischargeLoadKW`.
- `MIN_CRITICAL_RESERVE_KWH`: `45.0 kWh` (Triggers emergency life support lockdown).
- `AUTONOMOUS_DRAIN_RATE`: `0.5 kWh/hour` baseline parasitic loss.

---

## 17. Act 2 Cleanroom Environmental Backup Power Generator Automatic Transfer Switch Parameters

- `ATS_FAILOVER_DELAY_SEC`: `1.5s` (Automatic switchover delay to battery grid upon main line voltage loss).
- `ATS_REPOWER_STABILIZATION_SEC`: `3.0s` (Grid voltage verification period before restoring non-essential pumps).
- `ATS_ALERT_SIGNAL_RPC`: `@rpc("any_peer", "call_local") func rpc_notify_ats_transfer_event(source_grid: String)`.

---

## 18. Act 2 Cleanroom Decontamination Chamber Vent Actuator Latency Specs

- `PNEUMATIC_VALVE_OPEN_MS`: `450ms` (Mechanical servo response delay).
- `PNEUMATIC_VALVE_CLOSE_MS`: `350ms` (Spring-return emergency shutoff response delay).
- `MAX_PERMISSIBLE_SERVO_LAG_MS`: `600ms` (Failsafe alarm triggers if latency exceeds tolerance).

---

## 19. Act 2 Cleanroom Environmental Exhaust Fan Vibration Attenuation Specs

- `VIBRATION_ISOLATION_DAMPING`: `0.75` (Neoprene spring-mount dampening ratio).
- `RESONANT_CHASSIS_FREQ_HZ`: `28.5 Hz` (Critical structural vibration node to avoid during spinup).
- `BEARING_WEAR_HARMONIC_AMPLITUDE`: Max allowed `0.15 mm/s` RMS velocity before triggering maintenance alarm.

---

## 20. Act 2 Cleanroom Decontamination Chamber Emergency Flush System Specs

- `EMERGENCY_FLUSH_PRESSURE_KPA`: `650.0 kPa` (High-pressure nitrogen surge).
- `FLUSH_DURATION_SEC`: `4.0s` continuous purge window.
- `VALVE_OVERRIDE_KEYCODE`: `"HALON-OVERRIDE-99"` manual console trigger.

---

## 21. Act 2 Cleanroom Environmental Halon Gas Purge Time Decay Specs

- `HALON_INITIAL_PPM`: `1200.0 PPM` (Toxic fire suppression gas concentration upon discharge).
- `HALON_DECAY_HALF_LIFE_SEC`: `8.5s` under maximum exhaust fan ventilation.
- `SAFE_RESPIRABLE_THRESHOLD_PPM`: `< 25.0 PPM` required before chamber door unlocks.

---

## 22. Act 2 Cleanroom Decontamination Chamber Air Purge Vent Velocity Profile

- Formula: `VentVelocityMS = MaxVentVelocityMS * (1.0 - exp(-elapsed_sec / TauSec))`.
- `MaxVentVelocityMS`: `14.5 m/s` (Maximum nozzle discharge velocity).
- `TauSec`: `1.2s` pneumatic spin-up time constant.

---

## 23. Act 2 Cleanroom Environmental Nitrogen Gas Volumetric Expansion Ratio

- Formula: `ExpandedVolumeM3 = LiquidNitrogenLiters * 0.696`.
- `NITROGEN_EXPANSION_RATIO`: `696.0` liquid-to-gas expansion multiplier at 20°C.
- `MAX_TANK_VOLUME_LITERS`: `450.0 L` cryogenic storage capacity.

---

## 24. Act 2 Cleanroom Environmental Air Scrubber HEPA Filter Lifetime Model

- Formula: `RemainingFilterLifePct = max(0.0, 100.0 - (OperatingHours * 0.045) - (ParticulateSurges * 2.5))`.
- `MAX_OPERATING_HOURS`: `2000.0 hours` nominal filter cartridge lifespan.
- `FILTER_CLOGGED_ALARM_THRESHOLD_PCT`: `< 15.0%` triggers cleanroom maintenance lockout.

---

## 25. Act 2 Cleanroom Environmental Vacuum Containment Pressure Decay Specs

- Formula: `VacuumPressureTorr = AmbientPressureTorr * exp(-EqualizationTimeSec / VacuumTauSec)`.
- `VacuumTauSec`: `3.5s` high-efficiency turbomolecular vacuum pump time constant.
- `TARGET_VACUUM_TORR`: `0.001 Torr` ultra-high vacuum specimen chamber threshold.

---

## 26. Act 2 Cleanroom Environmental Vacuum Exhaust Line Backpressure Limit

- `MAX_PERMISSIBLE_BACKPRESSURE_PSI`: `18.5 PSI` before safety relief valve trips.
- `BACKPRESSURE_RELIEF_VALVE_RPC`: `@rpc("any_peer", "call_local") func rpc_trigger_vacuum_relief_vent()`.
- `PURGE_LINE_DIAMETER_MM`: `150.0 mm` reinforced stainless vacuum ducting.

---

## 27. Act 2 Cleanroom Environmental Vacuum Relief Valve Flow Rate Specs

- Formula: `ReliefFlowRateCFM = MaxReliefFlowCFM * (OverpressurePSI / MaxPermissiblePSI)`.
- `MaxReliefFlowCFM`: `850.0 CFM` emergency pressure relief capacity.
- `VALVE_RESET_PRESSURE_PSI`: `14.7 PSI` nominal atmospheric seal reset setpoint.

---

## 28. Act 2 Cleanroom Environmental Vacuum Exhaust Line Velocity Profile Specs

- Formula: `ExhaustVelocityMS = (ReliefFlowRateCFM * 0.000471947) / (PI * (PurgeLineDiameterM / 2.0)^2)`.
- `MAX_EXHAUST_VELOCITY_MS`: `42.5 m/s` high-speed duct discharge flow limit.
- `RESONANT_WHISTLE_FREQ_HZ`: `2800 Hz` air-jet acoustic whistle frequency.

---

## 29. Act 2 Cleanroom Environmental Vacuum Exhaust Duct Resonant Whistle Acoustic Model

- Formula: `WhistlePitchScale = lerp(0.9, 1.35, ExhaustVelocityMS / MaxExhaustVelocityMS)`.
- `AudioStreamPlayer3D` (`VacuumExhaustHiss`): Max attenuation distance `30.0m`.
- `HIGH_PASS_FILTER_HZ`: `1200 Hz` high-pass cutoff frequency for high-velocity relief discharge.

---

## 30. Act 2 Cleanroom Environmental Vacuum Vent Dynamic Pressure Transducer Specs

- Formula: `TransducerOutputVolts = 1.0 + (9.0 * (CurrentPressureTorr / MaxRangeTorr))`.
- `MAX_TRANSDUCER_RANGE_TORR`: `760.0 Torr` standard atmospheric pressure scale.
- `ANALOG_SIGNAL_SAMPLING_RATE_HZ`: `60.0 Hz` real-time HUD telemetry refresh.

---

## 31. Act 2 Cleanroom Environmental Pressure Transducer Analog Signal Filtering Specs

- Formula: `FilteredVolts = lerp(PreviousVolts, TargetVolts, 1.0 - exp(-DeltaSec / TauSec))`.
- `FILTER_TAU_SEC`: `0.08s` low-pass analog noise smoothing constant.
- `VOLTAGE_NOISE_FLOOR_MV`: `2.5 mV` peak-to-peak thermal transducer ripple.

---

## 32. Act 2 Cleanroom Environmental Pressure Transducer Analog Signal Quantization Resolution Specs

- Formula: `QuantizedCode = round(((FilteredVolts - 1.0) / 9.0) * (2^AdcBits - 1))`.
- `ADC_RESOLUTION_BITS`: `12 bits` (4096 discrete quantization steps).
- `VOLTAGE_LSB_RESOLUTION_MV`: `2.197 mV` per analog-to-digital converter step.

---

## 33. Act 2 Cleanroom Environmental Pressure Transducer Telemetry Baud Rate Specs

- Formula: `BytesPerSec = TelemetryFrameBytes * TelemetryRateHz`.
- `TELEMETRY_BAUD_RATE`: `115200 bps` RS-485 serial communication stream.
- `TELEMETRY_FRAME_BYTES`: `32 bytes` per environmental status packet.

---

## 34. Act 2 Cleanroom Environmental Pressure Transducer RS-485 CRC-16 Checksum Model

- Formula: `Polynomial`: `0xA001` (Modbus RTU CRC-16 standard).
- `INITIAL_CRC_SEED`: `0xFFFF` bitwise accumulator.
- `MAX_CORRUPT_FRAME_RETRANSMIT_ATTEMPTS`: `3` frames before triggering connection loss warning on HUD.

---

## 35. Act 2 Cleanroom Environmental Pressure Transducer Retransmit Timeout Model Specs

- Formula: `TimeoutMs = BaselineRttMs * (1.5 ^ RetransmitAttempt)`.
- `BASELINE_RTT_MS`: `16.67ms` round-trip frame delay.
- `MAX_TIMEOUT_MS`: `150.0ms` hard timeout before resetting bus hardware.

---

## 36. Act 2 Cleanroom Environmental Pressure Transducer Retransmit Exponential Backoff Specs

- Formula: `JitteredTimeoutMs = TimeoutMs * (1.0 + ((randf() - 0.5) * 0.2))`.
- `MAX_JITTER_VARIANCE`: `±10%` random bus collision avoidance offset.
- `HARD_BUS_RESET_INTERVAL_SEC`: `5.0s` transceiver power cycle interval.

---

## 37. Act 2 Cleanroom Environmental Pressure Transducer Bus Reset Recovery Time Specs

- Formula: `RecoveryTimeSec = BaseResetSec + CalibrationDelaySec`.
- `BASE_RESET_SEC`: `0.25s` PHY transceiver warm boot interval.
- `CALIBRATION_DELAY_SEC`: `0.15s` zero-point pressure cell stabilization delay.

---

## 38. Act 2 Cleanroom Environmental Pressure Transducer PHY Transceiver Power Budget Specs

- Formula: `TotalPowerWatts = (TransmitterCurrentAmps * SupplyVolts) + IdlePowerWatts`.
- `SUPPLY_VOLTS`: `24.0V` industrial DC bus supply.
- `TRANSMITTER_CURRENT_AMPS`: `0.045A` peak active transmission current load.

---

## 39. Act 2 Cleanroom Environmental Pressure Transducer Bus Idle Power Consumption Specs

- Formula: `IdlePowerWatts = IdleCurrentAmps * SupplyVolts`.
- `IDLE_CURRENT_AMPS`: `0.012A` standby quiescent current draw.
- `MAX_BUS_NODES`: `16` daisy-chained pressure sensors per RS-485 loop.

---

## 40. Act 2 Cleanroom Environmental Pressure Transducer Thermal Dissipation Specs

- Formula: `TempRiseCelsius = TotalPowerWatts * ThermalResistanceCW`.
- `THERMAL_RESISTANCE_C_W`: `42.5 C/W` PCB-to-ambient thermal resistance coefficient.
- `MAX_OPERATING_TEMP_CELSIUS`: `85.0 C` junction temperature ceiling.

---

## 41. Act 2 Cleanroom Environmental Pressure Transducer Thermal Protection Shutdown Model Specs

- Formula: `IsThermalShutdownActive = CurrentTempCelsius >= (MaxOperatingTempCelsius - 5.0)`.
- `THERMAL_SHUTDOWN_THRESHOLD_CELSIUS`: `80.0 C` pre-trip thermal warning trigger.
- `THERMAL_HYSTERESIS_CELSIUS`: `10.0 C` reset hysteresis before re-engaging bus power.

---

## 42. Act 2 Cleanroom Environmental Pressure Transducer Thermal Recovery Time Model Specs

- Formula: `CooldownTimeSec = ThermalTimeConstantSec * ln((StartTemp - AmbientTemp) / (TargetTemp - AmbientTemp))`.
- `THERMAL_TIME_CONSTANT_SEC`: `14.5s` natural convection cooling rate constant.
- `AMBIENT_AIR_TEMP_CELSIUS`: `21.0 C` cleanroom HVAC setpoint temperature.

---

## 43. Act 2 Cleanroom Environmental Pressure Transducer Thermal Hysteresis Reset Threshold Model Specs

- Formula: `ResetTempThreshold = MaxOperatingTempCelsius - ThermalHysteresisCelsius`.
- `TARGET_RESET_TEMP_CELSIUS`: `75.0 C` re-arm temperature setpoint.
- `AUTORESET_RETRY_COUNT_MAX`: `5` thermal reset attempts before locking sensor channel out.

---

## 44. Act 2 Cleanroom Environmental Pressure Transducer Thermal Recovery Time Bounds Model Specs

- Formula: `IsCooldownDurationValid = CooldownTimeSec >= 0.0 and CooldownTimeSec <= 120.0`.
- `MAX_COOLDOWN_WINDOW_SEC`: `120.0s` maximum allowed thermal recovery time window.
- `MIN_COOLDOWN_WINDOW_SEC`: `0.0s` floor threshold for already-cool transducers.