# Humanoid Body Rig Prototype Contract

`scenes/characters/humanoid_body_rig_prototype.tscn` is an isolated body-only
prototype based on Volette's blocked proportions. It is not connected to
`PlayerEntity` and deliberately contains no weapons.

## Directional views

The root owns `FrontView`, `SideView`, and `RearView`. `HumanoidBodyRig`
selects one view from the last meaningful movement/facing direction. The side
view mirrors for left-facing movement.

Every view exposes the same animation contract beneath `BodyMotion`:

- `TorsoPivot`
- `LeftLegPivot` and `RightLegPivot`
- `LeftArmPivot/ElbowPivot` and `RightArmPivot/ElbowPivot`

Artwork can add knee, ankle, hair, clothing, and detail pivots beneath these
stable groups without changing the movement API.

## Symmetric base construction

The prototype's base anatomy is strictly bilateral. Front and rear core forms
(pelvis, torso, armor, neck, head, and hair) are authored as one half in a
reusable `rig_parts/humanoid_*_core_half_prototype.tscn` component. Each view
contains one primary instance and one second instance beneath `CoreMirrorAxis`,
whose X scale is `-1`. Arms and legs follow the same component-instance pattern
under `RightArmMirrorAxis` and `RightLegMirrorAxis`.

An anatomical edit must be made in the corresponding `rig_parts` component,
not as an override on either instance. Both sides then update from the same
canonical geometry, so bilateral proportions cannot drift. The side profile is
a single lateral projection and mirrors as a whole when facing left; its paired
limbs still reuse the same arm and leg component resources.

Future asymmetric anatomy, clothing, equipment, damage, or silhouette detail
belongs in additive overlay nodes above this symmetric base. It must not replace
or silently override the canonical mirrored construction.

## Ownership

The owning entity may call only:

- `set_motion_state(direction, normalized_speed)` when movement state changes.
- `advance_motion(delta)` while moving.
- `reset_pose()` when returning to a known rest state.

The rig owns view selection and local presentation motion. It emits no gameplay
commands and has no manager or orchestrator references.

## Prototype decisions

- Limbs are rigid overlapping polygon pieces. This makes gaps and pivot errors
  visible before weight painting or skeletal deformation is introduced.
- Arms belong to the body contract, but hands have no grip or weapon sockets in
  this pass.
- Hair is a simple rear mass and cap used only to check head/torso layering.
- Volette colors make the silhouette easier to compare with her current art;
  palette and skin separation are future work.
- Weapon sockets, muzzle anchors, aim solving, detailed skin migration, and
  gameplay integration are intentionally deferred until the generic body
  contract is approved.
