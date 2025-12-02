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

    const sol_1 = try part_1(file_contents);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});
}

fn part_1(input: []u8) !usize {
    const trimmed = std.mem.trim(u8, input, " \t\r\n");
    var lines = std.mem.splitScalar(u8, trimmed, ',');

    var invalid: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        const range = try Range.from_line(line);

        for (range.from..range.to + 1) |id| {
            invalid += parse_id(id) orelse 0;
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

fn parse_id(id: usize) ?usize {
    var buffer: [4096]u8 = undefined;
    const result = std.fmt.bufPrintZ(buffer[0..], "{d}", .{id}) catch unreachable;
    const id_str = @as([]const u8, result);

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

test "Parse invalid Id" {
    try std.testing.expectEqual(parse_id("11"), null);
    try std.testing.expectEqual(parse_id("1188511885"), null);
    try std.testing.expectEqual(parse_id("222222"), null);
    try std.testing.expectEqual(parse_id("38593859"), null);
}

test "Parse valid Id" {
    try std.testing.expectEqual(parse_id("111"), "111");
}
