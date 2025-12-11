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

    const trimmed = std.mem.trim(u8, file_contents, "\t\r\n");

    const sol_1 = try part_1(allocator, trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});
}

fn part_1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var lines_iter = std.mem.splitScalar(u8, input, '\n');
    const start = std.mem.indexOf(u8, lines_iter.first(), "S").?;

    var current = std.AutoHashMap(usize, void).init(allocator);
    defer current.deinit();
    var next = std.AutoHashMap(usize, void).init(allocator);
    defer next.deinit();

    try current.put(start, {});
    var split_count: usize = 0;

    while (lines_iter.next()) |line| {
        var iterator = current.iterator();
        while (iterator.next()) |x| {
            const index = x.key_ptr.*;
            const elem = line[index];
            if (elem == '^') {
                split_count += 1;
                try next.put(index - 1, {});
                try next.put(index + 1, {});
            } else {
                try next.put(index, {});
            }
        }

        current.clearRetainingCapacity();
        std.mem.swap(std.AutoHashMap(usize, void), &current, &next);
    }

    return split_count;
}
