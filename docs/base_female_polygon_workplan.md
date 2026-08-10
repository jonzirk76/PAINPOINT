# Base Female Polygon Model Workplan

Status: deferred until the next weekly usage reset  
Prepared: 2026-08-07

## Objective

Preserve the accepted current polygon humanoid as the base male model and create
a parallel base female model that satisfies the same native humanoid runtime
contract. The first female pass should remove most blank-canvas labor while
remaining deliberately easy to correct in Godot.

The female model is a distinct authored anatomy, not a runtime deformation of
the male model. Both models reuse the same compilation, eight-direction
selection, locomotion, twisting, aiming, handed active-arm mirroring,
foreshortening, and relative-Z systems.

## Cost And Deferral

The rough five-view polygon fit is high-cost visual and scene work with
medium-to-high iteration risk. Work was deferred at 8% weekly usage rather than
consume the remaining budget before reset. No model or scene mutations were
made during this planning pass.

## Existing Work Safety

The accepted male source currently includes uncommitted edits in its five
canonical scenes, symmetry parts, active arm, and skin resource. These vertices
are the reference construction and must not be regenerated, normalized, or
rewritten mechanically.

Before deriving the female sources:

1. Recheck `git status` and review only the relevant humanoid art diffs.
2. Checkpoint the accepted male authoring files in a dedicated commit.
3. Include the female reference image in the later female-authoring commit, not
   the male checkpoint.
4. Do not rerun `build_neutral_polygon_base.gd`; it is a one-way promotion tool
   that would replace hand-authored work.

## Naming And Compatibility

Rebrand the existing model as the base male at the resource and editor-facing
level. Retain the existing `neutral_*` file paths initially so Godot resource
UIDs, workbenches, and gameplay references do not undergo a broad rename at the
same time as the female model is introduced.

Suggested identities:

- Existing `neutral_humanoid_rig.tres`: editor identity `base_male_humanoid`.
- Existing `neutral_polygon_skin.tres`: editor identity
  `base_male_polygon`.
- New female resources: `base_female_humanoid_rig.tres` and
  `base_female_polygon_skin.tres`.
- New female source directory:
  `scenes/characters/base_female_polygon/`.

A later isolated cleanup may rename legacy male paths after the two-model
workflow is proven. That rename is not part of this pass.

## Shared Semantic Contract

Every female canonical scene must preserve the established seven-bone paths:

```text
Hips
├── FarLeg
├── NearLeg
└── Torso
    ├── FarArm
    ├── NearArm
    └── Head
```

It must also preserve:

- the five authored directions: South, South West, West, North East, North;
- mirrored runtime derivatives for North West, East, and South East;
- `RESET` and `walk` animation names and compatible limb tracks;
- relative-Z ownership beneath semantic bones;
- `0/-1/-2` upper/middle/distal limb segment ordering;
- left-authored North and South symmetry parts beneath negative-X mirror axes;
- one left-authored active-arm scene, mirrored at runtime for right-hand shots;
- editable polygon metadata required by the raster polygon plugin.

The shared runtime scripts should not acquire male/female conditionals. If the
female anatomy needs different sockets or rest transforms, those differences
belong in its directional scenes and female rig resource.

## Projection And Proportion Guidance

The completed male trace is the projection reference. The female mockup at
`art/concept_art/female_character_template.png` is a silhouette and anatomy
guide, but it is less foreshortened and must not set the overall screen-space
height or vertical spacing.

For each canonical female view:

1. Match the male construction's head scale and pitch unless the female contour
   requires a small local correction.
2. Preserve the male view's head-to-feet envelope, neck height, torso depth,
   hip elevation, foot baseline, and amount of limb overlap.
3. Reshape individual forms inside that envelope rather than uniformly scaling
   the mockup figure.
4. Keep the frontal visible shoulder width and hip width approximately equal.
   The waist may narrow between them, but the shoulder socket span must not
   remain substantially wider than the hips as in the male base.
5. Carry the shoulder/hip relationship through the turn as projected volumes:
   the diagonal view uses depth overlap, and the profile shows the hip and chest
   depth appropriate to the same anatomy rather than forcing equal screen-X
   widths.
6. Preserve the established top-down compression. Do not lengthen the torso,
   thighs, or shins merely to match the mockup's more elevated camera.
7. Keep hands and feet fully inside the male gameplay envelope so direction
   changes do not produce apparent scale jumps.

Primary silhouette changes expected to remain visible at gameplay scale:

- shoulders closer to hip width;
- narrower waist and lower ribcage transition;
- fuller hip and upper-thigh masses;
- adjusted chest contour without changing the torso semantic boundary;
- slightly different upper-arm and thigh taper;
- no sex-specific hair or clothing in the anatomy base.

## Female Authoring Sources

Create a complete independent set rather than local overrides on male scenes:

- `base_female_polygon_south.tscn`
- `base_female_polygon_south_west.tscn`
- `base_female_polygon_west.tscn`
- `base_female_polygon_north_east.tscn`
- `base_female_polygon_north.tscn`
- `base_female_polygon_active_arm.tscn`
- North and South head, torso, hips, left-arm, and left-leg symmetry parts

Start from copies of the checkpointed male sources so bone paths, animations,
metadata, draw order, and projection bounds are inherited. Replace resource
references so female symmetric parts never point back into the male source
directory.

The rough polygon pass may use raster tracing where a clean region exists, but
the result should be simplified and fitted to the male projection envelope.
For shaded or connected mockup regions, use a small deliberately editable
polygon rather than preserving noisy line-art contours. The goal is a useful
construction blockout, not a literal high-resolution outline.

## Rig And Skin Resources

Create a female `HumanoidAnimationRigSource` and
`PolygonCharacterSkinSource`, each referencing the five female scenes. This
gives the female base independent sockets and authored rest shapes while keeping
all runtime behavior generic.

Initially copy the accepted male gait tracks and timing unchanged. Do not tune
female motion during the silhouette pass; that would make it difficult to tell
whether a visual difference comes from anatomy or animation.

The female skin resource owns the female active-arm scene. It follows the same
left-arm authoring contract documented by `PolygonCharacterSkinSource`; runtime
handedness mirroring needs no female-specific code.

## Review Workbench

Add a female directional review workbench with:

- the five editable canonical scenes;
- all eight derived gameplay directions;
- the female reference image as an optional overlay;
- inspector controls for overlay visibility and opacity;
- alignment based on the accepted male projection envelope;
- a male/female gameplay-scale comparison row using the same animation phase;
- labels that clearly distinguish source directions from mirrored derivatives.

The full 2048-by-2048 reference sheet may be displayed through five cropped
`AtlasTexture` regions or five region-enabled overlay sprites. Cropping belongs
to the workbench only; canonical female scenes must not depend on the raster
texture at runtime.

## Implementation Sequence

1. Checkpoint the accepted male art and change only editor/resource identities
   from neutral to base male.
2. Duplicate the five canonical scenes, symmetry parts, and active arm into the
   female directory while rewriting all internal female references.
3. Add female rig and skin resources and a female native runtime scene/slice
   that injects those resources into the existing generic runtime.
4. Fit South first, enforcing shoulders approximately equal to hips and the
   male head-to-feet envelope.
5. Fit North from the same width and symmetry contract.
6. Fit South West and North East using the frontal volumes and mockup depth
   cues, not raw mockup height.
7. Fit West last as the profile consistency check.
8. Fit the authored left active arm to the female upper-arm/hand proportions.
9. Add the review workbench and gameplay-scale male/female comparison.
10. Perform one static reference audit and hand the visual tuning pass to the
    user.

## Proposed Commit Boundaries

1. `Checkpoint base male polygon authoring`
   - accepted current male vertices, symmetry parts, active arm, and resource
     identity;
   - no female files.
2. `Scaffold base female humanoid sources`
   - independent female scenes, symmetry references, rig/skin resources, and
     runtime injection;
   - female template asset/import metadata.
3. `Add rough female directional polygon pass`
   - five fitted directions and active arm;
   - no gait retuning.
4. `Add base female review workbench`
   - adjustable overlay and male/female gameplay-scale comparison.

If the scaffold and rough fit are produced together mechanically and remain
easy to review, commits 2 and 3 may be combined. The male checkpoint must remain
separate.

## Validation And Handoff

Without explicit test permission, validation is limited to:

- `git diff --check`;
- scene/resource path and UID reference inspection;
- verifying every female resource points only to female authoring scenes;
- verifying all five scenes expose the semantic bone paths;
- verifying North/South mirrored instances point to female symmetry parts;
- verifying every Polygon2D beneath gameplay bones uses relative Z;
- checking that the active arm remains a left-authored source;
- checking that no male polygon vertices changed after the checkpoint.

The user remains the visual playtester. The first handoff should ask them to
inspect, in order: frontal shoulder/hip balance, total foreshortening, diagonal
volume continuity, profile depth, and direction-switch scale stability.

## Acceptance Criteria For The Rough Pass

- The male model is visibly and unambiguously branded as the base male without
  breaking legacy scene references.
- The female model can run through the existing eight-direction native runtime
  without conditional runtime code.
- All five female source views are independently editable and preserve the
  symmetry contract where applicable.
- Female and male figures occupy the same established gameplay projection
  envelope.
- The female front view reads as shoulders and hips of approximately equal
  width, with that anatomy remaining coherent through diagonal and profile
  views.
- The blockout is low-resolution and easy to touch up; it does not contain
  laborious contour noise copied from the mockup.
- Gait, twist, aim posture, active-arm handedness, and relative-Z behavior are
  inherited unchanged.
