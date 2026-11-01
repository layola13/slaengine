// parse.zig — SAX3D 块式组装文法解析器（Jev 裁定 F-1：SLA 块式）。
// 双模：.authoring 名字为 ident；.compiled 名字为 #<idx>，经名表解析。
// 文法以设计 §6 + 工作例为准；未知顶层声明/未知字段一律具名诊断
// （封闭词表），结构错误记 Sax3dParseError 并尝试在声明边界重同步。

const std = @import("std");
const model = @import("model.zig");
const lexer = @import("lexer.zig");

pub const Mode = enum { authoring, compiled };

pub const Parser = struct {
    toks: []lexer.Tok,
    pos: usize = 0,
    alloc: std.mem.Allocator,
    diags: *model.Diags,
    mode: Mode,
    names: []const []const u8 = &.{}, // compiled 模式名表
    saw_asset: bool = false,

    const PErr = error{ ParseFailed, OutOfMemory };

    fn peek(self: *Parser) ?lexer.Tok { return if (self.pos < self.toks.len) self.toks[self.pos] else null; }
    fn next(self: *Parser) ?lexer.Tok { const t = self.peek(); if (t != null) self.pos += 1; return t; }
    fn at(self: *Parser, s: []const u8) bool {
        const t = self.peek() orelse return false;
        return std.mem.eql(u8, t.text, s);
    }
    fn eat(self: *Parser, s: []const u8) bool { if (self.at(s)) { self.pos += 1; return true; } return false; }

    fn fail(self: *Parser, comptime fmt: []const u8, args: anytype) PErr {
        const t = self.peek();
        const line: u32 = if (t) |x| x.line else 0;
        const col: u32 = if (t) |x| x.col else 0;
        var buf: [512]u8 = undefined;
        const what = std.fmt.bufPrint(&buf, fmt, args) catch "?";
        self.diags.add("Sax3dParseError", "{d}:{d}: {s}", .{ line, col, what });
        return error.ParseFailed;
    }

    fn expect(self: *Parser, s: []const u8) PErr!void {
        if (!self.eat(s)) return self.fail("expected '{s}'", .{s});
    }
    fn ident(self: *Parser) PErr![]const u8 {
        const t = self.next() orelse return self.fail("expected identifier, got EOF", .{});
        if (t.kind != .ident) return self.fail("expected identifier, got '{s}'", .{t.text});
        return t.text;
    }
    fn keyword(self: *Parser) PErr![]const u8 { return self.ident(); }
    fn name(self: *Parser) PErr![]const u8 {
        const t = self.next() orelse return self.fail("expected name, got EOF", .{});
        switch (self.mode) {
            .authoring => {
                if (t.kind != .ident) return self.fail("expected name, got '{s}'", .{t.text});
                return t.text;
            },
            .compiled => {
                if (t.kind != .nameref) return self.fail("expected #<name-index> in compiled form, got '{s}'", .{t.text});
                const idx = std.fmt.parseInt(usize, t.text, 10) catch return self.fail("bad name index '#{s}'", .{t.text});
                if (idx >= self.names.len) {
                    self.diags.add("Sax3dCompiledNameRef", "{d}:{d}: name index #{d} out of range (table has {d})", .{ t.line, t.col, idx, self.names.len });
                    return error.ParseFailed;
                }
                return self.names[idx];
            },
        }
    }
    fn u64num(self: *Parser) PErr!u64 {
        const t = self.next() orelse return self.fail("expected integer, got EOF", .{});
        if (t.kind != .number) return self.fail("expected integer, got '{s}'", .{t.text});
        return std.fmt.parseInt(u64, t.text, 10) catch return self.fail("expected non-negative integer, got '{s}'", .{t.text});
    }
    fn f64num(self: *Parser) PErr!f64 {
        const t = self.next() orelse return self.fail("expected number, got EOF", .{});
        if (t.kind != .number) return self.fail("expected number, got '{s}'", .{t.text});
        return std.fmt.parseFloat(f64, t.text) catch return self.fail("bad number '{s}'", .{t.text});
    }
    fn literal(self: *Parser) PErr!model.Literal {
        const t = self.peek() orelse return self.fail("expected literal, got EOF", .{});
        if (t.kind == .number) { _ = self.next(); return .{ .scalar = try self.f64From(t) }; }
        if (t.kind == .ident and (std.mem.eql(u8, t.text, "true") or std.mem.eql(u8, t.text, "false"))) {
            _ = self.next();
            return .{ .boolean = std.mem.eql(u8, t.text, "true") };
        }
        if (self.eat("[")) {
            var vals: std.ArrayList(f64) = .empty;
            while (!self.eat("]")) {
                try vals.append(self.alloc, try self.f64num());
                _ = self.eat(",");
            }
            return .{ .vec = vals.items };
        }
        return self.fail("expected literal", .{});
    }
    fn f64From(self: *Parser, t: lexer.Tok) PErr!f64 {
        _ = self;
        return std.fmt.parseFloat(f64, t.text) catch return error.ParseFailed;
    }
    fn vecLiteral(self: *Parser) PErr![]const f64 {
        const lit = try self.literal();
        return switch (lit) { .vec => |v| v, else => self.fail("expected [..] vector literal", .{}) };
    }

    // 声明失败后的重同步：跳过花括号平衡区，直到深度归零且下一 token 为顶层关键字。
    fn resync(self: *Parser) void {
        var depth: i32 = 0;
        while (self.peek()) |t| {
            if (std.mem.eql(u8, t.text, "{")) depth += 1;
            if (std.mem.eql(u8, t.text, "}")) { if (depth == 0) { _ = self.next(); continue; } depth -= 1; }
            if (depth == 0 and t.kind == .ident and isTopKeyword(t.text)) return;
            _ = self.next();
        }
    }

    pub fn parseAsset(self: *Parser) model.Asset {
        var asset = model.Asset{};
        while (self.peek()) |t| {
            if (t.kind != .ident) { _ = self.next(); continue; }
            const kw = t.text;
            const before = self.diags.count();
            const r = self.parseTop(&asset, kw);
            if (r) |_| {} else |_| {
                if (self.diags.count() == before) self.diags.add("Sax3dParseError", "{d}:{d}: cannot parse declaration starting '{s}'", .{ t.line, t.col, kw });
                self.resync();
            }
        }
        if (!self.saw_asset)
            self.diags.add("Sax3dParseError", "missing 'asset <Name> version <n>;' header (exactly one required)", .{});
        return asset;
    }

    fn parseTop(self: *Parser, asset: *model.Asset, kw: []const u8) PErr!void {
        if (std.mem.eql(u8, kw, "asset")) {
            _ = self.next();
            if (self.saw_asset) return self.fail("duplicate 'asset' header (exactly one per file)", .{});
            self.saw_asset = true;
            asset.name = try self.name();
            try self.expect("version");
            asset.version = try self.u64num();
            try self.expect(";");
        } else if (std.mem.eql(u8, kw, "binary")) {
            _ = self.next();
            var b = model.BinaryDecl{ .file = "" };
            if (self.peek()) |t2| { if (t2.kind == .string) { _ = self.next(); b.file = t2.text; } }
            try self.expect("{");
            while (!self.eat("}")) {
                try self.expect("section");
                const nm = try self.name();
                var len: u64 = 0;
                if (self.mode == .authoring) len = try self.u64num();
                try self.expect(";");
                try b.sections.append(self.alloc, .{ .name = nm, .len = len });
            }
            asset.binary = b;
        } else if (std.mem.eql(u8, kw, "mesh")) { try asset.meshes.append(self.alloc, try self.parseMesh()); }
        else if (std.mem.eql(u8, kw, "skeleton")) { try asset.skeletons.append(self.alloc, try self.parseSkeleton()); }
        else if (std.mem.eql(u8, kw, "image")) { try asset.images.append(self.alloc, try self.parseImage()); }
        else if (std.mem.eql(u8, kw, "texture")) { try asset.textures.append(self.alloc, try self.parseTexture()); }
        else if (std.mem.eql(u8, kw, "shader")) { try asset.shaders.append(self.alloc, try self.parseShader()); }
        else if (std.mem.eql(u8, kw, "material")) { try asset.materials.append(self.alloc, try self.parseMaterial()); }
        else if (std.mem.eql(u8, kw, "scene")) { try asset.scenes.append(self.alloc, try self.parseScene()); }
        else if (std.mem.eql(u8, kw, "clip")) { try asset.clips.append(self.alloc, try self.parseClip()); }
        else {
            self.diags.add("Sax3dUnknownDeclaration", "{d}:{d}: unknown top-level declaration '{s}' (closed vocabulary)", .{ self.peek().?.line, self.peek().?.col, kw });
            _ = self.next();
            return error.ParseFailed;
        }
    }

    fn parseChannelInto(self: *Parser, list: *std.ArrayList(model.ChannelDecl)) PErr!void {
        const kw = try self.keyword(); // channel | attr
        const custom = std.mem.eql(u8, kw, "attr");
        const nm = if (custom) try self.name() else try self.ident();
        try self.expect(":");
        const ty = try self.ident();
        try self.expect("@");
        const sec = try self.name();
        try self.expect(";");
        try list.append(self.alloc, .{ .name = nm, .ty = ty, .section = sec, .custom = custom });
    }

    fn parseMesh(self: *Parser) PErr!model.MeshDecl {
        _ = self.next(); // mesh
        var m = model.MeshDecl{ .name = try self.name() };
        try self.expect("{");
        while (!self.eat("}")) {
            const k = try self.keyword();
            if (std.mem.eql(u8, k, "vertices")) { m.vertices = try self.u64num(); try self.expect(";"); }
            else if (std.mem.eql(u8, k, "topology")) { try self.expect(":"); m.topology = try self.ident(); try self.expect(";"); }
            else if (std.mem.eql(u8, k, "channel") or std.mem.eql(u8, k, "attr")) {
                self.pos -= 1;
                try self.parseChannelInto(&m.channels);
            } else if (std.mem.eql(u8, k, "indices")) {
                m.idx_ty = try self.ident();
                try self.expect("@");
                m.idx_section = try self.name();
                try self.expect("count");
                m.idx_count = try self.u64num();
                try self.expect(";");
            } else if (std.mem.eql(u8, k, "primitive")) {
                const pn = try self.name();
                try self.expect("{");
                try self.expect("material");
                try self.expect(":");
                const mat = try self.name();
                try self.expect(";");
                try self.expect("}");
                try m.prims.append(self.alloc, .{ .name = pn, .material = mat });
            } else if (std.mem.eql(u8, k, "morph")) {
                var mo = model.MorphDecl{ .name = try self.name() };
                try self.expect("{");
                while (!self.eat("}")) try self.parseChannelInto(&mo.channels);
                try m.morphs.append(self.alloc, mo);
            } else if (std.mem.eql(u8, k, "bounds")) {
                try self.expect("{");
                while (!self.eat("}")) {
                    const bk = try self.keyword();
                    if (!std.mem.eql(u8, bk, "min") and !std.mem.eql(u8, bk, "max"))
                        return self.fail("bounds: unknown field '{s}'", .{bk});
                    try self.expect(":");
                    const v = try self.vecLiteral();
                    if (v.len != 3) return self.fail("bounds {s} needs 3 components", .{bk});
                    if (std.mem.eql(u8, bk, "min")) m.bounds_min = v else m.bounds_max = v;
                    try self.expect(";");
                }
                m.has_bounds = true;
            } else return self.fail("mesh {s}: unknown item '{s}'", .{ m.name, k });
        }
        return m;
    }

    fn parseSkeleton(self: *Parser) PErr!model.SkeletonDecl {
        _ = self.next(); // skeleton
        var sk = model.SkeletonDecl{ .name = try self.name() };
        try self.expect("{");
        while (!self.eat("}")) {
            const k = try self.keyword();
            if (std.mem.eql(u8, k, "joint")) {
                var j = model.JointDecl{ .name = try self.name() };
                try self.expect("{");
                while (!self.eat("}")) {
                    const jk = try self.keyword();
                    if (std.mem.eql(u8, jk, "parent")) {
                        try self.expect(":");
                        const t = self.peek() orelse return self.fail("joint parent: EOF", .{});
                        if (t.kind == .ident and std.mem.eql(u8, t.text, "none")) { _ = self.next(); j.parent = null; }
                        else j.parent = try self.name();
                        try self.expect(";");
                    } else if (std.mem.eql(u8, jk, "bind")) {
                        try self.expect(":");
                        try self.expect("{");
                        while (!self.eat("}")) {
                            const bk = try self.keyword();
                            const want: usize = if (std.mem.eql(u8, bk, "r")) 4 else 3;
                            if (!std.mem.eql(u8, bk, "t") and !std.mem.eql(u8, bk, "r") and !std.mem.eql(u8, bk, "s"))
                                return self.fail("bind: unknown field '{s}'", .{bk});
                            try self.expect(":");
                            const v = try self.vecLiteral();
                            if (v.len != want) return self.fail("bind {s} needs {d} components", .{ bk, want });
                            if (std.mem.eql(u8, bk, "t")) j.bind_t = v;
                            if (std.mem.eql(u8, bk, "r")) j.bind_r = v;
                            if (std.mem.eql(u8, bk, "s")) j.bind_s = v;
                            try self.expect(";");
                        }
                        j.has_bind = true;
                    } else return self.fail("joint {s}: unknown item '{s}'", .{ j.name, jk });
                }
                try sk.joints.append(self.alloc, j);
            } else if (std.mem.eql(u8, k, "inverse_bind")) {
                try self.expect("@");
                sk.ib_section = try self.name();
                try self.expect(";");
            } else return self.fail("skeleton {s}: unknown item '{s}'", .{ sk.name, k });
        }
        return sk;
    }

    fn parseImage(self: *Parser) PErr!model.ImageDecl {
        _ = self.next(); // image
        var im = model.ImageDecl{ .name = try self.name() };
        try self.expect("{");
        while (!self.eat("}")) {
            const k = try self.keyword();
            if (std.mem.eql(u8, k, "source")) {
                if (self.eat("@")) { im.source_kind = .section; im.source = try self.name(); }
                else {
                    const t = self.next() orelse return self.fail("image source: EOF", .{});
                    if (t.kind != .string) return self.fail("image source: expected path string or @section", .{});
                    im.source_kind = .path; im.source = t.text;
                }
                try self.expect(";");
            } else if (std.mem.eql(u8, k, "format")) { im.format = try self.ident(); try self.expect(";"); }
            else if (std.mem.eql(u8, k, "size")) { const w = try self.u64num(); const h = try self.u64num(); im.size = .{ w, h }; try self.expect(";"); }
            else if (std.mem.eql(u8, k, "color_space")) { im.color_space = try self.ident(); try self.expect(";"); }
            else return self.fail("image {s}: unknown item '{s}'", .{ im.name, k });
        }
        return im;
    }

    fn parseTexture(self: *Parser) PErr!model.TextureDecl {
        _ = self.next(); // texture
        var t = model.TextureDecl{ .name = try self.name() };
        try self.expect("{");
        while (!self.eat("}")) {
            const k = try self.keyword();
            if (std.mem.eql(u8, k, "image")) { try self.expect(":"); t.image = try self.name(); try self.expect(";"); }
            else if (std.mem.eql(u8, k, "sampler")) {
                t.sampler.present = true;
                try self.expect("{");
                while (!self.eat("}")) {
                    const sk = try self.keyword();
                    const dst: *?[]const u8 = if (std.mem.eql(u8, sk, "mag")) &t.sampler.mag
                        else if (std.mem.eql(u8, sk, "min")) &t.sampler.min
                        else if (std.mem.eql(u8, sk, "mipmap")) &t.sampler.mipmap
                        else if (std.mem.eql(u8, sk, "wrap_u")) &t.sampler.wrap_u
                        else if (std.mem.eql(u8, sk, "wrap_v")) &t.sampler.wrap_v
                        else if (std.mem.eql(u8, sk, "wrap_w")) &t.sampler.wrap_w
                        else return self.fail("sampler: unknown field '{s}'", .{sk});
                    try self.expect(":");
                    dst.* = try self.ident();
                    try self.expect(";");
                }
            } else return self.fail("texture {s}: unknown item '{s}'", .{ t.name, k });
        }
        return t;
    }

    fn parseShader(self: *Parser) PErr!model.ShaderDecl {
        _ = self.next(); // shader
        var sh = model.ShaderDecl{ .name = try self.name() };
        if (self.mode == .authoring) {
            try self.expect(":");
            const kind = try self.ident();
            if (!std.mem.eql(u8, kind, "slasl")) return self.fail("shader {s}: only 'slasl' references in v1, got '{s}'", .{ sh.name, kind });
            const t = self.next() orelse return self.fail("shader path: EOF", .{});
            if (t.kind != .string) return self.fail("shader {s}: expected .slasl path string", .{sh.name});
            sh.slasl_path = t.text;
        }
        try self.expect(";");
        return sh;
    }

    fn parseMaterial(self: *Parser) PErr!model.MaterialDecl {
        _ = self.next(); // material
        var mt = model.MaterialDecl{ .name = try self.name() };
        try self.expect("{");
        while (!self.eat("}")) {
            const k = try self.keyword();
            if (std.mem.eql(u8, k, "shader")) { try self.expect(":"); mt.shader = try self.name(); try self.expect(";"); }
            else if (std.mem.eql(u8, k, "param")) {
                const pn = try self.ident(); // param 名是 shader 接口名，非声明名：两模式同为 ident
                try self.expect("=");
                const lit = try self.literal();
                try self.expect(";");
                try mt.params.append(self.alloc, .{ .name = pn, .lit = lit });
            } else if (std.mem.eql(u8, k, "texture")) {
                const bn = try self.ident(); // sampler 参数名，同上
                try self.expect(":");
                const tv = try self.name();
                try self.expect(";");
                try mt.texbinds.append(self.alloc, .{ .name = bn, .texture = tv });
            } else if (std.mem.eql(u8, k, "tex_transform")) {
                var tt = model.TexTransform{ .name = try self.ident() };
                try self.expect("{");
                while (!self.eat("}")) {
                    const tk = try self.keyword();
                    if (std.mem.eql(u8, tk, "offset") or std.mem.eql(u8, tk, "scale")) {
                        try self.expect(":");
                        const v = try self.vecLiteral();
                        if (v.len != 2) return self.fail("tex_transform {s} needs 2 components", .{tk});
                        if (std.mem.eql(u8, tk, "offset")) tt.offset = v else tt.scale = v;
                    } else if (std.mem.eql(u8, tk, "rotation")) {
                        try self.expect(":");
                        tt.rotation = try self.f64num();
                    } else return self.fail("tex_transform: unknown field '{s}'", .{tk});
                    try self.expect(";");
                }
                try mt.tex_transforms.append(self.alloc, tt);
            } else if (std.mem.eql(u8, k, "state")) {
                try self.expect("{");
                while (!self.eat("}")) {
                    const sk = try self.keyword();
                    if (std.mem.eql(u8, sk, "alpha")) { try self.expect(":"); mt.alpha = try self.ident(); }
                    else if (std.mem.eql(u8, sk, "cutoff")) { try self.expect(":"); mt.cutoff = try self.f64num(); }
                    else if (std.mem.eql(u8, sk, "double_sided")) { try self.expect(":"); const b = try self.literal(); mt.double_sided = switch (b) { .boolean => |x| x, else => return self.fail("double_sided needs bool", .{}) }; }
                    else if (std.mem.eql(u8, sk, "depth_write")) { try self.expect(":"); const b = try self.literal(); mt.depth_write = switch (b) { .boolean => |x| x, else => return self.fail("depth_write needs bool", .{}) }; }
                    else return self.fail("state: unknown field '{s}'", .{sk});
                    try self.expect(";");
                }
            } else return self.fail("material {s}: unknown item '{s}'", .{ mt.name, k });
        }
        return mt;
    }

    fn parseNode(self: *Parser) PErr!model.NodeDecl {
        _ = self.next(); // node
        var n = model.NodeDecl{ .name = try self.name() };
        try self.expect("{");
        while (!self.eat("}")) {
            const k = try self.keyword();
            if (std.mem.eql(u8, k, "node")) {
                self.pos -= 1;
                try n.children.append(self.alloc, try self.parseNode());
            } else if (std.mem.eql(u8, k, "transform")) {
                var tr = model.Transform{};
                try self.expect("{");
                while (!self.eat("}")) {
                    const tk = try self.keyword();
                    try self.expect(":");
                    const v = try self.vecLiteral();
                    if (std.mem.eql(u8, tk, "t")) { if (v.len != 3) return self.fail("transform t needs 3", .{}); tr.t = v; }
                    else if (std.mem.eql(u8, tk, "r")) { if (v.len != 4) return self.fail("transform r needs 4", .{}); tr.r = v; }
                    else if (std.mem.eql(u8, tk, "s")) { if (v.len != 3) return self.fail("transform s needs 3", .{}); tr.s = v; }
                    else return self.fail("transform: unknown field '{s}'", .{tk});
                    try self.expect(";");
                }
                n.transform = tr;
            } else if (std.mem.eql(u8, k, "matrix")) {
                try self.expect(":");
                const v = try self.vecLiteral();
                if (v.len != 16) return self.fail("matrix needs 16 components", .{});
                n.matrix = v;
                try self.expect(";");
            } else if (std.mem.eql(u8, k, "mesh")) { try self.expect(":"); n.mesh = try self.name(); try self.expect(";"); }
            else if (std.mem.eql(u8, k, "material")) { try self.expect(":"); n.material = try self.name(); try self.expect(";"); }
            else if (std.mem.eql(u8, k, "skin")) { try self.expect(":"); n.skin = try self.name(); try self.expect(";"); }
            else return self.fail("node {s}: unknown item '{s}'", .{ n.name, k });
        }
        return n;
    }

    fn parseScene(self: *Parser) PErr!model.SceneDecl {
        _ = self.next(); // scene
        var sc = model.SceneDecl{ .name = try self.name() };
        try self.expect("{");
        while (!self.eat("}")) {
            const k = try self.keyword();
            if (!std.mem.eql(u8, k, "node")) return self.fail("scene {s}: unknown item '{s}' (v1 payload: nodes only)", .{ sc.name, k });
            self.pos -= 1;
            try sc.roots.append(self.alloc, try self.parseNode());
        }
        return sc;
    }

    fn parseClip(self: *Parser) PErr!model.ClipDecl {
        _ = self.next(); // clip
        var c = model.ClipDecl{ .name = try self.name() };
        try self.expect("{");
        while (!self.eat("}")) {
            const k = try self.keyword();
            if (std.mem.eql(u8, k, "sampler")) {
                var s = model.AnimSampler{ .name = try self.name() };
                try self.expect("{");
                while (!self.eat("}")) {
                    const sk = try self.keyword();
                    if (std.mem.eql(u8, sk, "input")) {
                        try self.expect(":"); s.in_ty = try self.ident(); try self.expect("@");
                        s.in_section = try self.name(); try self.expect("count"); s.in_count = try self.u64num(); try self.expect(";");
                    } else if (std.mem.eql(u8, sk, "output")) {
                        try self.expect(":"); s.out_ty = try self.ident(); try self.expect("@");
                        s.out_section = try self.name(); try self.expect("count"); s.out_count = try self.u64num(); try self.expect(";");
                    } else if (std.mem.eql(u8, sk, "interpolation")) { try self.expect(":"); s.interpolation = try self.ident(); try self.expect(";"); }
                    else return self.fail("clip sampler: unknown item '{s}'", .{sk});
                }
                try c.samplers.append(self.alloc, s);
            } else if (std.mem.eql(u8, k, "channel")) {
                var ch = model.ClipChannel{};
                try self.expect("{");
                while (!self.eat("}")) {
                    const ck = try self.keyword();
                    try self.expect(":");
                    if (std.mem.eql(u8, ck, "node")) ch.node = try self.name()
                    else if (std.mem.eql(u8, ck, "path")) ch.path = try self.ident()
                    else if (std.mem.eql(u8, ck, "sampler")) ch.sampler = try self.name()
                    else return self.fail("clip channel: unknown field '{s}'", .{ck});
                    try self.expect(";");
                }
                try c.channels.append(self.alloc, ch);
            } else return self.fail("clip {s}: unknown item '{s}'", .{ c.name, k });
        }
        return c;
    }
};

pub fn isTopKeyword(s: []const u8) bool {
    const kws = [_][]const u8{ "asset", "binary", "mesh", "skeleton", "image", "texture", "shader", "material", "scene", "clip" };
    for (kws) |k| { if (std.mem.eql(u8, k, s)) return true; }
    return false;
}

pub fn parse(alloc: std.mem.Allocator, src: []const u8, mode: Mode, names: []const []const u8, diags: *model.Diags) !model.Asset {
    var p = Parser{ .toks = try lexer.tokenize(alloc, src), .alloc = alloc, .diags = diags, .mode = mode, .names = names };
    return p.parseAsset();
}
