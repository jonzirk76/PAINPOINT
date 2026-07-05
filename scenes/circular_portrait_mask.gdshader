shader_type canvas_item;

uniform float radius = 0.48;
uniform float softness = 0.01;

void fragment() {
    vec2 centered = UV - vec2(0.5);
    float dist = length(centered);

    float alpha = smoothstep(radius, radius - softness, dist);

    COLOR = texture(TEXTURE, UV);
    COLOR.a *= alpha;
}