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

    const sol_1 = try part_1(allocator, trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});

    const sol_2 = try part_2(allocator, trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
}

fn part_1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var parts = std.mem.splitSequence(u8, input, "\n\n");

    const intervals = try parse_and_merge_intervals(allocator, parts.next().?);
    defer allocator.free(intervals);

    var values = std.mem.splitScalar(u8, parts.next().?, '\n');

    var valid_count: usize = 0;
    while (values.next()) |v| {
        const value = try std.fmt.parseInt(usize, v, 10);

        for (intervals) |it| {
            if (it.contains(value)) {
                valid_count += 1;
                break;
            }
        }
    }

    return valid_count;
}

fn part_2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var parts = std.mem.splitSequence(u8, input, "\n\n");

    const intervals = try parse_and_merge_intervals(allocator, parts.next().?);
    defer allocator.free(intervals);

    var total_covered: usize = 0;
    for (intervals) |it| {
        total_covered += it.to - it.from + 1;
    }

    return total_covered;
}

fn parse_and_merge_intervals(allocator: std.mem.Allocator, input: []const u8) ![]Interval {
    var intervals = std.ArrayList(Interval){};
    defer intervals.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var new_it = try Interval.parse(line);

        var keep_merging = true;
        while (keep_merging) {
            keep_merging = false;

            var i: usize = 0;
            while (i < intervals.items.len) {
                if (new_it.try_merge(intervals.items[i])) |_| {
                    _ = intervals.swapRemove(i);
                    keep_merging = true;
                    break;
                }
                i += 1;
            }
        }
        try intervals.append(allocator, new_it);
    }
    return intervals.toOwnedSlice(allocator);
}

const Interval = struct {
    from: usize,
    to: usize,

    fn parse(input: []const u8) !Interval {
        var range = std.mem.splitScalar(u8, input, '-');
        const from = try std.fmt.parseInt(usize, range.next().?, 10);
        const to = try std.fmt.parseInt(usize, range.next().?, 10);

        return .{
            .from = from,
            .to = to,
        };
    }

    fn try_merge(self: *Interval, other: Interval) ?Interval {
        if (other.to < self.from or other.from > self.to) {
            return null;
        }

        self.from = @min(self.from, other.from);
        self.to = @max(self.to, other.to);
        return self.*;
    }

    fn contains(self: *const Interval, value: usize) bool {
        return self.from <= value and self.to >= value;
    }
};

test "Intervals overlap at the bottom" {
    var i1 = try Interval.parse("10-20");
    const i2 = try Interval.parse("5-15");

    _ = i1.try_merge(i2);

    try std.testing.expectEqual(5, i1.from);
    try std.testing.expectEqual(20, i1.to);
}

test "Intervals overlap at the top" {
    var i1 = try Interval.parse("10-20");
    const i2 = try Interval.parse("15-25");

    _ = i1.try_merge(i2);

    try std.testing.expectEqual(10, i1.from);
    try std.testing.expectEqual(25, i1.to);
}

test "Intervals do not overlap" {
    var i1 = try Interval.parse("10-20");
    const i2 = try Interval.parse("21-25");

    try std.testing.expectEqual(null, i1.try_merge(i2));
}

test "Interval contains value" {
    const i1 = try Interval.parse("10-20");

    try std.testing.expectEqual(true, i1.contains(11));
    try std.testing.expectEqual(true, i1.contains(20));
    try std.testing.expectEqual(false, i1.contains(21));
    try std.testing.expectEqual(false, i1.contains(9));
}
