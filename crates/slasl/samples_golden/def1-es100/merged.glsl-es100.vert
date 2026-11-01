precision highp float;
precision highp int;

uniform vec4 tint2;

attribute vec3 position;

varying float v_s;
varying float v_t;

void main()
{
    v_s = 2.0;
    v_t = (2.0 * 3.0);
    gl_Position = vec4((position * 2.0), 1.0);
}
