//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn sub(a: Vec4, b: Vec4) Vec4 {
        return Vec4{
            .x = a.x - b.x,
            .y = a.y - b.y,
            .z = a.z - b.z,
            .w = a.w - b.w,
        };
    }

    pub fn add(a: Vec4, b: Vec4) Vec4 {
        return Vec4{
            .x = a.x + b.x,
            .y = a.y + b.y,
            .z = a.z + b.z,
            .w = a.w + b.w,
        };
    }

    pub fn dot(a: Vec4, b: Vec4) f32 {
        return a.x * b.x +
            a.y * b.y +
            a.z * b.z +
            a.w * b.w;
    }

    pub fn mul(a: Vec4, b: f32) Vec4 {
        return Vec4{
            .x = a.x * b,
            .y = a.y * b,
            .z = a.z * b,
            .w = a.w * b,
        };
    }
};

const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(v: Vec4) Vec2 {
        return Vec2{
            .x = v.x,
            .y = v.y,
        };
    }
};

const Vec2i = struct {
    x: i32,
    y: i32,

    pub fn init(v: Vec2) Vec2i {
        return Vec2i{
            .x = @intFromFloat(v.x),
            .y = @intFromFloat(v.y),
        };
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
    pub fn fromVec4(v: Vec4) Color {
        return Color{
            .r = @intFromFloat(v.x * 255),
            .g = @intFromFloat(v.y * 255),
            .b = @intFromFloat(v.z * 255),
            .a = @intFromFloat(v.w * 255),
        };
    }
};

pub const Uniforms = struct { color: Color };

pub const Varyings = struct {
    v: [3][]Vec4 = undefined,

    pub fn init(comptime len: usize, storage: []Vec4) Varyings {
        const v = [3][]Vec4{ storage[0..len], storage[len..(2 * len)], storage[(2 * len)..(3 * len)] };
        return Varyings{
            .v = v,
        };
    }
};

pub const Varying = []Vec4;

pub const FragmentShader = fn (varying: []Vec4, uniforms: anytype) Vec4;

pub const Triangle = struct {
    v: [3]Vec4 = undefined,
};

pub const Image = struct {
    pixels: []u8,
    width: u32,
    height: u32,

    pub fn init(allocator: std.mem.Allocator, w: u32, h: u32) !Image {
        const pixels = try allocator.alloc(u8, 4 * w * h);
        return Image{ .pixels = pixels, .width = w, .height = h };
    }

    pub fn deinit(self: Image, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }

    pub fn setPixel(self: Image, x: usize, y: usize, color: Color) void {
        if (x >= self.width or y >= self.height) {
            return;
        }
        const offset = (y * self.width + x) * 4;
        self.pixels[offset] = color.r;
        self.pixels[offset + 1] = color.g;
        self.pixels[offset + 2] = color.b;
        self.pixels[offset + 3] = color.a;
    }
};

fn minv2i(a: Vec2i, b: Vec2i) Vec2i {
    return Vec2i{ .x = @min(a.x, b.x), .y = @min(a.y, b.y) };
}

fn maxv2i(a: Vec2i, b: Vec2i) Vec2i {
    return Vec2i{ .x = @max(a.x, b.x), .y = @max(a.y, b.y) };
}

fn bary_det(v1: Vec2, v2: Vec2, v3: Vec2) f32 {
    return (v2.y - v3.y) * (v1.x - v3.x) + (v3.x - v2.x) * (v1.y - v3.y);
}

const Bary = struct {
    l1: f32,
    l2: f32,
    l3: f32,
};

fn bary_coords(p: Vec2, v1: Vec2, v2: Vec2, v3: Vec2, det: f32) Bary {
    const l1 = ((v2.y - v3.y) * (p.x - v3.x) + (v3.x - v2.x) * (p.y - v3.y)) / det;
    const l2 = ((v3.y - v1.y) * (p.x - v3.x) + (v1.x - v3.x) * (p.y - v3.y)) / det;
    return Bary{ .l1 = l1, .l2 = l2, .l3 = 1 - l1 - l2 };
}

// Source - https://stackoverflow.com/a/2049593
// Posted by Kornel Kisielewicz, modified by community. See post 'Timeline' for change history
// Retrieved 2026-02-15, License - CC BY-SA 4.0

fn sign(p1: Vec2, p2: Vec2, p3: Vec2) f32 {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

fn pointInTriangle(pt: Vec2, v1: Vec2, v2: Vec2, v3: Vec2) bool {
    const d1 = sign(pt, v1, v2);
    const d2 = sign(pt, v2, v3);
    const d3 = sign(pt, v3, v1);

    const has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0);
    const has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0);

    return !(has_neg and has_pos);
}

fn interp_varyings(varyings: Varyings, bary: Bary, out: Varying) void {
    for (varyings.v[0], varyings.v[1], varyings.v[2], 0..) |a, b, c, i| {
        const v = a.mul(bary.l1).add(b.mul(bary.l2)).add(c.mul(bary.l3));
        out[i] = v;
    }
}

pub fn drawTriangle(canvas: Image, triangle: Triangle, comptime varyings_len: usize, varyings: Varyings, uniforms: anytype, fragment_shader: FragmentShader) void {
    const a2 = Vec2.init(triangle.v[0]);
    const b2 = Vec2.init(triangle.v[1]);
    const c2 = Vec2.init(triangle.v[2]);
    const ai = Vec2i.init(a2);
    const bi = Vec2i.init(b2);
    const ci = Vec2i.init(c2);
    const mini = minv2i(minv2i(ai, bi), ci);
    const maxi = maxv2i(maxv2i(ai, bi), ci);

    const miny: usize = @max(0, mini.y);
    const maxy: usize = @max(0, maxi.y + 1);
    const minx: usize = @max(0, mini.x);
    const maxx: usize = @max(0, maxi.x + 1);

    const det = bary_det(a2, b2, c2);

    for (miny..maxy) |y| {
        for (minx..maxx) |x| {
            const p = Vec2{ .x = @as(f32, @floatFromInt(x)) + 0.5, .y = @as(f32, @floatFromInt(y)) + 0.5 };
            if (pointInTriangle(p, a2, b2, c2)) {
                const bary = bary_coords(p, a2, b2, c2, det);
                var v: [varyings_len]Vec4 = undefined;
                interp_varyings(varyings, bary, &v);
                const color_v4 = fragment_shader(&v, uniforms);
                const color = Color.fromVec4(color_v4);
                canvas.setPixel(x, y, color);
            }
        }
    }
}

pub fn writeToTga(writer: *Io.Writer, image: Image) Io.Writer.Error!void {
    var header = [_]u8{ 0, 0, 2, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0 };
    header[12] = @intCast(image.width & 0xff);
    header[13] = @intCast((image.width >> 8) & 0xff);
    header[14] = @intCast(image.height & 0xff);
    header[15] = @intCast((image.height >> 8) & 0xff);
    _ = try writer.write(&header);
    _ = try writer.write(image.pixels);
}

/// This is a documentation comment to explain the `printAnotherMessage` function below.
///
/// Accepting an `Io.Writer` instance is a handy way to write reusable code.
pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
