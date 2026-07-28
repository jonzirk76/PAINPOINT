# Loomis Step-3 Head Tilt Lab

This lab projects the first three head-construction elements from one shared
3D orientation:

1. A spherical cranium silhouette.
2. A circular side-plane slice, seen as a projected ellipse.
3. A vertical facial centerline and horizontal brow midline wrapped across the
   front half of the sphere.

A translucent cuboid surrounds the sphere as an orientation audit. The cube is
not part of the Loomis head and should never influence the eventual silhouette.
Its only purpose is to make pitch, yaw, roll, and perspective drift easy to
see.

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

### Compliance cube

- Red, green, and blue cube edges define the same local X, Y, and Z directions
  used to orient the head.
- Every guide responds to pitch, yaw, and roll in agreement with the cube.
- The sphere may touch neither the cube faces nor its corners; the extra space
  keeps the cube readable as a reference cage.

## Scope boundary

This stage does not add a jaw, facial thirds, ear placement, features, or
stylization. Those should wait until the sphere, side-plane ellipse, and
midline behavior survive visual review across the initial tilt batch.
