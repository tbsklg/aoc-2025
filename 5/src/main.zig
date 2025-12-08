const std = @import("std");
const _5 = @import("_5");

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
}

fn part_1(input: []const u8) !usize {
    var parts = std.mem.splitSequence(u8, input, "\n\n");
    const ranges = parts.next().?;
    const ingredients = parts.next().?;

    std.log.debug("ranges: {s}", .{ranges});
    std.log.debug("ingredents: {s}", .{ingredients});
    return 0;
}

fn fold_ranges(input: []const u8) []Range {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var ranges = std.ArrayList([]u8){};
    defer ranges.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const range = try Range.from(line);
        ranges.append(allocator, range);
    }
}

const Range = struct {
    from: u32,
    to: u32,

    fn create(input: []const u8) !Range {
        var range = std.mem.splitScalar(u8, input, '-');
        const from = try std.fmt.parseInt(usize, range.next().?, 10);
        const to = try std.fmt.parseInt(usize, range.next().?, 10);

        return .{
            .from = @intCast(from),
            .to = @intCast(to),
        };
    }

    fn try_merge(self: *Range, range: Range) !Range {
        if (range.to < self.from or range.from > self.to) {
            return error.NoOverlap;
        }

        self.from = @min(self.from, range.from);
        self.to = @max(self.to, range.to);
        return self.*;
    }
};

test "Ranges overlap at the bottom" {
    var r1 = try Range.create("10-20");
    const r2 = try Range.create("5-15");

    _ = try r1.try_merge(r2);

    try std.testing.expectEqual(r1.from, 5);
    try std.testing.expectEqual(r1.to, 20);
}

test "Ranges overlap at the top" {
    var r1 = try Range.create("10-20");
    const r2 = try Range.create("15-25");

    _ = try r1.try_merge(r2);

    try std.testing.expectEqual(r1.from, 10);
    try std.testing.expectEqual(r1.to, 25);
}

test "Ranges do not overlap" {
    var r1 = try Range.create("10-20");
    const r2 = try Range.create("21-25");

    try std.testing.expectError(error.NoOverlap, r1.try_merge(r2));
}
