// sa3d_airlock.js -- generated SA3D WebGPU broker for SA/SAX.
// Shader bytes, mesh bytes, frame uniforms, and scene submission data come from SA/WASM memory.
const SA3D_AIRLOCK_VERSION = "0.2";
const _contexts = new Map();
const _objects = new Map();
let _nextHandle = 1;
let _instance = null;
let _mem = null;
let _lastError = "";

function _handle(value) {
  const h = _nextHandle++;
  _objects.set(h, value);
  return BigInt(h);
}

function _object(h) {
  return _objects.get(Number(h));
}

function _set_error(message) {
  _lastError = String(message || "unknown WebGPU error");
  return 1;
}

function _bytes(ptr, len) {
  return new Uint8Array(_mem.buffer, Number(ptr), Number(len));
}

function _read_str(ptr, len) {
  return new TextDecoder().decode(_bytes(ptr, len));
}

function _write_i64(ptr, value) {
  new DataView(_mem.buffer).setBigInt64(Number(ptr), BigInt(value), true);
}

function _write_str(ptr, len, text) {
  const bytes = new TextEncoder().encode(String(text));
  const n = Math.min(bytes.length, Number(len));
  _bytes(ptr, n).set(bytes.subarray(0, n));
  return BigInt(n);
}

function _read_i32(ptr) {
  return new DataView(_mem.buffer).getInt32(Number(ptr), true);
}

function _read_i64(ptr) {
  return Number(new DataView(_mem.buffer).getBigInt64(Number(ptr), true));
}

function _read_ptr_field(ptr) {
  return new DataView(_mem.buffer).getUint32(Number(ptr), true);
}

function _read_f32(ptr) {
  return new DataView(_mem.buffer).getFloat32(Number(ptr), true);
}

function _ctx(ctx_h) {
  const ctx = _contexts.get(Number(ctx_h));
  if (!ctx) throw new Error("invalid WebGPU context handle");
  return ctx;
}

function _require_ready() {
  if (!_instance || !_mem) throw new Error("SA3D airlock is not bound to WASM memory");
}

function _resize_canvas(ctx) {
  const canvas = ctx.canvas;
  const attrWidth = Number(canvas.getAttribute("width"));
  const attrHeight = Number(canvas.getAttribute("height"));
  const width = Math.max(1, Math.floor(attrWidth || canvas.width || 1024));
  const height = Math.max(1, Math.floor(attrHeight || canvas.height || 768));
  if (canvas.width !== width || canvas.height !== height || !ctx.configured) {
    canvas.width = width;
    canvas.height = height;
    ctx.context.configure({ device: ctx.device, format: ctx.format, alphaMode: "opaque" });
    if (ctx.depthTexture) ctx.depthTexture.destroy();
    ctx.depthTexture = null;
    ctx.depthWidth = 0;
    ctx.depthHeight = 0;
    ctx.configured = true;
  }
}

function _depth_view(ctx) {
  _resize_canvas(ctx);
  const width = ctx.canvas.width;
  const height = ctx.canvas.height;
  if (!ctx.depthTexture || ctx.depthWidth !== width || ctx.depthHeight !== height) {
    if (ctx.depthTexture) ctx.depthTexture.destroy();
    ctx.depthTexture = ctx.device.createTexture({
      size: [width, height],
      format: "depth24plus",
      usage: GPUTextureUsage.RENDER_ATTACHMENT,
    });
    ctx.depthWidth = width;
    ctx.depthHeight = height;
  }
  return ctx.depthTexture.createView();
}

function _request_webgpu_context(canvas_h, out_ctx_ptr) {
  _require_ready();
  const canvas = globalThis.sax_debug_get_node ? globalThis.sax_debug_get_node(canvas_h) : null;
  if (!canvas) {
    _write_i64(out_ctx_ptr, 0n);
    return _set_error("WebGPU canvas handle does not resolve to a DOM node");
  }
  if (typeof navigator === "undefined" || !navigator.gpu) {
    _write_i64(out_ctx_ptr, 0n);
    return _set_error("navigator.gpu is not available");
  }
  const ctx_h = _nextHandle++;
  const pending = (async () => {
    const adapter = await navigator.gpu.requestAdapter();
    if (!adapter) throw new Error("WebGPU adapter request failed");
    const device = await adapter.requestDevice();
    const context = canvas.getContext("webgpu");
    if (!context) throw new Error("canvas.getContext('webgpu') failed");
    const format = navigator.gpu.getPreferredCanvasFormat();
    const ctx = {
      canvas,
      adapter,
      device,
      context,
      format,
      ready: true,
      raf: 0,
      configured: false,
      depthTexture: null,
      depthWidth: 0,
      depthHeight: 0,
      genericPipeline: null,
      genericCameraBuffer: null,
      genericDefaultMaterial: null,
      genericModelBuffers: [],
    };
    _resize_canvas(ctx);
    return ctx;
  })().then((ctx) => {
    _contexts.set(ctx_h, ctx);
    return ctx;
  }).catch((err) => {
    _set_error(err && err.message ? err.message : err);
    throw err;
  });
  _contexts.set(ctx_h, { ready: false, pending, raf: 0 });
  _write_i64(out_ctx_ptr, ctx_h);
  return 0;
}

function _request_animation_frame(ctx_h, handler_ptr, handler_len, sax_ctx) {
  _require_ready();
  const ctx_key = Number(ctx_h);
  if (ctx_key === 0) return _set_error("cannot request WebGPU frame without a context handle");
  const ctx = _contexts.get(ctx_key);
  if (!ctx) return _set_error("invalid WebGPU context handle");
  const handler = _read_str(handler_ptr, handler_len);
  const loop = () => {
    const latest = _contexts.get(ctx_key);
    if (!latest) return;
    if (_instance && _instance.exports[handler]) _instance.exports[handler](sax_ctx);
    latest.raf = requestAnimationFrame(loop);
  };
  if (ctx.raf) cancelAnimationFrame(ctx.raf);
  ctx.raf = requestAnimationFrame(loop);
  return 0;
}

function _cancel_animation_frame(ctx_h) {
  const ctx_key = Number(ctx_h);
  if (ctx_key === 0) return 0;
  const ctx = _contexts.get(ctx_key);
  if (!ctx) return 0;
  if (ctx.raf) cancelAnimationFrame(ctx.raf);
  ctx.raf = 0;
  return 0;
}

function _create_gpu_buffer(ctx, usage, data_ptr, data_len) {
  const src = _bytes(data_ptr, data_len);
  const size = Math.max(4, Math.ceil(Number(data_len) / 4) * 4);
  const buffer = ctx.device.createBuffer({ size, usage: Number(usage), mappedAtCreation: true });
  new Uint8Array(buffer.getMappedRange()).set(src);
  buffer.unmap();
  return buffer;
}

const _generic_shader_code = `
struct Camera {
  view_proj: mat4x4<f32>,
};

struct Material {
  base_color: vec4<f32>,
};

struct Model {
  model: mat4x4<f32>,
};

@group(0) @binding(0) var<uniform> camera: Camera;
@group(1) @binding(0) var<uniform> material: Material;
@group(2) @binding(0) var<uniform> model: Model;

struct VsIn {
  @location(0) position: vec3<f32>,
  @location(1) normal: vec3<f32>,
  @location(2) uv: vec2<f32>,
};

struct VsOut {
  @builtin(position) position: vec4<f32>,
  @location(0) normal: vec3<f32>,
};

@vertex
fn vs_main(input: VsIn) -> VsOut {
  var out: VsOut;
  let world = model.model * vec4<f32>(input.position, 1.0);
  out.position = camera.view_proj * world;
  out.normal = normalize((model.model * vec4<f32>(input.normal, 0.0)).xyz);
  return out;
}

@fragment
fn fs_main(input: VsOut) -> @location(0) vec4<f32> {
  let light = max(dot(normalize(input.normal), normalize(vec3<f32>(0.35, 0.7, 0.55))), 0.18);
  return vec4<f32>(material.base_color.rgb * light, material.base_color.a);
}
`;

function _ensure_generic_pipeline(ctx) {
  if (ctx.genericPipeline) return ctx.genericPipeline;
  const shader = ctx.device.createShaderModule({ code: _generic_shader_code });
  const cameraBindGroupLayout = ctx.device.createBindGroupLayout({ entries: [{ binding: 0, visibility: GPUShaderStage.VERTEX, buffer: { type: "uniform" } }] });
  const materialBindGroupLayout = ctx.device.createBindGroupLayout({ entries: [{ binding: 0, visibility: GPUShaderStage.FRAGMENT, buffer: { type: "uniform" } }] });
  const modelBindGroupLayout = ctx.device.createBindGroupLayout({ entries: [{ binding: 0, visibility: GPUShaderStage.VERTEX, buffer: { type: "uniform" } }] });
  const pipelineLayout = ctx.device.createPipelineLayout({ bindGroupLayouts: [cameraBindGroupLayout, materialBindGroupLayout, modelBindGroupLayout] });
  const pipeline = ctx.device.createRenderPipeline({
    layout: pipelineLayout,
    vertex: { module: shader, entryPoint: "vs_main", buffers: [{ arrayStride: 32, attributes: [
      { shaderLocation: 0, offset: 0, format: "float32x3" },
      { shaderLocation: 1, offset: 12, format: "float32x3" },
      { shaderLocation: 2, offset: 24, format: "float32x2" },
    ] }] },
    fragment: { module: shader, entryPoint: "fs_main", targets: [{ format: ctx.format }] },
    primitive: { topology: "triangle-list", cullMode: "none" },
    depthStencil: { format: "depth24plus", depthWriteEnabled: true, depthCompare: "less" },
  });
  ctx.genericPipeline = { pipeline, cameraBindGroupLayout, materialBindGroupLayout, modelBindGroupLayout };
  return ctx.genericPipeline;
}

const _identity_view_proj = new Float32Array([
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1,
]);

function _camera_buffer(ctx, camera_ptr) {
  if (!ctx.genericCameraBuffer) {
    ctx.genericCameraBuffer = ctx.device.createBuffer({ size: 64, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
  }
  const data = Number(camera_ptr) === 0 ? new Uint8Array(_identity_view_proj.buffer) : new Uint8Array(_mem.buffer, Number(camera_ptr) + 128, 64);
  ctx.device.queue.writeBuffer(ctx.genericCameraBuffer, 0, data);
  return ctx.genericCameraBuffer;
}

const _identity_model = new Float32Array([
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1,
]);

function _model_bind_group(ctx, pipelineObj, index, transform_ptr, frame_index, frame_stride, frame_count) {
  let slot = ctx.genericModelBuffers[index];
  if (!slot) {
    const buffer = ctx.device.createBuffer({ size: 64, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
    const bindGroup = ctx.device.createBindGroup({ layout: pipelineObj.modelBindGroupLayout, entries: [{ binding: 0, resource: { buffer } }] });
    slot = { buffer, bindGroup };
    ctx.genericModelBuffers[index] = slot;
  }
  let data = new Uint8Array(_identity_model.buffer);
  const base = Number(transform_ptr);
  if (base !== 0) {
    const count = Math.max(0, Number(frame_count));
    const stride = Math.max(0, Number(frame_stride));
    const frame = count > 0 && stride >= 64 ? Number(frame_index) % count : 0;
    data = new Uint8Array(_mem.buffer, base + frame * stride, 64);
  }
  ctx.device.queue.writeBuffer(slot.buffer, 0, data);
  return slot.bindGroup;
}

function _default_material(ctx) {
  if (ctx.genericDefaultMaterial) return ctx.genericDefaultMaterial;
  const color = new Float32Array([1, 1, 1, 1]);
  const buffer = ctx.device.createBuffer({ size: 16, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
  ctx.device.queue.writeBuffer(buffer, 0, color);
  ctx.genericDefaultMaterial = { buffer, bindGroup: null };
  return ctx.genericDefaultMaterial;
}

function _material_bind_group(ctx, pipelineObj, materialObj) {
  const mat = materialObj || _default_material(ctx);
  if (!mat.bindGroup) {
    mat.bindGroup = ctx.device.createBindGroup({ layout: pipelineObj.materialBindGroupLayout, entries: [{ binding: 0, resource: { buffer: mat.buffer } }] });
  }
  return mat.bindGroup;
}

function _clear_color(scene_ptr) {
  if (Number(scene_ptr) === 0) return { r: 0.02, g: 0.025, b: 0.03, a: 1 };
  return {
    r: _read_f32(Number(scene_ptr) + 40),
    g: _read_f32(Number(scene_ptr) + 44),
    b: _read_f32(Number(scene_ptr) + 48),
    a: _read_f32(Number(scene_ptr) + 52) || 1,
  };
}

export function sax_sa3d_bind_wasm(instance, memory) {
  _instance = instance;
  _mem = memory;
}

export const sax_sa3d_airlock = {
  sa3d_request_context(canvas_h, out_ctx_ptr) {
    return _request_webgpu_context(canvas_h, out_ctx_ptr);
  },

  sa3d_create_buffer(ctx_h, usage, data_ptr, data_len, out_buffer_ptr) {
    _require_ready();
    const ctx = _ctx(ctx_h);
    if (!ctx.ready) {
      _write_i64(out_buffer_ptr, 0n);
      return _set_error("WebGPU context is not ready yet");
    }
    const buffer = _create_gpu_buffer(ctx, usage, data_ptr, data_len);
    _write_i64(out_buffer_ptr, _handle(buffer));
    return 0;
  },

  sa3d_create_shader(ctx_h, wgsl_ptr, wgsl_len, out_shader_ptr) {
    _require_ready();
    const ctx = _ctx(ctx_h);
    if (!ctx.ready) {
      _write_i64(out_shader_ptr, 0n);
      return _set_error("WebGPU context is not ready yet");
    }
    const code = _read_str(wgsl_ptr, wgsl_len);
    const shader = ctx.device.createShaderModule({ code });
    _write_i64(out_shader_ptr, _handle(shader));
    return 0;
  },

  sa3d_create_cube_pipeline(ctx_h, shader_h, vs_entry_ptr, vs_entry_len, fs_entry_ptr, fs_entry_len, out_pipeline_ptr) {
    _require_ready();
    const ctx = _ctx(ctx_h);
    if (!ctx.ready) {
      _write_i64(out_pipeline_ptr, 0n);
      return _set_error("WebGPU context is not ready yet");
    }
    const shader = _object(shader_h);
    if (!shader) {
      _write_i64(out_pipeline_ptr, 0n);
      return _set_error("invalid shader handle");
    }
    const vsEntry = _read_str(vs_entry_ptr, vs_entry_len);
    const fsEntry = _read_str(fs_entry_ptr, fs_entry_len);
    const bindGroupLayout = ctx.device.createBindGroupLayout({ entries: [{ binding: 0, visibility: GPUShaderStage.VERTEX, buffer: { type: "uniform" } }] });
    const pipelineLayout = ctx.device.createPipelineLayout({ bindGroupLayouts: [bindGroupLayout] });
    const pipeline = ctx.device.createRenderPipeline({
      layout: pipelineLayout,
      vertex: { module: shader, entryPoint: vsEntry, buffers: [{ arrayStride: 24, attributes: [
        { shaderLocation: 0, offset: 0, format: "float32x3" },
        { shaderLocation: 1, offset: 12, format: "float32x3" },
      ] }] },
      fragment: { module: shader, entryPoint: fsEntry, targets: [{ format: ctx.format }] },
      primitive: { topology: "triangle-list", cullMode: "none" },
      depthStencil: { format: "depth24plus", depthWriteEnabled: true, depthCompare: "less" },
    });
    _write_i64(out_pipeline_ptr, _handle({ pipeline, bindGroupLayout }));
    return 0;
  },

  sa3d_write_buffer(ctx_h, buffer_h, offset, data_ptr, data_len) {
    _require_ready();
    const ctx = _ctx(ctx_h);
    if (!ctx.ready) return 0;
    const buffer = _object(buffer_h);
    if (!buffer) return 0;
    ctx.device.queue.writeBuffer(buffer, Number(offset), _bytes(data_ptr, data_len));
    return 0;
  },

  sa3d_write_buffer_frame(ctx_h, buffer_h, offset, frames_ptr, frame_len, frame_idx) {
    _require_ready();
    const ctx = _ctx(ctx_h);
    if (!ctx.ready) return 0;
    const buffer = _object(buffer_h);
    if (!buffer) return 0;
    const len = Number(frame_len);
    const srcOffset = Number(frames_ptr) + Number(frame_idx) * len;
    ctx.device.queue.writeBuffer(buffer, Number(offset), new Uint8Array(_mem.buffer, srcOffset, len));
    return 0;
  },

  sa3d_submit_cube_frame(ctx_h, pipeline_h, vertex_h, index_h, uniform_h, index_count) {
    _require_ready();
    const ctx = _ctx(ctx_h);
    if (!ctx.ready) return 0;
    const pipelineObj = _object(pipeline_h);
    const vertex = _object(vertex_h);
    const index = _object(index_h);
    const uniform = _object(uniform_h);
    if (!pipelineObj || !vertex || !index || !uniform) return 0;
    const bindGroup = ctx.device.createBindGroup({ layout: pipelineObj.bindGroupLayout, entries: [{ binding: 0, resource: { buffer: uniform } }] });
    const encoder = ctx.device.createCommandEncoder();
    const depthView = _depth_view(ctx);
    const view = ctx.context.getCurrentTexture().createView();
    const pass = encoder.beginRenderPass({
      colorAttachments: [{ view, clearValue: { r: 0.02, g: 0.025, b: 0.03, a: 1 }, loadOp: "clear", storeOp: "store" }],
      depthStencilAttachment: { view: depthView, depthClearValue: 1.0, depthLoadOp: "clear", depthStoreOp: "store" },
    });
    pass.setPipeline(pipelineObj.pipeline);
    pass.setBindGroup(0, bindGroup);
    pass.setVertexBuffer(0, vertex);
    pass.setIndexBuffer(index, "uint16");
    pass.drawIndexed(Number(index_count));
    pass.end();
    ctx.device.queue.submit([encoder.finish()]);
    return 0;
  },

  sa3d_request_frame(ctx_h, handler_ptr, handler_len, sax_ctx) {
    return _request_animation_frame(ctx_h, handler_ptr, handler_len, sax_ctx);
  },

  sa3d_cancel_frame(ctx_h) {
    return _cancel_animation_frame(ctx_h);
  },

  sa3d_last_error(buf_ptr, buf_len) {
    _require_ready();
    return _write_str(buf_ptr, buf_len, _lastError);
  },

  sa3d_wgpu_request_renderer(canvas_h, out_renderer_ptr) {
    return _request_webgpu_context(canvas_h, out_renderer_ptr);
  },

  sa3d_wgpu_configure_renderer(renderer_h, target_desc_ptr) {
    _require_ready();
    const ctx = _ctx(renderer_h);
    if (!ctx.ready) return 2;
    const targetDesc = Number(target_desc_ptr);
    if (targetDesc !== 0) {
      const width = _read_i32(targetDesc + 8);
      const height = _read_i32(targetDesc + 12);
      if (width > 0) ctx.canvas.setAttribute("width", String(width));
      if (height > 0) ctx.canvas.setAttribute("height", String(height));
    }
    _resize_canvas(ctx);
    return 0;
  },

  sa3d_wgpu_upload_mesh(renderer_h, mesh_desc_ptr, out_mesh_ptr) {
    _require_ready();
    const ctx = _ctx(renderer_h);
    if (!ctx.ready) {
      _write_i64(out_mesh_ptr, 0n);
      return 2;
    }
    const meshDesc = Number(mesh_desc_ptr);
    const vertexPtr = _read_ptr_field(meshDesc + 0);
    const vertexLen = _read_i64(meshDesc + 8);
    const vertexStride = _read_i64(meshDesc + 16);
    const indexPtr = _read_ptr_field(meshDesc + 24);
    const indexLen = _read_i64(meshDesc + 32);
    const indexFormatCode = _read_i32(meshDesc + 40);
    const primitive = _read_i32(meshDesc + 44);
    if (vertexStride !== 32 || primitive !== 0) {
      _write_i64(out_mesh_ptr, 0n);
      return _set_error("generic WebGPU renderer currently supports P3N3UV2 triangle-list meshes");
    }
    const vertex = _create_gpu_buffer(ctx, GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST, vertexPtr, vertexLen);
    let index = null;
    let indexFormat = null;
    let indexCount = 0;
    if (indexPtr !== 0 && indexLen !== 0 && indexFormatCode !== 0) {
      index = _create_gpu_buffer(ctx, GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST, indexPtr, indexLen);
      indexFormat = indexFormatCode === 2 ? "uint32" : "uint16";
      indexCount = Math.floor(indexLen / (indexFormatCode === 2 ? 4 : 2));
    }
    const mesh = { vertex, index, indexFormat, indexCount, vertexCount: Math.floor(vertexLen / vertexStride) };
    _write_i64(out_mesh_ptr, _handle(mesh));
    return 0;
  },

  sa3d_wgpu_upload_material(renderer_h, material_desc_ptr, out_material_ptr) {
    _require_ready();
    const ctx = _ctx(renderer_h);
    if (!ctx.ready) {
      _write_i64(out_material_ptr, 0n);
      return 2;
    }
    const materialDesc = Number(material_desc_ptr);
    const color = new Float32Array([
      _read_f32(materialDesc + 8),
      _read_f32(materialDesc + 12),
      _read_f32(materialDesc + 16),
      _read_f32(materialDesc + 20) || 1,
    ]);
    const buffer = ctx.device.createBuffer({ size: 16, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
    ctx.device.queue.writeBuffer(buffer, 0, color);
    _write_i64(out_material_ptr, _handle({ buffer, bindGroup: null }));
    return 0;
  },

  sa3d_wgpu_render_frame(renderer_h, frame_desc_ptr) {
    _require_ready();
    const ctx = _ctx(renderer_h);
    if (!ctx.ready) return 2;
    const frameDesc = Number(frame_desc_ptr);
    const scenePtr = frameDesc === 0 ? 0 : _read_ptr_field(frameDesc + 8);
    const frameCameraPtr = frameDesc === 0 ? 0 : _read_ptr_field(frameDesc + 16);
    const frameIndex = frameDesc === 0 ? 0 : _read_i64(frameDesc + 32);
    const drawItemsPtr = scenePtr === 0 ? 0 : _read_ptr_field(scenePtr + 0);
    const drawItemsLen = scenePtr === 0 ? 0 : _read_i64(scenePtr + 8);
    const sceneCameraPtr = scenePtr === 0 ? 0 : _read_ptr_field(scenePtr + 16);
    const cameraPtr = frameCameraPtr || sceneCameraPtr;
    const pipelineObj = _ensure_generic_pipeline(ctx);
    const cameraBuffer = _camera_buffer(ctx, cameraPtr);
    const cameraBindGroup = ctx.device.createBindGroup({ layout: pipelineObj.cameraBindGroupLayout, entries: [{ binding: 0, resource: { buffer: cameraBuffer } }] });
    const encoder = ctx.device.createCommandEncoder();
    const depthView = _depth_view(ctx);
    const view = ctx.context.getCurrentTexture().createView();
    const pass = encoder.beginRenderPass({
      colorAttachments: [{ view, clearValue: _clear_color(scenePtr), loadOp: "clear", storeOp: "store" }],
      depthStencilAttachment: { view: depthView, depthClearValue: 1.0, depthLoadOp: "clear", depthStoreOp: "store" },
    });
    pass.setPipeline(pipelineObj.pipeline);
    pass.setBindGroup(0, cameraBindGroup);
    for (let i = 0; i < drawItemsLen; i++) {
      const itemPtr = drawItemsPtr + i * 56;
      const meshObj = _object(_read_i64(itemPtr + 0));
      if (!meshObj) continue;
      const materialObj = _object(_read_i64(itemPtr + 16));
      const transformPtr = _read_ptr_field(itemPtr + 24);
      const transformFrameStride = _read_i64(itemPtr + 40);
      const transformFrameCount = _read_i64(itemPtr + 48);
      pass.setBindGroup(1, _material_bind_group(ctx, pipelineObj, materialObj));
      pass.setBindGroup(2, _model_bind_group(ctx, pipelineObj, i, transformPtr, frameIndex, transformFrameStride, transformFrameCount));
      pass.setVertexBuffer(0, meshObj.vertex);
      if (meshObj.index) {
        pass.setIndexBuffer(meshObj.index, meshObj.indexFormat);
        pass.drawIndexed(meshObj.indexCount);
      } else {
        pass.draw(meshObj.vertexCount);
      }
    }
    pass.end();
    ctx.device.queue.submit([encoder.finish()]);
    return 0;
  },

  sa3d_wgpu_request_frame(renderer_h, handler_ptr, handler_len, sax_ctx) {
    return _request_animation_frame(renderer_h, handler_ptr, handler_len, sax_ctx);
  },

  sa3d_wgpu_cancel_frame(renderer_h) {
    return _cancel_animation_frame(renderer_h);
  },

  sa3d_wgpu_last_error(buf_ptr, buf_len) {
    _require_ready();
    return _write_str(buf_ptr, buf_len, _lastError);
  },
};

if (typeof window !== "undefined") {
  window.sax_sa3d_airlock = sax_sa3d_airlock;
  window.sax_sa3d_bind_wasm = sax_sa3d_bind_wasm;
}
