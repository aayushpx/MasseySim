shader_type canvas_item;
// Soft radial glow for the campus ground. Colours are tuned to sit in the
// Massey family: lighter around the quad centre, deeper at the edges.
uniform vec4 col_center : source_color = vec4(0.045, 0.075, 0.15, 1.0);
uniform vec4 col_edge : source_color = vec4(0.02, 0.05, 0.10, 1.0);
uniform vec2 uvc = vec2(0.5, 0.5);

void fragment() {
    float d = distance(UV, uvc);
    d = clamp(d * 1.6, 0.0, 1.0);
    COLOR = mix(col_center, col_edge, d * d);
}