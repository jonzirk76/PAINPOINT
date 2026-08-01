# Raster Region Polygon

Godot 4.7 editor plugin for tracing a contiguous color region in a `Sprite2D`
texture into an editable `Polygon2D`.

## Enable

1. Open **Project > Project Settings > Plugins**.
2. Enable **Raster Region Polygon**.
3. Open the **Raster Polygon** dock.

## Use

1. Select one `Sprite2D` whose texture contains the region to trace.
2. Click **Use Selected Sprite2D**.
3. Click inside a region in the dock preview.
4. Adjust **Tolerance**, **Vertex error**, **Cleanup radius**, and **Node name**.
5. Click **Create Polygon2D Child**.

Use the mouse wheel over the preview to zoom around the cursor and drag with
the middle mouse button to pan. The **−**, **+**, and **Fit** buttons provide
the same zoom controls without a wheel. Left-click selection continues to use
source-image pixel coordinates at every zoom level.

**Cleanup radius** performs a morphological close on the selected pixel mask
before its contour is generated. Small values bridge narrow interruptions such
as a hair strand crossing a face, preventing the outline from following that
channel into detailed features like an eye. `0 px` preserves the original mask;
start at `1 px` and increase only until the unwanted channel closes.

Use **Draw Fill Limit** to left-drag a lasso in the preview. Flood fill cannot
travel outside the blue boundary, even when pixels beyond it match the sampled
color. The lasso is stored with the generated node for recapture. **Clear
Limit** restores unrestricted fill.

The generated node is a child of the source sprite, uses the sampled color, and
is added through the editor undo/redo history. It also stores its trace seed and
settings as node metadata.

## Editing architecture

The dock is a view over a canonical editing model rather than the owner of
trace state:

- `TraceRecipe` owns seed, tolerance, simplification, cleanup, alpha, and fill
  limit settings and serializes versioned node metadata.
- `TraceDraft` combines a source with a recipe and owns the current generated
  preview result.
- `TraceSessionModel` owns the current draft, selected generated target, scene
  snapshot, and destination state.
- `TraceSceneChecker` reads the live Godot scene and classifies targets as
  clean, manually edited, stale, missing, or unmanaged.
- `TraceOperationController` turns UI requests into create, update, regenerate,
  or reject plans. It rechecks scene preconditions immediately before applying
  an accepted plan through editor undo/redo.

After every accepted mutation, the model is synchronized from the scene again.
Generated nodes receive stable trace IDs; node names remain user-facing labels
rather than hidden identity or command routing.

### Generated polygon vertex editing

The plugin includes a deliberately bounded vertex-edit mode for polygons it
generated. Select one generated `Polygon2D`, click **Edit Vertices**, then use
the handles inside the dock preview (not Godot's main 2D viewport):

- Drag empty canvas space to box-select vertices. Hold Shift to add a box to
  the current selection.
- Click a vertex to select it, or Shift-click to add it, then drag any selected
  vertex to move the entire selection.
- Press Delete/Backspace or click **Delete Selected** to remove the selection.
- Press Escape to clear the selection and **Stop** to leave vertex-edit mode.

Viewport gestures never mutate scene geometry directly. `PolygonEditSession`
owns the target, baseline, selection, and mode; `PolygonViewportEditTool`
translates editor input into proposals; `PolygonEditChecker` verifies target
identity and geometry; and `PolygonEditController` applies accepted plans as
single editor undo/redo actions. A changed polygon remains associated with its
trace recipe but is intentionally classified as manually edited, so later
regeneration retains its existing replacement warning.

The initial editor only supports box selection, group movement, and group
deletion. It rejects edits that leave a piece with fewer than three vertices
or that Godot cannot triangulate. It does not edit unmanaged `Polygon2D` nodes.

To revise a generated polygon:

1. Select the traced `Polygon2D`.
2. Click **Edit Selected Traced Polygon**.
3. Adjust its trace recipe and inspect the live preview.
4. Click **Update Selected Polygon2D**.

Creation and updating are separate destination flows. **Create New Polygon2D**
uses **New node name**, never overwrites an existing node, and makes the new
polygon the active update target. **Update Selected Polygon2D** ignores the
new-node name and changes only the generated polygon explicitly loaded with
**Edit Selected Traced Polygon**. Name collisions are blocked and explained.

When the existing polygon geometry or color no longer matches its regenerated
baseline, normal update becomes unavailable and the action changes to
**Regenerate Selected Polygon2D**. That destructive action asks for confirmation
before replacing manual changes.

## Headless/agent use

The tracing algorithm lives in `raster_region_tracer.gd` and does not depend on
the editor dock. `trace_texture_cli.gd` exposes it as a read-only JSON command:

```bash
godot4 --headless --path /path/to/project \
  --script res://addons/raster_region_polygon/trace_texture_cli.gd -- \
  --texture res://art/source.png \
  --x 320 --y 180 \
  --tolerance 0.12 \
  --vertex-error 3.0 \
  --cleanup-radius 1 \
  --limit-points "90,70;210,70;210,240;90,240" \
  --include-alpha true
```

For an `AtlasTexture`, pass its source texture and crop rectangle. Seed
coordinates and returned vertices are relative to the cropped region:

```bash
  --texture res://art/source_sheet.png \
  --region-x 289 --region-y 70 \
  --region-width 303 --region-height 697
```

The command prints image dimensions, sampled RGBA color, selected-pixel count,
and image-space polygon pieces. Simple regions contain one piece. Contours that
Godot cannot triangulate are passed through a small geometry repair offset and
emitted as ordinary valid sub-polygons instead of creating an invisible
`Polygon2D`. Automation clients can turn the pieces into `Polygon2D.polygon`
and `Polygon2D.polygons` data with
`RasterRegionTracer.build_polygon_data()`.

For a contiguous trace, contour repair keeps the dominant repaired outline and
discards small closed slivers produced around former self-touching points. A
single-piece result uses a normal empty `Polygon2D.polygons` array so its editor
handles do not contain cross-piece connector lines.

To update an existing traced node directly without driving the editor dock,
also pass its scene and root-relative node path:

```bash
  --scene res://scenes/tools/tracing_study.tscn \
  --node Sprite2D/HairMass \
  --summary-only true
```

Both options are required together. The command replaces the target
`Polygon2D` geometry, color, and recapture metadata, then saves the scene.
`--summary-only true` omits the potentially large coordinate arrays from the
JSON response.

## MVP limitations

- Four-connected color regions only.
- The tolerance is a maximum difference per RGBA channel.
- Region-enabled `Sprite2D` nodes are not supported yet.
- Contour repair can expand a complex boundary by up to a few pixels.
- Output is `Polygon2D` only.
