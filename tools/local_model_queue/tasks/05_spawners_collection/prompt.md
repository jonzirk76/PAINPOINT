You are making one mechanical GDScript typing edit in `scripts/managers/spawner_manager.gd`.

Replace exactly this declaration:

`var _spawners: Array = []`

with:

`var _spawners: Array[EnemyEntity] = []`

Constraints:

- Edit only `scripts/managers/spawner_manager.gd`.
- Make no other code, formatting, comment, ordering, or whitespace changes.
- Do not alter behavior.
- Do not run commands or tests.
- Do not add files.
- If the exact original declaration is absent, make no changes.
