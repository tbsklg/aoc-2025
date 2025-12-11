const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_contents = try std.fs.cwd().readFileAlloc(
        allocator,
        "input.txt",
        1024 * 1024,
    );
    defer allocator.free(file_contents);
    
    try part_1(allocator, file_contents);
}

fn part_1(_: std.mem.Allocator, input: []u8) !void {
    var lines_iter = std.mem.splitScalar(u8, input, '\n');

    while(lines_iter.next()) |line| {
        std.debug.print("{s}\n", .{line});
    }
}
