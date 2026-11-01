#version 300 es
precision highp float;
precision highp int;

layout(std140) uniform Params
{
    vec4 tint2;
};

in vec3 position;

out float v_s;
out float v_t;

void main()
{
    v_s = 2.0;
    v_t = (2.0 * 3.0);
    gl_Position = vec4((position * 2.0), 1.0);
}
