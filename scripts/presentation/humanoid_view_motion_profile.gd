@tool
extends Resource
class_name HumanoidViewMotionProfile

## Cycles per second for this projection's locomotion preview.
@export_range(0.1, 8.0, 0.1) var cycle_speed := 1.7

## Rigid leg rotation around this projection's hip sockets.
@export_range(0.0, 30.0, 0.1) var leg_swing_degrees := 4.0

## Translational stride reserved for projections whose sockets travel in screen space.
@export_range(0.0, 24.0, 0.5) var stride_distance := 8.5

## Forward-view projected leg-length mutation; unused by literal profile rotation.
@export_range(0.0, 0.35, 0.01) var leg_depth_swing_ratio := 0.12

## Rigid arm rotation around this projection's shoulder sockets.
@export_range(0.0, 24.0, 0.5) var arm_swing_degrees := 5.0

## Forward-view projected arm-length mutation; unused by literal profile rotation.
@export_range(0.0, 0.35, 0.01) var arm_depth_swing_ratio := 0.14

## Independent hips tilt for this projection.
@export_range(0.0, 12.0, 0.25) var hip_tilt_degrees := 3.0

## Vertical body travel for this projection.
@export_range(0.0, 8.0, 0.25) var body_bob_distance := 2.0

## Independent torso tilt for this projection.
@export_range(0.0, 8.0, 0.25) var torso_twist_degrees := 1.5

## Independent head stabilization for this projection.
@export_range(0.0, 8.0, 0.25) var head_counter_tilt_degrees := 2.0
