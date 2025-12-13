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

    const sol_2 = try part_2(allocator, trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
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

fn part_2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const start = std.mem.indexOf(u8, input, "S").?;

    var memo = std.AutoHashMap([2]usize, usize).init(allocator);
    defer memo.deinit();

    return try count_paths(allocator, input, start, 0, &memo);
}

fn count_paths(allocator: std.mem.Allocator, lines: []const u8, pos: usize, line: usize, memo: *std.AutoHashMap([2]usize, usize)) !usize {
    const new_line = std.mem.indexOf(u8, lines, "\n");

    if (memo.get(.{ pos, line })) |cached| {
        return cached;
    }

    if (new_line == null) {
        return 1;
    } else {
        const result: usize = cnt: {
            if (lines[pos] == '^') {
                const left = pos - 1;
                const right = pos + 1;

                break :cnt try count_paths(allocator, lines[new_line.? + 1 ..], left, line + 1, memo) +
                    try count_paths(allocator, lines[new_line.? + 1 ..], right, line + 1, memo);
            }
            break :cnt try count_paths(allocator, lines[new_line.? + 1 ..], pos, line + 1, memo);
        };

        try memo.put(.{ pos, line }, result);
        return result;
    }
}
