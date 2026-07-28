# Loomis Step-3 Head Tilt Lab

This lab projects the first three head-construction elements from one shared
3D orientation:

1. A spherical cranium silhouette.
2. A circular side-plane slice, seen as a projected ellipse.
3. A vertical facial centerline and horizontal brow midline wrapped across the
   front half of the sphere.

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
- `Step1Sphere`
- `Step2SidePlaneCut`
- `Step3Midlines`
- `Step4FaceGuidesAndJaw`

## Visual judging criteria

### Step 1: sphere

- The cranium silhouette remains circular regardless of head rotation.
- The sphere is centered inside the compliance cube.
- Rotation changes the internal guides, not the spherical silhouette.

### Step 2: side-plane cut

- The orange ellipse remains entirely inside the sphere.
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
- The facial plane joins the two ends of the brow guide to the two chin-side
  anchors.
- Paired triangular eye-cavity guides are centered halfway between the brow
  and nose guides. They are equilateral in facial-plane local space before
  projection.
- The mouth-bottom guide is halfway between the nose and chin guides.
- The default jaw profile is neutral, not canonical anatomy. Per-character
  tuning fields are `chin_drop_ratio`, `chin_forward_ratio`,
  `jaw_hinge_drop_ratio`, and `jaw_hinge_forward_ratio`.

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
