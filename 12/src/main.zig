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

    const sol_1 = try part_1(trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});
}

fn part_1(input: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, input, '\n');

    const skip = 30;
    var curr: usize = 0;

    while (curr < skip) {
        _ = lines.next();
        curr += 1;
    }

    var count: usize = 0;
    while (lines.next()) |line| {
        var region = try Region.from(line);

        var needed_area: usize = 0;
        for (region.present_counts) |presents_count| {
            needed_area += presents_count * 9;
        }

        if (region.area() >= needed_area) {
            count += 1;
        }
    }

    return count;
}

const Region = struct {
    width: usize,
    length: usize,
    present_counts: [6]usize,

    fn from(input: []const u8) !Region {
        var parts = std.mem.splitSequence(u8, input, ": ");
        var lhs = std.mem.splitScalar(u8, parts.next().?, 'x');

        const width = try std.fmt.parseInt(usize, lhs.next().?, 10);
        const length = try std.fmt.parseInt(usize, lhs.next().?, 10);

        var rhs = std.mem.splitScalar(u8, parts.next().?, ' ');

        var buffer: [6]usize = undefined;
        var index: usize = 0;
        while (rhs.next()) |count| {
            buffer[index] = try std.fmt.parseInt(usize, count, 10);
            index += 1;
        }

        return .{
            .width = width,
            .length = length,
            .present_counts = buffer,
        };
    }

    fn area(self: *Region) usize {
        return self.width * self.length;
    }
};
