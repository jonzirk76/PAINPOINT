Edit only scripts/resources/damage_packet.gd.

Make exactly these replacements:
- Replace `func copy_for_chain():` with `func copy_for_chain() -> DamagePacket:`
- Replace `func copy_for_explosion():` with `func copy_for_explosion() -> DamagePacket:`
- Replace `func copy_with_damage_bonus(bonus: int):` with `func copy_with_damage_bonus(bonus: int) -> DamagePacket:`

Do not change any other code, formatting, comments, ordering, or whitespace.
Do not run commands, tests, or create new files.
Make no changes if any exact original line is absent.
