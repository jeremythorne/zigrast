//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const kMaxVaryings = 64;

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

    pub fn mulV4(a: Vec4, b: Vec4) Vec4 {
        return Vec4{
            .x = a.x * b.x,
            .y = a.y * b.y,
            .z = a.z * b.z,
            .w = a.w * b.w,
        };
    }

    fn lerp(alpha: f32, b: Vec4, c: Vec4) Vec4 {
        return Vec4{
            .x = lerpf32(alpha, b.x, c.x),
            .y = lerpf32(alpha, b.y, c.y),
            .z = lerpf32(alpha, b.z, c.z),
            .w = lerpf32(alpha, b.w, c.w),
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

    pub fn equal(a: Mat4, b: Mat4) bool {
        for (0..4) |i| {
            for (0..4) |j| {
                const off = j + i * 4;
                if (a.a[off] != b.a[off]) {
                    return false;
                }
            }
        }
        return true;
    }

    pub fn mul(a: Mat4, b: Mat4) Mat4 {
        return Mat4{ .a = [_]f32{
            a.a[0] * b.a[0] + a.a[1] * b.a[4] + a.a[2] * b.a[8] + a.a[3] * b.a[12],
            a.a[0] * b.a[1] + a.a[1] * b.a[5] + a.a[2] * b.a[9] + a.a[3] * b.a[13],
            a.a[0] * b.a[2] + a.a[1] * b.a[6] + a.a[2] * b.a[10] + a.a[3] * b.a[14],
            a.a[0] * b.a[3] + a.a[1] * b.a[7] + a.a[2] * b.a[11] + a.a[3] * b.a[15],

            a.a[4] * b.a[0] + a.a[5] * b.a[4] + a.a[6] * b.a[8] + a.a[7] * b.a[12],
            a.a[4] * b.a[1] + a.a[5] * b.a[5] + a.a[6] * b.a[9] + a.a[7] * b.a[13],
            a.a[4] * b.a[2] + a.a[5] * b.a[6] + a.a[6] * b.a[10] + a.a[7] * b.a[14],
            a.a[4] * b.a[3] + a.a[5] * b.a[7] + a.a[6] * b.a[11] + a.a[7] * b.a[15],

            a.a[8] * b.a[0] + a.a[9] * b.a[4] + a.a[10] * b.a[8] + a.a[11] * b.a[12],
            a.a[8] * b.a[1] + a.a[9] * b.a[5] + a.a[10] * b.a[9] + a.a[11] * b.a[13],
            a.a[8] * b.a[2] + a.a[9] * b.a[6] + a.a[10] * b.a[10] + a.a[11] * b.a[14],
            a.a[8] * b.a[3] + a.a[9] * b.a[7] + a.a[10] * b.a[11] + a.a[11] * b.a[15],

            a.a[12] * b.a[0] + a.a[13] * b.a[4] + a.a[14] * b.a[8] + a.a[15] * b.a[12],
            a.a[12] * b.a[1] + a.a[13] * b.a[5] + a.a[14] * b.a[9] + a.a[15] * b.a[13],
            a.a[12] * b.a[2] + a.a[13] * b.a[6] + a.a[14] * b.a[10] + a.a[15] * b.a[14],
            a.a[12] * b.a[3] + a.a[13] * b.a[7] + a.a[14] * b.a[11] + a.a[15] * b.a[15],
        } };
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

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(v: Vec4) Vec2 {
        return Vec2{
            .x = v.x,
            .y = v.y,
        };
    }

    pub fn mulV2(a: Vec2, b: Vec2) Vec2 {
        return Vec2{
            .x = a.x * b.x,
            .y = a.x * b.y,
        };
    }

    pub fn dot(a: Vec2, b: Vec2) f32 {
        return a.x * b.x + a.y * b.y;
    }

    pub fn length(v: Vec2) f32 {
        return @sqrt(v.dot(v));
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

    pub fn toVec4(self: Color) Vec4 {
        return Vec4{
            .x = @as(f32, @floatFromInt(self.r)) / 255.0,
            .y = @as(f32, @floatFromInt(self.g)) / 255.0,
            .z = @as(f32, @floatFromInt(self.b)) / 255.0,
            .w = @as(f32, @floatFromInt(self.a)) / 255.0,
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

pub fn LOD(duvdx: Vec2, duvdy: Vec2, tex_size: Vec2) f32 {
    return @log2(@max(duvdx.mulV2(tex_size).length(), duvdy.mulV2(tex_size).length()));
}

pub const Varying = []Vec4;
pub const Varying2 = [kMaxVaryings]Vec4;

pub const VertexShader = fn (Attribute: anytype, uniforms: anytype, out: Varying) Vec4;
pub const FragmentShader = fn (varying: Varying, uniforms: anytype, grad_x: Varying, grad_y: Varying) Vec4;

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

    pub fn getPixel(self: Image, x: usize, y: usize) Color {
        if (x >= self.width or y >= self.height) {
            return Color{ .r = 0, .g = 0, .b = 0, .a = 0 };
        }
        const offset = (y * self.width + x) * 4;
        return Color{
            .r = self.pixels[offset],
            .g = self.pixels[offset + 1],
            .b = self.pixels[offset + 2],
            .a = self.pixels[offset + 3],
        };
    }

    pub fn sampleNearest(self: Image, u: f32, v: f32) Vec4 {
        const x: usize = @as(usize, @intFromFloat(@mod(u, 1.0) * @as(f32, @floatFromInt(self.width))));
        const y: usize = @as(usize, @intFromFloat(@mod(v, 1.0) * @as(f32, @floatFromInt(self.height))));
        return Color.toVec4(self.getPixel(x, y));
    }

    pub fn sampleLinear(self: Image, u: f32, v: f32) Vec4 {
        const wf = @as(f32, @floatFromInt(self.width));
        const hf = @as(f32, @floatFromInt(self.height));
        const xf = @mod(u, 1.0) * (wf - 1);
        const yf = @mod(v, 1.0) * (hf - 1);
        const ax = xf - @floor(xf);
        const ay = yf - @floor(yf);
        const x = @as(usize, @intFromFloat(xf));
        const y = @as(usize, @intFromFloat(yf));
        const xn = @as(usize, @intFromFloat(@mod(xf + 1, wf)));
        const yn = @as(usize, @intFromFloat(@mod(yf + 1, hf)));
        const a = Color.toVec4(self.getPixel(x, y));
        const b = Color.toVec4(self.getPixel(xn, y));
        const c = Color.toVec4(self.getPixel(x, yn));
        const d = Color.toVec4(self.getPixel(xn, yn));
        const ab = Vec4.lerp(ax, a, b);
        const cd = Vec4.lerp(ax, c, d);
        return Vec4.lerp(ay, ab, cd);
    }
};

pub const Texture = struct {
    size: Vec2,
    images: []Image,

    pub fn deinit(self: Texture, allocator: std.mem.Allocator) void {
        for (0..self.images.len) |i| {
            self.images[i].deinit(allocator);
        }
        allocator.free(self.images);
    }

    pub fn sampleNearest(self: Texture, u: f32, v: f32) Vec4 {
        if (self.images.len == 0) {
            return Vec4{ .x = 0, .y = 0, .z = 0, .w = 0 };
        }
        return self.images[0].sampleNearest(u, v);
    }

    pub fn sampleLinear(self: Texture, u: f32, v: f32) Vec4 {
        if (self.images.len == 0) {
            return Vec4{ .x = 0, .y = 0, .z = 0, .w = 0 };
        }
        return self.images[0].sampleLinear(u, v);
    }

    pub fn sampleMipMapLinear(self: Texture, u: f32, v: f32, level: f32) Vec4 {
        if (self.images.len == 0) {
            return Vec4{ .x = 0, .y = 0, .z = 0, .w = 0 };
        }
        if (level <= 0) {
            return self.images[0].sampleLinear(u, v);
        }
        const l0 = @max(0, @as(usize, @intFromFloat(level)));
        if (l0 >= self.images.len) {
            return self.images[self.images.len - 1].sampleLinear(u, v);
        }
        const al = level - @floor(level);
        const l1 = @min(self.images.len - 1, l0 + 1);
        const a = self.images[l0].sampleLinear(u, v);
        const b = self.images[l1].sampleLinear(u, v);
        return Vec4.lerp(al, a, b);
    }

    pub fn init(allocator: std.mem.Allocator, root: Image) !Texture {
        const levels = 1 + @as(
            usize,
            @intFromFloat(@max(
                @ceil(@log2(@as(f32, @floatFromInt(root.width)))),
                @ceil(@log2(@as(f32, @floatFromInt(root.height)))),
            )),
        );
        var images = try allocator.alloc(Image, levels);
        images[0] = root;
        var w = @max(1, root.width / 2);
        var h = @max(1, root.height / 2);
        for (1..levels) |i| {
            images[i] = try Image.init(allocator, w, h);
            for (0..h) |y| {
                for (0..w) |x| {
                    const up = images[i - 1];
                    const xup = x * up.width / w;
                    const yup = y * up.height / h;
                    const a = Color.toVec4(up.getPixel(xup, yup));
                    const b = Color.toVec4(up.getPixel(xup + 1, yup));
                    const c = Color.toVec4(up.getPixel(xup, yup + 1));
                    const d = Color.toVec4(up.getPixel(xup + 1, yup + 1));

                    images[i].setPixel(x, y, Color.fromVec4(a.add(b).add(c).add(d).mul(0.25)));
                }
            }
            w = @max(1, w / 2);
            h = @max(1, h / 2);
        }

        return Texture{
            .size = Vec2{ .x = @floatFromInt(images[0].width), .y = @floatFromInt(images[0].height) },
            .images = images,
        };
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
    while (i + 2 < attributes.len) : (i += 3) {
        for (0..3) |j| {
            triangle.v[j] = pipeline.vertexShade(attributes[i + j], uniforms, varyings.v[j]);
        }
        drawTriangle_2(framebuffer, triangle, pipeline, varyings, uniforms);
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

fn swap(T: type, a: T, b: T) struct { T, T } {
    const t = a;
    return .{ b, t };
}

fn unlerp(a: f32, b: f32, c: f32) f32 {
    return (a - b) / (c - b);
}

fn lerpf32(alpha: f32, b: f32, c: f32) f32 {
    return b + (c - b) * alpha;
}

fn lerpVarying(alpha: f32, b: Varying2, c: Varying2) Varying2 {
    var out: Varying2 = undefined;
    for (0..b.len) |i| {
        out[i] = Vec4.lerp(alpha, b[i], c[i]);
    }
    return out;
}

const Corner = struct {
    x: f32,
    z: f32,
    ow: f32,
    v: Varying2,
    v_len: usize,

    fn lerp(alpha: f32, b: Corner, c: Corner) Corner {
        return Corner{
            .x = lerpf32(alpha, b.x, c.x),
            .z = lerpf32(alpha, b.z, c.z),
            .ow = lerpf32(alpha, b.ow, c.ow),
            .v = lerpVarying(alpha, b.v, c.v),
            .v_len = b.v_len,
        };
    }

    fn add(a: Corner, b: Corner) Corner {
        var v: Varying2 = undefined;
        for (0..a.v_len) |i| {
            v[i] = Vec4.add(a.v[i], b.v[i]);
        }
        return Corner{
            .x = a.x + b.x,
            .z = a.z + b.z,
            .ow = a.ow + b.ow,
            .v = v,
            .v_len = a.v_len,
        };
    }

    fn sub(a: Corner, b: Corner) Corner {
        var v: Varying2 = undefined;
        for (0..a.v_len) |i| {
            v[i] = Vec4.sub(a.v[i], b.v[i]);
        }
        return Corner{
            .x = a.x - b.x,
            .z = a.z - b.z,
            .ow = a.ow - b.ow,
            .v = v,
            .v_len = a.v_len,
        };
    }

    fn mul(a: Corner, b: f32) Corner {
        var v: Varying2 = undefined;
        for (0..a.v_len) |i| {
            v[i] = Vec4.mul(a.v[i], b);
        }
        return Corner{
            .x = a.x * b,
            .z = a.z * b,
            .ow = a.ow * b,
            .v = v,
            .v_len = a.v_len,
        };
    }
};

const Trapezoid = struct {
    top: f32,
    bottom: f32,
    top_left: Corner,
    top_right: Corner,
    bottom_left: Corner,
    bottom_right: Corner,
};

pub fn drawTriangle_2(
    framebuffer: FrameBuffer,
    triangle: Triangle,
    pipeline: Pipeline,
    varyings: Varyings,
    uniforms: anytype,
) void {
    var a: [3]Vec4 = undefined;
    var ow: [3]f32 = undefined;
    var v: [3]Varying2 = undefined;
    if (pipeline.varyings_len > kMaxVaryings) {
        return;
    }
    for (0..3) |i| {
        // divide by w to convert to NDC
        ow[i] = 1.0 / triangle.v[i].w;
        a[i] = triangle.v[i].mul(ow[i]);
        // offset and mult by screen size
        a[i].x = (a[i].x + 1.0) * 0.5 * @as(f32, @floatFromInt(framebuffer.width()));
        a[i].y = (a[i].y + 1.0) * 0.5 * @as(f32, @floatFromInt(framebuffer.height()));
        // divide varyings by w
        for (0..pipeline.varyings_len) |j| {
            v[i][j] = varyings.v[i][j].mul(ow[i]);
        }
    }
    if (a[0].y == a[1].y and a[1].y == a[2].y) {
        return;
    }
    // sort by height
    if (a[1].y < a[0].y) {
        a[0], a[1] = swap(Vec4, a[0], a[1]);
        ow[0], ow[1] = swap(f32, ow[0], ow[1]);
        v[0], v[1] = swap(Varying2, v[0], v[1]);
    }
    if (a[2].y < a[1].y) {
        a[1], a[2] = swap(Vec4, a[1], a[2]);
        ow[1], ow[2] = swap(f32, ow[1], ow[2]);
        v[1], v[2] = swap(Varying2, v[1], v[2]);
    }
    if (a[1].y < a[0].y) {
        a[0], a[1] = swap(Vec4, a[0], a[1]);
        ow[0], ow[1] = swap(f32, ow[0], ow[1]);
        v[0], v[1] = swap(Varying2, v[0], v[1]);
    }
    // divide into two
    //      0
    //      |\
    //      | \
    // left |-- 1
    //      | /
    //      |/
    //      2
    var c: [3]Corner = undefined;
    for (0..3) |i| {
        c[i] = Corner{
            .x = a[i].x,
            .z = a[i].z,
            .ow = ow[i],
            .v = v[i],
            .v_len = pipeline.varyings_len,
        };
    }

    const alpha = unlerp(a[1].y, a[0].y, a[2].y);
    var left = Corner{
        .x = lerpf32(alpha, a[0].x, a[2].x),
        .z = lerpf32(alpha, a[0].z, a[2].z),
        .ow = lerpf32(alpha, ow[0], ow[2]),
        .v = lerpVarying(alpha, v[0], v[2]),
        .v_len = pipeline.varyings_len,
    };
    if (left.x > c[1].x) {
        left, c[1] = swap(Corner, left, c[1]);
    }
    const top = Trapezoid{
        .top = a[0].y,
        .bottom = a[1].y,
        .top_left = c[0],
        .top_right = c[0],
        .bottom_left = left,
        .bottom_right = c[1],
    };
    drawTrapezoid(framebuffer, top, pipeline, uniforms);
    const bottom = Trapezoid{
        .top = a[1].y,
        .bottom = a[2].y,
        .top_left = left,
        .top_right = c[1],
        .bottom_left = c[2],
        .bottom_right = c[2],
    };
    drawTrapezoid(framebuffer, bottom, pipeline, uniforms);
}

pub fn drawTrapezoid(framebuffer: FrameBuffer, trapezoid: Trapezoid, pipeline: Pipeline, uniforms: anytype) void {
    const screen_bottom = @as(f32, @floatFromInt(framebuffer.height()));
    const top = @min(@max(@round(trapezoid.top) + 0.5, 0.5), screen_bottom - 0.5);
    const bottom = @min(@max(@round(trapezoid.bottom) - 0.5, 0.5), screen_bottom - 0.5);
    const count = bottom - top;
    if (count <= 0) {
        return;
    }

    const top_alpha = unlerp(top, trapezoid.top, trapezoid.bottom);
    // adjust the tops of the edges by top_alpha
    const top_left = Corner.lerp(top_alpha, trapezoid.top_left, trapezoid.bottom_left);
    const top_right = Corner.lerp(top_alpha, trapezoid.top_right, trapezoid.bottom_right);

    const bottom_alpha = unlerp(bottom, trapezoid.top, trapezoid.bottom);
    // adjust the bottoms of the edges by bottom alpha
    const bottom_left = Corner.lerp(bottom_alpha, trapezoid.top_left, trapezoid.bottom_left);
    const bottom_right = Corner.lerp(bottom_alpha, trapezoid.top_right, trapezoid.bottom_right);

    const delta_left = bottom_left.sub(top_left).mul(1 / count);
    const delta_right = bottom_right.sub(top_right).mul(1 / count);

    var left = [2]Corner{ top_left, top_left.add(delta_left) };
    var right = [2]Corner{ top_right, top_right.add(delta_right) };
    const counti: usize = @intFromFloat(count);
    var i: usize = 0;
    while (i < counti) {
        const y: f32 = top + @as(f32, @floatFromInt(i));
        draw2HLine(framebuffer, y, left, right, pipeline, uniforms, i + 1 < counti);
        left[0] = left[1].add(delta_left);
        right[0] = right[1].add(delta_right);
        left[1] = left[0].add(delta_left);
        right[1] = right[0].add(delta_right);
        i += 2;
    }
}

pub fn draw2HLine(
    framebuffer: FrameBuffer,
    y: f32,
    left: [2]Corner,
    right: [2]Corner,
    pipeline: Pipeline,
    uniforms: anytype,
    bottom_line_in: bool,
) void {
    const screen_right = @as(f32, @floatFromInt(framebuffer.width()));
    var left_adj: [2]Corner = undefined;
    var delta: [2]Corner = undefined;
    var left_x: [2]f32 = undefined;
    var right_x: [2]f32 = undefined;
    for (0..2) |i| {
        left_x[i] = @max(@round(left[i].x) + 0.5, 0.5);
        right_x[i] = @min(@round(right[i].x) - 0.5, screen_right - 0.5);
    }
    const min_x = @min(left_x[0], left_x[1]);
    const max_x = @max(right_x[0], right_x[1]);
    if (min_x > max_x) {
        return;
    }
    for (0..2) |i| {
        const count = max_x - min_x;
        const left_alpha = unlerp(min_x, left[i].x, right[i].x);
        const right_alpha = unlerp(max_x, left[i].x, right[i].x);
        left_adj[i] = Corner.lerp(left_alpha, left[i], right[i]);
        const right_adj = Corner.lerp(right_alpha, left[i], right[i]);
        delta[i] = right_adj.sub(left_adj[i]).mul(1 / count);
    }
    const yi: usize = @intFromFloat(y);
    var v: [2][2]Corner = undefined;
    v[0][0] = left_adj[0];
    v[0][1] = left_adj[0].add(delta[0]);
    v[1][0] = left_adj[1];
    v[1][1] = left_adj[1].add(delta[1]);
    var xi: usize = @intFromFloat(min_x);
    const max_xi: usize = @intFromFloat(max_x);
    while (xi <= max_xi) {
        var grad_x: Varying2 = undefined;
        var grad_y: Varying2 = undefined;
        {
            const w_int00 = 1.0 / (v[0][0].ow + 0.000001);
            const w_int01 = 1.0 / (v[0][1].ow + 0.000001);
            const w_int10 = 1.0 / (v[1][0].ow + 0.000001);
            for (0..grad_x.len) |ii| {
                const v00 = v[0][0].v[ii].mul(w_int00);
                grad_x[ii] = v[0][1].v[ii].mul(w_int01).sub(v00);
                grad_y[ii] = v[1][0].v[ii].mul(w_int10).sub(v00);
            }
        }
        for (0..2) |i| {
            for (0..2) |j| {
                if ((i == 0 or bottom_line_in) and
                    xi + j >= @as(usize, @intFromFloat(left_x[i])) and xi + j <= @as(usize, @intFromFloat(right_x[i])))
                {
                    const depth = v[i][j].z;
                    if (depth < framebuffer.getDepth(xi + j, yi + i)) {
                        framebuffer.setDepth(xi + j, yi + i, depth);
                        var vv = v[i][j].v;
                        // divide by (1/w) to get perpective correct interpolation
                        const w_int = 1.0 / (v[i][j].ow + 0.000001);
                        for (0..vv.len) |ii| {
                            vv[ii] = vv[ii].mul(w_int);
                        }
                        const color_v4 = pipeline.fragmentShade(&vv, uniforms, &grad_x, &grad_y);
                        const color = Color.fromVec4(color_v4);
                        framebuffer.setPixel(xi + j, yi + i, color);
                    }
                }
            }
            v[i][0] = v[i][1].add(delta[i]);
            v[i][1] = v[i][0].add(delta[i]);
        }
        xi += 2;
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

test "mat4 mul itentity" {
    const a = Mat4.init();
    const b = Mat4.init();
    try std.testing.expect(Mat4.equal(a, b));
    const c = Mat4.mul(a, b);
    try std.testing.expect(Mat4.equal(a, c));
}
