You are making one mechanical GDScript typing edit in `scripts/managers/projectile_manager.gd`.

Replace exactly this declaration:

`var _projectiles: Array = []`

with:

`var _projectiles: Array[ProjectileEntity] = []`

Constraints:

- Edit only `scripts/managers/projectile_manager.gd`.
- Make no other code, formatting, comment, ordering, or whitespace changes.
- Do not alter behavior.
- Do not run commands or tests.
- Do not add files.
- If the exact original declaration is absent, make no changes.
