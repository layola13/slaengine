#version 300 es
precision highp float;
precision highp int;

layout(std140) uniform Camera
{
    mat4 view_proj;
};

layout(std140) uniform Params
{
    vec4 base_color;
    vec4 tint;
};

uniform sampler2D tex;

in vec2 v_uv;
out vec4 slasl_frag_color;

void main()
{
    vec4 tint_boost;
    vec4 tint_pre;
    tint_boost = (tint * 0.5);
    tint_pre = (tint_boost + tint);
    slasl_frag_color = (texture(tex, v_uv) * base_color);
    slasl_frag_color = (slasl_frag_color * tint_pre);
}
