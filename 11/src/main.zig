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

    const sol_2 = try part_2(allocator, trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
}

fn part_1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var devices = try parse_devices(allocator, input);
    var distances = std.StringHashMap(usize).init(allocator);
    defer distances.deinit();

    const paths = find_paths(allocator, "you", "out", devices, &distances);

    var iterator = devices.valueIterator();
    while (iterator.next()) |value| {
        defer allocator.free(value.*);
    }
    defer devices.deinit();

    return paths;
}

fn part_2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var devices = try parse_devices(allocator, input);
    var distances = std.StringHashMap(usize).init(allocator);
    defer distances.deinit();

    const svr_fft = try find_paths(allocator, "svr", "fft", devices, &distances);
    distances.clearRetainingCapacity();

    const fft_dac = try find_paths(allocator, "fft", "dac", devices, &distances);
    distances.clearRetainingCapacity();

    const dac_out = try find_paths(allocator, "dac", "out", devices, &distances);
    distances.clearRetainingCapacity();

    var iterator = devices.valueIterator();
    while (iterator.next()) |value| {
        defer allocator.free(value.*);
    }
    defer devices.deinit();

    return svr_fft * fft_dac * dac_out;
}

fn find_paths(allocator: std.mem.Allocator, current: []const u8, target: []const u8, devices: std.StringHashMap([][]const u8), distances: *std.StringHashMap(usize)) !usize {
    if (std.mem.eql(u8, current, target)) {
        return 1;
    }

    const neighbors = devices.get(current) orelse return 0;

    var sum: usize = 0;
    for (neighbors) |neighbor| {
        const neighbor_paths = distances.get(neighbor) orelse blk: {
            const paths = try find_paths(allocator, neighbor, target, devices, distances);
            try distances.put(neighbor, paths);
            break :blk paths;
        };
        sum += neighbor_paths;
    }

    return sum;
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
