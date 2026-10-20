-- The bead-shaped Temple uses its selected count to preserve that many
-- altars from a larger D-glyph pool, then turns the rest into decoration.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the source NSUBST between the preceding dash substitution and
-- following E/F substitutions, so the same glyphs are transformed.
local function configure(api)
    api:emit(directives.NSUBST,
        "D = " .. count.selected(api) .. ":B / *:tGTbbVn")
end

handler.configure = configure

return handler
