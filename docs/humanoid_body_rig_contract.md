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

The prototype's base anatomy is strictly bilateral. Hips, torso, head, arms,
and legs are authored as half or single-side components, then instanced beneath
negative-X mirror axes or mirrored socket anchors. Anatomical edits happen in
those canonical `rig_parts` scenes so bilateral proportions cannot drift.

An anatomical edit must be made in the corresponding `rig_parts` component,
not as an override on either instance. Both sides then update from the same
canonical geometry, so bilateral proportions cannot drift. The side profile is
a single lateral projection and mirrors as a whole when facing left; its paired
limbs still reuse the same arm and leg component resources.

Hair is deliberately excluded from the symmetry invariant. It is a single
head-owned overlay that may be edited asymmetrically. Future asymmetric anatomy,
clothing, equipment, damage, or silhouette detail follows that same additive
overlay rule and must not silently replace the canonical mirrored anatomy.

Directional projections own separate component resources when their geometry
cannot be shared honestly. In particular, the forward top-down arm and leg
components preserve Volette's foreshortened gameplay silhouette, while the side
profile retains lateral components. Symmetry is shared within a projection;
geometry is not forced across incompatible projections.

The profile implementation is a complete lateral assembly derived from
`volette_visual.tscn`. It preserves distinct near/far leg shapes and depth
layers, owns near/far shoulder and hip sockets, and flips as a complete assembly
for the opposite side. Profile limbs rotate rigidly around their sockets; they
do not use the forward view's projected-length depth mutation.

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
  Forward arm depth is hand, forearm, then upper arm/shoulder. Scene-tree
  insertion order is not the layering contract.
- The forward hierarchy has three principal forms in back-to-front order:
  `Hips`, `Torso`, and `Head`. Torso owns explicit hips, head, and shoulder
  anchors; hips own explicit left and right hip sockets. Appendages currently
  animate as stiff units from those sockets, even though their artwork remains
  visibly segmented for later joint work.
- Torso, hips, and head each own an independent rotation pivot. Hips and head
  pivots remain children of torso-owned anchors, so torso motion carries their
  connection points while their local rotations remain independent. This is a
  rigid-transform analogue of a bone hierarchy; `Skeleton2D`/`Bone2D` should be
  introduced later only when continuous polygon deformation and skin weights
  are required.
- Forward appendage swing is a depth projection. A sine wave lengthens one
  stiff appendage from its fixed socket while shortening its partner; arms also
  cross behind or above the torso according to their back/front phase. Small
  planar rotation is secondary. This is intentionally different from rotating
  the arms side-to-side like windshield wipers.
- Editor previews restore canonical transforms and dynamic arm layers before a
  scene save, then resume afterward. Animation extremes must never be serialized
  and recaptured as biased rest poses; every appendage owns the complete signed
  rear-to-front sine arc regardless of mirror state.
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
