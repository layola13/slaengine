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

in vec3 position;
in vec3 normal;

out vec3 v_normal;
out vec3 v_world;

void main()
{
    v_normal = normal;
    v_world = position;
    gl_Position = vec4(position, 1.0);
}
