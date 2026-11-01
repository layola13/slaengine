#version 300 es
precision highp float;
precision highp int;

layout(std140) uniform Scene
{
    vec3 light_dir;
};

layout(std140) uniform Params
{
    vec4 base_color;
};

in vec3 v_normal;
in vec3 v_world;
out vec4 slasl_frag_color;

void main()
{
    slasl_frag_color = vec4((((((normalize(cross(v_normal, vec3(0.0, 1.0, 0.0))) * length(v_world)) + reflect(v_normal, v_normal)) + vec3(sign(v_normal.x), abs(v_normal.y), floor(v_normal.z))) + vec3(sqrt(max(dot(v_normal, light_dir), 0.0)), log2(2.0), exp2(1.0))) + mix(base_color.rgb, vec3(1.0, 1.0, 1.0), (sin(0.5) * cos(0.5)))), 1.0);
}
