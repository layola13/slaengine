const std = @import("std");

const saasm_abi = @import("saasm_abi.zig");
const plugin_shim = saasm_abi.Plugin("3d_math");
pub const saasm_plugin_descriptor_v1 = plugin_shim.saasm_plugin_descriptor_v1;
pub const saasm_plugin_descriptor_v1_fn = plugin_shim.saasm_plugin_descriptor_v1_fn;
comptime {
    _ = plugin_shim;
}

pub const Vec2f = extern struct {
    x: f32,
    y: f32,
};

pub const Vec3f = extern struct {
    x: f32,
    y: f32,
    z: f32,
};

pub const Vec4f = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
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

pub const Ray3f = extern struct {
    origin: Vec3Af,
    direction: Vec3Af,
};

pub const Aabb3f = extern struct {
    min: Vec3Af,
    max: Vec3Af,
};

pub const BoundingSphere3f = extern struct {
    center: Vec3Af,
    radius: f32,
};

pub export fn sa3d_math_vec3f_set(out: *Vec3f, x: f32, y: f32, z: f32) callconv(.c) void {
    out.* = .{ .x = x, .y = y, .z = z };
}

pub export fn sa3d_math_vec2f_set(out: *Vec2f, x: f32, y: f32) callconv(.c) void {
    out.* = .{ .x = x, .y = y };
}

pub export fn sa3d_math_vec2f_add(out: *Vec2f, a: *const Vec2f, b: *const Vec2f) callconv(.c) void {
    out.* = .{ .x = a.x + b.x, .y = a.y + b.y };
}

pub export fn sa3d_math_vec2f_sub(out: *Vec2f, a: *const Vec2f, b: *const Vec2f) callconv(.c) void {
    out.* = .{ .x = a.x - b.x, .y = a.y - b.y };
}

pub export fn sa3d_math_vec2f_mul_scalar(out: *Vec2f, vec: *const Vec2f, scalar: f32) callconv(.c) void {
    out.* = .{ .x = vec.x * scalar, .y = vec.y * scalar };
}

pub export fn sa3d_math_vec2f_dot(a: *const Vec2f, b: *const Vec2f) callconv(.c) f32 {
    return a.x * b.x + a.y * b.y;
}

pub export fn sa3d_math_vec2f_length_squared(vec: *const Vec2f) callconv(.c) f32 {
    return sa3d_math_vec2f_dot(vec, vec);
}

pub export fn sa3d_math_vec2f_length(vec: *const Vec2f) callconv(.c) f32 {
    return @sqrt(sa3d_math_vec2f_length_squared(vec));
}

pub export fn sa3d_math_vec2f_normalize(out: *Vec2f, vec: *const Vec2f) callconv(.c) bool {
    const len = sa3d_math_vec2f_length(vec);
    if (len <= std.math.floatEps(f32)) {
        out.* = .{ .x = 0.0, .y = 0.0 };
        return false;
    }
    out.* = .{ .x = vec.x / len, .y = vec.y / len };
    return true;
}

pub export fn sa3d_math_vec3f_add(out: *Vec3f, a: *const Vec3f, b: *const Vec3f) callconv(.c) void {
    out.* = .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
}

pub export fn sa3d_math_vec3f_sub(out: *Vec3f, a: *const Vec3f, b: *const Vec3f) callconv(.c) void {
    out.* = .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
}

pub export fn sa3d_math_vec3f_dot(a: *const Vec3f, b: *const Vec3f) callconv(.c) f32 {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

pub export fn sa3d_math_vec3f_cross(out: *Vec3f, a: *const Vec3f, b: *const Vec3f) callconv(.c) void {
    out.* = .{
        .x = a.y * b.z - a.z * b.y,
        .y = a.z * b.x - a.x * b.z,
        .z = a.x * b.y - a.y * b.x,
    };
}

pub export fn sa3d_math_vec3f_mul_scalar(out: *Vec3f, vec: *const Vec3f, scalar: f32) callconv(.c) void {
    out.* = .{ .x = vec.x * scalar, .y = vec.y * scalar, .z = vec.z * scalar };
}

pub export fn sa3d_math_vec3f_length_squared(vec: *const Vec3f) callconv(.c) f32 {
    return sa3d_math_vec3f_dot(vec, vec);
}

pub export fn sa3d_math_vec3f_length(vec: *const Vec3f) callconv(.c) f32 {
    return @sqrt(sa3d_math_vec3f_length_squared(vec));
}

pub export fn sa3d_math_vec3f_normalize(out: *Vec3f, vec: *const Vec3f) callconv(.c) bool {
    const len = sa3d_math_vec3f_length(vec);
    if (len <= std.math.floatEps(f32)) {
        out.* = .{ .x = 0.0, .y = 0.0, .z = 0.0 };
        return false;
    }
    out.* = .{ .x = vec.x / len, .y = vec.y / len, .z = vec.z / len };
    return true;
}

pub export fn sa3d_math_vec4f_set(out: *Vec4f, x: f32, y: f32, z: f32, w: f32) callconv(.c) void {
    out.* = .{ .x = x, .y = y, .z = z, .w = w };
}

pub export fn sa3d_math_vec4f_add(out: *Vec4f, a: *const Vec4f, b: *const Vec4f) callconv(.c) void {
    out.* = .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z, .w = a.w + b.w };
}

pub export fn sa3d_math_vec4f_sub(out: *Vec4f, a: *const Vec4f, b: *const Vec4f) callconv(.c) void {
    out.* = .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z, .w = a.w - b.w };
}

pub export fn sa3d_math_vec4f_mul_scalar(out: *Vec4f, vec: *const Vec4f, scalar: f32) callconv(.c) void {
    out.* = .{ .x = vec.x * scalar, .y = vec.y * scalar, .z = vec.z * scalar, .w = vec.w * scalar };
}

pub export fn sa3d_math_vec4f_dot(a: *const Vec4f, b: *const Vec4f) callconv(.c) f32 {
    return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
}

pub export fn sa3d_math_vec4f_length_squared(vec: *const Vec4f) callconv(.c) f32 {
    return sa3d_math_vec4f_dot(vec, vec);
}

pub export fn sa3d_math_vec4f_length(vec: *const Vec4f) callconv(.c) f32 {
    return @sqrt(sa3d_math_vec4f_length_squared(vec));
}

pub export fn sa3d_math_vec4f_normalize(out: *Vec4f, vec: *const Vec4f) callconv(.c) bool {
    const len = sa3d_math_vec4f_length(vec);
    if (len <= std.math.floatEps(f32)) {
        out.* = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 };
        return false;
    }
    out.* = .{ .x = vec.x / len, .y = vec.y / len, .z = vec.z / len, .w = vec.w / len };
    return true;
}

fn vec3aFromVec3(v: *const Vec3f) Vec3Af {
    return .{ .x = v.x, .y = v.y, .z = v.z, .w = 0.0 };
}

pub export fn sa3d_math_quatf_identity(out: *Quatf) callconv(.c) void {
    out.* = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 };
}

pub export fn sa3d_math_quatf_from_rotation_x(out: *Quatf, angle: f32) callconv(.c) void {
    const half = angle * 0.5;
    out.* = .{ .x = @sin(half), .y = 0.0, .z = 0.0, .w = @cos(half) };
}

pub export fn sa3d_math_quatf_from_rotation_y(out: *Quatf, angle: f32) callconv(.c) void {
    const half = angle * 0.5;
    out.* = .{ .x = 0.0, .y = @sin(half), .z = 0.0, .w = @cos(half) };
}

pub export fn sa3d_math_quatf_from_rotation_z(out: *Quatf, angle: f32) callconv(.c) void {
    const half = angle * 0.5;
    out.* = .{ .x = 0.0, .y = 0.0, .z = @sin(half), .w = @cos(half) };
}

pub export fn sa3d_math_quatf_mul(out: *Quatf, lhs: *const Quatf, rhs: *const Quatf) callconv(.c) void {
    out.* = .{
        .x = lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
        .y = lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
        .z = lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
        .w = lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z,
    };
}

pub export fn sa3d_math_quatf_mul_vec3(out: *Vec3f, quat: *const Quatf, vec: *const Vec3f) callconv(.c) void {
    const tx = 2.0 * (quat.y * vec.z - quat.z * vec.y);
    const ty = 2.0 * (quat.z * vec.x - quat.x * vec.z);
    const tz = 2.0 * (quat.x * vec.y - quat.y * vec.x);
    out.* = .{
        .x = vec.x + quat.w * tx + (quat.y * tz - quat.z * ty),
        .y = vec.y + quat.w * ty + (quat.z * tx - quat.x * tz),
        .z = vec.z + quat.w * tz + (quat.x * ty - quat.y * tx),
    };
}

pub export fn sa3d_math_mat4f_identity(out: *Mat4f) callconv(.c) void {
    out.data = .{
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    };
}

pub export fn sa3d_math_mat4f_from_translation(out: *Mat4f, translation: *const Vec3f) callconv(.c) void {
    sa3d_math_mat4f_identity(out);
    out.data[12] = translation.x;
    out.data[13] = translation.y;
    out.data[14] = translation.z;
}

pub export fn sa3d_math_mat4f_from_scale_rotation_translation(out: *Mat4f, scale: *const Vec3f, rotation: *const Quatf, translation: *const Vec3f) callconv(.c) void {
    const q = rotation.*;
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
        (1.0 - (yy + zz)) * scale.x,
        (xy + wz) * scale.x,
        (xz - wy) * scale.x,
        0.0,
        (xy - wz) * scale.y,
        (1.0 - (xx + zz)) * scale.y,
        (yz + wx) * scale.y,
        0.0,
        (xz + wy) * scale.z,
        (yz - wx) * scale.z,
        (1.0 - (xx + yy)) * scale.z,
        0.0,
        translation.x,
        translation.y,
        translation.z,
        1.0,
    };
}

pub export fn sa3d_math_mat4f_mul(out: *Mat4f, lhs: *const Mat4f, rhs: *const Mat4f) callconv(.c) void {
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

pub export fn sa3d_math_mat4f_transform_point3(out: *Vec3f, mat: *const Mat4f, point: *const Vec3f) callconv(.c) void {
    out.* = .{
        .x = mat.data[0] * point.x + mat.data[4] * point.y + mat.data[8] * point.z + mat.data[12],
        .y = mat.data[1] * point.x + mat.data[5] * point.y + mat.data[9] * point.z + mat.data[13],
        .z = mat.data[2] * point.x + mat.data[6] * point.y + mat.data[10] * point.z + mat.data[14],
    };
}

pub export fn sa3d_math_ray3f_set(out: *Ray3f, origin: *const Vec3f, direction: *const Vec3f) callconv(.c) void {
    out.* = .{ .origin = vec3aFromVec3(origin), .direction = vec3aFromVec3(direction) };
}

pub export fn sa3d_math_ray3f_get_point(out: *Vec3f, ray: *const Ray3f, distance: f32) callconv(.c) void {
    out.* = .{
        .x = ray.origin.x + ray.direction.x * distance,
        .y = ray.origin.y + ray.direction.y * distance,
        .z = ray.origin.z + ray.direction.z * distance,
    };
}

pub export fn sa3d_math_ray3f_intersect_plane(distance_out: *f32, ray: *const Ray3f, plane_origin: *const Vec3f, plane_normal: *const Vec3f) callconv(.c) bool {
    const denominator = plane_normal.x * ray.direction.x + plane_normal.y * ray.direction.y + plane_normal.z * ray.direction.z;
    if (@abs(denominator) > std.math.floatEps(f32)) {
        const ox = plane_origin.x - ray.origin.x;
        const oy = plane_origin.y - ray.origin.y;
        const oz = plane_origin.z - ray.origin.z;
        const distance = (ox * plane_normal.x + oy * plane_normal.y + oz * plane_normal.z) / denominator;
        if (distance > std.math.floatEps(f32)) {
            distance_out.* = distance;
            return true;
        }
    }
    distance_out.* = 0.0;
    return false;
}

pub export fn sa3d_math_ray3f_plane_intersection_point(out: *Vec3f, ray: *const Ray3f, plane_origin: *const Vec3f, plane_normal: *const Vec3f) callconv(.c) bool {
    var distance: f32 = 0.0;
    if (sa3d_math_ray3f_intersect_plane(&distance, ray, plane_origin, plane_normal)) {
        sa3d_math_ray3f_get_point(out, ray, distance);
        return true;
    }
    out.* = .{ .x = 0.0, .y = 0.0, .z = 0.0 };
    return false;
}

pub export fn sa3d_math_aabb3f_from_min_max(out: *Aabb3f, min: *const Vec3f, max: *const Vec3f) callconv(.c) void {
    out.* = .{ .min = vec3aFromVec3(min), .max = vec3aFromVec3(max) };
}

pub export fn sa3d_math_aabb3f_new(out: *Aabb3f, center: *const Vec3f, half_size: *const Vec3f) callconv(.c) void {
    out.* = .{
        .min = .{
            .x = center.x - half_size.x,
            .y = center.y - half_size.y,
            .z = center.z - half_size.z,
            .w = 0.0,
        },
        .max = .{
            .x = center.x + half_size.x,
            .y = center.y + half_size.y,
            .z = center.z + half_size.z,
            .w = 0.0,
        },
    };
}

pub export fn sa3d_math_aabb3f_center(out: *Vec3f, aabb: *const Aabb3f) callconv(.c) void {
    out.* = .{
        .x = (aabb.min.x + aabb.max.x) / 2.0,
        .y = (aabb.min.y + aabb.max.y) / 2.0,
        .z = (aabb.min.z + aabb.max.z) / 2.0,
    };
}

pub export fn sa3d_math_aabb3f_half_size(out: *Vec3f, aabb: *const Aabb3f) callconv(.c) void {
    out.* = .{
        .x = (aabb.max.x - aabb.min.x) / 2.0,
        .y = (aabb.max.y - aabb.min.y) / 2.0,
        .z = (aabb.max.z - aabb.min.z) / 2.0,
    };
}

pub export fn sa3d_math_aabb3f_visible_area(aabb: *const Aabb3f) callconv(.c) f32 {
    const bx = @max(aabb.max.x - aabb.min.x, 0.0);
    const by = @max(aabb.max.y - aabb.min.y, 0.0);
    const bz = @max(aabb.max.z - aabb.min.z, 0.0);
    return bx * (by + bz) + by * bz;
}

pub export fn sa3d_math_aabb3f_merge(out: *Aabb3f, lhs: *const Aabb3f, rhs: *const Aabb3f) callconv(.c) void {
    out.* = .{
        .min = .{
            .x = @min(lhs.min.x, rhs.min.x),
            .y = @min(lhs.min.y, rhs.min.y),
            .z = @min(lhs.min.z, rhs.min.z),
            .w = 0.0,
        },
        .max = .{
            .x = @max(lhs.max.x, rhs.max.x),
            .y = @max(lhs.max.y, rhs.max.y),
            .z = @max(lhs.max.z, rhs.max.z),
            .w = 0.0,
        },
    };
}

pub export fn sa3d_math_aabb3f_contains_aabb(outer: *const Aabb3f, inner: *const Aabb3f) callconv(.c) bool {
    return inner.min.x >= outer.min.x and inner.min.y >= outer.min.y and inner.min.z >= outer.min.z and
        inner.max.x <= outer.max.x and inner.max.y <= outer.max.y and inner.max.z <= outer.max.z;
}

pub export fn sa3d_math_aabb3f_contains_point(aabb: *const Aabb3f, point: *const Vec3f) callconv(.c) bool {
    return point.x >= aabb.min.x and point.y >= aabb.min.y and point.z >= aabb.min.z and
        point.x <= aabb.max.x and point.y <= aabb.max.y and point.z <= aabb.max.z;
}

pub export fn sa3d_math_aabb3f_intersects(lhs: *const Aabb3f, rhs: *const Aabb3f) callconv(.c) bool {
    return lhs.min.x <= rhs.max.x and lhs.min.y <= rhs.max.y and lhs.min.z <= rhs.max.z and
        lhs.max.x >= rhs.min.x and lhs.max.y >= rhs.min.y and lhs.max.z >= rhs.min.z;
}

pub export fn sa3d_math_aabb3f_grow(out: *Aabb3f, aabb: *const Aabb3f, amount: *const Vec3f) callconv(.c) void {
    out.* = .{
        .min = .{ .x = aabb.min.x - amount.x, .y = aabb.min.y - amount.y, .z = aabb.min.z - amount.z, .w = 0.0 },
        .max = .{ .x = aabb.max.x + amount.x, .y = aabb.max.y + amount.y, .z = aabb.max.z + amount.z, .w = 0.0 },
    };
}

pub export fn sa3d_math_aabb3f_shrink(out: *Aabb3f, aabb: *const Aabb3f, amount: *const Vec3f) callconv(.c) void {
    out.* = .{
        .min = .{ .x = aabb.min.x + amount.x, .y = aabb.min.y + amount.y, .z = aabb.min.z + amount.z, .w = 0.0 },
        .max = .{ .x = aabb.max.x - amount.x, .y = aabb.max.y - amount.y, .z = aabb.max.z - amount.z, .w = 0.0 },
    };
}

pub export fn sa3d_math_aabb3f_scale_around_center(out: *Aabb3f, aabb: *const Aabb3f, scale: *const Vec3f) callconv(.c) void {
    const center = Vec3Af{
        .x = (aabb.min.x + aabb.max.x) / 2.0,
        .y = (aabb.min.y + aabb.max.y) / 2.0,
        .z = (aabb.min.z + aabb.max.z) / 2.0,
        .w = 0.0,
    };
    const half = Vec3Af{
        .x = (aabb.max.x - aabb.min.x) / 2.0,
        .y = (aabb.max.y - aabb.min.y) / 2.0,
        .z = (aabb.max.z - aabb.min.z) / 2.0,
        .w = 0.0,
    };
    out.* = .{
        .min = .{ .x = center.x - half.x * scale.x, .y = center.y - half.y * scale.y, .z = center.z - half.z * scale.z, .w = 0.0 },
        .max = .{ .x = center.x + half.x * scale.x, .y = center.y + half.y * scale.y, .z = center.z + half.z * scale.z, .w = 0.0 },
    };
}

pub export fn sa3d_math_aabb3f_closest_point(out: *Vec3f, aabb: *const Aabb3f, point: *const Vec3f) callconv(.c) void {
    out.* = .{
        .x = std.math.clamp(point.x, aabb.min.x, aabb.max.x),
        .y = std.math.clamp(point.y, aabb.min.y, aabb.max.y),
        .z = std.math.clamp(point.z, aabb.min.z, aabb.max.z),
    };
}

pub export fn sa3d_math_bounding_sphere3f_new(out: *BoundingSphere3f, center: *const Vec3f, radius: f32) callconv(.c) void {
    out.* = .{ .center = vec3aFromVec3(center), .radius = radius };
}

pub export fn sa3d_math_bounding_sphere3f_aabb(out: *Aabb3f, sphere: *const BoundingSphere3f) callconv(.c) void {
    out.* = .{
        .min = .{ .x = sphere.center.x - sphere.radius, .y = sphere.center.y - sphere.radius, .z = sphere.center.z - sphere.radius, .w = 0.0 },
        .max = .{ .x = sphere.center.x + sphere.radius, .y = sphere.center.y + sphere.radius, .z = sphere.center.z + sphere.radius, .w = 0.0 },
    };
}

pub export fn sa3d_math_aabb3f_intersects_sphere(aabb: *const Aabb3f, sphere: *const BoundingSphere3f) callconv(.c) bool {
    const closest = Vec3f{
        .x = std.math.clamp(sphere.center.x, aabb.min.x, aabb.max.x),
        .y = std.math.clamp(sphere.center.y, aabb.min.y, aabb.max.y),
        .z = std.math.clamp(sphere.center.z, aabb.min.z, aabb.max.z),
    };
    const dx = sphere.center.x - closest.x;
    const dy = sphere.center.y - closest.y;
    const dz = sphere.center.z - closest.z;
    return dx * dx + dy * dy + dz * dz <= sphere.radius * sphere.radius;
}

fn approxEq(a: f32, b: f32) bool {
    return @abs(a - b) <= 0.00001;
}

pub export fn sa3d_math_selftest() callconv(.c) i32 {
    var a: Vec3f = undefined;
    var b: Vec3f = undefined;
    var out: Vec3f = undefined;
    var cross: Vec3f = undefined;
    sa3d_math_vec3f_set(&a, 1.0, 2.0, 3.0);
    sa3d_math_vec3f_set(&b, 4.0, 5.0, 6.0);
    sa3d_math_vec3f_add(&out, &a, &b);
    if (out.x != 5.0 or out.y != 7.0 or out.z != 9.0) return 1;
    sa3d_math_vec3f_sub(&out, &b, &a);
    if (out.x != 3.0 or out.y != 3.0 or out.z != 3.0) return 2;
    if (sa3d_math_vec3f_dot(&a, &b) != 32.0) return 3;
    sa3d_math_vec3f_cross(&cross, &a, &b);
    if (cross.x != -3.0 or cross.y != 6.0 or cross.z != -3.0) return 4;

    var ray: Ray3f = undefined;
    var point: Vec3f = undefined;
    sa3d_math_ray3f_set(&ray, &a, &b);
    sa3d_math_ray3f_get_point(&point, &ray, 2.0);
    if (point.x != 9.0 or point.y != 12.0 or point.z != 15.0) return 5;

    const zero = Vec3f{ .x = 0.0, .y = 0.0, .z = 0.0 };
    const z_dir = Vec3f{ .x = 0.0, .y = 0.0, .z = 1.0 };
    const z_plane = Vec3f{ .x = 0.0, .y = 0.0, .z = 1.0 };
    var z_ray: Ray3f = undefined;
    var distance: f32 = 0.0;
    var hit_point: Vec3f = undefined;
    sa3d_math_ray3f_set(&z_ray, &zero, &z_dir);
    if (!sa3d_math_ray3f_intersect_plane(&distance, &z_ray, &z_plane, &z_dir)) return 10;
    if (!approxEq(distance, 1.0)) return 11;
    if (!sa3d_math_ray3f_plane_intersection_point(&hit_point, &z_ray, &z_plane, &z_dir)) return 12;
    if (!approxEq(hit_point.z, 1.0)) return 13;
    if (sa3d_math_ray3f_intersect_plane(&distance, &z_ray, &zero, &Vec3f{ .x = 1.0, .y = 0.0, .z = 0.0 })) return 14;

    const center = Vec3f{ .x = 10.0, .y = 20.0, .z = 30.0 };
    const half = Vec3f{ .x = 2.0, .y = 3.0, .z = 4.0 };
    const inner_half = Vec3f{ .x = 1.0, .y = 1.0, .z = 1.0 };
    var outer: Aabb3f = undefined;
    var inner: Aabb3f = undefined;
    var merged: Aabb3f = undefined;
    var out_center: Vec3f = undefined;
    var out_half: Vec3f = undefined;
    sa3d_math_aabb3f_new(&outer, &center, &half);
    sa3d_math_aabb3f_center(&out_center, &outer);
    sa3d_math_aabb3f_half_size(&out_half, &outer);
    if (outer.min.x != 8.0 or outer.max.z != 34.0) return 6;
    if (out_center.x != 10.0 or out_half.z != 4.0) return 7;
    sa3d_math_aabb3f_new(&inner, &center, &inner_half);
    if (!sa3d_math_aabb3f_contains_aabb(&outer, &inner)) return 8;
    sa3d_math_aabb3f_merge(&merged, &outer, &inner);
    if (merged.min.x != 8.0 or merged.max.z != 34.0) return 9;
    return 0;
}

pub export fn sa3d_math_bounding_selftest() callconv(.c) i32 {
    const min = Vec3f{ .x = -1.0, .y = -1.0, .z = -1.0 };
    const max = Vec3f{ .x = 1.0, .y = 1.0, .z = 1.0 };
    var aabb: Aabb3f = undefined;
    sa3d_math_aabb3f_from_min_max(&aabb, &min, &max);
    if (!approxEq(sa3d_math_aabb3f_visible_area(&aabb), 12.0)) return 1;

    const inside = Vec3f{ .x = 0.25, .y = 0.1, .z = 0.3 };
    const outside = Vec3f{ .x = 10.0, .y = -10.0, .z = 0.5 };
    if (!sa3d_math_aabb3f_contains_point(&aabb, &inside)) return 2;
    if (sa3d_math_aabb3f_contains_point(&aabb, &outside)) return 3;

    var closest: Vec3f = undefined;
    sa3d_math_aabb3f_closest_point(&closest, &aabb, &outside);
    if (!approxEq(closest.x, 1.0) or !approxEq(closest.y, -1.0) or !approxEq(closest.z, 0.5)) return 4;

    const pad = Vec3f{ .x = 1.0, .y = 1.0, .z = 1.0 };
    var grown: Aabb3f = undefined;
    var shrunk: Aabb3f = undefined;
    var scaled: Aabb3f = undefined;
    sa3d_math_aabb3f_grow(&grown, &aabb, &pad);
    if (!approxEq(grown.min.x, -2.0) or !approxEq(grown.max.z, 2.0)) return 5;
    sa3d_math_aabb3f_shrink(&shrunk, &grown, &pad);
    if (!sa3d_math_aabb3f_contains_aabb(&aabb, &shrunk) or !approxEq(shrunk.min.x, -1.0)) return 6;
    const scale = Vec3f{ .x = 2.0, .y = 2.0, .z = 2.0 };
    sa3d_math_aabb3f_scale_around_center(&scaled, &aabb, &scale);
    if (!approxEq(scaled.min.x, -2.0) or !approxEq(scaled.max.y, 2.0)) return 7;

    const other_min = Vec3f{ .x = 0.5, .y = 0.5, .z = 0.5 };
    const other_max = Vec3f{ .x = 2.0, .y = 2.0, .z = 2.0 };
    const miss_min = Vec3f{ .x = 1.1, .y = 0.0, .z = 0.0 };
    const miss_max = Vec3f{ .x = 2.0, .y = 0.5, .z = 0.25 };
    var overlap: Aabb3f = undefined;
    var miss: Aabb3f = undefined;
    sa3d_math_aabb3f_from_min_max(&overlap, &other_min, &other_max);
    sa3d_math_aabb3f_from_min_max(&miss, &miss_min, &miss_max);
    if (!sa3d_math_aabb3f_intersects(&aabb, &overlap)) return 8;
    if (sa3d_math_aabb3f_intersects(&aabb, &miss)) return 9;

    const sphere_center = Vec3f{ .x = 1.5, .y = 1.5, .z = 1.5 };
    var sphere: BoundingSphere3f = undefined;
    var sphere_aabb: Aabb3f = undefined;
    sa3d_math_bounding_sphere3f_new(&sphere, &sphere_center, 1.0);
    if (!sa3d_math_aabb3f_intersects_sphere(&aabb, &sphere)) return 10;
    sphere.center.x = 1.75;
    sphere.center.y = 1.75;
    sphere.center.z = 1.75;
    if (sa3d_math_aabb3f_intersects_sphere(&aabb, &sphere)) return 11;
    sa3d_math_bounding_sphere3f_aabb(&sphere_aabb, &sphere);
    if (!approxEq(sphere_aabb.min.x, 0.75) or !approxEq(sphere_aabb.max.z, 2.75)) return 12;
    return 0;
}

pub export fn sa3d_math_transform_selftest() callconv(.c) i32 {
    var identity_q: Quatf = undefined;
    var identity_m: Mat4f = undefined;
    sa3d_math_quatf_identity(&identity_q);
    sa3d_math_mat4f_identity(&identity_m);
    if (!approxEq(identity_q.w, 1.0) or !approxEq(identity_m.data[0], 1.0) or !approxEq(identity_m.data[15], 1.0)) return 1;

    const scale = Vec3f{ .x = 2.0, .y = 3.0, .z = 4.0 };
    const translation = Vec3f{ .x = 5.0, .y = 6.0, .z = 7.0 };
    var matrix: Mat4f = undefined;
    sa3d_math_mat4f_from_scale_rotation_translation(&matrix, &scale, &identity_q, &translation);
    if (!approxEq(matrix.data[0], 2.0) or !approxEq(matrix.data[5], 3.0) or !approxEq(matrix.data[10], 4.0)) return 2;
    if (!approxEq(matrix.data[12], 5.0) or !approxEq(matrix.data[13], 6.0) or !approxEq(matrix.data[14], 7.0)) return 3;

    const point = Vec3f{ .x = 1.0, .y = 2.0, .z = 3.0 };
    var transformed: Vec3f = undefined;
    sa3d_math_mat4f_transform_point3(&transformed, &matrix, &point);
    if (!approxEq(transformed.x, 7.0) or !approxEq(transformed.y, 12.0) or !approxEq(transformed.z, 19.0)) return 4;

    var half_turn_y: Quatf = undefined;
    sa3d_math_quatf_from_rotation_y(&half_turn_y, std.math.pi);
    const x_axis = Vec3f{ .x = 1.0, .y = 0.0, .z = 0.0 };
    var rotated_x: Vec3f = undefined;
    sa3d_math_quatf_mul_vec3(&rotated_x, &half_turn_y, &x_axis);
    if (!approxEq(rotated_x.x, -1.0) or !approxEq(rotated_x.z, 0.0)) return 5;

    var rot_matrix: Mat4f = undefined;
    const unit = Vec3f{ .x = 1.0, .y = 1.0, .z = 1.0 };
    const zero = Vec3f{ .x = 0.0, .y = 0.0, .z = 0.0 };
    sa3d_math_mat4f_from_scale_rotation_translation(&rot_matrix, &unit, &half_turn_y, &zero);
    if (!approxEq(rot_matrix.data[0], -1.0) or !approxEq(rot_matrix.data[10], -1.0)) return 6;

    var translated: Mat4f = undefined;
    var combined: Mat4f = undefined;
    sa3d_math_mat4f_from_translation(&translated, &translation);
    sa3d_math_mat4f_mul(&combined, &translated, &rot_matrix);
    if (!approxEq(combined.data[12], 5.0) or !approxEq(combined.data[13], 6.0) or !approxEq(combined.data[14], 7.0)) return 7;
    return 0;
}

pub export fn sa3d_math_vector_selftest() callconv(.c) i32 {
    var a2: Vec2f = undefined;
    var b2: Vec2f = undefined;
    var out2: Vec2f = undefined;
    sa3d_math_vec2f_set(&a2, 3.0, 4.0);
    sa3d_math_vec2f_set(&b2, -1.0, 2.0);
    sa3d_math_vec2f_add(&out2, &a2, &b2);
    if (!approxEq(out2.x, 2.0) or !approxEq(out2.y, 6.0)) return 1;
    sa3d_math_vec2f_sub(&out2, &a2, &b2);
    if (!approxEq(out2.x, 4.0) or !approxEq(out2.y, 2.0)) return 2;
    if (!approxEq(sa3d_math_vec2f_dot(&a2, &b2), 5.0)) return 3;
    if (!approxEq(sa3d_math_vec2f_length(&a2), 5.0)) return 4;
    if (!sa3d_math_vec2f_normalize(&out2, &a2)) return 5;
    if (!approxEq(out2.x, 0.6) or !approxEq(out2.y, 0.8)) return 6;

    var zero2: Vec2f = undefined;
    sa3d_math_vec2f_set(&zero2, 0.0, 0.0);
    if (sa3d_math_vec2f_normalize(&out2, &zero2)) return 7;

    var a3 = Vec3f{ .x = 2.0, .y = 0.0, .z = 0.0 };
    var out3: Vec3f = undefined;
    sa3d_math_vec3f_mul_scalar(&out3, &a3, 3.0);
    if (!approxEq(out3.x, 6.0) or !approxEq(out3.y, 0.0)) return 8;
    if (!approxEq(sa3d_math_vec3f_length(&out3), 6.0)) return 9;
    if (!sa3d_math_vec3f_normalize(&out3, &out3)) return 10;
    if (!approxEq(out3.x, 1.0) or !approxEq(out3.y, 0.0) or !approxEq(out3.z, 0.0)) return 11;

    var a4: Vec4f = undefined;
    var b4: Vec4f = undefined;
    var out4: Vec4f = undefined;
    sa3d_math_vec4f_set(&a4, 1.0, 2.0, 3.0, 4.0);
    sa3d_math_vec4f_set(&b4, 5.0, 6.0, 7.0, 8.0);
    sa3d_math_vec4f_add(&out4, &a4, &b4);
    if (!approxEq(out4.x, 6.0) or !approxEq(out4.w, 12.0)) return 12;
    sa3d_math_vec4f_sub(&out4, &b4, &a4);
    if (!approxEq(out4.y, 4.0) or !approxEq(out4.z, 4.0)) return 13;
    if (!approxEq(sa3d_math_vec4f_dot(&a4, &b4), 70.0)) return 14;
    if (!approxEq(sa3d_math_vec4f_length_squared(&a4), 30.0)) return 15;
    sa3d_math_vec4f_mul_scalar(&out4, &a4, 0.5);
    if (!approxEq(out4.x, 0.5) or !approxEq(out4.w, 2.0)) return 16;
    return 0;
}

test "math f32 vec3 functions match Bevy glam equations" {
    var a: Vec3f = undefined;
    var b: Vec3f = undefined;
    var out: Vec3f = undefined;
    var cross: Vec3f = undefined;

    sa3d_math_vec3f_set(&a, 1.0, 2.0, 3.0);
    sa3d_math_vec3f_set(&b, 4.0, 5.0, 6.0);
    sa3d_math_vec3f_add(&out, &a, &b);
    try std.testing.expectEqual(@as(f32, 5.0), out.x);
    try std.testing.expectEqual(@as(f32, 7.0), out.y);
    try std.testing.expectEqual(@as(f32, 9.0), out.z);

    sa3d_math_vec3f_sub(&out, &b, &a);
    try std.testing.expectEqual(@as(f32, 3.0), out.x);
    try std.testing.expectEqual(@as(f32, 3.0), out.y);
    try std.testing.expectEqual(@as(f32, 3.0), out.z);
    try std.testing.expectEqual(@as(f32, 32.0), sa3d_math_vec3f_dot(&a, &b));

    sa3d_math_vec3f_cross(&cross, &a, &b);
    try std.testing.expectEqual(@as(f32, -3.0), cross.x);
    try std.testing.expectEqual(@as(f32, 6.0), cross.y);
    try std.testing.expectEqual(@as(f32, -3.0), cross.z);
}

test "math selftest exposes Bevy backed behavior to SA tests" {
    try std.testing.expectEqual(@as(i32, 0), sa3d_math_selftest());
}

test "math f32 ray and aabb functions match Bevy source formulas" {
    const origin = Vec3f{ .x = 1.0, .y = 2.0, .z = 3.0 };
    const direction = Vec3f{ .x = 4.0, .y = 5.0, .z = 6.0 };
    var ray: Ray3f = undefined;
    var point: Vec3f = undefined;
    sa3d_math_ray3f_set(&ray, &origin, &direction);
    sa3d_math_ray3f_get_point(&point, &ray, 2.0);
    try std.testing.expectEqual(@as(f32, 9.0), point.x);
    try std.testing.expectEqual(@as(f32, 12.0), point.y);
    try std.testing.expectEqual(@as(f32, 15.0), point.z);

    const zero = Vec3f{ .x = 0.0, .y = 0.0, .z = 0.0 };
    const z_dir = Vec3f{ .x = 0.0, .y = 0.0, .z = 1.0 };
    const z_plane = Vec3f{ .x = 0.0, .y = 0.0, .z = 1.0 };
    const x_normal = Vec3f{ .x = 1.0, .y = 0.0, .z = 0.0 };
    var z_ray: Ray3f = undefined;
    var distance: f32 = 0.0;
    var hit_point: Vec3f = undefined;
    sa3d_math_ray3f_set(&z_ray, &zero, &z_dir);
    try std.testing.expect(sa3d_math_ray3f_intersect_plane(&distance, &z_ray, &z_plane, &z_dir));
    try std.testing.expectEqual(@as(f32, 1.0), distance);
    try std.testing.expect(sa3d_math_ray3f_plane_intersection_point(&hit_point, &z_ray, &z_plane, &z_dir));
    try std.testing.expectEqual(@as(f32, 1.0), hit_point.z);
    try std.testing.expect(!sa3d_math_ray3f_intersect_plane(&distance, &z_ray, &zero, &x_normal));

    const center = Vec3f{ .x = 10.0, .y = 20.0, .z = 30.0 };
    const half = Vec3f{ .x = 2.0, .y = 3.0, .z = 4.0 };
    var outer: Aabb3f = undefined;
    var inner: Aabb3f = undefined;
    var merged: Aabb3f = undefined;
    var out_center: Vec3f = undefined;
    var out_half: Vec3f = undefined;
    sa3d_math_aabb3f_new(&outer, &center, &half);
    sa3d_math_aabb3f_center(&out_center, &outer);
    sa3d_math_aabb3f_half_size(&out_half, &outer);
    try std.testing.expectEqual(@as(f32, 8.0), outer.min.x);
    try std.testing.expectEqual(@as(f32, 34.0), outer.max.z);
    try std.testing.expectEqual(@as(f32, 10.0), out_center.x);
    try std.testing.expectEqual(@as(f32, 4.0), out_half.z);

    const inner_half = Vec3f{ .x = 1.0, .y = 1.0, .z = 1.0 };
    sa3d_math_aabb3f_new(&inner, &center, &inner_half);
    try std.testing.expect(sa3d_math_aabb3f_contains_aabb(&outer, &inner));
    sa3d_math_aabb3f_merge(&merged, &outer, &inner);
    try std.testing.expectEqual(@as(f32, 8.0), merged.min.x);
    try std.testing.expectEqual(@as(f32, 34.0), merged.max.z);
}

test "math f32 bounding functions match Bevy Aabb3d formulas" {
    try std.testing.expectEqual(@as(i32, 0), sa3d_math_bounding_selftest());
}

test "math f32 quat and mat4 functions match Bevy transform formulas" {
    try std.testing.expectEqual(@as(i32, 0), sa3d_math_transform_selftest());
}

test "math f32 vec2 vec3 and vec4 functions match glam formulas" {
    try std.testing.expectEqual(@as(i32, 0), sa3d_math_vector_selftest());
}
