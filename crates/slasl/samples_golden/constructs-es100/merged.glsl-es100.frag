precision highp float;
precision highp int;

uniform vec4 base_color;

uniform sampler2D irr;

varying vec3 v_normal;
vec4 slasl_probe_volume(sampler2D env, vec3 dir)
{
    vec3 d = normalize(dir);
    vec2 uv = vec2(atan(d.z, d.x) * 0.15915494 + 0.5, acos(clamp(d.y, -1.0, 1.0)) * 0.31830989);
    return texture2D(env, uv);
}


void main()
{
    gl_FragColor = (slasl_probe_volume(irr, v_normal) * base_color);
}
