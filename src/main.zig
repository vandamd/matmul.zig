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
                    sum = sum + (try matA.get(i, k) * try matB.get(k, j));
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

    var matA = try Matrix.full(alloc, 5, 2, 4);
    defer matA.deinit(alloc);

    var matB = try Matrix.full(alloc, 2, 2, 2);
    defer matB.deinit(alloc);

    var naiveMult = try Matrix.naiveMult(alloc, matA, matB);
    defer naiveMult.deinit(alloc);
    std.debug.print("mult produced: {d}\n", .{naiveMult.data});
}
