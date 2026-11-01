// lib.zig — src 模块汇聚点，供 tools/ 下的验收工具以 @import("sax3d") 消费。
pub const model = @import("model.zig");
pub const parse = @import("parse.zig");
pub const ifacemod = @import("iface.zig");
pub const checkmod = @import("check.zig");
pub const layout = @import("layout.zig");
pub const binio = @import("binio.zig");
pub const packform = @import("packform.zig");
pub const schema = @import("schema_gen.zig");
