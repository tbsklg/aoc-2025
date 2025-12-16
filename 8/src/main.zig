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
    const points = try parse_points(allocator, input);
    defer allocator.free(points);

    const distances = try calc_distances(allocator, points);
    defer allocator.free(distances);

    for (0..1000) |i| {
        distances[i].start.merge(distances[i].end);
    }

    var circuits = std.AutoHashMap(*Point, usize).init(allocator);
    defer circuits.deinit();

    for (points) |*p| {
        const root = p.findRoot();

        if (circuits.get(root)) |v| {
            try circuits.put(root, v + 1);
        } else {
            try circuits.put(root, 1);
        }
    }

    var values = std.ArrayList(usize){};
    defer values.deinit(allocator);

    var iter = circuits.iterator();
    while (iter.next()) |entry| {
        try values.append(allocator, entry.value_ptr.*);
    }

    std.mem.sort(usize, values.items, {}, comptime std.sort.desc(usize));

    const top3_count = @min(3, values.items.len);

    var result: usize = 1;
    for (values.items[0..top3_count]) |value| {
        result *= value;
    }

    return result;
}

fn calc_distances(allocator: std.mem.Allocator, points: []Point) ![]Distance {
    var distances = std.ArrayList(Distance){};
    defer distances.deinit(allocator);
    for (points, 0..) |*start_point, i| {
        for (points, 0..) |*end_point, j| {
            if (j > i) {
                const distance = start_point.distance(end_point);
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

fn parse_points(allocator: std.mem.Allocator, input: []const u8) ![]Point {
    var points = std.ArrayList(Point){};
    defer points.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try points.append(allocator, try Point.from(line));
    }
    return points.toOwnedSlice(allocator);
}

const Distance = struct {
    start: *Point,
    end: *Point,
    distance: f64,
};

const Point = struct {
    x: usize,
    y: usize,
    z: usize,
    parent: ?*Point,

    pub fn from(input: []const u8) !Point {
        var iter = std.mem.splitScalar(u8, input, ',');
        const x = try std.fmt.parseInt(usize, iter.next().?, 10);
        const y = try std.fmt.parseInt(usize, iter.next().?, 10);
        const z = try std.fmt.parseInt(usize, iter.next().?, 10);
        return .{
            .x = x,
            .y = y,
            .z = z,
            .parent = null,
        };
    }

    pub fn distance(self: *const Point, other: *const Point) f64 {
        const dx = @as(f64, @floatFromInt(self.x)) - @as(f64, @floatFromInt(other.x));
        const dy = @as(f64, @floatFromInt(self.y)) - @as(f64, @floatFromInt(other.y));
        const dz = @as(f64, @floatFromInt(self.z)) - @as(f64, @floatFromInt(other.z));
        return @sqrt(dx * dx + dy * dy + dz * dz);
    }

    pub fn findRoot(self: *Point) *Point {
        if (self.parent) |parent| {
            self.parent = parent.findRoot();
            return self.parent.?;
        }
        return self;
    }

    pub fn merge(self: *Point, other: *Point) void {
        const root1 = self.findRoot();
        const root2 = other.findRoot();

        if (root1 == root2) {
            return;
        }

        root2.parent = root1;
    }

    pub fn equals(self: *Point, other: *Point) bool {
        return self.x == other.x and self.y == other.y and self.z == other.z;
    }
};

test "Parse point" {
    const p1 = try Point.from("1,2,3");

    try std.testing.expectEqual(null, p1.parent);
}

test "Merge points" {
    var p1 = try Point.from("1,2,3");
    var p2 = try Point.from("3,4,5");

    try p1.merge(&p2);

    try std.testing.expect(p1.parent == null);
    try std.testing.expectEqual(p2.parent.?, &p1);
    try std.testing.expectEqual(p1.parent, null);
}

test "Merge existing point" {
    var p1 = try Point.from("1,2,3");
    var p2 = try Point.from("3,4,5");

    try p1.merge(&p2);
    try p2.merge(&p2);

    try std.testing.expect(p1.parent == null);
    try std.testing.expectEqual(p2.parent.?, &p1);
    try std.testing.expectEqual(p1.parent, null);
}

test "Merge existing point on higher level" {
    var p1 = try Point.from("1,2,3");
    var p2 = try Point.from("3,4,5");
    var p3 = try Point.from("1,2,3");

    try p1.merge(&p2);
    try p2.merge(&p3);

    try std.testing.expect(p3.parent == null);
}

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
