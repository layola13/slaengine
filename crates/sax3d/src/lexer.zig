// lexer.zig — SAX3D 文本词法（创作形与编译形共用）。
// 编译形的名字以 #<idx> 出现，词法为 nameref token；其余 token 相同。

const std = @import("std");

pub const TokKind = enum { ident, number, string, nameref, punct };
pub const Tok = struct { kind: TokKind, text: []const u8, line: u32, col: u32 };

pub fn tokenize(alloc: std.mem.Allocator, src: []const u8) ![]Tok {
    var toks: std.ArrayList(Tok) = .empty;
    var i: usize = 0;
    var line: u32 = 1;
    var line_start: usize = 0;
    while (i < src.len) {
        const c = src[i];
        if (c == '\n') { line += 1; i += 1; line_start = i; continue; }
        if (std.ascii.isWhitespace(c)) { i += 1; continue; }
        if (c == '/' and i + 1 < src.len and src[i + 1] == '/') {
            while (i < src.len and src[i] != '\n') i += 1;
            continue;
        }
        const col: u32 = @intCast(i - line_start + 1);
        if (std.ascii.isAlphabetic(c) or c == '_') {
            const s = i;
            while (i < src.len and (std.ascii.isAlphanumeric(src[i]) or src[i] == '_' or src[i] == '-')) i += 1;
            try toks.append(alloc, .{ .kind = .ident, .text = src[s..i], .line = line, .col = col });
            continue;
        }
        if (std.ascii.isDigit(c) or (c == '-' and i + 1 < src.len and std.ascii.isDigit(src[i + 1]))) {
            const s = i;
            if (src[i] == '-') i += 1;
            while (i < src.len and (std.ascii.isDigit(src[i]) or src[i] == '.')) i += 1;
            try toks.append(alloc, .{ .kind = .number, .text = src[s..i], .line = line, .col = col });
            continue;
        }
        if (c == '"') {
            const s = i + 1;
            i += 1;
            while (i < src.len and src[i] != '"' and src[i] != '\n') i += 1;
            try toks.append(alloc, .{ .kind = .string, .text = src[s..i], .line = line, .col = col });
            if (i < src.len) i += 1; // closing quote
            continue;
        }
        if (c == '#') {
            const s = i + 1;
            i += 1;
            while (i < src.len and std.ascii.isDigit(src[i])) i += 1;
            try toks.append(alloc, .{ .kind = .nameref, .text = src[s..i], .line = line, .col = col });
            continue;
        }
        try toks.append(alloc, .{ .kind = .punct, .text = src[i .. i + 1], .line = line, .col = col });
        i += 1;
    }
    return toks.items;
}
