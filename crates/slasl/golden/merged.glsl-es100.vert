precision highp float;
precision highp int;

uniform mat4 view_proj;

uniform vec4 base_color;
uniform vec4 tint;

attribute vec3 position;
attribute vec2 uv;

varying vec2 v_uv;

void main()
{
    v_uv = uv;
    gl_Position = (view_proj * vec4(position, 1.0));
}
