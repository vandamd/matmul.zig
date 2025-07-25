const std = @import("std");

pub const Matrix = struct {
    rows: usize,
    columns: usize,
    data: []f32,

    pub fn deinit(self: *Matrix, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn full(allocator: std.mem.Allocator, rows: usize, columns: usize, fill_value: f32) !Matrix {
        if (rows <= 0 or columns <= 0) {
            return error.invalidDimension;
        }

        const numElements = rows * columns;
        const data = try allocator.alloc(f32, numElements);

        for (0..data.len) |i| {
            data[i] = fill_value;
        }

        return Matrix{
            .rows = rows,
            .columns = columns,
            .data = data,
        };
    }

    pub fn rand(allocator: std.mem.Allocator, rows: usize, columns: usize) !Matrix {
        if (rows <= 0 or columns <= 0) {
            return error.invalidDimension;
        }

        const numElements = rows * columns;
        const data = try allocator.alloc(f32, numElements);

        var prng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        const random = prng.random();

        for (0..data.len) |i| {
            data[i] = std.Random.float(random, f32);
        }

        return Matrix{
            .rows = rows,
            .columns = columns,
            .data = data,
        };
    }

    pub fn zeros(allocator: std.mem.Allocator, rows: usize, columns: usize) !Matrix {
        if (rows <= 0 or columns <= 0) {
            return error.invalidDimension;
        }

        return Matrix.full(allocator, rows, columns, 0.0);
    }

    pub fn ones(allocator: std.mem.Allocator, rows: usize, columns: usize) !Matrix {
        if (rows <= 0 or columns <= 0) {
            return error.invalidDimension;
        }

        return Matrix.full(allocator, rows, columns, 1.0);
    }

    pub fn get(self: Matrix, row: usize, column: usize) !f32 {
        if (row <= 0 or column <= 0) {
            return error.invalidDimension;
        } else if (row > self.rows or column > self.columns) {
            return error.elementDoesNotExist;
        }

        const offset = (self.columns * (row - 1)) + column - 1;
        return self.data[offset];
    }

    pub fn naiveMult(allocator: std.mem.Allocator, matA: Matrix, matB: Matrix) !Matrix {
        if (matA.rows <= 0 or matA.columns <= 0 or matB.rows <= 0 or matB.columns <= 0) {
            return error.invalidDimension;
        } else if (matA.columns != matB.rows) {
            return error.invalidMultDimensions;
        }

        const rows = matA.rows;
        const columns = matB.columns;

        const numElements = rows * columns;
        const data = try allocator.alloc(f32, numElements);

        for (1..rows + 1) |i| {
            for (1..columns + 1) |j| {
                var sum: f32 = 0;
                for (1..matA.columns + 1) |k| {
                    sum += try matA.get(i, k) * try matB.get(k, j);
                }

                data[(columns * (i - 1)) + j - 1] = sum;
            }
        }

        return Matrix{
            .rows = rows,
            .columns = columns,
            .data = data,
        };
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const time = std.time;
    const Instant = time.Instant;

    var matA = try Matrix.rand(alloc, 5, 5);
    defer matA.deinit(alloc);

    const start = try Instant.now();

    // BASELINE 1
    var naiveMult = try Matrix.naiveMult(alloc, matA, matA);
    defer naiveMult.deinit(alloc);

    const end = try Instant.now();
    const elapsed: f64 = @floatFromInt(end.since(start));
    std.debug.print("Time Elapsed: {d:.3}ms\n", .{elapsed / time.ns_per_ms});
    std.debug.print("Data: {d:.3}\n", .{naiveMult.data});
}

test "validate naive" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var matA = try Matrix.zeros(alloc, 5, 5);
    defer matA.deinit(alloc);
    var matB = try Matrix.ones(alloc, 5, 5);
    defer matB.deinit(alloc);
    var resultA = try Matrix.naiveMult(alloc, matA, matB);
    defer resultA.deinit(alloc);

    try std.testing.expectEqualSlices(f32, matA.data, resultA.data);

    var matC = try Matrix.ones(alloc, 5, 5);
    defer matC.deinit(alloc);
    var matD = try Matrix.ones(alloc, 5, 5);
    defer matD.deinit(alloc);
    var resultB = try Matrix.naiveMult(alloc, matC, matD);
    defer resultB.deinit(alloc);

    const expectedResult = [_]f32{5} ** 25;

    try std.testing.expectEqualSlices(f32, &expectedResult, resultB.data);
}
