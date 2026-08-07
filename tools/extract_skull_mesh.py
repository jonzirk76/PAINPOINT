#!/usr/bin/env python3
"""Extract a lightweight, upright skull mesh from the Artec skeleton scan."""

from __future__ import annotations

import argparse
import json
from array import array
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--metadata", type=Path)
    parser.add_argument("--minimum-source-z", type=float, default=635.0)
    parser.add_argument("--cluster-size", type=float, default=1.5)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    coordinates = array("f")
    source_min = [float("inf")] * 3
    source_max = [float("-inf")] * 3

    with args.source.open("r", encoding="ascii", errors="ignore") as source:
        for line in source:
            if not line.startswith("v "):
                continue
            x, y, z = map(float, line.split()[1:4])
            coordinates.extend((x, y, z))
            for axis, value in enumerate((x, y, z)):
                source_min[axis] = min(source_min[axis], value)
                source_max[axis] = max(source_max[axis], value)

    def vertex_allowed(source_index: int) -> bool:
        offset = (source_index - 1) * 3
        x, y, z = coordinates[offset : offset + 3]
        if z < args.minimum_source_z:
            return False
        # Remove the upper cervical column below the cranial base while
        # retaining the anterior mandible and posterior base of the skull.
        if z < 680.0 and 155.0 < y < 225.0:
            return False
        # Remove the scan's narrow mounting post above the crown.
        if z > 825.0 and 15.0 < x < 40.0 and 225.0 < y < 260.0:
            return False
        return True

    cell_to_index: dict[tuple[int, int, int], int] = {}
    cell_sums: list[list[float]] = []
    source_to_output: dict[int, int] = {}
    faces: set[tuple[int, int, int]] = set()
    cluster = args.cluster_size

    def output_index(source_index: int) -> int:
        existing = source_to_output.get(source_index)
        if existing is not None:
            return existing
        offset = (source_index - 1) * 3
        x, y, z = coordinates[offset : offset + 3]
        # Source: X left/right, Y back/front, Z down/up.
        # Godot: X left/right, Y up/down, Z back/front. Front faces -Z.
        converted = (x, z, -y)
        cell = tuple(round(value / cluster) for value in converted)
        result = cell_to_index.get(cell)
        if result is None:
            result = len(cell_sums) + 1
            cell_to_index[cell] = result
            cell_sums.append([converted[0], converted[1], converted[2], 1.0])
        else:
            accumulator = cell_sums[result - 1]
            accumulator[0] += converted[0]
            accumulator[1] += converted[1]
            accumulator[2] += converted[2]
            accumulator[3] += 1.0
        source_to_output[source_index] = result
        return result

    with args.source.open("r", encoding="ascii", errors="ignore") as source:
        for line in source:
            if not line.startswith("f "):
                continue
            raw_indices = [int(part.split("/", 1)[0]) for part in line.split()[1:4]]
            if any(not vertex_allowed(index) for index in raw_indices):
                continue
            face = tuple(output_index(index) for index in raw_indices)
            if len(set(face)) == 3:
                faces.add(face)

    vertices = [
        (values[0] / values[3], values[1] / values[3], values[2] / values[3])
        for values in cell_sums
    ]
    center_x = (min(vertex[0] for vertex in vertices) + max(vertex[0] for vertex in vertices)) / 2.0
    bottom_y = min(vertex[1] for vertex in vertices)
    center_z = (min(vertex[2] for vertex in vertices) + max(vertex[2] for vertex in vertices)) / 2.0
    vertices = [(x - center_x, y - bottom_y, z - center_z) for x, y, z in vertices]

    args.destination.parent.mkdir(parents=True, exist_ok=True)
    with args.destination.open("w", encoding="ascii", newline="\n") as destination:
        destination.write("# Derived from Artec Group Human skeleton scan, CC BY 3.0\n")
        destination.write("# Cropped skull reference; vertex-cluster reduction applied\n")
        for x, y, z in vertices:
            destination.write(f"v {x:.5f} {y:.5f} {z:.5f}\n")
        for a, b, c in sorted(faces):
            destination.write(f"f {a} {b} {c}\n")

    metadata = {
        "source": str(args.source),
        "license": "Creative Commons Attribution 3.0 Unported",
        "attribution": "Artec Group Inc. (www.artec3d.com)",
        "minimum_source_z": args.minimum_source_z,
        "cluster_size": cluster,
        "source_vertex_count": len(coordinates) // 3,
        "output_vertex_count": len(vertices),
        "output_face_count": len(faces),
        "source_bounds": {"minimum": source_min, "maximum": source_max},
        "axis_conversion": "source (x,y,z) -> Godot (x,z,-y); front is -Z",
    }
    metadata_path = args.metadata or args.destination.with_suffix(".json")
    metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
