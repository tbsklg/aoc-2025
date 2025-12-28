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
        const result = try bfs(allocator, m);
        total += result;
    }

    return total;
}

const State = struct {
    button: []const u8,
    lights: []const u8,
    depth: usize,
};

fn bfs(allocator: std.mem.Allocator, m: Machine) !usize {
    const initial_lights = try allocator.alloc(u8, m.lights.len);
    defer allocator.free(initial_lights);

    for (0..initial_lights.len) |i| {
        initial_lights[i] = '.';
    }

    var stack = std.ArrayList(State){};
    defer {
        for (stack.items) |state| {
            if (state.lights.ptr != initial_lights.ptr) {
                allocator.free(state.lights);
            }
        }
        stack.deinit(allocator);
    }

    for (m.buttons) |b| {
        try stack.append(allocator, .{ .button = b, .lights = initial_lights, .depth = 0 });
    }

    var visited = std.StringHashMap(void).init(allocator);
    defer {
        var it = visited.keyIterator();
        while (it.next()) |key| {
            allocator.free(key.*);
        }
        visited.deinit();
    }

    const initial_copy = try allocator.dupe(u8, initial_lights);
    try visited.put(initial_copy, {});

    var i: usize = 0;
    while (i < stack.items.len) : (i += 1) {
        const current_state = stack.items[i];
        const button = current_state.button;
        const lights = current_state.lights;
        const depth = current_state.depth;

        const toggled = try toggle(allocator, lights, button);

        if (std.mem.eql(u8, m.lights, toggled)) {
            allocator.free(toggled);
            return depth + 1;
        }

        if (visited.contains(toggled)) {
            allocator.free(toggled);
            continue;
        }

        const toggled_for_visited = try allocator.dupe(u8, toggled);
        try visited.put(toggled_for_visited, {});

        for (m.buttons) |next_button| {
            const toggled_copy = try allocator.dupe(u8, toggled);
            try stack.append(allocator, .{
                .button = next_button,
                .lights = toggled_copy,
                .depth = depth + 1,
            });
        }

        allocator.free(toggled);
    }

    std.debug.print("No solution found\n", .{});
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

        try lights.append(allocator, c);
    }

    return lights.toOwnedSlice(allocator);
}
