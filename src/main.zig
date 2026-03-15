const std = @import("std");
const Io = std.Io;

const zigrast = @import("zigrast");

const Attribute = struct {
    pos: zigrast.Vec4,
    uv: zigrast.Vec2,
};

const Uniforms = struct {
    offset: zigrast.Vec4,
    proj: zigrast.Mat4,
    tex: zigrast.Image,
};

fn vs(attribute: Attribute, uniforms: anytype, out: zigrast.Varying) zigrast.Vec4 {
    out[0] = zigrast.Vec4{ .x = 1.0, .y = 1.0, .z = 1.0, .w = 1.0 };
    out[1] = zigrast.Vec4{ .x = attribute.uv.x, .y = attribute.uv.y, .z = 0, .w = 0 };
    return uniforms.proj.mulv4(attribute.pos.add(uniforms.offset));
}

fn fs(varying: zigrast.Varying, uniforms: anytype) zigrast.Vec4 {
    const s = uniforms.tex.sampleNearest(varying[1].x, varying[1].y);
    return varying[0].mulV4(s);
}

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    const image = try zigrast.Image.init(arena, 320, 240);
    defer image.deinit(arena);
    const depth = try zigrast.DepthBuffer.init(arena, 320, 240);
    const frameBuffer = zigrast.FrameBuffer{
        .image = image,
        .depthBuffer = depth,
    };

    const pipeline = zigrast.Pipeline{
        .vertexShade = vs,
        .fragmentShade = fs,
        .varyings_len = 2,
        .attributes_type = Attribute,
    };

    // a cube
    //
    //  g-----------h
    //  |  e --- f  |
    //  |  a --- b  |
    //  | /       \ |
    //  |/         \|
    //  c---------- d
    const a = zigrast.Vec4{ .x = -0.5, .y = -0.5, .z = -0.5, .w = 1.0 };
    const b = zigrast.Vec4{ .x = 0.5, .y = -0.5, .z = -0.5, .w = 1.0 };
    const c = zigrast.Vec4{ .x = -0.5, .y = -0.5, .z = 0.5, .w = 1.0 };
    const d = zigrast.Vec4{ .x = 0.5, .y = -0.5, .z = 0.5, .w = 1.0 };
    const e = zigrast.Vec4{ .x = -0.5, .y = 0.5, .z = -0.5, .w = 1.0 };
    const f = zigrast.Vec4{ .x = 0.5, .y = 0.5, .z = -0.5, .w = 1.0 };
    const g = zigrast.Vec4{ .x = -0.5, .y = 0.5, .z = 0.5, .w = 1.0 };
    const h = zigrast.Vec4{ .x = 0.5, .y = 0.5, .z = 0.5, .w = 1.0 };

    const one_one = zigrast.Vec2{ .x = 1.0, .y = 1.0 };
    const one_zero = zigrast.Vec2{ .x = 1.0, .y = 0.0 };
    const zero_one = zigrast.Vec2{ .x = 0.0, .y = 1.0 };
    const zero_zero = zigrast.Vec2{ .x = 0.0, .y = 0.0 };

    const attributes = [_]Attribute{
        // bottom
        Attribute{ .pos = a, .uv = zero_one },
        Attribute{ .pos = b, .uv = one_one },
        Attribute{ .pos = c, .uv = zero_zero },
        Attribute{ .pos = c, .uv = zero_zero },
        Attribute{ .pos = b, .uv = one_one },
        Attribute{ .pos = d, .uv = one_zero },
        // left
        Attribute{ .pos = a, .uv = zero_one },
        Attribute{ .pos = c, .uv = one_one },
        Attribute{ .pos = e, .uv = zero_zero },
        Attribute{ .pos = e, .uv = zero_zero },
        Attribute{ .pos = c, .uv = one_one },
        Attribute{ .pos = g, .uv = one_zero },
        // front
        Attribute{ .pos = c, .uv = zero_one },
        Attribute{ .pos = d, .uv = one_one },
        Attribute{ .pos = g, .uv = zero_zero },
        Attribute{ .pos = g, .uv = zero_zero },
        Attribute{ .pos = d, .uv = one_one },
        Attribute{ .pos = h, .uv = one_zero },
        // right
        Attribute{ .pos = d, .uv = zero_one },
        Attribute{ .pos = b, .uv = one_one },
        Attribute{ .pos = h, .uv = zero_zero },
        Attribute{ .pos = h, .uv = zero_zero },
        Attribute{ .pos = b, .uv = one_one },
        Attribute{ .pos = f, .uv = one_zero },
        // back
        Attribute{ .pos = b, .uv = zero_one },
        Attribute{ .pos = a, .uv = one_one },
        Attribute{ .pos = f, .uv = zero_zero },
        Attribute{ .pos = f, .uv = zero_zero },
        Attribute{ .pos = a, .uv = one_one },
        Attribute{ .pos = e, .uv = one_zero },
        // top
        Attribute{ .pos = g, .uv = zero_one },
        Attribute{ .pos = h, .uv = one_one },
        Attribute{ .pos = e, .uv = zero_zero },
        Attribute{ .pos = e, .uv = zero_zero },
        Attribute{ .pos = h, .uv = one_one },
        Attribute{ .pos = f, .uv = one_zero },
    };

    const texture = try zigrast.Image.init(arena, 2, 2);
    defer texture.deinit(arena);

    const black = zigrast.Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
    const white = zigrast.Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
    texture.setPixel(0, 0, black);
    texture.setPixel(1, 0, white);
    texture.setPixel(0, 1, white);
    texture.setPixel(1, 1, black);

    var uniforms = Uniforms{
        .offset = zigrast.Vec4{ .x = -1.0, .y = -1.0, .z = -2.0, .w = 0.0 },
        .proj = .init_projection(1.0, 240.0 / 320.0, 0.5, 50.0),
        .tex = texture,
    };

    // draw 4 cubes
    zigrast.drawTriangles(pipeline, &attributes, uniforms, frameBuffer);
    uniforms.offset.x = 1.0;
    zigrast.drawTriangles(pipeline, &attributes, uniforms, frameBuffer);
    uniforms.offset.y = 1.0;
    zigrast.drawTriangles(pipeline, &attributes, uniforms, frameBuffer);
    uniforms.offset.x = -1.0;
    zigrast.drawTriangles(pipeline, &attributes, uniforms, frameBuffer);

    const file = try Io.Dir.createFile(
        Io.Dir.cwd(),
        io,
        "out.tga",
        .{},
    );
    defer file.close(io);
    var buffer: [1024]u8 = undefined;
    var w: Io.File.Writer = .init(file, io, &buffer);
    try zigrast.writeToTga(&w.interface, image);
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
