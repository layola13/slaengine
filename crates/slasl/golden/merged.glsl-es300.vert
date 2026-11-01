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

in vec3 position;
in vec2 uv;

out vec2 v_uv;

void main()
{
    v_uv = uv;
    gl_Position = (view_proj * vec4(position, 1.0));
}
