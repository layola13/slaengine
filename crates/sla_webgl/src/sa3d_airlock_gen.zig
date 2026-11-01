const std = @import("std");

pub const AirlockGenerator = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) AirlockGenerator {
        return .{ .allocator = allocator };
    }

    pub fn generate(self: *AirlockGenerator) !std.array_list.Managed(u8) {
        var out = std.array_list.Managed(u8).init(self.allocator);
        errdefer out.deinit();
        try out.appendSlice(source);
        return out;
    }
};

pub const source = @embedFile("sa3d_airlock_runtime.js");

const legacy_source =
    \\// sa3d_airlock.js -- generated SA3D WebGPU broker for SA/SAX.
    \\// The render kernel, shader bytes, geometry bytes, and frame uniforms come from SA/WASM memory.
    \\const SA3D_AIRLOCK_VERSION = "0.1";
    \\const _contexts = new Map();
    \\const _objects = new Map();
    \\let _nextHandle = 1;
    \\let _instance = null;
    \\let _mem = null;
    \\let _lastError = "";
    \\
    \\function _handle(value) {
    \\  const h = _nextHandle++;
    \\  _objects.set(h, value);
    \\  return BigInt(h);
    \\}
    \\
    \\function _object(h) {
    \\  return _objects.get(Number(h));
    \\}
    \\
    \\function _set_error(message) {
    \\  _lastError = String(message || "unknown WebGPU error");
    \\  return 1;
    \\}
    \\
    \\function _bytes(ptr, len) {
    \\  return new Uint8Array(_mem.buffer, Number(ptr), Number(len));
    \\}
    \\
    \\function _read_str(ptr, len) {
    \\  return new TextDecoder().decode(_bytes(ptr, len));
    \\}
    \\
    \\function _write_i64(ptr, value) {
    \\  new DataView(_mem.buffer).setBigInt64(Number(ptr), BigInt(value), true);
    \\}
    \\
    \\function _write_str(ptr, len, text) {
    \\  const bytes = new TextEncoder().encode(String(text));
    \\  const n = Math.min(bytes.length, Number(len));
    \\  _bytes(ptr, n).set(bytes.subarray(0, n));
    \\  return BigInt(n);
    \\}
    \\
    \\function _ctx(ctx_h) {
    \\  const ctx = _contexts.get(Number(ctx_h));
    \\  if (!ctx) throw new Error("invalid WebGPU context handle");
    \\  return ctx;
    \\}
    \\
    \\function _require_ready() {
    \\  if (!_instance || !_mem) throw new Error("SA3D airlock is not bound to WASM memory");
    \\}
    \\
    \\function _resize_canvas(ctx) {
    \\  const canvas = ctx.canvas;
    \\  const attrWidth = Number(canvas.getAttribute("width"));
    \\  const attrHeight = Number(canvas.getAttribute("height"));
    \\  const width = Math.max(1, Math.floor(attrWidth || canvas.width || 1024));
    \\  const height = Math.max(1, Math.floor(attrHeight || canvas.height || 768));
    \\  if (canvas.width !== width || canvas.height !== height || !ctx.configured) {
    \\    canvas.width = width;
    \\    canvas.height = height;
    \\    ctx.context.configure({ device: ctx.device, format: ctx.format, alphaMode: "opaque" });
    \\    if (ctx.depthTexture) ctx.depthTexture.destroy();
    \\    ctx.depthTexture = null;
    \\    ctx.depthWidth = 0;
    \\    ctx.depthHeight = 0;
    \\    ctx.configured = true;
    \\  }
    \\}
    \\
    \\function _depth_view(ctx) {
    \\  _resize_canvas(ctx);
    \\  const width = ctx.canvas.width;
    \\  const height = ctx.canvas.height;
    \\  if (!ctx.depthTexture || ctx.depthWidth !== width || ctx.depthHeight !== height) {
    \\    if (ctx.depthTexture) ctx.depthTexture.destroy();
    \\    ctx.depthTexture = ctx.device.createTexture({
    \\      size: [width, height],
    \\      format: "depth24plus",
    \\      usage: GPUTextureUsage.RENDER_ATTACHMENT,
    \\    });
    \\    ctx.depthWidth = width;
    \\    ctx.depthHeight = height;
    \\  }
    \\  return ctx.depthTexture.createView();
    \\}
    \\
    \\export function sax_sa3d_bind_wasm(instance, memory) {
    \\  _instance = instance;
    \\  _mem = memory;
    \\}
    \\
    \\export const sax_sa3d_airlock = {
    \\  sa3d_request_context(canvas_h, out_ctx_ptr) {
    \\    _require_ready();
    \\    const canvas = globalThis.sax_debug_get_node ? globalThis.sax_debug_get_node(canvas_h) : null;
    \\    if (!canvas) {
    \\      _write_i64(out_ctx_ptr, 0n);
    \\      return _set_error("WebGPU canvas handle does not resolve to a DOM node");
    \\    }
    \\    if (typeof navigator === "undefined" || !navigator.gpu) {
    \\      _write_i64(out_ctx_ptr, 0n);
    \\      return _set_error("navigator.gpu is not available");
    \\    }
    \\    const ctx_h = _nextHandle++;
    \\    const pending = (async () => {
    \\      const adapter = await navigator.gpu.requestAdapter();
    \\      if (!adapter) throw new Error("WebGPU adapter request failed");
    \\      const device = await adapter.requestDevice();
    \\      const context = canvas.getContext("webgpu");
    \\      if (!context) throw new Error("canvas.getContext('webgpu') failed");
    \\      const format = navigator.gpu.getPreferredCanvasFormat();
    \\      const ctx = { canvas, adapter, device, context, format, ready: true, raf: 0, configured: false, depthTexture: null, depthWidth: 0, depthHeight: 0 };
    \\      _resize_canvas(ctx);
    \\      return ctx;
    \\    })().then((ctx) => {
    \\      _contexts.set(ctx_h, ctx);
    \\      return ctx;
    \\    }).catch((err) => {
    \\      _set_error(err && err.message ? err.message : err);
    \\      throw err;
    \\    });
    \\    _contexts.set(ctx_h, { ready: false, pending, raf: 0 });
    \\    _write_i64(out_ctx_ptr, ctx_h);
    \\    return 0;
    \\  },
    \\
    \\  sa3d_create_buffer(ctx_h, usage, data_ptr, data_len, out_buffer_ptr) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) {
    \\      _write_i64(out_buffer_ptr, 0n);
    \\      return _set_error("WebGPU context is not ready yet");
    \\    }
    \\    const src = _bytes(data_ptr, data_len);
    \\    const size = Math.max(4, Math.ceil(Number(data_len) / 4) * 4);
    \\    const buffer = ctx.device.createBuffer({ size, usage: Number(usage), mappedAtCreation: true });
    \\    new Uint8Array(buffer.getMappedRange()).set(src);
    \\    buffer.unmap();
    \\    _write_i64(out_buffer_ptr, _handle(buffer));
    \\    return 0;
    \\  },
    \\
    \\  sa3d_create_shader(ctx_h, wgsl_ptr, wgsl_len, out_shader_ptr) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) {
    \\      _write_i64(out_shader_ptr, 0n);
    \\      return _set_error("WebGPU context is not ready yet");
    \\    }
    \\    const code = _read_str(wgsl_ptr, wgsl_len);
    \\    const shader = ctx.device.createShaderModule({ code });
    \\    _write_i64(out_shader_ptr, _handle(shader));
    \\    return 0;
    \\  },
    \\
    \\  sa3d_create_cube_pipeline(ctx_h, shader_h, vs_entry_ptr, vs_entry_len, fs_entry_ptr, fs_entry_len, out_pipeline_ptr) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) {
    \\      _write_i64(out_pipeline_ptr, 0n);
    \\      return _set_error("WebGPU context is not ready yet");
    \\    }
    \\    const shader = _object(shader_h);
    \\    if (!shader) {
    \\      _write_i64(out_pipeline_ptr, 0n);
    \\      return _set_error("invalid shader handle");
    \\    }
    \\    const vsEntry = _read_str(vs_entry_ptr, vs_entry_len);
    \\    const fsEntry = _read_str(fs_entry_ptr, fs_entry_len);
    \\    const bindGroupLayout = ctx.device.createBindGroupLayout({ entries: [{ binding: 0, visibility: GPUShaderStage.VERTEX, buffer: { type: "uniform" } }] });
    \\    const pipelineLayout = ctx.device.createPipelineLayout({ bindGroupLayouts: [bindGroupLayout] });
    \\    const pipeline = ctx.device.createRenderPipeline({
    \\      layout: pipelineLayout,
    \\      vertex: { module: shader, entryPoint: vsEntry, buffers: [{ arrayStride: 24, attributes: [
    \\        { shaderLocation: 0, offset: 0, format: "float32x3" },
    \\        { shaderLocation: 1, offset: 12, format: "float32x3" },
    \\      ] }] },
    \\      fragment: { module: shader, entryPoint: fsEntry, targets: [{ format: ctx.format }] },
    \\      primitive: { topology: "triangle-list", cullMode: "none" },
    \\      depthStencil: { format: "depth24plus", depthWriteEnabled: true, depthCompare: "less" },
    \\    });
    \\    _write_i64(out_pipeline_ptr, _handle({ pipeline, bindGroupLayout }));
    \\    return 0;
    \\  },
    \\
    \\  sa3d_write_buffer(ctx_h, buffer_h, offset, data_ptr, data_len) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) return 0;
    \\    const buffer = _object(buffer_h);
    \\    if (!buffer) return 0;
    \\    ctx.device.queue.writeBuffer(buffer, Number(offset), _bytes(data_ptr, data_len));
    \\    return 0;
    \\  },
    \\
    \\  sa3d_write_buffer_frame(ctx_h, buffer_h, offset, frames_ptr, frame_len, frame_idx) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) return 0;
    \\    const buffer = _object(buffer_h);
    \\    if (!buffer) return 0;
    \\    const len = Number(frame_len);
    \\    const srcOffset = Number(frames_ptr) + Number(frame_idx) * len;
    \\    ctx.device.queue.writeBuffer(buffer, Number(offset), new Uint8Array(_mem.buffer, srcOffset, len));
    \\    return 0;
    \\  },
    \\
    \\  sa3d_submit_cube_frame(ctx_h, pipeline_h, vertex_h, index_h, uniform_h, index_count) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) return 0;
    \\    const pipelineObj = _object(pipeline_h);
    \\    const vertex = _object(vertex_h);
    \\    const index = _object(index_h);
    \\    const uniform = _object(uniform_h);
    \\    if (!pipelineObj || !vertex || !index || !uniform) return 0;
    \\    const bindGroup = ctx.device.createBindGroup({ layout: pipelineObj.bindGroupLayout, entries: [{ binding: 0, resource: { buffer: uniform } }] });
    \\    const encoder = ctx.device.createCommandEncoder();
    \\    const depthView = _depth_view(ctx);
    \\    const view = ctx.context.getCurrentTexture().createView();
    \\    const pass = encoder.beginRenderPass({
    \\      colorAttachments: [{ view, clearValue: { r: 0.02, g: 0.025, b: 0.03, a: 1 }, loadOp: "clear", storeOp: "store" }],
    \\      depthStencilAttachment: { view: depthView, depthClearValue: 1.0, depthLoadOp: "clear", depthStoreOp: "store" },
    \\    });
    \\    pass.setPipeline(pipelineObj.pipeline);
    \\    pass.setBindGroup(0, bindGroup);
    \\    pass.setVertexBuffer(0, vertex);
    \\    pass.setIndexBuffer(index, "uint16");
    \\    pass.drawIndexed(Number(index_count));
    \\    pass.end();
    \\    ctx.device.queue.submit([encoder.finish()]);
    \\    return 0;
    \\  },
    \\
    \\  sa3d_request_frame(ctx_h, handler_ptr, handler_len, sax_ctx) {
    \\    _require_ready();
    \\    const ctx_key = Number(ctx_h);
    \\    if (ctx_key === 0) return _set_error("cannot request WebGPU frame without a context handle");
    \\    const ctx = _contexts.get(ctx_key);
    \\    if (!ctx) return _set_error("invalid WebGPU context handle");
    \\    const handler = _read_str(handler_ptr, handler_len);
    \\    const loop = () => {
    \\      const latest = _contexts.get(ctx_key);
    \\      if (!latest) return;
    \\      if (_instance && _instance.exports[handler]) _instance.exports[handler](sax_ctx);
    \\      latest.raf = requestAnimationFrame(loop);
    \\    };
    \\    if (ctx.raf) cancelAnimationFrame(ctx.raf);
    \\    ctx.raf = requestAnimationFrame(loop);
    \\    return 0;
    \\  },
    \\
    \\  sa3d_cancel_frame(ctx_h) {
    \\    const ctx_key = Number(ctx_h);
    \\    if (ctx_key === 0) return 0;
    \\    const ctx = _contexts.get(ctx_key);
    \\    if (!ctx) return 0;
    \\    if (ctx.raf) cancelAnimationFrame(ctx.raf);
    \\    ctx.raf = 0;
    \\    return 0;
    \\  },
    \\
    \\  sa3d_last_error(buf_ptr, buf_len) {
    \\    _require_ready();
    \\    return _write_str(buf_ptr, buf_len, _lastError);
    \\  },
    \\};
    \\
    \\if (typeof window !== "undefined") {
    \\  window.sax_sa3d_airlock = sax_sa3d_airlock;
    \\  window.sax_sa3d_bind_wasm = sax_sa3d_bind_wasm;
    \\}
    \\
;

test "sa3d airlock exposes broker-only imports" {
    var generator = AirlockGenerator.init(std.testing.allocator);
    const js = try generator.generate();
    defer js.deinit();

    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "export const sax_sa3d_airlock"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa3d_submit_cube_frame"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa3d_wgpu_request_renderer"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa3d_wgpu_upload_mesh"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa3d_wgpu_upload_material"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa3d_wgpu_render_frame"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "_ensure_generic_pipeline"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "drawItemsPtr"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa3d_write_buffer_frame"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "typeof navigator === \"undefined\" || !navigator.gpu"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "cannot request WebGPU frame without a context handle"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "if (ctx_key === 0) return 0;"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "createRenderPipeline"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "depth24plus"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "depthStencilAttachment"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "GPUTextureUsage.RENDER_ATTACHMENT"));
    try std.testing.expect(std.mem.indexOf(u8, js.items, "cube_vertices") == null);
    try std.testing.expect(std.mem.indexOf(u8, js.items, "struct Uniforms") == null);
}
