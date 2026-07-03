# Character SVGs

Top-down vector character concepts for the current greybox style.

- `player_character.svg`
- `player_body.svg`
- `player_arms_gun.svg`
- `player_upper_body_gun.svg`
- `basic_enemy_chaser.svg`
- `fast_enemy_runner.svg`
- `tank_enemy_brute.svg`
- `shooter_enemy_orbiter.svg`
- `boss_enemy_overlord.svg`

Each SVG uses a transparent background and a `128x128` viewBox so it can be imported as a texture or used as reference art for later sprite work.

`player_character.svg` is split into two labeled groups:

- `bottom_half_feet`: simple oval feet intended for walking offsets or frame swaps.
- `top_half_body_and_gun`: the purple-haired upper body, blue outfit, arms, and gun.

`player_body.svg` and `player_arms_gun.svg` are the runtime layers. `PlayerEntity` draws animated oval feet in code, keeps the body layer upright, and rotates only the arms/gun layer toward the normalized aim direction.

`player_upper_body_gun.svg` is kept as a combined reference layer.
