# Box Construction Lab

The box construction lab is a deterministic perspective workbench for testing
how accurately a 2D polygon cage reconstructs a known 3D cuboid. It translates
the useful Drawabox feedback loop—construct, extend, inspect, adjust—into
measurable Godot geometry. It does not attempt to reproduce the human
pen-control portion of the 250-box exercise.

Open `res://scenes/tools/construction_lab/box_construction_lab.tscn` to review
the four-case sample batch. Press Space to generate a new deterministic set of
corner offsets. The underlying cuboids and poses remain fixed.

## What the display means

- Translucent faces and the thin white cage are the exact 3D-to-2D projection.
- Red edges are the cuboid's local X family.
- Green edges are the local Y family.
- Blue edges are the local Z family.
- Faint extensions reveal whether each attempted edge family is drifting away
  from a shared convergence.
- White dots are the attempted 2D corners.

The ground truth is deliberately visible in this first lab so the scoring
system can be judged. A later challenge mode should hide it until an attempt is
submitted.

## Scoring criteria

The overall score is a weighted diagnostic, not an aesthetic grade.

| Criterion | Weight | Measurement | What to inspect |
| --- | ---: | --- | --- |
| Corner placement | 40% | Root-mean-square distance from the eight projected corners | Silhouette, plane proportions, and landmark placement |
| Convergence | 35% | Mean angular error across all twelve edges | Each color family should aim consistently toward one vanishing direction |
| Topology | 15% | Convex faces with winding matching the ground truth | No folded, crossed, or inside-out polygon faces |
| Face proportion | 10% | Relative projected-area error across six faces | Near/far relationships and foreshortening |

The default diagnostic bands are:

- **90–100, ready:** construction is suitable as a polygon scaffold.
- **75–89.99, solid:** usable, but inspect the largest axis or corner error.
- **60–74.99, review:** correct the construction before adding detail.
- **Below 60, rebuild:** return to the major axes and silhouette.

These thresholds are intentionally provisional. Judge whether they match
visible usefulness before treating them as locked requirements.

## Human judging workflow

1. **Read the silhouette first.** Ignore the score. Decide whether the box
   feels like one rigid volume rather than six unrelated quadrilaterals.
2. **Check the three edge families.** Follow red, green, and blue separately.
   Their extensions should converge consistently. A single outlier usually
   identifies the corner that needs rebuilding.
3. **Check near and far planes.** Confirm the face nearer the camera does not
   accidentally read as the smaller or more distant plane.
4. **Check topology.** Look for crossed edges, concave faces, reversed winding,
   or a corner shared inconsistently by adjacent faces.
5. **Read the metrics.** Use corner RMSE to locate placement trouble and the
   per-axis convergence values in the JSON report to identify the weakest
   spatial axis.
6. **Choose one correction.** Move only the corner or edge family responsible
   for the largest visible error, then reassess. Do not polish individual
   faces independently.
7. **Accept or reject the scaffold.** Use `ready` as the initial acceptance
   band, while also recording cases where the score and visual judgment
   disagree.

For curriculum calibration, the disagreements are more valuable than the
passing cases. Preserve examples where a high score still looks spatially
wrong, or a lower score remains useful for stylized art; those should drive
future weighting changes.

## Running the targeted checks

From the repository root, using the Godot executable available on the machine:

```text
godot --headless --path . --script res://tests/box_construction_lab_test.gd
godot --headless --path . --script res://scripts/tools/construction_lab/run_box_construction_batch.gd
```

The second command writes the deterministic report to
`res://docs/art_pipeline/box_construction_sample_batch.json`.

## Next stage

Once the score agrees with human judgment on representative boxes, extend the
same projection and evaluation boundary with a jaw wedge, cranium ellipsoid,
side-plane cut, and facial cross-contours. Do not add portrait scoring until
the box lab exposes which errors its current metrics fail to catch.
