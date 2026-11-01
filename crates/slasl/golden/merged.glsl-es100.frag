precision highp float;
precision highp int;

uniform mat4 view_proj;

uniform vec4 base_color;
uniform vec4 tint;

uniform sampler2D tex;

varying vec2 v_uv;

void main()
{
    vec4 tint_boost;
    vec4 tint_pre;
    tint_boost = (tint * 0.5);
    tint_pre = (tint_boost + tint);
    gl_FragColor = (texture2D(tex, v_uv) * base_color);
    gl_FragColor = (gl_FragColor * tint_pre);
}
