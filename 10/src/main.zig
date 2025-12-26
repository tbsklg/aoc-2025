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
        var m = try Machine.from(allocator, line);
        defer m.deinit();
        _ = try guenther(m);
    }

    return 0;
}

fn guenther(m: Machine) !usize {
    const result = m.lights;

    const masked = m.buttons[5];

    std.debug.print("{any} - {any}\n", .{result, masked});

    return masked;
}

const Machine = struct {
    lights: usize,
    buttons: []usize,
    allocator: std.mem.Allocator,

    fn from(allocator: std.mem.Allocator, input: []const u8) !Machine {
        var iter = std.mem.splitScalar(u8, input, ' ');
        const lights = try parse_lights(allocator, iter.next().?);
        defer allocator.free(lights);

        var buttons: std.ArrayList(usize) = .empty;
        defer buttons.deinit(allocator);

        while (iter.next()) |part| {
            if (part[0] == '(') {
                const button = try parse_button(allocator, part, lights.len);
                try buttons.append(allocator, button);
            }
        }

        var result: usize = 0;
        for (lights, 0..) |bit, i| {
            result |= @as(usize, bit) << @intCast(lights.len - 1 - i);
        }

        return .{
            .lights = result,
            .buttons = try buttons.toOwnedSlice(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *Machine) void {
        self.allocator.free(self.buttons);
    }
};

fn parse_button(allocator: std.mem.Allocator, input: []const u8, len: usize) !usize {
    var button: std.ArrayList(u8) = .empty;
    defer button.deinit(allocator);

    for (0..len) |_| {
        try button.append(allocator, 0);
    }

    for (input) |c| {
        if (c == '(' or c == ')' or c == ',') {
            continue;
        }

        button.items[c - '0'] = 1;
    }

    var result: usize = 0;
    for (button.items, 0..) |bit, i| {
        result |= @as(usize, bit) << @intCast(button.items.len - 1 - i);
    }

    return result;
}

fn parse_lights(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var lights: std.ArrayList(u8) = .empty;
    defer lights.deinit(allocator);

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
