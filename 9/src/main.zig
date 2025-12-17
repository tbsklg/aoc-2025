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
    const points = try extract_points(allocator, input);
    defer allocator.free(points);

    var largest_area: usize = 0;
    for (points, 0..) |l, i| {
        for (points[i..]) |r| {
            const area = @abs(l.x - r.x + 1) * @abs(l.y - r.y + 1);

            if (area > largest_area) {
                largest_area = area;
            }
        }
    }

    return largest_area;
}

fn extract_points(allocator: std.mem.Allocator, input: []const u8) ![]Point {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var points = std.ArrayList(Point){};
    defer points.deinit(allocator);

    while (lines.next()) |line| {
        const point = try Point.from(line);

        try points.append(allocator, point);
    }

    return points.toOwnedSlice(allocator);
}

const Point = struct {
    x: i64,
    y: i64,

    pub fn from(input: []const u8) !Point {
        var parts = std.mem.splitScalar(u8, input, ',');

        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);

        return .{ .x = x, .y = y };
    }
};
