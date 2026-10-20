-- Theory of operation: several overflow maps use a shaft as a local trap
-- only when another floor exists below them. Keep the branch-bottom rule
-- shared while preserving each map's source glyph and hook position.
local directives = require("constants.vault_directives")

local handler = {}

-- The source caret glyph is a shaft except on the branch's final floor.
local function shaft_caret(api)
    if api:depth() ~= api:branch_bottom() then
        api:emit(directives.KFEAT, "^ = shaft trap")
    end
end

-- Nemelex uses a instead of the usual caret for the same shaft rule.
local function shaft_a(api)
    if api:depth() ~= api:branch_bottom() then
        api:emit(directives.KFEAT, "a = shaft trap")
    end
end

handler.shaft_caret = shaft_caret
handler.shaft_a = shaft_a

return handler
