# Neutral Humanoid Directional Cutout Proof

The neutral humanoid proof converts the five authored projections in
`characterbasetransparent.png` into editable Godot cutout rigs. The joint guides
in `joint_designation.tscn` define the anatomical partitions; source alpha defines
the exterior contour of each generated Polygon2D.

## Direction contract

The canonical scenes are South, South West, West, North West, and North. North
East, East, and South East are mirrored instances of the corresponding western
scene. This keeps the first proof eight-way without introducing three additional
authoring surfaces that can drift.

`neutral_humanoid_8_way.tscn` exposes the eight directions as one inspector enum.
Its active view is selected from the five canonical scenes at runtime.

## Rig contract

Each canonical scene owns this hierarchy:

- Hips
  - HipsMass
  - FarLeg / NearLeg
    - Thigh
    - Shin / ShinMass
    - Foot / FootMass
  - Torso / TorsoMass
    - FarArm / NearArm
      - UpperArm
      - Forearm / ForearmMass
      - Hand / HandMass
    - Head / HeadMass

The arms and legs animate in opposed phases beneath connected body anchors. The
profile's far arm and leg deliberately reuse the clear near-side source geometry.
Far-side pieces render behind the body and use darker modulation to communicate
depth; South and North retain equal bilateral depth.

## Regeneration

Run `build_neutral_directional_cutouts.gd` headlessly to rebuild the five
canonical scenes after changing the guide lines. Regeneration replaces generated
polygon geometry, so direct vertex edits to those five generated scenes should be
treated as disposable until the proof is promoted to a permanent authoring flow.

Open and run `neutral_humanoid_cutout_workbench.tscn` to compare all eight runtime
directions and the five editable canonical assemblies in one 1280x720 view.
