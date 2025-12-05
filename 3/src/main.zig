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

    const sol_1 = try part_1(trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});

    const sol_2 = try part_2(trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_2});
}

fn part_1(input: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var result: usize = 0;
    while (lines.next()) |line| {
        result += try largest_joltage(line);
    }
    return result;
}

fn part_2(input: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var result: usize = 0;
    while (lines.next()) |line| {
        var state = [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
        largest_joltage_2(line, &state, 0, 0);
        result += try std.fmt.parseInt(usize, &state, 10);
    }

    return result;
}

fn largest_joltage(input: []const u8) !u8 {
    var bat_0: u8 = 0;
    var bat_1: u8 = 0;

    for (0..input.len - 1) |i| {
        if (input[i] > bat_0) {
            bat_0 = input[i];
            bat_1 = 0;

            for (input[i + 1 ..]) |y| {
                if (y > bat_1) {
                    bat_1 = y;
                }
            }
        }
    }

    const result = [_]u8{ bat_0, bat_1 };
    return try std.fmt.parseInt(u8, &result, 10);
}

// TODO: use monotonic stack instead
fn largest_joltage_2(input: []const u8, state: []u8, depth: usize, start: usize) void {
    if (depth >= state.len) return;

    const remaining = state.len - depth;
    const end = input.len - remaining + 1;

    for (start..end) |i| {
        if (input[i] > state[depth]) {
            state[depth] = input[i];
            if (depth + 1 < state.len) {
                state[depth + 1] = 0;
                largest_joltage_2(input, state, depth + 1, i + 1);
            }
        }
    }
}

test "Largest possible joltage" {
    try std.testing.expectEqual(98, largest_joltage("987654321111111"));
    try std.testing.expectEqual(89, largest_joltage("811111111111119"));
    try std.testing.expectEqual(78, largest_joltage("234234234234278"));
    try std.testing.expectEqual(92, largest_joltage("818181911112111"));
}
