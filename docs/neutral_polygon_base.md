# Neutral Polygon Base

The neutral polygon base promotes the accepted raster cutout proof into five
editable, flat-color canonical scenes. It preserves the cutout hierarchy,
anchors, far-side modulation, and projection-specific walk animations without
retaining a texture dependency on the raster reference.

The five authored scenes are South, South West, West, North East, and North.
North West, East, and South East remain mirrored derivatives selected by
`neutral_polygon_8_way.tscn`.

## Ownership

- `neutral_cutout` owns disposable raster-derived reference scenes.
- `neutral_polygon_base` owns editable polygon art.
- `neutral_polygon_8_way.gd` owns direction selection and mirroring only.
- `neutral_polygon_review_workbench.tscn` owns comparison presentation only.

The promotion builder is intentionally one-way. Running
`build_neutral_polygon_base.gd` again replaces the five polygon scenes and should
only be done before hand-authored vertex edits begin, or after those edits have
been deliberately preserved elsewhere.

Open `neutral_polygon_review_workbench.tscn` to inspect all eight animated
directions and compare the five canonical polygon scenes against adjustable
raster overlays.
