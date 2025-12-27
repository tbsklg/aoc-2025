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
        _ = try guenther(allocator, m);
    }

    return 0;
}

const State = struct { []const u8, []const u8, usize };

fn guenther(allocator: std.mem.Allocator, m: Machine) !usize {
    const initial_lights = try allocator.alloc(u8, m.lights.len);
    defer allocator.free(initial_lights);

    for (0..initial_lights.len) |i| {
        initial_lights[i] = '.';
    }

    var stack = std.ArrayList(State){};
    defer stack.deinit(allocator);

    for (m.buttons) |b| {
        try stack.append(allocator, .{ b, initial_lights, 0 });
    }

    for (stack.items) |b| {
        const toggled = try toggle(allocator, b.@"1", b.@"0");

        if (std.mem.eql(u8, m.lights, toggled)) {
            std.debug.print("Found {s} - {d}\n", .{ toggled, b.@"2" });
        }

        for (m.buttons) |button| {
            if (!std.mem.eql(u8, b.@"0", button)) {
                std.debug.print("Skip {s}\n", .{button});
                continue;
            }
            // add to queue
        }

        defer allocator.free(toggled);
        std.debug.print("{s}\n", .{toggled});
    }

    // const result_0 = try toggle(allocator, initial_state, m.buttons[0]);
    // const result_1 = try toggle(allocator, result_0, m.buttons[1]);
    // const result_2 = try toggle(allocator, result_1, m.buttons[2]);
    //
    // defer allocator.free(result_0);
    // defer allocator.free(result_1);
    // defer allocator.free(result_2);
    //
    // std.debug.print("{s}\n", .{result_2});
    return 0;
}

fn toggle(allocator: std.mem.Allocator, state: []const u8, button: []const u8) ![]const u8 {
    var result = std.ArrayList(u8){};
    defer result.deinit(allocator);

    for (0..state.len) |i| {
        if (button[i] == '#') {
            if (state[i] == '.') {
                try result.append(allocator, '#');
            } else {
                try result.append(allocator, '.');
            }
        } else {
            try result.append(allocator, state[i]);
        }
    }

    return result.toOwnedSlice(allocator);
}

const Machine = struct {
    lights: []const u8,
    buttons: [][]const u8,
    allocator: std.mem.Allocator,

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
            .allocator = allocator,
        };
    }

    fn deinit(self: *Machine) void {
        for (self.buttons) |button| {
            self.allocator.free(button);
        }
        self.allocator.free(self.buttons);
        self.allocator.free(self.lights);
    }
};

fn parse_button(allocator: std.mem.Allocator, input: []const u8, len: usize) ![]const u8 {
    var button: std.ArrayList(u8) = .{};
    defer button.deinit(allocator);

    for (0..len) |_| {
        try button.append(allocator, '.');
    }

    for (input) |c| {
        if (c == '(' or c == ')' or c == ',') {
            continue;
        }

        button.items[c - '0'] = '#';
    }

    return button.toOwnedSlice(allocator);
}

fn parse_lights(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var lights: std.ArrayList(u8) = .{};
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
