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
4. Adjust **Tolerance** and **Vertex error**.
5. Click **Create Polygon2D Child**.

The generated node is a child of the source sprite, uses the sampled color, and
is added through the editor undo/redo history. It also stores its trace seed and
settings as node metadata.

To revise a generated polygon:

1. Select the traced `Polygon2D`.
2. Click **Edit Selected Traced Polygon**.
3. Adjust tolerance or vertex error and inspect the live preview.
4. Click **Update Selected Polygon2D**.

Updating replaces the existing geometry through editor undo/redo rather than
creating a duplicate node.

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
and image-space polygon vertices. An automation client can convert the returned
vertices with `RasterRegionTracer.image_points_to_sprite_local()` or apply the
same centering/offset/flip transform before creating a `Polygon2D`.

## MVP limitations

- Four-connected color regions only.
- The tolerance is a maximum difference per RGBA channel.
- Region-enabled `Sprite2D` nodes are not supported yet.
- Internal holes are not represented.
- Output is `Polygon2D` only.
