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
    var lines = std.mem.splitScalar(u8, input, '\n');
    var total: usize = 0;

    while (lines.next()) |line| {
        var m = try Machine.from(allocator, line);
        defer m.deinit();

        const result = try min_presses_lights(allocator, m);
        total += result;
    }

    return total;
}

fn min_presses_lights(allocator: std.mem.Allocator, m: Machine) !usize {
    var queue = std.ArrayList(struct { usize, usize }){};
    defer queue.deinit(allocator);

    try queue.append(allocator, .{ 0, 0 });

    var seen = std.AutoArrayHashMap(usize, void).init(allocator);
    defer seen.deinit();
    try seen.put(0, {});

    while (queue.items.len > 0) {
        const head = queue.orderedRemove(0);

        if (head.@"0" == m.lights) {
            return head.@"1";
        }

        for (m.buttons) |button| {
            var toggled = head.@"0";

            for (button) |press| {
                toggled = toggled ^ (@as(u32, 1) << @intCast(press));
            }

            if (seen.contains(toggled)) {
                continue;
            }

            try seen.put(toggled, {});
            try queue.append(allocator, .{ toggled, head.@"1" + 1 });
        }
    }

    unreachable;
}

const Machine = struct {
    lights: usize,
    buttons: [][]const usize,
    joltage: []const usize,
    allocator: std.mem.Allocator,

    fn from(allocator: std.mem.Allocator, input: []const u8) !Machine {
        var parts = std.mem.splitScalar(u8, input, ' ');
        const lights = try parse_lights(parts.next().?);

        var _buttons = std.ArrayList([]const usize){};
        while (parts.next()) |part| {
            const peek = parts.peek();

            if (part[0] == '(') {
                const button = try parse_button(allocator, part);
                try _buttons.append(allocator, button);
            }

            if (peek != null and peek.?[0] == '{') {
                break;
            }
        }

        const buttons = try _buttons.toOwnedSlice(allocator);
        const joltage = try parse_joltage(allocator, parts.next().?);

        return .{
            .lights = lights,
            .buttons = buttons,
            .joltage = joltage,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Machine) void {
        for (self.buttons) |button| {
            self.allocator.free(button);
        }
        self.allocator.free(self.buttons);
        self.allocator.free(self.joltage);
    }
};

// {3,5,4,7}
fn parse_joltage(allocator: std.mem.Allocator, input: []const u8) ![]const usize {
    var joltage = std.ArrayList(usize){};
    defer joltage.deinit(allocator);

    const trimmed = input[1 .. input.len - 1];
    var iter = std.mem.splitScalar(u8, trimmed, ',');

    while (iter.next()) |i| {
        const n = try std.fmt.parseInt(usize, i, 10);
        try joltage.append(allocator, n);
    }

    return joltage.toOwnedSlice(allocator);
}

// (0,3,4)
fn parse_button(allocator: std.mem.Allocator, input: []const u8) ![]const usize {
    var button = std.ArrayList(usize){};
    defer button.deinit(allocator);

    const trimmed = input[1 .. input.len - 1];
    var iter = std.mem.splitScalar(u8, trimmed, ',');

    while (iter.next()) |i| {
        const n = try std.fmt.parseInt(usize, i, 10);
        try button.append(allocator, n);
    }

    return button.toOwnedSlice(allocator);
}

// [#.##.]
fn parse_lights(input: []const u8) !usize {
    var acc: usize = 0;
    var pos: usize = 0;

    for (input) |c| {
        if (c == '[' or c == ']') {
            continue;
        }

        if (c == '#') {
            acc |= (@as(usize, 1) << @intCast(pos));
        }
        pos += 1;
    }

    return acc;
}
