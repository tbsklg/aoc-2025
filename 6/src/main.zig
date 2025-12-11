const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_contents = try std.fs.cwd().readFileAlloc(
        allocator,
        "input.txt",
        1025 * 1024,
    );
    defer allocator.free(file_contents);

    const trimmed = std.mem.trim(u8, file_contents, "\t\r\n");

    const sol_1 = try part_1(allocator, trimmed);
    std.debug.print("Solution part 1: {d}\n", .{sol_1});

    const sol_2 = try part_2(allocator, trimmed);
    std.debug.print("Solution part 2: {d}\n", .{sol_2});
}

fn part_1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const homework = try parse_homework(allocator, input);
    defer {
        for (homework) |line| {
            allocator.free(line);
        }
        allocator.free(homework);
    }

    const numbers = try parse_numbers(allocator, homework[0 .. homework.len - 1]);
    defer {
        for (numbers) |line| {
            allocator.free(line);
        }
        allocator.free(numbers);
    }

    const operators = try parse_operator(allocator, homework[homework.len - 1]);
    defer allocator.free(operators);

    return do_math(operators, numbers);
}

fn part_2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const homework = try parse_homework(allocator, input);
    defer {
        for (homework) |line| {
            allocator.free(line);
        }
        allocator.free(homework);
    }

    return do_math_right_to_left(allocator, homework);
}

const Operator = enum { add, multiply };

fn do_math_right_to_left(allocator: std.mem.Allocator, input: [][]u8) !usize {
    var total: usize = 0;

    var numbers = std.ArrayList(usize){};
    defer numbers.deinit(allocator);

    const width = input[0].len;
    for (0..width) |col| {
        var digits = std.ArrayList(u8){};
        defer digits.deinit(allocator);

        const column_index = width - 1 - col;
        for (input, 0..) |row, row_index| {
            const raw = row[column_index];

            if (raw == '+') {
                try flushDigitsToNumbers(allocator, &digits, &numbers);
                const result = consume_sum(&numbers);
                total += result;
                break;
            }

            if (raw == '*') {
                try flushDigitsToNumbers(allocator, &digits, &numbers);
                const result = consume_product(&numbers);
                total += result;
                break;
            }

            if (raw != ' ') {
                try digits.append(allocator, raw);
            }

            if (row_index == input.len - 1) {
                try flushDigitsToNumbers(allocator, &digits, &numbers);
            }
        }
    }
    return total;
}

fn flushDigitsToNumbers(
    allocator: std.mem.Allocator,
    digits: *std.ArrayList(u8),
    numbers: *std.ArrayList(usize),
) !void {
    if (digits.items.len == 0) return;

    const slice = try digits.toOwnedSlice(allocator);
    defer allocator.free(slice);

    const number = try std.fmt.parseInt(usize, slice, 10);
    try numbers.append(allocator, number);

    digits.clearRetainingCapacity();
}

fn consume_sum(numbers: *std.ArrayList(usize)) usize {
    var result: usize = 0;
    for (numbers.items) |value| {
        result += value;
    }

    numbers.clearRetainingCapacity();
    return result;
}

fn consume_product(numbers: *std.ArrayList(usize)) usize {
    var result: usize = 1;
    for (numbers.items) |value| {
        result *= value;
    }

    numbers.clearRetainingCapacity();
    return result;
}

fn do_math(operators: []Operator, numbers: [][]const usize) usize {
    var total: usize = 0;
    for (0..numbers[0].len) |col| {
        const op = operators[col];

        var result: usize = switch (op) {
            .add => 0,
            .multiply => 1,
        };

        for (numbers) |row| {
            const value = row[col];
            switch (op) {
                .add => result += value,
                .multiply => result *= value,
            }
        }

        total += result;
    }

    return total;
}

fn parse_numbers(allocator: std.mem.Allocator, input: [][]u8) ![][]const usize {
    var lines = std.ArrayList([]const usize){};
    defer lines.deinit(allocator);

    for (input) |line| {
        var numbers = std.ArrayList(usize){};
        defer numbers.deinit(allocator);

        var raw_numbers = std.mem.tokenizeScalar(u8, line, ' ');
        while (raw_numbers.next()) |raw| {
            const number = try std.fmt.parseInt(usize, raw, 10);
            try numbers.append(allocator, number);
        }

        try lines.append(allocator, try numbers.toOwnedSlice(allocator));
    }

    return lines.toOwnedSlice(allocator);
}

fn parse_operator(allocator: std.mem.Allocator, input: []u8) ![]Operator {
    var raw_operators = std.mem.tokenizeScalar(u8, input, ' ');

    var operators = std.ArrayList(Operator){};
    defer operators.deinit(allocator);

    while (raw_operators.next()) |raw| {
        if (std.mem.eql(u8, raw, "*")) {
            try operators.append(allocator, Operator.multiply);
        }

        if (std.mem.eql(u8, raw, "+")) {
            try operators.append(allocator, Operator.add);
        }
    }

    return operators.toOwnedSlice(allocator);
}

fn parse_homework(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var homework = std.ArrayList([]u8){};
    defer homework.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const mutable_line = try allocator.dupe(u8, line);
        try homework.append(allocator, mutable_line);
    }

    return homework.toOwnedSlice(allocator);
}
