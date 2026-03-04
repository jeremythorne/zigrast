const std = @import("std");
const Io = std.Io;

const zigrast = @import("zigrast");

const Attribute = struct {
    pos: zigrast.Vec4,
    color: zigrast.Vec4,
};

fn vs(attribute: Attribute, uniforms: anytype, out: zigrast.Varying) zigrast.Vec4 {
    _ = uniforms;
    out[0] = attribute.color;
    return attribute.pos;
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

    const pipeline = zigrast.Pipeline{
        .vertexShade = vs,
        .fragmentShade = fs,
        .varyings_len = 1,
        .attributes_type = Attribute,
    };
    const attributes = [3]Attribute{
        Attribute{
            .pos = zigrast.Vec4{ .x = 10, .y = 10, .z = 0, .w = 1 },
            .color = zigrast.Vec4{ .x = 1.0, .y = 0.0, .z = 0.0, .w = 1 },
        },
        Attribute{
            .pos = zigrast.Vec4{ .x = 300, .y = 120, .z = 0, .w = 1 },
            .color = zigrast.Vec4{ .x = 0.0, .y = 1.0, .z = 0.0, .w = 1 },
        },
        Attribute{
            .pos = zigrast.Vec4{ .x = 60, .y = 230, .z = 0, .w = 1 },
            .color = zigrast.Vec4{ .x = 0.0, .y = 0.0, .z = 1.0, .w = 1 },
        },
    };

    zigrast.drawTriangles(pipeline, &attributes, {}, image);

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
