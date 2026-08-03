# Neutral Polygon Base

The neutral polygon base promotes the accepted raster cutout proof into five
editable, flat-color canonical scenes. It preserves the cutout hierarchy,
anchors, far-side modulation, and projection-specific walk animations without
retaining a texture dependency on the raster reference.

The five authored scenes are South, South West, West, North East, and North.
North West, East, and South East remain mirrored derivatives selected by
`neutral_polygon_8_way.tscn`.

## Ownership

- `neutral_cutout` owns disposable raster-derived reference scenes.
- `neutral_polygon_base` owns the current editable canonical source scenes. Their
  bone hierarchy, animations, and neutral polygons remain together while the
  source split is introduced without rewriting hand-authored vertices.
- `neutral_humanoid_rig.tres` identifies the reusable directional pivots,
  anchors, and AnimationPlayer libraries.
- `neutral_polygon_skin.tres` identifies the editable directional polygon skin
  and its active-arm geometry.
- `neutral_polygon_8_way.gd` owns direction selection, mirroring, and the active
  view's walk/idle animation state for the authoring review selector.
- `neutral_polygon_twist_8_way.gd` composes the rig and skin into a persistent
  runtime direction cache. It never owns canonical vertices or animation data.
- `neutral_polygon_review_workbench.tscn` owns comparison presentation only.
- `neutral_polygon_locomotion_test.tscn` owns the isolated runtime movement test only.

## Rig And Skin Source Contract

The reusable humanoid is separated conceptually into an animation rig source
and a character skin source. A `HumanoidAnimationRigSource` provides the five
editable canonical direction scenes whose `Skeleton2D`, `Bone2D`, anchor, and
`AnimationPlayer` data define motion. A `PolygonCharacterSkinSource` provides
path-compatible direction scenes whose Polygon2D nodes define the visible
character, including character-specific appendage silhouettes and authored
detail layers.

The neutral rig and neutral skin intentionally reference the same five existing
canonical scenes during this compatibility phase. This preserves all current
hand edits. A later character skin may point at separate scenes with the same
semantic skeleton paths; at cache construction, the reusable rig's bone rest
transforms and animation libraries are applied to those skin scenes. The active
aim arm is selected independently from the skin resource.

Runtime direction changes do not instantiate or free scenes. At startup, the
twist composite creates five persistent canonical views for each subassembly,
with the other three directions represented by mirror flags. It filters each
cached view to its semantic responsibility and stops its hidden AnimationPlayer.
Turning restores the authored seam state, hides the previous four views, reveals
four cached views, applies their mirror flags, aligns anchors, and resumes the
shared walk phase. This moves allocation cost to initialization and keeps
authored scenes out of the turn-time lifecycle.

Walk continuity is transferred as a normalized cycle phase rather than an
absolute timestamp, because the authored direction animations may have different
durations. Seam solves always derive directly from stored authored polygons, so
turning does not first rebuild the outgoing hidden torso mesh.

Character-specific clothing, armor, hair, markings, and replacement appendage
geometry should live inside the skin's directional scenes under the relevant
bone or semantic layer. They inherit rig animation because their enclosing bone
paths remain stable. A character requiring incompatible anatomy should receive
a separate rig source instead of weakening the humanoid contract.

The promotion builder is intentionally one-way. Running
`build_neutral_polygon_base.gd` again replaces the five polygon scenes and should
only be done before hand-authored vertex edits begin, or after those edits have
been deliberately preserved elsewhere.

Open `neutral_polygon_review_workbench.tscn` to inspect all eight animated
directions and compare the five canonical polygon scenes against adjustable
raster overlays.

Open `neutral_polygon_locomotion_test.tscn` and run the current scene to walk
the polygon base through a generated one-cell room with WASD or the controller
left stick. The harness removes all generated combat contents before play, so
only procedural room geometry, collision, and the eight-way character remain.
Its lower-right display bay shows the existing player, three enemy profiles,
and common destructible props at their real gameplay sizes; these references
have processing, collision, and gameplay-group membership disabled.

## Native Skeleton Vertical Slice

`neutral_native_skeleton_slice.tscn` is the replacement-backend spike. After the
three-view proof, it was extended to compile all five canonical rig and skin
resources and derive North West, East, and South East by mirroring. Source
instances never enter the live scene tree: their local authored hierarchies are
compiled synchronously and then discarded. Runtime then
owns one persistent `Skeleton2D`, seven invariant principal bones, one
`AnimationPlayer`, and one `AnimationTree`.

Each canonical Polygon2D is flattened relative to its nearest principal bone and
placed in a direction-specific semantic skin slot. Changing direction switches
those lightweight slots, applies that direction's bone rest contract, and asks
the AnimationTree state machine for its synchronized idle or walk state. It does
not retain or toggle complete canonical character scenes.

Canonical animations store `Skeleton2D.position` in their original raster-sheet
coordinate system, so those absolute values are not blended directly. The native
compiler rewrites that track as a zero-based `MotionOffset` track and leaves
directional rest placement in the pose contract. This prevents a direction
cross-fade from sending the rig through the large gap between source canvases.

Directional skin and rest-pose changes are discrete. Their limb tracks are
authored around projection-specific sockets, so geometrically cross-fading those
transforms can pass through the torso or collapse a limb even when both authored
endpoints are valid. `AnimationTree` keeps the locomotion phase synchronized,
but its direction transitions use a zero-duration swap by default. Future
cross-fades belong between animations sharing one projection and rest contract.

Run `neutral_native_skeleton_slice_workbench.tscn` to inspect the initial
architecture proof. The workbench automatically cycles S/SW/W; keys `1`, `2`, and `3` select them,
Space toggles walking, and `C` toggles automatic cycling. This is deliberately a
three-view performance and ownership proof, not yet the gameplay replacement.

`neutral_polygon_locomotion_test.tscn` now uses the same native runtime for all
eight movement octants. It intentionally disables the older twist, seam, aim,
and active-arm layers so this harness measures only direction switching and the
canonical walk clips.

Forearm, hand, shin, and foot paths differ between the existing canonical
scenes. Until those paths receive a uniform authored contract, their polygons
are compiled into the nearest principal arm or leg slot. The first native slice
therefore preserves the approved stiff-appendage behavior rather than claiming
unsupported joint semantics. Canonical scenes remain the editable source of
truth throughout the migration.

The locomotion test also hosts the first twist-chain prototype. Movement sets
the hips/legs direction, while arrows or the right stick provide an independent
desired aim direction. Torso rotation is limited to one 45-degree step from the
hips, head rotation to two steps from the torso, and the arms to one final step
from the head. The torso-facing scene owns both shoulder locations: aim-facing
arm geometry is attached to those two anchors independently instead of bringing
its own shoulder spacing into the composite. Releasing aim returns the chain to
the hips direction.

While the shot presentation is active, the ordinary arm pair uses the torso-facing view and
holds at its rest pose. A single side-neutral composite arm replaces whichever
arm has the cleaner shoulder-to-aim path, inherits that shoulder's depth, and
rotates continuously toward the exact aim vector. A small angular shoulder-switch
cone prevents the active arm from rapidly changing sides near an ambiguous boundary.

## Aim Posture Resolver

`HumanoidAimPostureResolver` owns shot memory and posture policy independently
from the native skeleton renderer. A shot event activates the pointing arm
immediately and refreshes a presentation-only hold timer. Holding the aim stick
pauses that timer so the pointing arm remains active until the stick returns to
neutral. While moving, the hips
remain aligned to locomotion, the torso turns at most one octant toward the shot,
and the head turns at most two further octants. The inactive arm remains part of
the torso subassembly.

When movement falls below the brace threshold, a short grace period protects
against incidental stops. The resolver then advances the hips and torso together
through consecutive 45-degree views until the aligned body rests 45 degrees from
the remembered shot. The head tracks immediately within its two-octant limit,
and the pointing arm continues to use the exact continuous shot vector. Once a
brace transition begins it finishes even if the arm's presentation timer expires,
and the completed brace remains until locomotion takes ownership again.

The current body stance remains valid while later shots fall inside its exported
angular comfort window. Separately, shoulder selection retains the current arm
when the shot is nearly perpendicular to the authored shoulder axis. These
stateful hysteresis rules prevent small aim changes from repeatedly rotating the
body or swapping the visible shooting shoulder.

The active shoulder is resolved from the canonical torso view's authored shoulder
coordinates. Their separation is projected onto the aim direction so the shoulder
that geometrically leads the shot is preferred. A configurable angular grace band
retains the current shoulder when neither socket is clearly closer, preventing
small aim changes from swapping the visible shooting shoulder. This same rule
applies across all torso orientations without encoding directional exceptions.
The continuous arm applies perspective shortening only along its authored local
length axis, preserving arm thickness as it rotates between vertical and horizontal
screen directions.

Run `neutral_polygon_twist_review_workbench.tscn` to inspect the representative
orientation matrix. Its eight rows cover every hips direction; the first column
shows the unarmed rest composite and the remaining columns aim through all eight
octants. Each frozen cell labels the resolved hips, torso, head, and active-arm
directions so a mismatched canonical view or attachment is easy to identify.

## Torso-To-Hips Seam Pilot

The twist composite derives its displayed lower-torso boundary from a fresh copy
of the authored torso polygon on every solve. Vertices in the lower boundary band
bind by normalized distance and retained normal offset to the torso view's own hip
seam, then resolve against the active hips view. A configurable inward overlap
prevents cracks without making the solved polygon canonical or accumulating
deformation between frames.

`torso_hip_seam_overlap` is exposed on the twist scene for visual tuning. Press
`T` in either the locomotion test or twist review matrix to compare the same pose
with the seam enabled and disabled.

## Whole-Character Foreshortening

The twist scene places the completed authored-space composite beneath a
`ProjectionRoot`. Its `foreshortening` property compresses screen Y around the
character's foot origin after seams and subassembly anchors are resolved. A value
of `1.0` preserves the authored model; lower values test steeper top-down viewing
angles without rewriting canonical polygons. The continuous active arm applies
the inverse projection when calculating its local angle so its displayed result
continues pointing along the requested aim vector.

The locomotion test and twist review matrix start at `0.65`. Press `[` or `]` to
adjust the factor in five-percent steps while keeping the currently displayed
pose intact. `preserve_head_shape` counter-scales the visible head around its neck
anchor, so the head retains authored proportions while its placement still
follows the projected body construction.

## North And South Symmetry Contract

The North and South head, torso, hips, arms, and legs use left-authored symmetry parts.
Edit the corresponding scene under `neutral_polygon_base/symmetry_parts`; the
canonical direction scene uses that source directly and places an
opposite-side copy under a negative-X mirror axis. Do not make local changes to
the mirrored instances, because those instances deliberately derive from the
left-authored source.

This contract applies to the editable rest construction, not every animated
pose. Walk animation tracks retain opposite limb phases and near/far draw order
so the gait alternates correctly while both sides still derive from the same
authored geometry.
