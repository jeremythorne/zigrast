const std = @import("std");
const Io = std.Io;

const zigrast = @import("zigrast");

const Attribute = struct {
    pos: zigrast.Vec4,
    color: zigrast.Vec4,
};

const Uniforms = struct {
    offset: zigrast.Vec4,
    proj: zigrast.Mat4,
};

fn vs(attribute: Attribute, uniforms: anytype, out: zigrast.Varying) zigrast.Vec4 {
    out[0] = attribute.color;
    return uniforms.proj.mulv4(attribute.pos.add(uniforms.offset));
}

fn fs(varying: zigrast.Varying, uniforms: anytype) zigrast.Vec4 {
    _ = uniforms;
    return varying[0];
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
        .varyings_len = 1,
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

    const red = zigrast.Vec4{ .x = 1.0, .y = 0.0, .z = 0.0, .w = 1.0 };
    const green = zigrast.Vec4{ .x = 0.0, .y = 1.0, .z = 0.0, .w = 1.0 };
    const blue = zigrast.Vec4{ .x = 0.0, .y = 0.0, .z = 1.0, .w = 1.0 };

    const attributes = [_]Attribute{
        // bottom
        Attribute{ .pos = a, .color = green },
        Attribute{ .pos = b, .color = green },
        Attribute{ .pos = c, .color = red },
        Attribute{ .pos = c, .color = red },
        Attribute{ .pos = b, .color = green },
        Attribute{ .pos = d, .color = red },
        // left
        Attribute{ .pos = a, .color = green },
        Attribute{ .pos = c, .color = green },
        Attribute{ .pos = e, .color = green },
        Attribute{ .pos = e, .color = green },
        Attribute{ .pos = c, .color = green },
        Attribute{ .pos = g, .color = green },
        // front
        Attribute{ .pos = c, .color = blue },
        Attribute{ .pos = d, .color = blue },
        Attribute{ .pos = g, .color = blue },
        Attribute{ .pos = g, .color = blue },
        Attribute{ .pos = d, .color = blue },
        Attribute{ .pos = h, .color = blue },
        // right
        Attribute{ .pos = d, .color = red },
        Attribute{ .pos = b, .color = green },
        Attribute{ .pos = h, .color = red },
        Attribute{ .pos = h, .color = red },
        Attribute{ .pos = b, .color = green },
        Attribute{ .pos = f, .color = green },
        // back
        Attribute{ .pos = b, .color = green },
        Attribute{ .pos = a, .color = green },
        Attribute{ .pos = f, .color = green },
        Attribute{ .pos = f, .color = green },
        Attribute{ .pos = a, .color = green },
        Attribute{ .pos = e, .color = green },
        // top
        Attribute{ .pos = g, .color = blue },
        Attribute{ .pos = h, .color = blue },
        Attribute{ .pos = e, .color = green },
        Attribute{ .pos = e, .color = green },
        Attribute{ .pos = h, .color = blue },
        Attribute{ .pos = f, .color = green },
    };

    var uniforms = Uniforms{
        .offset = zigrast.Vec4{ .x = -1.0, .y = -1.0, .z = -2.0, .w = 0.0 },
        .proj = .init_projection(1.0, 240.0 / 320.0, 0.5, 50.0),
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
