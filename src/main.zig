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
        @memset(data, fill_value);

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
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var zeros = try Matrix.zeros(alloc, 5, 5);
    defer zeros.deinit(alloc);
    std.debug.print("zeros produced: {any}\n", .{zeros});

    var ones = try Matrix.ones(alloc, 2, 2);
    defer ones.deinit(alloc);
    std.debug.print("ones produced: {any}\n", .{ones});

    var twenties = try Matrix.full(alloc, 2, 2, 20);
    defer twenties.deinit(alloc);
    std.debug.print("twenties produced: {d}\n", .{twenties.data});
}
