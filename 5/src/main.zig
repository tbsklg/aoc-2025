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

    const sol_2 = try part_2(trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
}

fn part_1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var parts = std.mem.splitSequence(u8, input, "\n\n");

    const ranges = try fold_ranges(allocator, parts.next().?);
    defer allocator.free(ranges);

    var ingredients = std.mem.splitScalar(u8, parts.next().?, '\n');

    var count: usize = 0;
    while (ingredients.next()) |i| {
        const ingredient = try std.fmt.parseInt(usize, i, 10);

        for (ranges) |r| {
            if (r.includes(ingredient)) {
                count += 1;
                break;
            }
        }
    }

    return count;
}

fn part_2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var parts = std.mem.splitSequence(u8, input, "\n\n");

    const ranges = try fold_ranges(allocator, parts.next().?);
    defer allocator.free(ranges);

    var count: usize = 0;
    for (ranges) |r| {
        count += r.to - r.from + 1;
    }

    return count;
}

fn fold_ranges(allocator: std.mem.Allocator, input: []const u8) ![]Range {
    var ranges = std.ArrayList(Range){};
    defer ranges.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var new_range = try Range.create(line);

        var keep_merging = true;
        while (keep_merging) {
            keep_merging = false;

            var i: usize = 0;
            while (i < ranges.items.len) {
                if (new_range.try_merge(ranges.items[i])) |_| {
                    _ = ranges.swapRemove(i);
                    keep_merging = true;
                    break;
                }
                i += 1;
            }
        }
        try ranges.append(allocator, new_range);
    }
    return ranges.toOwnedSlice(allocator);
}

const Range = struct {
    from: usize,
    to: usize,

    fn create(input: []const u8) !Range {
        var range = std.mem.splitScalar(u8, input, '-');
        const from = try std.fmt.parseInt(usize, range.next().?, 10);
        const to = try std.fmt.parseInt(usize, range.next().?, 10);

        return .{
            .from = @intCast(from),
            .to = @intCast(to),
        };
    }

    fn try_merge(self: *Range, range: Range) ?Range {
        if (range.to < self.from or range.from > self.to) {
            return null;
        }

        self.from = @min(self.from, range.from);
        self.to = @max(self.to, range.to);
        return self.*;
    }

    fn includes(self: *const Range, ingredient: usize) bool {
        return self.from <= ingredient and self.to >= ingredient;
    }
};

test "Ranges overlap at the bottom" {
    var r1 = try Range.create("10-20");
    const r2 = try Range.create("5-15");

    _ = r1.try_merge(r2);

    try std.testing.expectEqual(5, r1.from);
    try std.testing.expectEqual(20, r1.to);
}

test "Ranges overlap at the top" {
    var r1 = try Range.create("10-20");
    const r2 = try Range.create("15-25");

    _ = r1.try_merge(r2);

    try std.testing.expectEqual(10, r1.from);
    try std.testing.expectEqual(25, r1.to);
}

test "Ranges do not overlap" {
    var r1 = try Range.create("10-20");
    const r2 = try Range.create("21-25");

    try std.testing.expectEqual(null, r1.try_merge(r2));
}

test "Range has ingredient" {
    const r1 = try Range.create("10-20");

    try std.testing.expectEqual(true, r1.includes(11));
    try std.testing.expectEqual(true, r1.includes(20));
    try std.testing.expectEqual(false, r1.includes(21));
    try std.testing.expectEqual(false, r1.includes(9));
}
