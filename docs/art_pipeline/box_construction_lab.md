# Box Construction Lab

The box construction lab is a deterministic perspective workbench for testing
how accurately a 2D polygon cage reconstructs a known 3D cuboid. It translates
the useful Drawabox feedback loop—construct, extend, inspect, adjust—into
measurable Godot geometry. It does not attempt to reproduce the human
pen-control portion of the 250-box exercise.

Run the visual batch generator, then open any scene in
`res://scenes/tools/construction_lab/generated/`. Each generated scene is an
editable Godot artifact built from `Polygon2D`, `Line2D`, and `Label` nodes.
The generated folder is intentionally left untracked so visual experiments do
not accumulate in feature commits.

`res://scenes/tools/construction_lab/box_construction_lab.tscn` remains a quick
four-case overview. Press Space in that overview to generate a new
deterministic set of corner offsets.

## What the display means

- Differently shaded faces are actual `Polygon2D` nodes built from the
  attempted corners.
- The thin white cage is the exact 3D-to-2D projection.
- Red edges are the cuboid's local X family.
- Green edges are the local Y family.
- Blue edges are the local Z family.
- Each right-side proof panel places the intended vanishing point as a yellow
  diamond.
- Thin pale rays show the exact path from the projected vertices to the
  intended vanishing point.
- Bright axis-colored extensions continue the attempted edges. Any separation
  from the diamond makes the construction error visible.
- White dots are the attempted 2D corners.

The ground truth and intended vanishing points are deliberately visible in
this first lab so the scoring system can be judged. A later challenge mode
should hide them until an attempt is submitted.

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
   per-axis convergence labels in the proof scene to identify the weakest
   spatial axis. The JSON report is machine-readable support, not the human
   review surface.
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
godot --headless --path . --script res://scripts/tools/construction_lab/generate_visual_box_batch.gd
```

The second command writes the deterministic machine-readable report to
`res://docs/art_pipeline/box_construction_sample_batch.json`. The third writes
the editable visual proof scenes to the untracked generated folder.

## Next stage

Once the score agrees with human judgment on representative boxes, extend the
same projection and evaluation boundary with a jaw wedge, cranium ellipsoid,
side-plane cut, and facial cross-contours. Do not add portrait scoring until
the box lab exposes which errors its current metrics fail to catch.
