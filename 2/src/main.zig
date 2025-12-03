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

    const trimmed = std.mem.trim(u8, file_contents, " \t\r\n");

    const sol_1 = try part_1(trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});

    const sol_2 = try part_2(trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
}

fn part_1(input: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, input, ',');

    var invalid: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        const range = try Range.from_line(line);

        for (range.from..range.to + 1) |id| {
            invalid += parse_invalid_id(id) orelse 0;
        }
    }

    return invalid;
}

fn part_2(input: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, input, ',');

    var invalid: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        const range = try Range.from_line(line);

        for (range.from..range.to + 1) |id| {
            invalid += parse_invalid_id_2(id) orelse 0;
        }
    }

    return invalid;
}

const Range = struct {
    from: usize,
    to: usize,

    fn from_line(line: []const u8) !Range {
        var range = std.mem.splitScalar(u8, line, '-');
        const from = try std.fmt.parseInt(usize, range.next().?, 10);
        const to = try std.fmt.parseInt(usize, range.next().?, 10);

        return .{
            .from = from,
            .to = to,
        };
    }
};

fn parse_invalid_id(id: usize) ?usize {
    const id_str = as_u8(id);

    if (id_str.len % 2 != 0) {
        return null;
    }

    const lh = id_str[0 .. id_str.len / 2];
    const rh = id_str[id_str.len / 2 .. id_str.len];

    if (std.mem.eql(u8, lh, rh)) {
        return id;
    }

    return null;
}

fn parse_invalid_id_2(id: usize) ?usize {
    const id_str = as_u8(id);

    if (id_str.len == 1) {
        return null;
    }

    var has_pattern = true;
    for (0..id_str.len / 2 + 1) |i| {
        var it = std.mem.window(u8, id_str, i + 1, i + 1);

        const base = it.next().?;
        while (it.next()) |x| {
            if (!std.mem.eql(u8, base, x)) {
                has_pattern = false;
                break;
            }
            has_pattern = true;
        }

        if (has_pattern) {
            break;
        }
    }

    if (has_pattern) {
        return id;
    }

    return null;
}

fn as_u8(x: usize) []const u8 {
    var buffer: [4096]u8 = undefined;
    const result = std.fmt.bufPrintZ(buffer[0..], "{d}", .{x}) catch unreachable;
    return @as([]const u8, result);
}

test "Parse invalid Id" {
    try std.testing.expectEqual(parse_invalid_id(11), 11);
    try std.testing.expectEqual(parse_invalid_id(1188511885), 1188511885);
    try std.testing.expectEqual(parse_invalid_id(222222), 222222);
    try std.testing.expectEqual(parse_invalid_id(38593859), 38593859);
    try std.testing.expectEqual(parse_invalid_id(111), null);
}

test "Parse invalid Id extended" {
    try std.testing.expectEqual(parse_invalid_id_2(2121212121), 2121212121);
    try std.testing.expectEqual(parse_invalid_id_2(222222), 222222);
    try std.testing.expectEqual(parse_invalid_id_2(11), 11);
    try std.testing.expectEqual(parse_invalid_id_2(123123123), 123123123);
    try std.testing.expectEqual(parse_invalid_id_2(1111111), 1111111);
    try std.testing.expectEqual(parse_invalid_id_2(12), null);
}
