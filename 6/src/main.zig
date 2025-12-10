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

const Operator = enum { add, multiply };

fn do_math(operators: []Operator, numbers: [][]const usize) usize {
    var total: usize = 0;
    for (0..numbers[0].len) |i| {
        const operator = operators[i];

        var result: usize = 0;
        for (numbers) |number_line| {
            const number = number_line[i];
            if (operator == Operator.add) {
                result += number;
            }

            if (operator == Operator.multiply) {
                result = @max(result, 1) * number;
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
