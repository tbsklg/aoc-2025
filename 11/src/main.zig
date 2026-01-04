const std = @import("std");
const _11 = @import("_11");

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
    var devices = try parse_devices(allocator, input);
    var iterator = devices.valueIterator();

    const count = try bfs(allocator, devices);

    while (iterator.next()) |value| {
        defer allocator.free(value.*);
    }
    defer devices.deinit();

    return count;
}

fn bfs(allocator: std.mem.Allocator, devices: std.StringHashMap([][]const u8)) !usize {
    var queue = std.ArrayList(struct { std.ArrayList([]const u8) }){};
    defer {
        for (queue.items) |*item| {
            item.@"0".deinit(allocator);
        }
        queue.deinit(allocator);
    }

    var start = std.ArrayList([]const u8){};

    try start.append(allocator, "you");
    try queue.append(allocator, .{start});

    var count: usize = 0;

    while (queue.items.len > 0) {
        var head = queue.orderedRemove(0);
        const current = head.@"0".getLast();

        if (std.mem.eql(u8, current, "out")) {
            head.@"0".deinit(allocator);
            count += 1;
            continue;
        }

        const targets = devices.get(current) orelse {
            head.@"0".deinit(allocator);
            continue;
        };

        for (targets) |target| {
            var next_path = std.ArrayList([]const u8){};
            try next_path.appendSlice(allocator, head.@"0".items);
            try next_path.append(allocator, target);

            try queue.append(allocator, .{next_path});
        }

        head.@"0".deinit(allocator);
    }

    return count;
}

fn parse_devices(allocator: std.mem.Allocator, input: []const u8) !std.StringHashMap([][]const u8) {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var devices = std.StringHashMap([][]const u8).init(allocator);

    while (lines.next()) |line| {
        const device = try parse_device(allocator, line);
        try devices.put(device.@"0", device.@"1");
    }

    return devices;
}

fn parse_device(allocator: std.mem.Allocator, line: []const u8) !struct { []const u8, [][]const u8 } {
    var parts = std.mem.splitScalar(u8, line, ':');
    const device = parts.next().?;

    const targets = std.mem.trim(u8, parts.next().?, " ");
    var targets_iter = std.mem.splitScalar(u8, targets, ' ');

    var devices = std.ArrayList([]const u8){};

    while (targets_iter.next()) |target| {
        try devices.append(allocator, std.mem.trim(u8, target, " "));
    }

    return .{
        device,
        try devices.toOwnedSlice(allocator),
    };
}
