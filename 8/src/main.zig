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
}

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
};

test "Calculate distance between two points" {
    const p1 = try Point.from("1,2,3");
    const p2 = try Point.from("4,5,6");

    const d = p1.distance(&p2);

    try std.testing.expectEqual(5.196152422706632, d);
}
