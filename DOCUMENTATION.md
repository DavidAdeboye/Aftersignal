# GAME ENGINE SYSTEM ARCHITECTURE SPECIFICATION
Document Version: 1.0.0
Target Engine: Godot Engine 3D
Project Name: Aftersignal

## 1. CHARACTER KINEMATICS & INPUT HANDLING

### 1.1 Spatial Coordinate System
- Coordinate Basis: Right-handed Y-Up spatial orientation.
- Spatial Vector Axes:
  - Positive X: Right lateral movement vector
  - Positive Y: Upward vertical vector
  - Positive Z: Backward depth vector (toward camera view)

### 1.2 Ground Movement Kinematics
- Base Walking Speed: 7.5 meters per second.
- Sprint Velocity Multiplier: 1.6x base speed factor (12.0 m/s total).
- Acceleration Curve: Applied via linear interpolation (lerp) per frame delta.
- Friction & Deceleration: Exponential decay applied when direction length approaches zero.
- Slope Handling: Max floor angle configured at 45.0 degrees. Dynamic floor normal alignment enabled to prevent unwanted sliding on valid terrain.

### 1.3 Jump & Air Kinematics
- Gravity Acceleration: Constant downward vector of 24.5 m/s² applied on Y-axis.
- Jump Impulse Velocity: Initial Y-velocity boost of 10.5 m/s upon jump execution.
- Terminal Fall Speed: Capped at -40.0 m/s to preserve collision integrity and prevent phase-through bugs.
- Air Control Dynamics: Horizontal velocity direction changes capped at 25% effectiveness while in airborne state.
- Coyote Time Buffer: 0.15-second grace window after leaving ledges to register jump inputs.
- Jump Input Buffering: 0.12-second pre-landing input buffer to queue jump actions automatically upon floor contact.

---

## 2. CAMERA CONTROLLER & TARGETING MATH

### 2.1 SpringArm3D & Collision Avoidance
- Node Type: SpringArm3D attached to top-level Player spatial transform.
- Spring Length: Default offset of 4.5 meters behind player mesh.
- Margin Clearance: 0.2 meters radius collision sphere to prevent geometry clipping.
- Collision Mask: Configured to detect Layer 1 (Static Environment) while ignoring Layer 2 (Player Body).

### 2.2 Rotational Kinematics & Mouse Look
- Yaw Axis (Horizontal Rotation): Unconstrained 360-degree orbital rotation around global Y-axis.
- Pitch Axis (Vertical Rotation): Clamped between -80.0 degrees (looking up) and +75.0 degrees (looking down) to prevent gimbal lock.
- Mouse Sensitivity Coefficient: 0.003 radians per raw device pixel movement.
- Camera Rotation Smoothing: Spherical linear interpolation (slerp) with speed factor 15.0 applied to smooth sudden mouse input spikes.

---

## 3. GLOBAL ENGINE STATE MACHINE & EVENT BUS

## 3.1 Enumerated Game States
- PRE_GAME_INITIALIZATION: Scene assets loading, physics thread boothstrapping, pre-caching shader pipeliines.
- MAIN_MENU: UI overlay active, world update loop paused, input capture set to UI mode.
- GAMEPLAY_ACTIVE: Player input enabled, full physics stimulation running, collision signals actively listening.
- GAMEPLAY_PAUSED: time scale set to 0.0, UI menu stack rendered, player input locked.
- GAME_OVER: Death sequence playing, player input disabled, restart/respawn transtion queued.

## 3.2 Global Custom Signal Bus (GDScript Events)
- signal player_health_changed(current_hp:float, max_hp: float)
- signal player_stamina_depleted()
- signal player_stamina_refilled()
- signal item_collected(item_id: String, item_quantity:int)
- sgnal checkpoint_activated(checkpoint_position: Vector3)
- signal level_section_loaded(section_name: String)
- signal boss_fight_triggered(boss_name: String)
- signal spatial_audio_triggered(sound_effect_id: String, location: Vector3)

---

## 4. COLLISION MATRIX & RESOURCE PIPELINE

### 4.1 Physics Collision Layer Allocation
- Layer 1 (Environment): Static terrain, walls, buildings, floor geometry, static obstacles.
- layer 2 (Player): Kinematic player capsule collider and hurtbox.
- layer 3 (Enemies): NPC dynamic hitboxes, pathfinding obstacle volumes, enemy hurtboxes
- layer 4 (Projectiles):