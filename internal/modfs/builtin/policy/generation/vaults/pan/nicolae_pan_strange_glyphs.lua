-- Theory of operation: one source draw chooses how many of the five
-- authored glyph pairs remain before SUBVAULT fills the surviving slots.
-- The map geometry and child requests stay in the companion DES file.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit conditional substitutions in the original order. Drawing once is
-- significant: four separate rolls would change both the distribution
-- of surviving glyphs and later choices on the vault layout stream.
local function choose_count(api)
    local count = api:roll(15)

    if count < 13 then
        api:emit(directives.SUBST, "Ee = _")
    end

    if count < 8 then
        api:emit(directives.SUBST, "Dd = _")
    end

    if count < 3 then
        api:emit(directives.SUBST, "Cc = _")
    end

    if count < 1 then
        api:emit(directives.SUBST, "Bb = _")
    end
end

handler.choose_count = choose_count

return handler
