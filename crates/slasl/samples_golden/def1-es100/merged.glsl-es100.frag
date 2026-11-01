precision highp float;
precision highp int;

uniform vec4 tint2;

varying float v_s;
varying float v_t;

void main()
{
    gl_FragColor = (tint2 * (v_s + v_t));
}
