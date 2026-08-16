Edit only scripts/managers/item_manager.gd.

Make exactly this replacement:
- Replace `var _pickups: Array = []` with `var _pickups: Array[PickupEntity] = []`

Do not change any other code, formatting, comments, ordering, or whitespace.
Do not run commands, tests, or create new files.
Make no changes if the exact original line is absent.
