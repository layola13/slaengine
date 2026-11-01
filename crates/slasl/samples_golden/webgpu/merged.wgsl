struct CameraBlock {
  view_proj: mat4x4<f32>,
}
@group(0) @binding(0) var<uniform> Camera: CameraBlock;

struct Params {
  base_color: vec4<f32>,
  tint: vec4<f32>,
}
@group(1) @binding(0) var<uniform> params: Params;

@group(1) @binding(1) var tex: texture_2d<f32>;
@group(1) @binding(2) var tex_sampler: sampler;

@id(0) override USE_TINT: bool = true;

struct VertexIn {
  @location(0) position: vec3<f32>,
  @location(1) uv: vec2<f32>,
}

struct VertexOut {
  @builtin(position) clip_position: vec4<f32>,
  @location(0) v_uv: vec2<f32>,
}

struct FragmentOut {
  @location(0) frag_color: vec4<f32>,
}

@vertex
fn vertex_main(input: VertexIn) -> VertexOut {
    var output: VertexOut;
    output.v_uv = input.uv;
    output.clip_position = (Camera.view_proj * vec4<f32>(input.position, 1.0));
    return output;
}

@fragment
fn fragment_main(input: VertexOut) -> FragmentOut {
    var output: FragmentOut;
    var frag_color: vec4<f32>;
    var tint_boost: vec4<f32>;
    var tint_pre: vec4<f32>;
    tint_boost = (params.tint * 0.5);
    tint_pre = (tint_boost + params.tint);
    frag_color = (textureSample(tex, tex_sampler, input.v_uv) * params.base_color);
    frag_color = (frag_color * tint_pre);
    output.frag_color = frag_color;
    return output;
}
