# Act 2: Research Labs — Narrative Lore & Dialogue Drafts

This document contains background narrative logs, character profiles, and dialogue scripts for Act 2 (`02_research_labs.tscn`).

---

## 1. Character Arcs & Lore Background

### Dr. Osei Farrow (Lead Researcher)
- **Role:** Chief Exobiologist & Station Director at Boreas Research Station.
- **Psychological Arc:**
  - *Phase 1 (Day 1-20):* Methodical scientific investigation. Standard spectroscopy and seismic impulse testing.
  - *Phase 2 (Day 21-45):* Discovery of organic-silicate crystal growth responding directly to human brainwaves and thermal activity.
  - *Phase 3 (Day 46-70):* Emotional attachment. Farrow begins addressing the crystalline entity directly in private logs.
  - *Phase 4 (Day 71+):* The Realization. Farrow discovers the entity is assimilating human consciousness non-violently. She attempts a mercy-kill blackout by overloading the sub-ice power grid, inadvertently stranding the crew.

### Callum Bray (Systems Specialist / Whistleblower)
- **Role:** Power Grid Analyst & Auxiliary Communications Officer.
- **Psychological Arc:**
  - Discovers secret encrypted transmissions sent by corporate off-site executives ordering the team to bypass containment protocols.
  - Attempts to broadcast a distress signal warning off-site vessels before his terminal access is revoked.

---

## 2. Act 2 Audio & Terminal Log Transcripts

### Log #201: Encrypted Terminal (Science Lab Core)
> **[TRANSCRIPT — Dr. Osei Farrow, Day 34]**
> *"The containment field isn't holding because it isn't a physical pressure issue. The crystal structure is lattice-matching our neural signals. When Callum entered the cleanroom today, the signal resonance spiked 400%. It wasn't attacking him... it was attempting to synchronize."*

### Log #202: Maintenance Access Terminal (Sub-Level B)
> **[TRANSCRIPT — Callum Bray, Day 52]**
> *"Corporate sent an automated override command this morning. They don't want us to seal the excavation site. They want us to increase power to the drill core. Farrow thinks she's communicating with a god, but corporate thinks they've found an infinite energy source. They're both blind."*

---

## 3. Co-Op Dialogue Sequences (Player A & Player B)

### Sequence 1: Entering the Research Lab Cleanroom
- **SALVAGER A:** *"Look at these glass partitions... they were reinforced with heavy lead lining. What were they keeping inside?"*
- **SALVAGER B:** *"Or what were they trying to keep out? Read the terminal on the central desk — Farrow's team was measuring neural impulses, not radiation."*

### Sequence 2: Discovering the First Black-Box Fragment
- **SALVAGER A:** *"I found a flight recorder fragment... it's scorched. The casing was melted from the inside out."*
- **SALVAGER B:** *"Hold on, the timestamp matches the exact minute the station went dark. We need the second half from the lower sub-level to decode the full audio log."*

---

## 4. Act 2 Puzzle Design: Cleanroom Decontamination Sequence

### Objective
Unseal the inner cleanroom airlock to access the main Research Lab Core.

### Co-Op Mechanics & Synchronization
1. **Player A (Decontamination Equalizer):** Must interact with Terminal Alpha to balance atmosphere pressure between 400–450 kPa.
2. **Player B (Bio-Filter Frequency Sampler):** Must interact with Terminal Beta to match the resonant frequency harmonic (440 Hz).
3. **Synchronization Window:** Both terminals must be confirmed within 3.0 seconds of each other. If window expires, pressure vents and resets.

### Puzzle Feedback & Audio Cues
- **Terminal Display Alpha:** Shows live pressure gauge and target zone.
- **Terminal Display Beta:** Shows live frequency spectrum.
- **Completion Cue:** Green status light flash, airlock depressurization sound, doors unlatch.

---

## 5. Act 2 Puzzle Design: Acoustic Resonance Alignment

### Objective
Synchronize the central crystal containment grid frequency to disable forcefield barriers around the primary sample core.

### Co-Op Mechanics
1. **Signal Disruptor Pulse:** Player A uses Signal Disruptor tool to emit a 440 Hz pulse at the central resonance emitter.
2. **Frequency Matcher:** Player B aligns the phase offset slider on the research console to match the wave amplitude.
3. **Outcome:** Forcefield drops for 45 seconds, permitting access to the main black-box audio fragment.

---

## 6. Act 2 Environmental Audio & Atmospheric Ambience

### Ambient Loops
- `cleanroom_ambient_hum.wav`: Low-frequency 60 Hz electrical hum with rhythmic air filtration hiss.
- `crystal_resonance_drone.wav`: Sub-bass 440 Hz acoustic vibration triggering subtle screen distortion.

### Dynamic Audio Triggers
- `bio_warning_alarm.wav`: Triggers when cleanroom pressure drops below 350 kPa.
- `airlock_seal_engage.wav`: Heavy mechanical latch SFX when both terminals validate synchronization.

---

## 7. Act 2 Environmental VFX & Lighting Specifications

### Cleanroom Lighting States
- `PRIMARY_ACTIVE`: Cyan/white 5000K fluorescent ceiling panels.
- `CONTAINMENT_ALERT`: Pulsing Amber (0.5 Hz) emergency strobe lighting.
- `DEPRESSURE_VENT`: Frost fog particle emitters activate at floor level.

### Volumetric Effects
- Volumetric fog density: `0.02` in cleanroom entry corridor, increasing to `0.08` in sub-surface excavation core.

---

## 8. Act 2 Environmental Audio Log Placement Locations (`02_research_labs.tscn`)

- **Log #203 (Cleanroom Decontamination):** Positioned on terminal desk in Cleanroom Airlock Alpha (`Vector3(-12.0, 0.4, -22.0)`).
- **Log #204 (Power Grid Bypass):** Positioned on wall console in Sub-Level Maintenance Access (`Vector3(-24.5, 0.6, -18.0)`).
- **Log #205 (Bio-Sensor Spectrum):** Positioned on primary research console in Core Laboratory (`Vector3(-30.0, 0.6, -32.0)`).
- **Log #206 (Containment Breach):** Positioned near damaged security barrier in Excavation Transit Bay (`Vector3(-38.0, 0.4, -40.0)`).

---

## 9. Act 2 Sub-Surface Excavation Bay Hazard Geometry (`02_research_labs.tscn`)

### Structural Collapse Debris Nodes
- `CollapsedBeam01`: RigidBody3D / StaticBody3D blocking Main Tunnel B (`Vector3(-28.0, 0.0, -25.0)`). Must be melted using Welding Torch.
- `CorrodedGrate02`: Interactable floor panel giving access to Sub-Level 3 conduit bypass.

### Crystalline Hazard Zones
- `CrystalSpireAlpha`: Emits periodic 15.0 damage pulse every 4.0s unless disrupted by Signal Disruptor (440 Hz pulse).

---

## 10. Act 2 Cleanroom Environmental Sound Effects Asset Inventory

- `sfx_cleanroom_decontam_loop.wav`: 44.1 kHz 16-bit stereo loop for high-pressure air jet cycle (12.0s duration).
- `sfx_airlock_pneumatic_release.wav`: Heavy pneumatic seal hiss on chamber depressurization (1.8s duration).
- `sfx_crystal_harmonic_ping.wav`: Resonant crystal response ping when hit by 440 Hz Signal Disruptor pulse (0.9s duration).

---

## 11. Act 2 Cleanroom Environmental Shading & Material Shaders

- `crystal_growth_shader.gdshader`: Dynamic rim-light emission shader driven by distance to nearest player.
- `frosted_glass_cleanroom.tres`: StandardMaterial3D with roughness `0.1`, metallic `0.8`, refractive index `1.45` for glass viewing chamber.
- `decontam_laser_grid.gdshader`: Pulsing cyan planar grid shader indicating active hazard boundary.

---

## 12. Act 2 Cleanroom Environmental Decals & Caution Markings

- `decal_caution_hazard_stripes.tscn`: Projected decal node along cleanroom floor threshold.
- `decal_station_logo_boreas.tscn`: Weathered Boreas Station emblem projected onto cleanroom glass wall.
- `decal_biohazard_symbol.tscn`: High-contrast yellow/black biohazard stencil near decontamination chamber entry.

---

## 13. Act 2 Cleanroom Environmental Post-Processing Effects

- `WorldEnvironment` (Cleanroom Volume): `glow_enabled = true`, `glow_bloom = 0.15`, `glow_blend_mode = GLOW_BLEND_MODE_SOFT`.
- `ChromaticAberration`: Intensity scales dynamically from `0.0` up to `0.05` when standing near high-frequency crystalline spires.
- `ColorCorrection`: Cold cyan color gradingLUT (`color_grading_cleanroom.png`) applied during decontamination cycle.

---

## 14. Act 2 Cleanroom Environmental Lighting Preset Configurations

- `OmniLight3D` (Decontam Nozzle Array): Energy `2.5`, Color `Color(0.1, 0.9, 1.0)`, Attenuation `1.5`, Range `6.0m`.
- `SpotLight3D` (Specimen Inspection Desk): Energy `4.0`, Color `Color(1.0, 0.95, 0.85)`, Spot Angle `35.0 deg`, Attenuation `1.0`.
- `DirectionalLight3D` (Sub-Surface Bore Shaft Fill): Energy `0.4`, Color `Color(0.05, 0.1, 0.2)`, Sky Mode `LIGHT_SKY_MODE_OFF`.

---

## 15. Act 2 Cleanroom Decontamination Alarm Audio Trigger Conditions

- `alarm_pressure_drop.wav`: Triggers when chamber pressure falls below 380.0 kPa (looped until pressure normalizes).
- `alarm_desync_warning.wav`: Plays single staccato chime when player interaction timestamps differ by > 2.0s.
- `alarm_chamber_sealed.wav`: Plays confirmation chime when both door locks engage simultaneously.

---

## 16. Act 2 Cleanroom Environmental Physics Materials & Footstep Surface Audio Mapping

- `physics_mat_metal_grate.tres`: Friction `0.7`, Restitution `0.1`, Surface SFX Group `FOOTSTEP_METAL_GRATE`.
- `physics_mat_cleanroom_tile.tres`: Friction `0.85`, Restitution `0.05`, Surface SFX Group `FOOTSTEP_POLISHED_TILE`.
- `physics_mat_subsurface_ice.tres`: Friction `0.25`, Restitution `0.2`, Surface SFX Group `FOOTSTEP_COMPACTED_ICE`.

---

## 17. Act 2 Environmental Camera Shake & Spatial Impulse Parameters

- `CameraImpulse` (Heavy Airlock Seal Release): Trauma `0.45`, Frequency `25.0 Hz`, Decay Rate `1.2`.
- `CameraImpulse` (Sub-Surface Drill Pulse): Trauma `0.2`, Frequency `10.0 Hz`, Decay Rate `0.8` (continuous periodic rumbling).
- `CameraImpulse` (Crystal Overdrive Shockwave): Trauma `0.85`, Frequency `40.0 Hz`, Decay Rate `2.5`.

---

## 18. Act 2 Environmental Dynamic Ambient Audio Mix Bus Snapshot Definitions

- `AudioBusSnapshot` (`SNAP_CLEANROOM_NORMAL`): Reverb Wet `0.25`, LowPass Cutoff `18000 Hz`, Music Volume `-6.0 dB`.
- `AudioBusSnapshot` (`SNAP_DECONTAM_ACTIVE`): Reverb Wet `0.65`, LowPass Cutoff `4500 Hz`, Music Volume `-18.0 dB` (focus on ventilation hiss).
- `AudioBusSnapshot` (`SNAP_CONTAINMENT_BREACH`): Reverb Wet `0.80`, LowPass Cutoff `1200 Hz`, Master Volume `-3.0 dB` (muffled underwater acoustics).

---

## 19. Act 2 Environmental Volumetric Snow & Sub-Surface Ice Shader Parameters

- `subsurface_glacial_ice.gdshader`: Sub-surface scattering depth `0.15m`, albedo tint `Color(0.85, 0.95, 1.0)`, roughness map scale `4.0`.
- `frost_buildup_overlay.gdshader`: Dynamic frost growth on visor overlay driven by `external_temp_c` parameter.
- `snow_drift_particle_system.tscn`: GPU particles for atmospheric frost flakes in unheated maintenance tunnels (`amount = 1200`, `speed = 1.2 m/s`).

---

## 20. Act 2 Environmental Sub-Surface Acoustic Resonance Echo Delay Node Maps

- `AudioEffectDelay` (`Node_BoreShaft`): Tap 1 Delay `240ms`, Tap 1 Feedback `0.4`, Tap 2 Delay `480ms`, Tap 2 Feedback `0.25`.
- `AudioEffectDelay` (`Node_CleanroomVault`): Tap 1 Delay `85ms`, Tap 1 Feedback `0.15` (tight metallic slapback reflection).
- `AudioEffectDelay` (`Node_AbyssalChasm`): Tap 1 Delay `750ms`, Tap 1 Feedback `0.65` (deep cavernous reverberation).

---

## 21. Act 2 Environmental Dynamic Occlusion Raycast Subsystem Parameters

- `AudioOcclusionRaycast`: Ray count `16` spherical probes radiating from audio emitter.
- `LowPassOcclusionFilter`: Dynamic cutoff frequency `f_cutoff = lerp(20000 Hz, 800 Hz, occlusion_ratio)`.
- `WallThicknessAttenuator`: `-6.0 dB` attenuation per 0.5m reinforced steel wall thickness.

---

## 22. Act 2 Environmental Doppler Shift & Velocity-Based Pitch Modulation Specs

- Formula: `DopplerPitchScale = (SPEED_OF_SOUND_M_S + V_listener) / (SPEED_OF_SOUND_M_S - V_source)`.
- `SPEED_OF_SOUND_M_S`: `343.0 m/s` (Nominal STP atmospheric baseline).
- `MAX_PITCH_SHIFT_LIMIT`: Clamped to `[0.5, 2.0]` (Prevents audio artifacting during sudden physics impulses).

---

## 23. Act 2 Environmental Dynamic Ambient Wind Soundscape Parameters

- `AudioStreamPlayer` (`WindTunnelHowl`): Pitch scale modulating continuously between `0.85` and `1.15` via Simplex noise generator.
- `AudioEffectBandPassFilter`: Center frequency `1200 Hz`, Bandwidth `400 Hz` for narrow corridor whistling effects.
- `DynamicVolumeRamp`: Volume `-24.0 dB` (Indoors) -> `0.0 dB` (Exposed sub-surface abyssal chasm).

---

## 24. Act 2 Environmental High-Frequency Resonant Crystal Sound Synthesis Engine Specs

- `AudioStreamGenerator`: Synthesizes 440 Hz fundamental sine tone with 880 Hz second harmonic shimmer in real-time.
- `BufferLengthSec`: `0.1s` low-latency procedural audio buffer.
- `AmplitudeModulation`: LFO frequency `3.5 Hz` depth `0.2` for pulsing crystal aura.

---

## 25. Act 2 Sub-Surface Sub-Zero Thermal Suit Life Support Energy Drain Model

- Formula: `SuitPowerDrainMW = BaselineDrainMW * (1.0 + (abs(TargetTempC - AmbientTempC) * 0.05))`.
- `BaselineDrainMW`: `0.12 MW` baseline suit regulation power.
- `TargetTempC`: `20.0 C` internal suit heating setpoint.

---

## 26. Act 2 Sub-Surface Oxygen Consumption Rate vs Ambient Pressure Model

- Formula: `OxygenConsumptionLpm = BaselineO2Lpm * (1.0 + (clamp(NominalPressurekPa - AmbientPressurekPa, 0.0, 300.0) / 100.0))`.
- `BaselineO2Lpm`: `1.5 L/min` nominal metabolic consumption rate.
- `NominalPressurekPa`: `101.3 kPa` standard atmospheric sea-level equivalent.

---

## 27. Act 2 Sub-Surface Ice Core Drill Penetration Force Equations

- Formula: `PenetrationRateMmSec = (DrillTorqueNm * DrillRpm) / (HardnessCoeff * 1000.0)`.
- `HardnessCoeff`: `4.8` (Compacted glacial silicate ice matrix hardness).
- `NOMINAL_DRILL_RPM`: `1800 RPM` baseline core bit velocity.

---

## 28. Act 2 Dynamic Abyssal Chasm Echo Reverberation Decay Time Specs

- `AudioEffectReverb` (`AbyssalCavern`): Room size `0.95`, Dampening `0.25`, RT60 Decay Time `4.2s`.
- `PredelayMs`: `120ms` initial wall reflection gap.
- `HighCutoffHz`: `3500 Hz` frequency damping for long cavernous tails.

---

## 29. Act 2 Dynamic Seismic Activity Impulse & Camera Shake Profile

- Formula: `CameraShakeOffset = Vector3(noise.get_noise_2d(time*10, 0), noise.get_noise_2d(time*10, 1), 0) * (Trauma ^ 2) * MaxAngle`.
- `TraumaDecayRate`: `0.75 / sec` linear stabilization.
- `MAX_SHAKE_ANGLE_DEG`: `4.5 deg` maximum rotational roll impulse during sub-surface quake.

---

## 30. Act 2 Dynamic Player Character Suit Oxygen Pressure Equalization Rate

- Formula: `SuitO2FillRatePctSec = (SupplyPressurekPa / 100.0) * 4.5`.
- `MAX_SUIT_O2_CAPACITY_LITERS`: `6.0 L` high-pressure emergency suit tank.
- `EQUALIZATION_LOCKOUT_PRESSURE_KPA`: `< 80.0 kPa` prevents suit auto-fill until airlock reaches threshold.

---

## 31. Act 2 Character Model Skeleton Mesh Attachment & Bone Scale Parameters

- `CharacterMeshScale`: `Vector3(0.01, 0.01, 0.01)` FBX unit normalization scale factor.
- `HeadBoneName`: `"mixamorig_Head"` (Hidden in local first-person view, visible to co-op peers).
- `HandAttachmentBone`: `"mixamorig_RightHand"` (Target anchor for welding torch & scanner attachments).

---

## 32. Act 2 Dynamic Player Character Suit Thruster Fuel Consumption Model

- Formula: `ThrusterFuelDrainKgSec = BaselineThrusterRateKgSec * (1.0 + (ThrustMagnitude / MaxThrustForceN))`.
- `BaselineThrusterRateKgSec`: `0.02 kg/sec` RCS cold-gas stabilization consumption.
- `MAX_THRUST_FORCE_N`: `450.0 N` maximum micro-gravity EVA boost impulse.

---

## 33. Act 2 Dynamic Player Character Suit Thruster Particle Jet Direction Vectors

- Formula: `JetVelocityVector = -1.0 * DirectionNormal * (ParticleSpeedMS * (1.0 + (ThrustPct * 0.5)))`.
- `PARTICLE_SPEED_MS`: `12.5 m/s` baseline cold-gas expulsion velocity.
- `MAX_PARTICLE_EMISSION_RATE`: `120 particles/sec` during full EVA thrust impulse.

---

## 34. Act 2 Dynamic Player Character Suit Thruster Sound Pitch Scaling Specs

- Formula: `ThrusterAudioPitch = lerp(0.85, 1.45, ThrustPct)`.
- `AudioStreamPlayer3D` (`RcsThrusterHiss`): Attenuation cut-off distance `25.0m`.
- `LowPassFilterCutoff`: `4500 Hz` high-frequency damping for realistic suit helmet reverberation.

---

## 35. Act 2 Dynamic Player Character Suit Thruster Visual Flash Intensity Specs

- Formula: `OmniLightEnergy = MaxFlashEnergy * ThrustPct * (0.8 + (randf() * 0.4))`.
- `MAX_FLASH_ENERGY`: `2.8` OmniLight3D light intensity during full thrust ignition.
- `LIGHT_COLOR_CYAN`: `Color(0.2, 0.85, 1.0)` cryogenic cold-gas discharge glow.

---

## 36. Act 2 Dynamic Player Character Suit Thruster Visual Flash Fade Decay Rate Specs

- Formula: `CurrentLightEnergy = max(0.0, CurrentLightEnergy - (DecayRate * DeltaSec))`.
- `DECAY_RATE`: `8.5 / sec` linear energy dissipation rate.
- `MIN_FLASH_THRESHOLD`: `< 0.05` energy cutoff threshold.

---

## 37. Act 2 Dynamic Player Character Suit Thruster Visual Flash Color Temperature Specs

- Formula: `FlashColor = Color.cyan.lerp(Color.white, ThrustPct * 0.6)`.
- `COLD_GAS_BASE_COLOR`: `Color(0.18, 0.78, 0.98)` cold nitrogen expansion.
- `PEAK_THRUST_WHITE_HOT`: `Color(0.85, 0.95, 1.0)` peak thrust ionization core.

---

## 38. Act 2 Dynamic Player Character Suit Thruster Visual Flash Lens Flare Scale Specs

- Formula: `Sprite3DScale = Vector3.ONE * (BaseFlareScale * (0.8 + (ThrustPct * 0.7)))`.
- `BASE_FLARE_SCALE`: `0.35` QuadMesh sprite scale multiplier.
- `ANAMORPHIC_RATIO`: `Vector3(1.8, 0.45, 1.0)` horizontal lens flare stretch ratio.

---

## 39. Act 2 Dynamic Player Character Suit Thruster Visual Flash Lens Flare Color Gradient Specs

- Formula: `FlareModulateColor = Color(0.3, 0.9, 1.0, clamp(ThrustPct * 0.9, 0.0, 1.0))`.
- `FLARE_TEXTURE_RES`: `256x256` radial gradient lens flare texture.
- `BLEND_MODE_ADDITIVE`: Additive canvas item blend mode for cinematic blooming.

---

## 40. Act 2 Dynamic Player Character Suit Thruster Visual Flash Particle Emitter Lifetime Specs

- Formula: `ParticleLifetimeSec = BaseLifetimeSec * (0.85 + (randf() * 0.3))`.
- `BASE_LIFETIME_SEC`: `0.45s` particle extinction lifespan.
- `INITIAL_VELOCITY_VARIANCE`: `±15%` cone spread velocity randomness factor.

---

## 41. Act 2 Dynamic Player Character Suit Thruster Visual Flash Particle Trail Length Specs

- Formula: `TrailLengthMeters = ParticleSpeedMS * ParticleLifetimeSec`.
- `MAX_TRAIL_LENGTH_METERS`: `5.625m` maximum cold-gas plume extension.
- `DENSITY_ATTENUATION_FACTOR`: `0.75` linear opacity decay along plume length.

---

## 42. Act 2 Dynamic Player Character Suit Thruster Visual Flash Particle Plume Angle Spread Specs

- Formula: `PlumeRadiusMeters = TrailLengthMeters * tan(deg_to_rad(SpreadAngleDeg / 2.0))`.
- `SPREAD_ANGLE_DEG`: `18.5 deg` conical expansion angle.
- `MAX_PLUME_RADIUS_METERS`: `0.916m` terminal plume expansion boundary.

---

## 43. Act 2 Dynamic Player Character Suit Thruster Visual Flash Particle Turbulence Noise Specs

- Formula: `TurbulenceOffset = FastNoiseLite.get_noise_3d(pos.x, pos.y, pos.z) * TurbulenceStrength`.
- `TURBULENCE_STRENGTH`: `0.42` particle deflection magnitude.
- `NOISE_FREQUENCY`: `2.8 Hz` spatial turbulence frequency scale.

---

## 44. Act 2 Dynamic Player Character Suit Thruster Visual Flash Particle Color Ramp Modulation Specs

- Formula: `ParticleColor = Gradient.sample(ParticleAgeNormalized)`.
- `GRADIENT_KEY_0`: `Color(1.0, 1.0, 1.0, 1.0)` at birth (0.0).
- `GRADIENT_KEY_1`: `Color(0.2, 0.8, 1.0, 0.6)` at midlife (0.5).
- `GRADIENT_KEY_2`: `Color(0.05, 0.3, 0.7, 0.0)` at death (1.0).

---

## 45. Act 2 Dynamic Player Character Suit Thruster Visual Flash Particle Blend Mode Specs

- Formula: `FinalPixelColor = ParticleColor * TextureSample * AmbientLightingScale`.
- `MATERIAL_BLEND_MODE`: `BLEND_MODE_ADD` (additive transparency).
- `DEPTH_DRAW_MODE`: `DEPTH_DRAW_DISABLED` to prevent sorting artifacts in semi-transparent particle cloud.

---

## 46. Act 2 Dynamic Player Character Suit Thruster Visual Flash Particle Shadow Casting Specs

- Formula: `OmniLight3D.shadow_enabled = true` when `ThrustPct > 0.35`.
- `SHADOW_BIAS`: `0.02` distance offset to avoid self-shadow acne on character suit geometry.
- `SHADOW_BLUR`: `1.5` soft PCF shadow filtering kernel radius.

---

## 47. Act 2 Dynamic Player Character Suit Thruster Visual Flash Light Energy Attenuation Specs

- Formula: `OmniLight3D.omni_attenuation = lerp(1.2, 0.45, ThrustPct)`.
- `MIN_ATTENUATION`: `0.45` smooth illumination falloff curve at max thrust.
- `MAX_ATTENUATION`: `1.2` sharp localized illumination falloff curve at low thrust.

---

## 48. Act 2 Dynamic Player Character Suit Thruster Visual Flash Light Range Attenuation Specs

- Formula: `OmniLight3D.omni_range = BaseRangeMeters * (0.7 + (ThrustPct * 0.8))`.
- `BASE_RANGE_METERS`: `4.5m` baseline illumination sphere radius.
- `PEAK_RANGE_METERS`: `6.75m` max thrust burst illumination sphere radius.

---

## 49. Act 2 Dynamic Player Character Suit Thruster Visual Flash Light Flicker Noise Specs

- Formula: `FlickerEnergy = BaseEnergy * (1.0 + (sin(TimeSec * 35.0) * 0.08) + ((randf() - 0.5) * 0.05))`.
- `FLICKER_FREQUENCY_HZ`: `35.0 Hz` high-frequency electrical nozzle flicker.
- `MAX_FLICKER_AMPLITUDE`: `±13%` randomized flash intensity ripple.

---

## 50. Act 2 Dynamic Player Character Suit Thruster Visual Flash Nozzle Heat Distortion Mesh Specs

- Formula: `ScreenDistortionScale = BaseDistortionScale * (0.5 + (ThrustPct * 0.9))`.
- `BASE_DISTORTION_SCALE`: `0.025` normal map refraction displacement factor.
- `NORMAL_MAP_ANIMATION_SPEED`: `Vector2(0.0, -4.5)` screen-space normal map scrolling velocity.

---

## 51. Act 2 Dynamic Player Character Suit Thruster Visual Flash Screen Shockwave Ring Specs

- Formula: `ShockwaveRadius = BaseRadius * (1.0 + (AgeSec * ExpansionRate))`.
- `BASE_SHOCKWAVE_RADIUS`: `0.1m` initial nozzle detonation ring size.
- `EXPANSION_RATE`: `12.5 m/s` radial shockwave propagation speed.

---

## 52. Act 2 Dynamic Player Character Suit Thruster Visual Flash Chromatic Aberration Pulse Specs

- Formula: `AberrationStrength = MaxAberration * exp(-DecayRate * PulseAgeSec) * ThrustPct`.
- `MAX_ABERRATION`: `0.015` screen-space RGB color channel separation magnitude.
- `DECAY_RATE`: `18.0 / sec` rapid exponential chromatic relaxation rate.
