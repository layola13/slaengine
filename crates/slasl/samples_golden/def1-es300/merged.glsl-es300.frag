#version 300 es
precision highp float;
precision highp int;

layout(std140) uniform Params
{
    vec4 tint2;
};

in float v_s;
in float v_t;
out vec4 slasl_frag_color;

void main()
{
    slasl_frag_color = (tint2 * (v_s + v_t));
}
