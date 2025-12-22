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

    while (lines.next()) |line| {
        const m = try Machine.from(allocator, line);
        defer allocator.free(m.lights);
        defer allocator.free(m.buttons);

        for (m.buttons) |button| {
            defer allocator.free(button);
        }

        std.debug.print("{any}", .{m});
    }

    return 0;
}

const Machine = struct {
    lights: []const u8,
    buttons: [][]const u8,

    fn from(allocator: std.mem.Allocator, input: []const u8) !Machine {
        var iter = std.mem.splitScalar(u8, input, ' ');
        const lights = try parse_lights(allocator, iter.next().?);

        var buttons = std.ArrayList([]const u8){};

        while (iter.next()) |part| {
            if (part[0] == '(') {
                const button = try parse_button(allocator, part, lights.len);
                try buttons.append(allocator, button);
            }
        }

        return .{
            .lights = lights,
            .buttons = try buttons.toOwnedSlice(allocator),
        };
    }
};

fn parse_button(allocator: std.mem.Allocator, input: []const u8, len: usize) ![]const u8 {
    var button = std.ArrayList(u8){};

    for (0..len) |_| {
        try button.append(allocator, 0);
    }

    for (input) |c| {
        if (c == '(' or c == ')' or c == ',') {
            continue;
        }

        button.items[c - '0'] = 1;
    }

    return button.toOwnedSlice(allocator);
}

fn parse_lights(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var lights = std.ArrayList(u8){};

    for (input) |c| {
        if (c == '[' or c == ']') {
            continue;
        }

        if (c == '#') {
            try lights.append(allocator, 1);
            continue;
        }

        if (c == '.') {
            try lights.append(allocator, 0);
            continue;
        }
    }

    return lights.toOwnedSlice(allocator);
}
