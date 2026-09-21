// Modern Coding CRT

float warp = 0.19;      // was 0.25
float scan = 0.30;      // was 0.50

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 dc = abs(0.5 - uv);
    dc *= dc;

    // Curvature
    uv.x -= 0.5;
    uv.x *= 1.0 + dc.y * (0.3 * warp);
    uv.x += 0.5;

    uv.y -= 0.5;
    uv.y *= 1.0 + dc.x * (0.4 * warp);
    uv.y += 0.5;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
    {
        fragColor = vec4(0.0);
        return;
    }

    vec3 color = texture(iChannel0, uv).rgb;

    // -----------------------------
    // Darker image, preserve highlights
    // -----------------------------
    color = pow(color, vec3(1.10));

    // -----------------------------
    // Increase saturation
    // -----------------------------
    float luma = dot(color, vec3(0.299,0.587,0.114));
    color = mix(vec3(luma), color, 1.15);

    // -----------------------------
    // Highlight boost
    // -----------------------------
    color += smoothstep(0.70, 1.0, color) * 0.035;

    // -----------------------------
    // Slight phosphor tint
    // -----------------------------
    color *= vec3(0.97, 1.00, 0.98);

    // -----------------------------
    // Softer scanlines
    // -----------------------------
    float scanMask =
        1.0 -
        (0.5 + 0.5 * sin(fragCoord.y * 3.14159265))
        * scan * 0.35;

    color *= scanMask;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
