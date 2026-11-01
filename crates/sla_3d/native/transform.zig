const std = @import("std");

const saasm_abi = @import("saasm_abi.zig");
const plugin_shim = saasm_abi.Plugin("3d_transform");
pub const saasm_plugin_descriptor_v1 = plugin_shim.saasm_plugin_descriptor_v1;
pub const saasm_plugin_descriptor_v1_fn = plugin_shim.saasm_plugin_descriptor_v1_fn;
comptime {
    _ = plugin_shim;
}

pub const Vec3f = extern struct {
    x: f32,
    y: f32,
    z: f32,
};

pub const Vec3Af = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

pub const Quatf = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

pub const Mat4f = extern struct {
    data: [16]f32,
};

pub const Transform3f = extern struct {
    translation: Vec3Af,
    rotation: Quatf,
    scale: Vec3Af,
};

pub const GlobalTransform3f = extern struct {
    matrix: Mat4f,
    dirty: u64,
};

pub const TransformNode3f = extern struct {
    entity: u64,
    parent: u64,
    first_child: u64,
    next_sibling: u64,
    local: Transform3f,
    world: GlobalTransform3f,
};

fn vec3a(x: f32, y: f32, z: f32) Vec3Af {
    return .{ .x = x, .y = y, .z = z, .w = 0.0 };
}

fn quatIdentity() Quatf {
    return .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 };
}

fn quatMul(lhs: Quatf, rhs: Quatf) Quatf {
    return .{
        .x = lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
        .y = lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
        .z = lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
        .w = lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z,
    };
}

fn quatMulVec3(q: Quatf, v: Vec3f) Vec3f {
    const tx = 2.0 * (q.y * v.z - q.z * v.y);
    const ty = 2.0 * (q.z * v.x - q.x * v.z);
    const tz = 2.0 * (q.x * v.y - q.y * v.x);
    return .{
        .x = v.x + q.w * tx + (q.y * tz - q.z * ty),
        .y = v.y + q.w * ty + (q.z * tx - q.x * tz),
        .z = v.z + q.w * tz + (q.x * ty - q.y * tx),
    };
}

fn mat4TransformPoint(mat: *const Mat4f, point: Vec3f) Vec3f {
    return .{
        .x = mat.data[0] * point.x + mat.data[4] * point.y + mat.data[8] * point.z + mat.data[12],
        .y = mat.data[1] * point.x + mat.data[5] * point.y + mat.data[9] * point.z + mat.data[13],
        .z = mat.data[2] * point.x + mat.data[6] * point.y + mat.data[10] * point.z + mat.data[14],
    };
}

fn approxEq(a: f32, b: f32) bool {
    return @abs(a - b) <= 0.00001;
}

pub export fn sa3d_transform3f_identity(out: *Transform3f) callconv(.c) void {
    out.* = .{
        .translation = vec3a(0.0, 0.0, 0.0),
        .rotation = quatIdentity(),
        .scale = vec3a(1.0, 1.0, 1.0),
    };
}

pub export fn sa3d_transform3f_from_xyz(out: *Transform3f, x: f32, y: f32, z: f32) callconv(.c) void {
    sa3d_transform3f_identity(out);
    out.translation = vec3a(x, y, z);
}

pub export fn sa3d_transform3f_from_translation(out: *Transform3f, translation: *const Vec3f) callconv(.c) void {
    sa3d_transform3f_from_xyz(out, translation.x, translation.y, translation.z);
}

pub export fn sa3d_transform3f_from_rotation(out: *Transform3f, rotation: *const Quatf) callconv(.c) void {
    sa3d_transform3f_identity(out);
    out.rotation = rotation.*;
}

pub export fn sa3d_transform3f_from_scale(out: *Transform3f, scale: *const Vec3f) callconv(.c) void {
    sa3d_transform3f_identity(out);
    out.scale = vec3a(scale.x, scale.y, scale.z);
}

pub export fn sa3d_transform3f_set_translation(transform: *Transform3f, translation: *const Vec3f) callconv(.c) void {
    transform.translation = vec3a(translation.x, translation.y, translation.z);
}

pub export fn sa3d_transform3f_set_rotation(transform: *Transform3f, rotation: *const Quatf) callconv(.c) void {
    transform.rotation = rotation.*;
}

pub export fn sa3d_transform3f_set_scale(transform: *Transform3f, scale: *const Vec3f) callconv(.c) void {
    transform.scale = vec3a(scale.x, scale.y, scale.z);
}

pub export fn sa3d_transform3f_to_matrix(out: *Mat4f, transform: *const Transform3f) callconv(.c) void {
    const q = transform.rotation;
    const sx = transform.scale.x;
    const sy = transform.scale.y;
    const sz = transform.scale.z;

    const x2 = q.x + q.x;
    const y2 = q.y + q.y;
    const z2 = q.z + q.z;
    const xx = q.x * x2;
    const xy = q.x * y2;
    const xz = q.x * z2;
    const yy = q.y * y2;
    const yz = q.y * z2;
    const zz = q.z * z2;
    const wx = q.w * x2;
    const wy = q.w * y2;
    const wz = q.w * z2;

    out.data = .{
        (1.0 - (yy + zz)) * sx,
        (xy + wz) * sx,
        (xz - wy) * sx,
        0.0,
        (xy - wz) * sy,
        (1.0 - (xx + zz)) * sy,
        (yz + wx) * sy,
        0.0,
        (xz + wy) * sz,
        (yz - wx) * sz,
        (1.0 - (xx + yy)) * sz,
        0.0,
        transform.translation.x,
        transform.translation.y,
        transform.translation.z,
        1.0,
    };
}

pub export fn sa3d_transform3f_transform_point(out: *Vec3f, transform: *const Transform3f, point: *const Vec3f) callconv(.c) void {
    const scaled = Vec3f{
        .x = transform.scale.x * point.x,
        .y = transform.scale.y * point.y,
        .z = transform.scale.z * point.z,
    };
    const rotated = quatMulVec3(transform.rotation, scaled);
    out.* = .{
        .x = rotated.x + transform.translation.x,
        .y = rotated.y + transform.translation.y,
        .z = rotated.z + transform.translation.z,
    };
}

pub export fn sa3d_transform3f_mul_transform(out: *Transform3f, parent: *const Transform3f, child: *const Transform3f) callconv(.c) void {
    const child_translation = Vec3f{ .x = child.translation.x, .y = child.translation.y, .z = child.translation.z };
    var transformed_translation: Vec3f = undefined;
    sa3d_transform3f_transform_point(&transformed_translation, parent, &child_translation);
    out.* = .{
        .translation = vec3a(transformed_translation.x, transformed_translation.y, transformed_translation.z),
        .rotation = quatMul(parent.rotation, child.rotation),
        .scale = vec3a(parent.scale.x * child.scale.x, parent.scale.y * child.scale.y, parent.scale.z * child.scale.z),
    };
}

pub export fn sa3d_transform3f_rotate(transform: *Transform3f, rotation: *const Quatf) callconv(.c) void {
    transform.rotation = quatMul(rotation.*, transform.rotation);
}

pub export fn sa3d_transform3f_rotate_local(transform: *Transform3f, rotation: *const Quatf) callconv(.c) void {
    transform.rotation = quatMul(transform.rotation, rotation.*);
}

pub export fn sa3d_transform3f_translate_around(transform: *Transform3f, point: *const Vec3f, rotation: *const Quatf) callconv(.c) void {
    const relative = Vec3f{
        .x = transform.translation.x - point.x,
        .y = transform.translation.y - point.y,
        .z = transform.translation.z - point.z,
    };
    const rotated = quatMulVec3(rotation.*, relative);
    transform.translation = vec3a(point.x + rotated.x, point.y + rotated.y, point.z + rotated.z);
}

pub export fn sa3d_transform3f_rotate_around(transform: *Transform3f, point: *const Vec3f, rotation: *const Quatf) callconv(.c) void {
    sa3d_transform3f_translate_around(transform, point, rotation);
    sa3d_transform3f_rotate(transform, rotation);
}

pub export fn sa3d_transform3f_local_x(out: *Vec3f, transform: *const Transform3f) callconv(.c) void {
    out.* = quatMulVec3(transform.rotation, .{ .x = 1.0, .y = 0.0, .z = 0.0 });
}

pub export fn sa3d_transform3f_local_y(out: *Vec3f, transform: *const Transform3f) callconv(.c) void {
    out.* = quatMulVec3(transform.rotation, .{ .x = 0.0, .y = 1.0, .z = 0.0 });
}

pub export fn sa3d_transform3f_local_z(out: *Vec3f, transform: *const Transform3f) callconv(.c) void {
    out.* = quatMulVec3(transform.rotation, .{ .x = 0.0, .y = 0.0, .z = 1.0 });
}

pub export fn sa3d_transform3f_forward(out: *Vec3f, transform: *const Transform3f) callconv(.c) void {
    var back: Vec3f = undefined;
    sa3d_transform3f_local_z(&back, transform);
    out.* = .{ .x = -back.x, .y = -back.y, .z = -back.z };
}

pub export fn sa3d_global_transform3f_identity(out: *GlobalTransform3f) callconv(.c) void {
    out.matrix.data = .{
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    };
    out.dirty = 0;
}

pub export fn sa3d_global_transform3f_from_transform(out: *GlobalTransform3f, transform: *const Transform3f) callconv(.c) void {
    sa3d_transform3f_to_matrix(&out.matrix, transform);
    out.dirty = 0;
}

fn mat4Mul(out: *Mat4f, lhs: *const Mat4f, rhs: *const Mat4f) void {
    var result: [16]f32 = undefined;
    var col: usize = 0;
    while (col < 4) : (col += 1) {
        var row: usize = 0;
        while (row < 4) : (row += 1) {
            result[col * 4 + row] = lhs.data[0 * 4 + row] * rhs.data[col * 4 + 0] +
                lhs.data[1 * 4 + row] * rhs.data[col * 4 + 1] +
                lhs.data[2 * 4 + row] * rhs.data[col * 4 + 2] +
                lhs.data[3 * 4 + row] * rhs.data[col * 4 + 3];
        }
    }
    out.data = result;
}

pub export fn sa3d_global_transform3f_mul_transform(out: *GlobalTransform3f, parent: *const GlobalTransform3f, child: *const Transform3f) callconv(.c) void {
    var child_matrix: Mat4f = undefined;
    sa3d_transform3f_to_matrix(&child_matrix, child);
    mat4Mul(&out.matrix, &parent.matrix, &child_matrix);
    out.dirty = 0;
}

pub export fn sa3d_global_transform3f_transform_point(out: *Vec3f, transform: *const GlobalTransform3f, point: *const Vec3f) callconv(.c) void {
    out.* = mat4TransformPoint(&transform.matrix, point.*);
}

pub export fn sa3d_transform_node3f_init(node: *TransformNode3f, entity: u64, parent: u64) callconv(.c) void {
    node.entity = entity;
    node.parent = parent;
    node.first_child = 0;
    node.next_sibling = 0;
    sa3d_transform3f_identity(&node.local);
    sa3d_global_transform3f_identity(&node.world);
    node.world.dirty = 1;
}

pub export fn sa3d_transform_node3f_set_parent(node: *TransformNode3f, parent: u64) callconv(.c) void {
    node.parent = parent;
    node.world.dirty = 1;
}

pub export fn sa3d_transform_node3f_link_child(parent_node: *TransformNode3f, child_node: *TransformNode3f) callconv(.c) void {
    child_node.parent = parent_node.entity;
    child_node.next_sibling = parent_node.first_child;
    parent_node.first_child = child_node.entity;
    parent_node.world.dirty = 1;
    child_node.world.dirty = 1;
}

pub export fn sa3d_transform_node3f_update_local_world(node: *TransformNode3f) callconv(.c) void {
    sa3d_global_transform3f_from_transform(&node.world, &node.local);
}

pub export fn sa3d_transform_node3f_update_world_from_parent(node: *TransformNode3f, parent_node: *const TransformNode3f) callconv(.c) void {
    sa3d_global_transform3f_mul_transform(&node.world, &parent_node.world, &node.local);
}

pub export fn sa3d_transform_selftest() callconv(.c) i32 {
    var identity: Transform3f = undefined;
    var matrix: Mat4f = undefined;
    sa3d_transform3f_identity(&identity);
    if (identity.translation.x != 0.0 or identity.rotation.w != 1.0 or identity.scale.x != 1.0) return 1;
    sa3d_transform3f_to_matrix(&matrix, &identity);
    if (matrix.data[0] != 1.0 or matrix.data[5] != 1.0 or matrix.data[10] != 1.0 or matrix.data[15] != 1.0) return 2;

    var root: Transform3f = undefined;
    var child: Transform3f = undefined;
    var root_global: GlobalTransform3f = undefined;
    var child_global: GlobalTransform3f = undefined;
    const root_scale = Vec3f{ .x = 2.0, .y = 3.0, .z = 4.0 };
    const child_scale = Vec3f{ .x = 1.0, .y = 1.0, .z = 1.0 };
    sa3d_transform3f_from_xyz(&root, 5.0, 6.0, 7.0);
    root.scale = vec3a(root_scale.x, root_scale.y, root_scale.z);
    sa3d_transform3f_from_xyz(&child, 1.0, 2.0, 3.0);
    child.scale = vec3a(child_scale.x, child_scale.y, child_scale.z);
    sa3d_global_transform3f_from_transform(&root_global, &root);
    sa3d_global_transform3f_mul_transform(&child_global, &root_global, &child);
    if (child_global.matrix.data[0] != 2.0 or child_global.matrix.data[5] != 3.0 or child_global.matrix.data[10] != 4.0) return 3;
    if (child_global.matrix.data[12] != 7.0 or child_global.matrix.data[13] != 12.0 or child_global.matrix.data[14] != 19.0) return 4;

    var rotated: Transform3f = undefined;
    const half_turn_y = Quatf{ .x = 0.0, .y = 1.0, .z = 0.0, .w = 0.0 };
    sa3d_transform3f_from_rotation(&rotated, &half_turn_y);
    sa3d_transform3f_to_matrix(&matrix, &rotated);
    if (matrix.data[0] != -1.0 or matrix.data[10] != -1.0) return 5;

    const point = Vec3f{ .x = 1.0, .y = 2.0, .z = 3.0 };
    var point_out: Vec3f = undefined;
    sa3d_transform3f_transform_point(&point_out, &root, &point);
    if (!approxEq(point_out.x, 7.0) or !approxEq(point_out.y, 12.0) or !approxEq(point_out.z, 19.0)) return 6;

    var combined: Transform3f = undefined;
    sa3d_transform3f_mul_transform(&combined, &root, &child);
    if (!approxEq(combined.translation.x, 7.0) or !approxEq(combined.translation.y, 12.0) or !approxEq(combined.translation.z, 19.0)) return 7;
    if (!approxEq(combined.scale.x, 2.0) or !approxEq(combined.scale.y, 3.0) or !approxEq(combined.scale.z, 4.0)) return 8;

    var local_axis: Vec3f = undefined;
    sa3d_transform3f_local_x(&local_axis, &rotated);
    if (!approxEq(local_axis.x, -1.0) or !approxEq(local_axis.y, 0.0) or !approxEq(local_axis.z, 0.0)) return 9;
    sa3d_transform3f_forward(&local_axis, &rotated);
    if (!approxEq(local_axis.x, 0.0) or !approxEq(local_axis.y, 0.0) or !approxEq(local_axis.z, 1.0)) return 10;

    var moved: Transform3f = undefined;
    const origin = Vec3f{ .x = 0.0, .y = 0.0, .z = 0.0 };
    sa3d_transform3f_from_xyz(&moved, 1.0, 0.0, 0.0);
    sa3d_transform3f_translate_around(&moved, &origin, &half_turn_y);
    if (!approxEq(moved.translation.x, -1.0) or !approxEq(moved.translation.z, 0.0)) return 11;
    sa3d_transform3f_rotate_around(&moved, &origin, &half_turn_y);
    if (!approxEq(moved.translation.x, 1.0) or !approxEq(moved.rotation.y, 1.0)) return 12;

    sa3d_global_transform3f_transform_point(&point_out, &root_global, &point);
    if (!approxEq(point_out.x, 7.0) or !approxEq(point_out.y, 12.0) or !approxEq(point_out.z, 19.0)) return 13;

    var parent_node: TransformNode3f = undefined;
    var child_node: TransformNode3f = undefined;
    sa3d_transform_node3f_init(&parent_node, 100, 0);
    sa3d_transform_node3f_init(&child_node, 200, 0);
    if (parent_node.world.dirty != 1 or child_node.world.dirty != 1) return 14;
    sa3d_transform_node3f_link_child(&parent_node, &child_node);
    if (child_node.parent != 100 or parent_node.first_child != 200) return 15;
    parent_node.local = root;
    child_node.local = child;
    sa3d_transform_node3f_update_local_world(&parent_node);
    sa3d_transform_node3f_update_world_from_parent(&child_node, &parent_node);
    if (parent_node.world.dirty != 0 or child_node.world.dirty != 0) return 16;
    if (!approxEq(child_node.world.matrix.data[12], 7.0) or !approxEq(child_node.world.matrix.data[13], 12.0) or !approxEq(child_node.world.matrix.data[14], 19.0)) return 17;
    sa3d_transform_node3f_set_parent(&child_node, 300);
    if (child_node.parent != 300 or child_node.world.dirty != 1) return 18;
    return 0;
}

test "transform native identity and constructors match Bevy Transform" {
    var t: Transform3f = undefined;
    sa3d_transform3f_identity(&t);
    try std.testing.expectEqual(@as(f32, 0.0), t.translation.x);
    try std.testing.expectEqual(@as(f32, 1.0), t.rotation.w);
    try std.testing.expectEqual(@as(f32, 1.0), t.scale.z);

    sa3d_transform3f_from_xyz(&t, 1.0, 2.0, 3.0);
    try std.testing.expectEqual(@as(f32, 1.0), t.translation.x);
    try std.testing.expectEqual(@as(f32, 3.0), t.translation.z);
    try std.testing.expectEqual(@as(f32, 1.0), t.scale.x);
}

test "transform native matrix and propagation match Bevy SRT equations" {
    try std.testing.expectEqual(@as(i32, 0), sa3d_transform_selftest());
}

test "transform native point axis and rotation helpers match Bevy Transform" {
    try std.testing.expectEqual(@as(i32, 0), sa3d_transform_selftest());
}
