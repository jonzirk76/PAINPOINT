# Native Cutout Rig Spike

The spike deliberately tests one authored projection before the directional system grows again.

Open `res://scenes/tools/volette_native_cutout_spike_workbench.tscn` and run the current scene. The left panel shows the bottom-left projection and its horizontal mirror at authoring scale. The right panel compares the same rig at approximately 80 world pixels against the current player SVG.

## Semantic contract

The reusable body contract is a seven-piece `Skeleton2D` hierarchy:

```text
Hips
├── FarLeg
├── NearLeg
└── Torso
    ├── FarArm
    ├── NearArm
    └── Head
```

Each `Bone2D` owns rigid `Polygon2D` artwork. The `walk` animation belongs to `AnimationPlayer`; there is no procedural gait script. Torso, hips, and head remain independently animatable even though the first walk keeps their rotations neutral.

Hair, weapons, aiming, view selection, deformation weights, and runtime player integration are intentionally outside this spike. The next decision is whether this one-view workflow is comfortable and readable enough at gameplay scale to justify adding the other authored projections and an `AnimationTree`.
