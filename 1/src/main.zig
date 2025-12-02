const std = @import("std");
const aoc_2025 = @import("aoc_2025");

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

    const sol_1 = try part_1(file_contents, 50);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});

    const sol_2 = try part_2(file_contents, 50);
    std.debug.print("Solution part 2: {d}", .{sol_2});
}

fn part_1(input: []u8, start: i32) !usize {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var current = start;
    var timesZero: usize = 0;

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const rotation = try Rotation.from_line(line);

        if (rotation.dir == 'R') {
            current = @mod(current + rotation.times, 100);
        } else if (rotation.dir == 'L') {
            current = @mod(current - rotation.times, 100);
        }

        if (current == 0) {
            timesZero += 1;
        }
    }

    return timesZero;
}

fn part_2(input: []const u8, start: i32) !usize {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var current = start;
    var zeroCross: usize = 0;

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const rotation = try Rotation.from_line(line);
        if (rotation.dir == 'R') {
            const cycles = @divFloor(current + rotation.times, 100);

            zeroCross += @as(usize, @intCast(cycles));
            current = @mod(current + rotation.times, 100);
        } else if (rotation.dir == 'L') {
            if (current - rotation.times > 0) {
                current = current - rotation.times;
                continue;
            }

            var cycles = @divFloor(@abs(current - rotation.times), 100);
            if (current != 0) {
                cycles += 1;
            }

            zeroCross += @as(usize, @intCast(cycles));
            current = @mod(current - rotation.times, 100);
        }
    }

    return zeroCross;
}

const Rotation = struct {
    dir: u8,
    times: i32,

    fn from_line(line: []const u8) !Rotation {
        const dir = line[0];
        const times = try std.fmt.parseInt(i32, line[1..], 10);

        return .{
            .dir = dir,
            .times = times,
        };
    }
};

test "Part 2" {
    try std.testing.expectEqual(part_2("L68\nL30\nR48\nL5\nR60\nL55\nL1\nL99\nR14\nL82", 50), 6);
}

test "Left Rotation" {
    try std.testing.expectEqual(part_2("L50", 50), 1);
    try std.testing.expectEqual(part_2("L60", 50), 1);
    try std.testing.expectEqual(part_2("L65", 50), 1);
    try std.testing.expectEqual(part_2("L10", 5), 1);
    try std.testing.expectEqual(part_2("L150", 50), 2);
    try std.testing.expectEqual(part_2("L105", 5), 2);
    try std.testing.expectEqual(part_2("L68", 50), 1);
    try std.testing.expectEqual(part_2("L30", 82), 0);
    try std.testing.expectEqual(part_2("L5", 48), 0);
    try std.testing.expectEqual(part_2("L1", 3), 0);
    try std.testing.expectEqual(part_2("L99", 2), 1);
    try std.testing.expectEqual(part_2("L68", 50), 1);
    try std.testing.expectEqual(part_2("L30", 82), 0);
    try std.testing.expectEqual(part_2("L5", 0), 0);
}

test "Right Rotation" {
    try std.testing.expectEqual(part_2("R50", 50), 1);
    try std.testing.expectEqual(part_2("R55", 50), 1);
    try std.testing.expectEqual(part_2("R150", 50), 2);
    try std.testing.expectEqual(part_2("R105", 5), 1);
    try std.testing.expectEqual(part_2("R195", 5), 2);
    try std.testing.expectEqual(part_2("R60", 43), 1);
    try std.testing.expectEqual(part_2("R48", 82), 1);
}
