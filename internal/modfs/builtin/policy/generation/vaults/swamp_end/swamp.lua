-- Theory of operation: the standard Swamp ending is usually guarded by an
-- ordinary dragon or hydra. One time in eleven the original DES script
-- changes its O slot into the Lernaean hydra's & slot. The rune's KITEM
-- declaration already covers both glyphs, so one item remains.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the source substitution at its DES position only on the rare draw.
local function rare_lernaean_hydra(api)
    if api:one_in(11) then
        api:emit(directives.SUBST, "4 = .:999 4:1, O = &")
    end
end

handler.rare_lernaean_hydra = rare_lernaean_hydra

return handler
