const std = @import("std");
const Io = std.Io;

const zigrast = @import("zigrast");

fn fs(varying: zigrast.Varying, uniforms: anytype) zigrast.Vec4 {
    _ = uniforms;
    return varying[0];
}

pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

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

    const a = zigrast.Vec4{ .x = 10, .y = 10, .z = 0, .w = 1 };
    const b = zigrast.Vec4{ .x = 300, .y = 120, .z = 0, .w = 1 };
    const c = zigrast.Vec4{ .x = 60, .y = 230, .z = 0, .w = 1 };
    // const color = zigrast.Color{ .r = 0xff, .g = 0, .b = 0, .a = 0xff };
    // const uniforms = zigrast.Uniforms{ .color = color };
    var varying_storage: [3]zigrast.Vec4 = undefined;
    const varyings: zigrast.Varyings = .init(1, &varying_storage);
    varyings.v[0][0] = zigrast.Vec4{ .x = 1.0, .y = 0.0, .z = 0.0, .w = 1 };
    varyings.v[1][0] = zigrast.Vec4{ .x = 0.0, .y = 1.0, .z = 0.0, .w = 1 };
    varyings.v[2][0] = zigrast.Vec4{ .x = 0.0, .y = 0.0, .z = 1.0, .w = 1 };

    const v = [3]zigrast.Vec4{ a, b, c };
    const triangle = zigrast.Triangle{
        .v = v,
    };
    zigrast.drawTriangle(image, triangle, 1, varyings, .{}, fs);

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
    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try zigrast.printAnotherMessage(stdout_writer);

    try stdout_writer.flush(); // Don't forget to flush!
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
