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

    pub fn debug_print(a: Vec4) void {
        std.debug.print("{} {} {} {}\n", .{ a.x, a.y, a.z, a.w });
    }
};

pub const Mat4 = struct {
    a: [16]f32 = undefined,

    pub fn mulv4(self: Mat4, v: Vec4) Vec4 {
        return Vec4{
            .x = self.a[0] * v.x + self.a[1] * v.y + self.a[2] * v.z + self.a[3] * v.w,
            .y = self.a[4] * v.x + self.a[5] * v.y + self.a[6] * v.z + self.a[7] * v.w,
            .z = self.a[8] * v.x + self.a[9] * v.y + self.a[10] * v.z + self.a[11] * v.w,
            .w = self.a[12] * v.x + self.a[13] * v.y + self.a[14] * v.z + self.a[15] * v.w,
        };
    }

    pub fn init() Mat4 {
        return Mat4{
            .a = [16]f32{
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            },
        };
    }

    pub fn init_projection(r: f32, t: f32, n: f32, f: f32) Mat4 {
        return Mat4{
            .a = [_]f32{
                n / r, 0,     0,                  0,
                0,     n / t, 0,                  0,
                0,     0,     -(f + n) / (f - n), -2 * f * n / (f - n),
                0,     0,     -1,                 0,
            },
        };
    }

    pub fn debug_print(a: Mat4) void {
        std.debug.print("{} {} {} {}\n", .{ a.a[0], a.a[1], a.a[2], a.a[3] });
        std.debug.print("{} {} {} {}\n", .{ a.a[4], a.a[5], a.a[6], a.a[7] });
        std.debug.print("{} {} {} {}\n", .{ a.a[8], a.a[9], a.a[10], a.a[11] });
        std.debug.print("{} {} {} {}\n", .{ a.a[12], a.a[13], a.a[14], a.a[15] });
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
            .r = @intFromFloat(@min(@max(0, v.x * 255), 255)),
            .g = @intFromFloat(@min(@max(0, v.y * 255), 255)),
            .b = @intFromFloat(@min(@max(0, v.z * 255), 255)),
            .a = @intFromFloat(@min(@max(0, v.w * 255), 255)),
        };
    }
};

pub const Varyings = struct {
    v: [3][]Vec4 = undefined,

    pub fn mul(self: Varyings, f: [3]f32) void {
        for (0..3) |i| {
            for (0..self.v[i].len) |j| {
                self.v[i][j] = self.v[i][j].mul(f[i]);
            }
        }
    }

    pub fn init(comptime len: usize, storage: []Vec4) Varyings {
        const v = [3][]Vec4{ storage[0..len], storage[len..(2 * len)], storage[(2 * len)..(3 * len)] };
        return Varyings{
            .v = v,
        };
    }
};

pub const Varying = []Vec4;

pub const VertexShader = fn (Attribute: anytype, uniforms: anytype, out: Varying) Vec4;
pub const FragmentShader = fn (varying: []Vec4, uniforms: anytype) Vec4;

pub const Pipeline = struct {
    vertexShade: VertexShader,
    fragmentShade: FragmentShader,
    varyings_len: comptime_int,
    attributes_type: type,
};

const Triangle = struct {
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
        self.pixels[offset] = color.b;
        self.pixels[offset + 1] = color.g;
        self.pixels[offset + 2] = color.r;
        self.pixels[offset + 3] = color.a;
    }
};

pub const DepthBuffer = struct {
    pixels: []f32,
    width: u32,
    height: u32,

    pub fn init(allocator: std.mem.Allocator, w: u32, h: u32) !DepthBuffer {
        const pixels = try allocator.alloc(f32, w * h);
        @memset(pixels, std.math.floatMax(f32));
        return DepthBuffer{ .pixels = pixels, .width = w, .height = h };
    }

    pub fn deinit(self: Image, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }

    pub fn setDepth(self: DepthBuffer, x: usize, y: usize, depth: f32) void {
        if (x >= self.width or y >= self.height) {
            return;
        }
        const offset = (y * self.width + x);
        self.pixels[offset] = depth;
    }

    pub fn getDepth(self: DepthBuffer, x: usize, y: usize) f32 {
        if (x >= self.width or y >= self.height) {
            return 0;
        }
        const offset = (y * self.width + x);
        return self.pixels[offset];
    }
};

pub const FrameBuffer = struct {
    image: Image,
    depthBuffer: DepthBuffer,

    pub fn width(self: FrameBuffer) usize {
        return self.image.width;
    }

    pub fn height(self: FrameBuffer) usize {
        return self.image.height;
    }

    pub fn setPixel(self: FrameBuffer, x: usize, y: usize, color: Color) void {
        self.image.setPixel(x, y, color);
    }

    pub fn setDepth(self: FrameBuffer, x: usize, y: usize, depth: f32) void {
        self.depthBuffer.setDepth(x, y, depth);
    }

    pub fn getDepth(self: FrameBuffer, x: usize, y: usize) f32 {
        return self.depthBuffer.getDepth(x, y);
    }
};

pub fn drawTriangles(pipeline: Pipeline, attributes: []const pipeline.attributes_type, uniforms: anytype, framebuffer: FrameBuffer) void {
    var triangle = Triangle{};
    var varying_storage: [3 * pipeline.varyings_len]Vec4 = undefined;
    const varyings: Varyings = .init(pipeline.varyings_len, &varying_storage);
    var i: usize = 0;
    while (i < attributes.len) : (i += 3) {
        for (0..3) |j| {
            triangle.v[j] = pipeline.vertexShade(attributes[i + j], uniforms, varyings.v[j]);
        }
        drawTriangle(framebuffer, triangle, pipeline, varyings, uniforms);
    }
}

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

fn interp_f32(a: f32, b: f32, c: f32, bary: Bary) f32 {
    return a * bary.l1 + b * bary.l2 + c * bary.l3;
}

fn interp_varyings(varyings: Varyings, bary: Bary, out: Varying) void {
    for (varyings.v[0], varyings.v[1], varyings.v[2], 0..) |a, b, c, i| {
        const v = a.mul(bary.l1).add(b.mul(bary.l2)).add(c.mul(bary.l3));
        out[i] = v;
    }
}

pub fn drawTriangle(framebuffer: FrameBuffer, triangle: Triangle, pipeline: Pipeline, varyings: Varyings, uniforms: anytype) void {
    const varyings_len = pipeline.varyings_len;
    var a: [3]Vec4 = undefined;
    var a2: [3]Vec2 = undefined;
    var ai: [3]Vec2i = undefined;
    var ow: [3]f32 = undefined;
    for (0..3) |i| {
        // divide by w to convert to NDC
        ow[i] = 1.0 / triangle.v[i].w;
        a[i] = triangle.v[i].mul(ow[i]);
        a2[i] = Vec2.init(a[i]);
        // offset and mult by screen size
        a2[i].x = (a2[i].x + 1.0) * 0.5 * @as(f32, @floatFromInt(framebuffer.width()));
        a2[i].y = (a2[i].y + 1.0) * 0.5 * @as(f32, @floatFromInt(framebuffer.height()));
        ai[i] = Vec2i.init(a2[i]);
    }
    // divide varyings by w
    varyings.mul(ow);

    // find bounding box in screen space
    const mini = minv2i(minv2i(ai[0], ai[1]), ai[2]);
    const maxi = maxv2i(maxv2i(ai[0], ai[1]), ai[2]);

    const miny: usize = @max(0, mini.y);
    const maxy: usize = @max(0, maxi.y + 1);
    const minx: usize = @max(0, mini.x);
    const maxx: usize = @max(0, maxi.x + 1);

    const det = bary_det(a2[0], a2[1], a2[2]);

    // for each pixel in bounding box
    for (miny..maxy) |y| {
        for (minx..maxx) |x| {
            const p = Vec2{ .x = @as(f32, @floatFromInt(x)) + 0.5, .y = @as(f32, @floatFromInt(y)) + 0.5 };
            if (pointInTriangle(p, a2[0], a2[1], a2[2])) {
                const bary = bary_coords(p, a2[0], a2[1], a2[2], det);
                const w_int = 1.0 / interp_f32(ow[0], ow[1], ow[2], bary);
                const depth = w_int * interp_f32(a[0].z, a[1].z, a[2].z, bary);
                if (depth > framebuffer.getDepth(x, y)) {
                    continue;
                }
                framebuffer.setDepth(x, y, depth);
                var v: [varyings_len]Vec4 = undefined;
                interp_varyings(varyings, bary, &v);
                // divide by (1/w) to get perpective correct interpolation
                for (0..varyings_len) |i| {
                    v[i] = v[i].mul(w_int);
                }
                const color_v4 = pipeline.fragmentShade(&v, uniforms);
                const color = Color.fromVec4(color_v4);
                framebuffer.setPixel(x, y, color);
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

test "interp float" {
    const a = Vec2{ .x = 0.1, .y = 0.1 };
    const b = Vec2{ .x = 1.1, .y = 0.1 };
    const c = Vec2{ .x = 0.1, .y = 1.1 };
    const det = bary_det(a, b, c);

    const bary_at_a = bary_coords(a, a, b, c, det);
    const i_at_a = interp_f32(5, 6, 20, bary_at_a);
    try std.testing.expect(i_at_a == 5);

    const bary_at_b = bary_coords(b, a, b, c, det);
    const i_at_b = interp_f32(5, 6, 20, bary_at_b);
    try std.testing.expect(i_at_b == 6);

    const bary_at_c = bary_coords(c, a, b, c, det);
    const i_at_c = interp_f32(5, 6, 20, bary_at_c);
    try std.testing.expect(i_at_c == 20);

    const mid_bc = Vec2{ .x = (b.x + c.x) / 2, .y = (b.y + c.y) / 2 };
    const bary_at_mid_bc = bary_coords(mid_bc, a, b, c, det);
    const i_at_mid_bc = interp_f32(5, 6, 20, bary_at_mid_bc);
    try std.testing.expect(i_at_mid_bc == (6 + 20) / 2);
}

test "point in triangle" {
    //
    //
    //
    //  | \
    //  |  \
    // 4|   \ 2
    //  |  1 \
    //  |     \
    //  -------
    //     3

    const a = Vec2{ .x = 0.1, .y = 0.1 };
    const b = Vec2{ .x = 1.1, .y = 0.1 };
    const c = Vec2{ .x = 0.1, .y = 1.1 };

    const p1 = Vec2{ .x = 0.5, .y = 0.5 };
    try std.testing.expect(pointInTriangle(p1, a, b, c) == true);

    const p2 = Vec2{ .x = 0.7, .y = 0.7 };
    try std.testing.expect(pointInTriangle(p2, a, b, c) == false);

    const p3 = Vec2{ .x = 0.5, .y = 0.0 };
    try std.testing.expect(pointInTriangle(p3, a, b, c) == false);

    const p4 = Vec2{ .x = 0.0, .y = 0.5 };
    try std.testing.expect(pointInTriangle(p4, a, b, c) == false);
}
