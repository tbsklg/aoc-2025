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

    try part_1(allocator, trimmed);
}

fn part_1(allocator: std.mem.Allocator, input: []const u8) !void {
    const points = try parse_points(allocator, input);
    defer allocator.free(points);

    const distances = try calc_distances(allocator, points);
    defer allocator.free(distances);
}

fn calc_distances(allocator: std.mem.Allocator, points: []const Point) ![]Distance {
    var distances = std.ArrayList(Distance){};
    defer distances.deinit(allocator);

    for (points, 0..) |start_point, i| {
        for (points, 0..) |end_point, j| {
            if (j > i) {
                const distance = start_point.distance(&end_point);
                try distances.append(allocator, .{ .start = start_point, .end = end_point, .distance = distance });
            }
        }
    }

    std.mem.sort(Distance, distances.items, {}, compareByDistance);
    return distances.toOwnedSlice(allocator);
}

fn compareByDistance(context: void, a: Distance, b: Distance) bool {
    _ = context;
    return a.distance < b.distance;
}

fn parse_points(allocator: std.mem.Allocator, input: []const u8) ![]const Point {
    var points = std.ArrayList(Point){};
    defer points.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        try points.append(allocator, try Point.from(line));
    }

    return points.toOwnedSlice(allocator);
}

const Distance = struct {
    start: Point,
    end: Point,
    distance: f64,
};

const Point = struct {
    x: usize,
    y: usize,
    z: usize,

    pub fn from(input: []const u8) !Point {
        var iter = std.mem.splitScalar(u8, input, ',');

        const x = try std.fmt.parseInt(usize, iter.next().?, 10);
        const y = try std.fmt.parseInt(usize, iter.next().?, 10);
        const z = try std.fmt.parseInt(usize, iter.next().?, 10);

        return .{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn distance(self: *const Point, other: *const Point) f64 {
        const dx = @as(f64, @floatFromInt(self.x)) - @as(f64, @floatFromInt(other.x));
        const dy = @as(f64, @floatFromInt(self.y)) - @as(f64, @floatFromInt(other.y));
        const dz = @as(f64, @floatFromInt(self.z)) - @as(f64, @floatFromInt(other.z));

        return @sqrt(dx * dx + dy * dy + dz * dz);
    }

    pub fn equals(self: *const Point, other: *const Point) bool {
        return self.x == other.x and self.y == other.y and self.z == other.z;
    }
};

test "Calculate distance between two points" {
    const p1 = try Point.from("1,2,3");
    const p2 = try Point.from("4,5,6");

    const d1 = p1.distance(&p2);
    try std.testing.expectEqual(5.196152422706632, d1);

    const d2 = p2.distance(&p1);
    try std.testing.expectEqual(5.196152422706632, d2);
}

test "Parse points" {
    const allocator = std.testing.allocator;
    const input = "123,456,789\n987,654,321";

    const points = try parse_points(allocator, input);
    defer allocator.free(points);

    try std.testing.expectEqual(2, points.len);
}

test "Connect points" {
    const allocator = std.testing.allocator;
    const input = "123,456,789\n987,654,321";

    const points = try parse_points(allocator, input);
    defer allocator.free(points);

    var conns = try calc_distances(allocator, points);
    defer conns.deinit();

    defer {
        var outer_iter = conns.iterator();
        while (outer_iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
    }

    try std.testing.expectEqual(2, conns.count());

    const p1: Point = .{ .x = 123, .y = 456, .z = 789 };
    const p2: Point = .{ .x = 987, .y = 654, .z = 321 };

    const p1_conns = conns.get(p1).?;
    try std.testing.expect(p1_conns.contains(p2));
    try std.testing.expect(!p1_conns.contains(p1));

    const p2_conns = conns.get(p2).?;
    try std.testing.expect(p2_conns.contains(p1));
    try std.testing.expect(!p2_conns.contains(p2));
}
