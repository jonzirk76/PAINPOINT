Edit only scripts/managers/fauna_manager.gd.

Make exactly this replacement:
- Replace `func spawn_cat(spawn_position: Vector2, movement_seed: int = 0):` with `func spawn_cat(spawn_position: Vector2, movement_seed: int = 0) -> Node:`

Do not change any other code, formatting, comments, ordering, or whitespace.
Do not run commands, tests, or create new files.
Make no changes if the exact original line is absent.
