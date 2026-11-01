precision highp float;
precision highp int;

uniform vec4 base_color;

attribute vec3 position;
attribute vec3 normal;

varying vec3 v_normal;

void main()
{
    v_normal = normal;
    gl_Position = vec4(position, 1.0);
}
