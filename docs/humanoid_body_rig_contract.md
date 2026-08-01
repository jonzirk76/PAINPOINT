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

Directional projections own separate component resources when their geometry
cannot be shared honestly. In particular, the forward top-down arm and leg
components preserve Volette's foreshortened gameplay silhouette, while the side
profile retains lateral components. Symmetry is shared within a projection;
geometry is not forced across incompatible projections.

## Ownership

The owning entity may call only:

- `set_motion_state(direction, normalized_speed)` when movement state changes.
- `advance_motion(delta)` while moving.
- `reset_pose()` when returning to a known rest state.

The rig owns view selection and local presentation motion. It emits no gameplay
commands and has no manager or orchestrator references.

## Prototype decisions

- The established `volette_visual.tscn` upper-body polygon is treated as a
  combined torso-and-arms envelope, not as anatomical torso width. The armor
  mass is the torso-width reference; separate arm components occupy the rest of
  the old envelope.
- Base draw order is explicit and anatomical: boots are furthest back, followed
  by lower legs, knees, upper legs, pelvis, torso/armor, neck, head, and hair.
  Arm segments layer independently above the base torso where their joints
  require it. Scene-tree insertion order is not the layering contract.
- The front head half is adapted from the developed outline in
  `volette_visual.tscn`, then mirrored canonically instead of being redrawn as a
  generic oval.
- `FrontView` means the authored top-down, forward-facing gameplay projection;
  it is not an orthographic front elevation. Its large overlapping head,
  compressed torso, diagonal arms, and receding legs are intentional.
- Forward-view proportions and locomotion timing use
  `volette_walk_cycle_preview.tscn` as their visual reference: opposing 8.5-pixel
  strides, restrained 1.3-degree leg rotation, recovering-foot lift, hip/body
  counter-motion, and a slower two-pixel bounce. The arms remain independent
  rig components instead of being fused into the torso artwork.
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
