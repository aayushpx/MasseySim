shader_type canvas_item;
// Very light cinematic vignette. Subtle on purpose - premium means restrained.
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 0.42);

void fragment() {
    vec2 p = SCREEN_UV - vec2(0.5);
    float r = length(p) * 1.35;
    COLOR = vec4(tint.rgb, tint.a * smoothstep(0.55, 1.05, r));
}