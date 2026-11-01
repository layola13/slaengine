struct Params {
  tint2: vec4<f32>,
}
@group(1) @binding(0) var<uniform> params: Params;

@id(0) override SCALE: f32 = 2.0;
@id(1) override STEPS: i32 = 3;

struct VertexIn {
  @location(0) position: vec3<f32>,
}

struct VertexOut {
  @builtin(position) clip_position: vec4<f32>,
  @location(0) v_s: f32,
  @location(1) v_t: f32,
}

struct FragmentOut {
  @location(0) frag_color: vec4<f32>,
}

@vertex
fn vertex_main(input: VertexIn) -> VertexOut {
    var output: VertexOut;
    output.v_s = 2.0;
    output.v_t = (2.0 * 3.0);
    output.clip_position = vec4<f32>((input.position * 2.0), 1.0);
    return output;
}

@fragment
fn fragment_main(input: VertexOut) -> FragmentOut {
    var output: FragmentOut;
    var frag_color: vec4<f32>;
    frag_color = (params.tint2 * (input.v_s + input.v_t));
    output.frag_color = frag_color;
    return output;
}
