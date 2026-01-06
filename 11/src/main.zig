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

    // const sol_1 = try part_1(allocator, trimmed);
    // std.debug.print("Solution part 1: {d}\n", .{sol_1});

    const sol_2 = try part_2(allocator, trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
}

fn part_1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var devices = try parse_devices(allocator, input);
    var iterator = devices.valueIterator();

    const path = (try bfs(allocator, "you", devices));

    for (path) |value| {
        defer allocator.free(value);
    }
    defer allocator.free(path);

    while (iterator.next()) |value| {
        defer allocator.free(value.*);
    }
    defer devices.deinit();

    return path.len;
}

fn part_2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var devices = try parse_devices(allocator, input);
    var distances = std.StringHashMap(usize).init(allocator);
    defer distances.deinit();

    const paths = find_paths(allocator, "svr", devices, &distances);

    var iterator = devices.valueIterator();
    while (iterator.next()) |value| {
        defer allocator.free(value.*);
    }
    defer devices.deinit();

    return paths;
}

fn find_paths(allocator: std.mem.Allocator, current: []const u8, devices: std.StringHashMap([][]const u8), distances: *std.StringHashMap(usize)) !usize {
    if (std.mem.eql(u8, current, "out")) {
        return 0;
    }

    const neighbors = devices.get(current).?;

    var sum: usize = 0;
    for (neighbors) |neighbor| {
        const neighbor_paths = distances.get(neighbor) orelse blk: {
            const paths = try find_paths(allocator, neighbor, devices, distances) + 1;
            try distances.put(neighbor, paths);
            break :blk paths;
        };
        sum += neighbor_paths;
    }

    return sum;
}

fn bfs(allocator: std.mem.Allocator, start: []const u8, devices: std.StringHashMap([][]const u8)) ![][][]const u8 {
    var queue = std.ArrayList(std.ArrayList([]const u8)){};
    defer {
        for (queue.items) |*item| {
            item.deinit(allocator);
        }
        queue.deinit(allocator);
    }

    var start_path = std.ArrayList([]const u8){};

    try start_path.append(allocator, start);
    try queue.append(allocator, start_path);

    var path = std.ArrayList([][]const u8){};

    while (queue.items.len > 0) {
        var head = queue.pop().?;
        const current = head.getLast();

        if (std.mem.eql(u8, current, "out")) {
            const target_path = try head.toOwnedSlice(allocator);

            try path.append(allocator, target_path);

            continue;
        }

        const targets = devices.get(current) orelse {
            head.deinit(allocator);
            continue;
        };

        for (targets) |target| {
            var next_path = std.ArrayList([]const u8){};
            try next_path.appendSlice(allocator, head.items);
            try next_path.append(allocator, target);

            try queue.append(allocator, next_path);
        }

        head.deinit(allocator);
    }

    return path.toOwnedSlice(allocator);
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
