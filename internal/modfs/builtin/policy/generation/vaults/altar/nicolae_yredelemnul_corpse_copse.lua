-- Theory of operation: this corpse grove uses the current absolute depth
-- to vary how often open floor becomes a zombie slot. The source wrote an
-- NSUBST expression dynamically; keep its depth local to this placement.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the original weighted glyph expression before altar and tree rules.
local function scale_zombie_slots(api)
    api:emit(directives.NSUBST,
        ". = " .. api:absolute_depth() .. "=1 / 1=1. / .")
end

handler.scale_zombie_slots = scale_zombie_slots

return handler
