shader_type canvas_item;
// Full-screen cinema pass: dark vignette + a faint Massey-grade veil + film
// grain, all in ONE subtle rect on a CanvasLayer above the world, below the
// HUD. Deliberately restrained - the poster look should stay poster-bright.
// Stays transparent in the centre; only vignette edges, a whisper of grade
// veil and grain specks contribute. No SCREEN_TEXTURE reads, so it renders
// identically on Forward+ and the Compatibility (Web) renderer.
uniform vec4 vig_col : source_color = vec4(0.012, 0.03, 0.07, 0.40);
uniform float vig_inner : hint_range(0.0, 1.0) = 0.5;
uniform float vig_outer : hint_range(0.5, 1.6) = 1.1;
uniform float grade : hint_range(0.0, 0.35) = 0.05;
uniform vec4 grade_navy : source_color = vec4(0.04, 0.09, 0.19, 1.0);
uniform vec4 grade_gold : source_color = vec4(0.22, 0.15, 0.05, 1.0);
uniform float grain : hint_range(0.0, 0.15) = 0.03;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 p = uv - vec2(0.5);
    float r = length(p * vec2(1.0, 0.82)) * 1.8;
    float vig = smoothstep(vig_inner, vig_outer, r);

    // Grading veil: squid-ink navy up top, warm gold at the floor line.
    vec3 grade_col = mix(grade_navy.rgb, grade_gold.rgb, clamp(p.y + 0.5, 0.0, 1.0));
    float veil = grade * (0.4 + 0.6 * vig);

    // Animated grain: paired speckles so some go light, some go dark.
    vec2 cell = uv * vec2(1000.0, 560.0) + vec2(floor(TIME * 12.0), 0.0);
    float g = step(0.985, hash(cell)) - step(0.985, hash(cell + vec2(7.0, 3.0)));

    float a = clamp(vig_col.a * vig + veil + abs(g) * grain, 0.0, 1.0);
    vec3 c = grade_col + vec3(g * grain);
    COLOR = vec4(c, a);
}