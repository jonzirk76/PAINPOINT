# Anatomy Polygon Experiments

These studies apply the projected Loomis construction to two deliberately
different proportion systems.

## Skull batch

Run:

```text
godot --headless --path . --script res://scripts/tools/construction_lab/generate_anatomy_polygon_experiments.gd
```

The four scenes under `scenes/tools/anatomy/skull_studies/` use the same
pitch, yaw, roll, facial thirds, side ellipses, jaw hinges, and facial-plane
anchors as the Loomis tilt batch. Layered polygons interpret those anchors as
a cranial vault, temporal masses, recessed orbits, nasal aperture, zygomatic
bridges, maxilla, tooth row, and mandible. Toggle `ConstructionScaffold` to
compare the skull planes with the underlying guides.

The mouth-bottom guideline passes through the midpoint of the skull's tooth
row. This provides a shared placement landmark when translating from realistic
anatomy into the shortened anime lower face.

The source skull sheet is an anatomical reference, not a view-by-view trace.
All four studies derive from the shared projection so spatial consistency has
priority over matching any one photograph.

## Anime portrait comparison

`scenes/tools/experiment_polygon_comparison_v2.tscn` places three panels
side-by-side:

1. `experiment.png`
2. the original direct polygon reconstruction
3. a new construction-driven polygon reconstruction

The new attempt preserves anime direction rather than forcing realistic skull
ratios. It enlarges the cranium and orbits, compresses the nose and lower face,
and tapers the jaw. Perspective still affects the paired features: the near
eye is wider, the far eye is compressed, the nose follows the facial
center-plane, and the mouth sits halfway between the nose base and the
anime-shortened chin. Toggle `ConstructionOverlay` under `NewArtwork` to
inspect those relationships.
