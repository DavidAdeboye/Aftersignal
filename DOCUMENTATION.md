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
- layer 4 (Projectiles): Fast-moving projectile raycasts, bullet hitboxes, area damage volumes.
- layer 5 (Interactables): Area3D overlap detectors for chests, doors, switches, pickups.
- layer 6 (Hazards): Kill zones, lava fields, out-of-bounds reset volumes, spike traps.

### 4.2 Asset Formats & Materials Specifications
- 3D Model Import Format: glTF 2.0 (.glb, .gltf) for scenes, animated meshes, and rigid environment props.
- Texture Formats: COmpressed WebP/ PNG utilizing PBR workflow (Albedo, Roughness, Normal, Metallic, Ambient Occlusion).
- Material shaders: Custom spatial shaders (.gdshader) with vertex displacement for dynamic ocean waves adn custom toon outline passses.
- Audio Formats: OGG Vorbis for long looping ambient music streams, WAV for low-latency spatial SFX samples.


## 5. USER INTERFACE (UI) & AUDIO ARCHITECTURE

### 5.1 Control node Hierachy and screen canvas
- canvas layer (priority 100): Overlays heads-up display independent of 3d worls space coordinates.
- control containers: MarginCOntainer root with VBoxContainer for structured layout alignment.
- HUD Elements:
  - HealthBar (textureProgressBar): Value bound dynamically to a player health signa; updates.
  - StaminaBar(TextureProgresBar): Smooth lerp interpolation applied to value changes.
  - Recticle (Control / CenterContainer): Fixed center point viewpory indicator

### 5.2 Audio stream management
- AudioStreamPlayer (master Bus): Handles non-positional user interface sound effects and global music state.
- AudioStreamPlayer3D (Spatiol sound): positional audio emitter with attenuation curves configured for 3d positional acoustics.
- Sound Effect Categories:
  - Step SFX: Randomzed pitch variance (0.9x to 1.1x multiplier) triggered per step animation event.
  - Impact SFX: Dynamic volume scaling dependent on downward Y-velocity prior to floor contact.
  

---

## 6. LEVEL STREAMING & OPTIMIZATION PIPELINE

### 6.1 Multi-threaded chunk loading
- Background loading: ResourceLoader.load_threaded_request() utilized to prevernt main thread frame drops during level transitions
- Asynchronous scene instantiation: Chunck scenes loaded dynamically into memory nased on player spatial position proximity.

### 6.2 Rendering & Performance Targets
- Occlusion Culling: enabled to prevent rendering geometery occluded behind solid sructures.
- Distanve LOD (level of detail): Automatic mesh simplifications applied dynamically to distant environment models.
- Shadow Distance: DirectionalLight3D shadow render distance capped at 50.0 meters to ensure consistent 60+ FPS performance.


## 7. 3D LIGHTING & SHADER ARCHITECTURE

### 7.1 Environment & lightning configuration
- WorldEnvironment node:
  - Background Mode: Custom Skybox (ProceduralSkyMaterial / PanoramaSkyMaterial). 
  - Ambient Light: Sky color contribution set to 0.45 intensity for smooth indirect filling.
  - Tonemap Mode: ACES Filmic operator enabled for expanded dynamicc color range.
  - Glow / Bloom: Soft bloom enabled with threshold 1.0 and intensity 0.5 for illuminated emitters.
- DirectionalLight3D (Sun Emitter):
  - Shadows Enabled: Directional shadow map size set to 2048x2048 depth buffer.
  - Light Energy: 1.2 lux unit multiplier for realistic daytime outdoor contrast

### 7.2 Custom shader specifications (.gdshader):
- Water Surface Shader:
  - VErtex Displacement: Gerstner wave algorithim calculating dynamic height displacement.
  - Transparency & Depth: Soft edge depth diatance blending using SceneDepthTexture.
-  Toon / Cel Pass Shader:
  - Light ramp: clamped diffuse lighting values into 3 distinct step bands.
  - Outline pass: inverted hull technique inflating vertex normals in a second render pass.

---

## 8. ENEMY AI ENGINE & NAVIGATION MESH

### 8.1 Pathfinding & navigation server
- NavigationRegion3D: Bakes 3d floor geometery into unified walkable mesh agent bonds.
- NavigationAgent3D Node:
  - Target Desired Distance: 1.5 meters radius threshold for destination reach.
  - Path Desired Distance: 0.75 meters radius check for intermediate path waypoints.
  - Velocity Obstacle Avoidance: Reciprocal Velocity Obstacle (RVO) avoidance enabled to prevent enemy stacking.

### 8.2 Enemy Finite State Machine (FSM)
- IDLE: Scans 360-degree vision cone using RayCast3D for Player target detection.
- PATROL: Executes random node waypoint selection across active NavigationMesh.
- CHASE: Dynamically updates NavigationAgent3D targetg position toward Player spatial global position.
- ATTACK: Locks movement rotation, instantiates attack hurtbox volume, execute cooldown timer.
- STUN / DEATH: Disables collision shapes, instantiates ragdoll physics body, executes queue_free().

---

## 9. PERSISTENCE & DATA SAVING FRAMEWORK

### 9.1 Serialization Pipeline
- File Storage Format: Encrypted binary / JSON structured payloads stored in `user://saves/` path.
- State Serialization Pipeline:
  - Transform Data: Global Position (Vector3) and rotation basis (Quaternion) encoded into floating-point arrays.
  - Inventoray Arrays: Items identifier strings, stack quantities, and slot indices mapped into dictionaries.
  - Player Metadata: Accumulated play time seconds, active quest objectives, and unlocked abilities bitmast.

### 9.2 Threaded File I/O Operations
- Asynchronous save pipeline: WorkerThreadpoolused to encode file bytes off the main renderer thread to eliminate frame stutters during auto-save events.
- Atomic File Overwrites: saves written to a temporary `.tmp` file before replacing master `.save` file to prevent corrupted state on force shutdown.

---

## 10. PERFORMANCE PROFILING & BENCHMARKS

### 10.1 Frame Budget & Allocation
- Total frame budget: 16.66 milliseconds per frame (Targetting constant 60 FPS baselne.)
- CPU Render Thread Allocation:
  - Kinematics and dynamic physics calculations: capped at < 4.0ms per physics tick.
  - Scene Navigation and pathfinding Updates: Capped at < 2.5 ms per proces frame.
  - GDScript script execution and logic: capped at < 3.0 ms per frame.
- GU frame budget: Geometry rasterization, shader passes, and most post-processing lighting capped at 7.0ms.

### 10.2 Memory management Guidelines
- Node Tree Cleanups: Explicit call of `queue_free()` on instatiated temporary objects (projectiles, particles, transient UI popups).
- Object Pooling pipeline: pre-installing high-frequency particle nodes and audio players to bypass memory allocation overhead during heavy combat loops.

---

## 11. INVENTORY SYSTEM AND ITEM DATA STRUCTURES

### 11.1 Inventory Architecture
The inventory uses a grid based layout managed by a cntralized data manager node.
Items are stored as resouecr files containing data for display names, descriptions, maximum stack size, and icon texture paths.
The system uses a dictionary data structure where each key is an integer representing the slot index and the value is a custom item object.

### 11.2 Item Types and Data Fields
- Consumable Items: restores player health or stamina instantly on consumption.
- Equipment Items: Modifies base stats like movement speed, damage output, or defense multipliers.
- Quest Items: Unique key items that unlock progress doors or trigger narrative events.
- Material Items: Stackable resource drops used for upgrading equipment or unlocking features.

---

## 12. SOUND DESIGN AND AMBIENT ENVIRONMENT PIPELINE

### 12.1 Dynamic Audio Buses
The audio engine divides all project sound inro three main buses: Master, Music, and Sound Effects.
Each bus has independent volume sliders mapped from negative eighty decibels up to six decibels.
The sound effects bus applies a high pass filter when the player enters underwater areas or enclosed spaces.

### 12.2 Footstep Audio Systerm
Footstep sounds trigger automatically using animation track events attached to the runnng and walking animations.
When a footstep event fires, a downward raycast detects the floor material type under the player feet.
The system then plays a randomized sound sample matched to the detected surface material like stone, wood, dirt, or a metal

---

## 13. WEATHER AND DAY NIGHT CYCLE SYSTEMS

## 13.1 Directional Sun sky roattion
The game tracks global world time using a continous floaring point from zero to twenty four hours.
A master light pivot rotates around horizonta; axis to stimulate sun elevation and directional shadows.
As the time reaches night hours, sun light energy drops smoothly to zero while directional moon liht energy ries.

### 13.2 Environmental Fog Dynamics
Fog density and sky tint colors update dynamically based on the active hour of the world time.
Morning hours transition from deep blue atmospheric fog into warm orange sun highlights.
Rain events dynamically increase fog density while reducing the spatial view distance of the player camera.

---

## 14. Input Mapping and accessibility features

