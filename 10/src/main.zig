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

        std.debug.print("Machine {any}", .{m});

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

const Matrix = struct {
    data: std.ArrayList(std.ArrayList(u8)),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, m: usize, n: usize) !Matrix {
        var data = try std.ArrayList(std.ArrayList(u8)).initCapacity(allocator, m);

        var i: usize = 0;
        while (i < m) : (i += 1) {
            var row = try std.ArrayList(u8).initCapacity(allocator, n);
            try row.appendNTimes(allocator, 0, n);
            try data.append(allocator, row);
        }

        return Matrix{
            .data = data,
            .allocator = allocator,
        };
    }

    fn get(self: Matrix, row: usize, col: usize) u8 {
        return self.data.items[row].items[col];
    }

    fn set(self: *Matrix, row: usize, col: usize, value: u8) void {
        self.data.items[row].items[col] = value;
    }

    fn swap(self: *Matrix, i: usize, j: usize) void {
        std.mem.swap(std.ArrayList(u8), &self.data.items[i], &self.data.items[j]);
    }

    fn xor_rows(self: *Matrix, target_row_idx: usize, source_row_idx: usize) void {
        const num_cols = self.data.items[0].items.len;

        for (0..num_cols) |col| {
            const xor_result = self.get(target_row_idx, col) ^ self.get(source_row_idx, col);
            self.set(target_row_idx, col, xor_result);
        }
    }

    fn eliminate_below(self: *Matrix, pivot_row: usize, col: usize) void {
        for (self.data.items[pivot_row + 1 ..], pivot_row + 1..) |row, idx| {
            if (row.items[col] == 1) {
                self.xor_rows(idx, pivot_row);
            }
        }
    }

    fn row_echelon_form(self: *Matrix) void {
        const num_columns = self.data.items[0].items.len;

        var row_idx: usize = 0;
        for (0..num_columns) |col_idx| {
            if (row_idx >= self.data.items.len) break;

            const pivot_row = self.find_pivot(row_idx, col_idx);

            if (pivot_row == null) {
                continue;
            }

            self.swap(row_idx, pivot_row.?);
            self.eliminate_below(row_idx, col_idx);

            row_idx += 1;
        }
    }

    fn find_pivot(self: Matrix, row_idx: usize, col_idx: usize) ?usize {
        for (self.data.items[row_idx..], row_idx..) |row, idx| {
            if (row.items[col_idx] == 1) {
                return idx;
            }
        }

        return null;
    }

    fn deinit(self: *Matrix) void {
        for (self.data.items) |*row| {
            row.deinit(self.allocator);
        }

        self.data.deinit(self.allocator);
    }
};

fn create_matrix(allocator: std.mem.Allocator, m: Machine) !Matrix {
    const num_positions = m.joltage.len;
    const num_buttons = m.buttons.len;

    var matrix = try Matrix.init(allocator, num_positions, num_buttons);

    for (m.buttons, 0..) |button, button_idx| {
        for (button) |position| {
            matrix.set(position, button_idx, 1);
        }
    }

    return matrix;
}

test "create matrix from machine" {
    const allocator = std.testing.allocator;

    const button0 = [_]usize{ 1, 2, 3 };
    const button1 = [_]usize{ 0, 1 };
    const button2 = [_]usize{ 0, 2, 3 };

    var buttons = [_][]const usize{
        &button0,
        &button1,
        &button2,
    };

    const joltage = [_]usize{ 200, 19, 207, 207 };

    const machine = Machine{
        .lights = 0b1110,
        .buttons = &buttons,
        .joltage = &joltage,
        .allocator = allocator,
    };

    var matrix = try create_matrix(allocator, machine);
    defer matrix.deinit();

    try std.testing.expectEqual(0, matrix.get(0, 0));
    try std.testing.expectEqual(1, matrix.get(0, 1));
    try std.testing.expectEqual(1, matrix.get(1, 0));
    try std.testing.expectEqual(1, matrix.get(0, 2));
}

test "swap rows in matrix" {
    const allocator = std.testing.allocator;

    const button0 = [_]usize{ 1, 2, 3 };
    const button1 = [_]usize{ 0, 1 };
    const button2 = [_]usize{ 0, 2, 3 };

    var buttons = [_][]const usize{
        &button0,
        &button1,
        &button2,
    };

    const joltage = [_]usize{ 200, 19, 207, 207 };

    const machine = Machine{
        .lights = 0b1110,
        .buttons = &buttons,
        .joltage = &joltage,
        .allocator = allocator,
    };

    // | 0 1 1 |
    // | 1 1 0 |
    // | 1 0 1 |
    // | 1 0 1 |
    var matrix = try create_matrix(allocator, machine);
    defer matrix.deinit();

    // | 1 1 0 |
    // | 0 1 1 |
    // | 1 0 1 |
    // | 1 0 1 |
    matrix.swap(0, 1);

    try std.testing.expectEqual(1, matrix.get(0, 0));
    try std.testing.expectEqual(0, matrix.get(1, 0));
}

test "find pivot row" {
    const allocator = std.testing.allocator;

    const button0 = [_]usize{ 1, 2, 3 };
    const button1 = [_]usize{ 0, 1 };
    const button2 = [_]usize{ 0, 2, 3 };

    var buttons = [_][]const usize{
        &button0,
        &button1,
        &button2,
    };

    const joltage = [_]usize{ 200, 19, 207, 207 };

    const machine = Machine{
        .lights = 0b1110,
        .buttons = &buttons,
        .joltage = &joltage,
        .allocator = allocator,
    };

    // | 0 1 1 |
    // | 1 1 0 |
    // | 1 0 1 |
    // | 1 0 1 |
    var matrix = try create_matrix(allocator, machine);
    defer matrix.deinit();

    try std.testing.expectEqual(1, matrix.find_pivot(0, 0));
    try std.testing.expectEqual(2, matrix.find_pivot(2, 0));
    try std.testing.expectEqual(null, matrix.find_pivot(2, 1));
}

test "xor rows" {
    const allocator = std.testing.allocator;

    const button0 = [_]usize{ 1, 2, 3 };
    const button1 = [_]usize{ 0, 1 };
    const button2 = [_]usize{ 0, 2, 3 };

    var buttons = [_][]const usize{
        &button0,
        &button1,
        &button2,
    };

    const joltage = [_]usize{ 200, 19, 207, 207 };

    const machine = Machine{
        .lights = 0b1110,
        .buttons = &buttons,
        .joltage = &joltage,
        .allocator = allocator,
    };

    // Create same matrix as before
    // | 0 1 1 |
    // | 1 1 0 |
    // | 1 0 1 |
    // | 1 0 1 |
    var matrix = try create_matrix(allocator, machine);
    defer matrix.deinit();

    matrix.xor_rows(2, 1);

    try std.testing.expectEqual(0, matrix.get(2, 0));
    try std.testing.expectEqual(1, matrix.get(2, 1));
    try std.testing.expectEqual(1, matrix.get(2, 2));

    try std.testing.expectEqual(1, matrix.get(1, 0));
    try std.testing.expectEqual(1, matrix.get(1, 1));
    try std.testing.expectEqual(0, matrix.get(1, 2));
}

test "row echelon form - binary matrix" {
    const allocator = std.testing.allocator;
    
    var matrix = try Matrix.init(allocator, 4, 3);
    defer matrix.deinit();
    
    // Before REF:
    // | 0 1 1 |  row 0
    // | 1 1 0 |  row 1
    // | 1 0 1 |  row 2
    // | 1 0 1 |  row 3
    
    // Row 0: [0, 1, 1]
    matrix.set(0, 0, 0);
    matrix.set(0, 1, 1);
    matrix.set(0, 2, 1);
    
    // Row 1: [1, 1, 0]
    matrix.set(1, 0, 1);
    matrix.set(1, 1, 1);
    matrix.set(1, 2, 0);
    
    // Row 2: [1, 0, 1]
    matrix.set(2, 0, 1);
    matrix.set(2, 1, 0);
    matrix.set(2, 2, 1);
    
    // Row 3: [1, 0, 1]
    matrix.set(3, 0, 1);
    matrix.set(3, 1, 0);
    matrix.set(3, 2, 1);
    
    matrix.row_echelon_form();
    
    // After REF (expected result):
    // | 1 1 0 |  
    // | 0 1 1 |  
    // | 0 0 0 |  
    // | 0 0 0 |  
    
    try std.testing.expectEqual(1, matrix.get(0, 0));
    try std.testing.expectEqual(1, matrix.get(0, 1));
    try std.testing.expectEqual(0, matrix.get(0, 2));
    
    try std.testing.expectEqual(0, matrix.get(1, 0));
    try std.testing.expectEqual(1, matrix.get(1, 1));
    try std.testing.expectEqual(1, matrix.get(1, 2));
    
    try std.testing.expectEqual(0, matrix.get(2, 0));
    try std.testing.expectEqual(0, matrix.get(2, 1));
    try std.testing.expectEqual(0, matrix.get(2, 2));
    
    try std.testing.expectEqual(0, matrix.get(3, 0));
    try std.testing.expectEqual(0, matrix.get(3, 1));
    try std.testing.expectEqual(0, matrix.get(3, 2));
}
