# Loomis Step-3 Head Tilt Lab

This lab projects the first three head-construction elements from one shared
3D orientation:

1. A Loomis sphere refined into an elongated cranial ellipsoid.
2. The original circular Loomis side-plane slice, retained as a stable
   landmark inside the refined cranial volume.
3. A vertical facial centerline and horizontal brow midline wrapped across the
   front half of the cranium.
4. Mirrored facial and jaw anchors.
5. Eye spheres, a nose wedge, a vertical lower-face cylinder, and a neck
   cylinder expanded from the shared scaffold.

A translucent tangent cube surrounds the sphere as an orientation audit. Its
side length is exactly the sphere diameter, so the sphere touches every cube
plane at one point. The cube is not part of the Loomis head and should never
influence the eventual silhouette.

## Generate the visual batch

Run:

```text
godot --headless --path . --script res://scripts/tools/construction_lab/generate_loomis_step3_batch.gd
```

The generator writes four editable, intentionally untracked scenes to:

```text
res://scenes/tools/anatomy/generated_loomis_step3/
```

Open any generated scene and press F6. In the scene tree, independently toggle:

- `ComplianceCube`
- `Step1CraniumVolume`
- `Step2SidePlaneCut`
- `Step3Midlines`
- `Step4FaceGuidesAndJaw`
- `Step5FeatureVolumes`

## Recommended navigation

Start with `00_standardized_feature_volume_review.tscn`. It is the overview
and should be the normal entry point.

1. Use the 3×3 sheet to compare front, three-quarter, and profile placement
   across neutral, up, and down tilts.
2. Expand one card in the scene tree, then expand its `SharedProjection`.
3. Hide all five step groups.
4. Enable the groups in numerical order:
   `Step1CraniumVolume`, `Step2SidePlaneCut`, `Step3Midlines`,
   `Step4FaceGuidesAndJaw`, then `Step5FeatureVolumes`.
5. To edit or inspect a larger version, open the closest numbered single-pose
   scene. The numbered scenes use the same generated projection data at a
   larger scale.

The compliance cube exists only in the numbered single-pose scenes. It audits
rotation and perspective; it is not part of the head model and can normally
remain hidden during proportion review.

## Visual judging criteria

### Step 1: cranial volume

- The original sphere remains the proportional starting idea, but the visible
  volume is slightly narrower side-to-side and longer front-to-back.
- The same ellipsoid rotates with every internal guide.
- The posterior expansion changes the side silhouette without breaking the
  face-local symmetry axes.

### Step 2: side-plane cut

- The orange ellipse retains the original pre-skull-study Loomis placement:
  its local plane is 55% of the original sphere radius from center.
- Its underlying circle retains the original spherical cut radius even though
  the surrounding cranial silhouette is now elongated.
- It represents the same proportional slice in every pose: the plane is
  positioned at 55% of the sphere radius on the camera-near side.
- The ellipse becomes narrower or broader because of rotation, not because its
  underlying circular cut changes shape.
- Its two internal axes remain centered on the ellipse.

### Step 3: midlines

- The cyan vertical centerline runs from the top to the bottom of the sphere
  across its front hemisphere.
- The pink brow midline wraps from one side of the sphere to the other across
  the front hemisphere.
- Both curves meet at the yellow front-center marker.
- Looking up or down shifts their curvature coherently.
- Roll rotates the side plane and both midlines as one construction.

The tangent front-face square includes flat horizontal and vertical midpoint
lines. These define the same two 3D construction planes as the curved spherical
midlines. The straight side-plane diameter likewise shows the brow midline
flattening across the sliced plane.

### Step 4: facial thirds, mirrored jaw, and feature block-in

- The brow, nose, and chin guides are separate local-X lines projected at their
  own facial heights. Their image-space tilt is calculated rather than copied.
- The gold center descent continues from the sphere's front-center point
  through the nose center to the chin.
- The default orange near-ear jaw hinge is placed at the bottom extent of the
  side-plane ellipse.
- Each jaw hinge connects to the matching side of the chin rather than the
  center point. The far hinge and conceptual far-side ellipse are produced by
  mirroring the same local-space construction used on the visible side.
- The brow is the sphere midline. Brow-to-nose and nose-to-chin form the next
  two approximate thirds; these remain character- and style-tunable.
- The facial plane begins where the spherical brow curve meets each flat
  side-plane brow diameter, then descends to the two chin-side anchors.
- Each eye cavity uses two projected planes. The upper plane recedes from the
  brow ridge into the conceptual facial mass; the lower plane returns to the
  facial surface halfway between the brow and nose guides.
- A triangular nose block begins near the middle depth of the eye cavities and
  widens symmetrically to a base constrained to the nose guide.
- The mouth-bottom guide is halfway between the nose and chin guides.
- The default jaw profile is neutral, not canonical anatomy. Per-character
  tuning fields are `chin_drop_ratio`, `chin_forward_ratio`,
  `jaw_hinge_drop_ratio`, and `jaw_hinge_forward_ratio`.

### Step 5: feature volumes

- Both eyes are equal spheres mirrored across the face-local Y midline.
- The front of each eye sphere is approximately tangent to the vertical plane
  touching the brow in side view. The orbital planes wrap around the spheres;
  they do not replace them.
- The nose remains a symmetric wedge expanding from the facial plane.
- The lower maxilla, teeth, mouth region, and chin are grouped into one
  vertical conceptual cylinder. Its top cap touches the nose line and its
  bottom cap touches the chin.
- The cylinder width comes from the skull-study facial mass. Its front tangent
  sits near the nasal-cavity plane so the mass remains inset into the skull.
- The mouth is a projected curve on the front of this cylinder. Stylized lips
  and individual teeth should be derived from the shared volume rather than
  placed independently.
- The foramen magnum is an underside anchor. The neck is represented by a
  cylinder whose centerline begins at the middle of that opening.
- The foramen center is the first major joint. Head pitch rotates the skull
  around this attachment while the neck cylinder keeps a roughly stable
  orientation, tilted 15° backward in profile by default.
- The default neck joint angle is intentionally inside a 10–20° useful range
  and is controlled by `neck_joint_angle_degrees`.
- Oblique views may look asymmetric after projection, but all paired feature
  anchors originate from mirrored local-space coordinates.

## Standardized review sheet

The generator also writes:

```text
res://scenes/tools/anatomy/generated_loomis_step3/00_standardized_feature_volume_review.tscn
```

This scene uses a fixed 3×3 matrix. Rows are neutral, looking up, and looking
down. Columns are front, three-quarter, and one profile. Scale, proportions,
colors, and visible construction groups remain identical so feature depth can
be compared without reframing noise.

### Compliance cube

- Red, green, and blue cube edges define the same local X, Y, and Z directions
  used to orient the head.
- Every guide responds to pitch, yaw, and roll in agreement with the cube.
- The sphere touches each cube plane once and remains clear of every cube edge
  and corner.

## Scope boundary

This stage establishes proportional construction rather than finished
features. Eye shape, mouth volume, anatomical ear placement, and stylization
should wait until the facial plane and mirrored jaw survive visual review
across the initial tilt batch.
