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

fn part_2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const polygon = try extract_points(allocator, input);
    defer allocator.free(polygon);

    // Coordinate compression: collect all unique x and y coordinates
    var x_coords = std.ArrayList(isize){};
    defer x_coords.deinit(allocator);
    var y_coords = std.ArrayList(isize){};
    defer y_coords.deinit(allocator);

    for (polygon) |p| {
        try x_coords.append(allocator, p.x);
        try y_coords.append(allocator, p.y);
    }

    // Sort and deduplicate
    std.mem.sort(isize, x_coords.items, {}, comptime std.sort.asc(isize));
    std.mem.sort(isize, y_coords.items, {}, comptime std.sort.asc(isize));

    const unique_x = try deduplicateSorted(allocator, x_coords.items);
    defer allocator.free(unique_x);
    const unique_y = try deduplicateSorted(allocator, y_coords.items);
    defer allocator.free(unique_y);

    // Create compressed polygon
    var compressed_polygon = try allocator.alloc(Point, polygon.len);
    defer allocator.free(compressed_polygon);

    for (polygon, 0..) |p, i| {
        const cx = findIndex(unique_x, p.x);
        const cy = findIndex(unique_y, p.y);
        compressed_polygon[i] = Point{ .x = cx, .y = cy };
    }

    // Try all pairs of polygon vertices as opposite corners
    var max_area: usize = 0;

    for (0..polygon.len) |i| {
        for (i..polygon.len) |j| {
            if (i == j) continue;

            const p1 = compressed_polygon[i];
            const p2 = compressed_polygon[j];

            // Get rectangle bounds in compressed space
            const min_cx = @min(p1.x, p2.x);
            const max_cx = @max(p1.x, p2.x);
            const min_cy = @min(p1.y, p2.y);
            const max_cy = @max(p1.y, p2.y);

            // Check if all corners are inside/on polygon
            const corners = [_]Point{
                Point{ .x = min_cx, .y = min_cy },
                Point{ .x = max_cx, .y = min_cy },
                Point{ .x = min_cx, .y = max_cy },
                Point{ .x = max_cx, .y = max_cy },
            };

            var all_corners_valid = true;
            for (corners) |corner| {
                // Map back to original coordinates for polygon check
                const orig_corner = Point{ .x = unique_x[@intCast(corner.x)], .y = unique_y[@intCast(corner.y)] };
                if (!pointInPolygon(orig_corner, polygon) and !isOnPolygonEdge(orig_corner, polygon)) {
                    all_corners_valid = false;
                    break;
                }
            }

            if (!all_corners_valid) continue;

            // Sample all compressed coordinate pairs in rectangle
            var all_inside = true;
            var cx = min_cx;
            while (cx <= max_cx) : (cx += 1) {
                var cy = min_cy;
                while (cy <= max_cy) : (cy += 1) {
                    const orig_point = Point{ .x = unique_x[@intCast(cx)], .y = unique_y[@intCast(cy)] };
                    if (!pointInPolygon(orig_point, polygon) and !isOnPolygonEdge(orig_point, polygon)) {
                        all_inside = false;
                        break;
                    }
                }
                if (!all_inside) break;
            }

            if (all_inside) {
                // Calculate actual area using original coordinates
                const min_x = unique_x[@intCast(min_cx)];
                const max_x = unique_x[@intCast(max_cx)];
                const min_y = unique_y[@intCast(min_cy)];
                const max_y = unique_y[@intCast(max_cy)];

                const width = @abs(max_x - min_x) + 1;
                const height = @abs(max_y - min_y) + 1;
                const area = @as(usize, @intCast(width)) * @as(usize, @intCast(height));

                if (area > max_area) {
                    max_area = area;
                }
            }
        }
    }

    return max_area;
}

fn deduplicateSorted(allocator: std.mem.Allocator, sorted: []const isize) ![]isize {
    if (sorted.len == 0) return try allocator.alloc(isize, 0);

    var result = std.ArrayList(isize){};
    defer result.deinit(allocator);

    try result.append(allocator, sorted[0]);
    for (sorted[1..]) |val| {
        if (val != result.items[result.items.len - 1]) {
            try result.append(allocator, val);
        }
    }

    return result.toOwnedSlice(allocator);
}

fn findIndex(sorted: []const isize, value: isize) isize {
    for (sorted, 0..) |v, i| {
        if (v == value) return @intCast(i);
    }
    unreachable;
}

// ray casting
fn pointInPolygon(point: Point, polygon: []const Point) bool {
    var inside = false;
    var j = polygon.len - 1;

    for (polygon, 0..) |_, i| {
        const xi = polygon[i].x;
        const yi = polygon[i].y;
        const xj = polygon[j].x;
        const yj = polygon[j].y;

        const intersect = ((yi > point.y) != (yj > point.y)) and
            (point.x < @divTrunc((xj - xi) * (point.y - yi), (yj - yi)) + xi);

        if (intersect) inside = !inside;
        j = i;
    }

    return inside;
}

// Check if a point is on the polygon edge
fn isOnPolygonEdge(point: Point, polygon: []const Point) bool {
    for (0..polygon.len) |i| {
        const j = (i + 1) % polygon.len;
        const p1 = polygon[i];
        const p2 = polygon[j];

        // Check if point is on the line segment between p1 and p2
        // Points are on same horizontal line
        if (p1.y == p2.y and p1.y == point.y) {
            const min_x = @min(p1.x, p2.x);
            const max_x = @max(p1.x, p2.x);
            if (point.x >= min_x and point.x <= max_x) {
                return true;
            }
        }

        // Points are on same vertical line
        if (p1.x == p2.x and p1.x == point.x) {
            const min_y = @min(p1.y, p2.y);
            const max_y = @max(p1.y, p2.y);
            if (point.y >= min_y and point.y <= max_y) {
                return true;
            }
        }
    }

    return false;
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
    x: isize,
    y: isize,

    pub fn from(input: []const u8) !Point {
        var parts = std.mem.splitScalar(u8, input, ',');

        const x = try std.fmt.parseInt(isize, parts.next().?, 10);
        const y = try std.fmt.parseInt(isize, parts.next().?, 10);

        return .{ .x = x, .y = y };
    }
};
