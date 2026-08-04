extends Node3D
class_name SignalJammer

## A radio dead-zone. While a player stands inside its radius, their outgoing
## radio signal is degraded (or killed outright), forcing the pair to physically
## relocate to hold a clean conversation — the "rooms built to jam signal"
## mechanic from the design doc's communication section.
##
## Player controllers query every node in the "signal_jammers" group each frame
## and apply the worst jam they're currently standing in. No Area3D/physics is
## needed — a simple spherical radius keeps it cheap and deterministic across
## peers (position is already network-synced, so every peer agrees on who's
## inside which jammer).

## Radius of the dead-zone in meters.
@export var radius: float = 6.0

## How badly the signal is jammed. 1.0 = total blackout (no signal at all),
## 0.5 = signal quality is halved, 0.0 = no effect.
@export_range(0.0, 1.0) var jam_strength: float = 1.0


func _ready() -> void:
	add_to_group("signal_jammers")


## Returns a multiplier in [0, 1] to apply to a player's signal_quality for a
## player at the given world position. 1.0 means "not affected by this jammer".
func signal_multiplier_for(world_pos: Vector3) -> float:
	if global_position.distance_to(world_pos) <= radius:
		return 1.0 - jam_strength
	return 1.0
