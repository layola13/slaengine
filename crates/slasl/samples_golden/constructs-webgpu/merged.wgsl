struct SceneBlock {
  light_dir: vec3<f32>,
  light_color: vec3<f32>,
  cam_pos: vec3<f32>,
}
@group(0) @binding(0) var<uniform> Scene: SceneBlock;

struct Params {
  base_color: vec4<f32>,
  metallic: f32,
  roughness: f32,
}
@group(1) @binding(0) var<uniform> params: Params;

@group(1) @binding(1) var env: texture_2d<f32>;
@group(1) @binding(2) var env_sampler: sampler;

struct VertexIn {
  @location(0) position: vec3<f32>,
  @location(1) normal: vec3<f32>,
}

struct VertexOut {
  @builtin(position) clip_position: vec4<f32>,
  @location(0) v_normal: vec3<f32>,
  @location(1) v_world: vec3<f32>,
}

struct FragmentOut {
  @location(0) frag_color: vec4<f32>,
}

fn slasl_principled(base_color: vec3<f32>, metallic: f32, roughness: f32, normal: vec3<f32>, view_dir: vec3<f32>, light_dir: vec3<f32>, light_color: vec3<f32>) -> vec3<f32>
{
    let n = normalize(normal);
    let v = normalize(view_dir);
    let l = normalize(light_dir);
    let h = normalize(l + v);
    let ndv = max(dot(n, v), 0.0001);
    let ndl = max(dot(n, l), 0.0);
    let ndh = max(dot(n, h), 0.0);
    let vdh = max(dot(v, h), 0.0);
    let a = max(roughness * roughness, 0.0001);
    let a2 = a * a;
    let denom = ndh * ndh * (a2 - 1.0) + 1.0;
    let nd = a2 / (3.14159265 * denom * denom);
    let f0 = mix(vec3<f32>(0.04, 0.04, 0.04), base_color, metallic);
    let f = f0 + (vec3<f32>(1.0, 1.0, 1.0) - f0) * pow(1.0 - vdh, 5.0);
    let k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
    let gv = ndv / (ndv * (1.0 - k) + k);
    let gl = ndl / (ndl * (1.0 - k) + k);
    let spec = nd * f * (gv * gl) / max(4.0 * ndv * ndl, 0.0001);
    let diffuse = base_color * (1.0 - metallic) / 3.14159265;
    return (diffuse + spec) * light_color * ndl;
}

fn slasl_probe_sphere(env: texture_2d<f32>, env_sampler: sampler, dir: vec3<f32>) -> vec4<f32>
{
    let d = normalize(dir);
    let uv = vec2<f32>(atan2(d.z, d.x) * 0.15915494 + 0.5, acos(clamp(d.y, -1.0, 1.0)) * 0.31830989);
    return textureSample(env, env_sampler, uv);
}

@vertex
fn vertex_main(input: VertexIn) -> VertexOut {
    var output: VertexOut;
    output.v_normal = input.normal;
    output.v_world = input.position;
    output.clip_position = vec4<f32>(input.position, 1.0);
    return output;
}

@fragment
fn fragment_main(input: VertexOut) -> FragmentOut {
    var output: FragmentOut;
    var frag_color: vec4<f32>;
    frag_color = (slasl_probe_sphere(env, env_sampler, input.v_normal) + (vec4<f32>(slasl_principled(params.base_color.rgb, params.metallic, params.roughness, input.v_normal, (Scene.cam_pos - input.v_world), Scene.light_dir, Scene.light_color), 1.0) * 0.5));
    output.frag_color = frag_color;
    return output;
}
