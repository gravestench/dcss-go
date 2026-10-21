-- Theory of operation: Jude's first Swamp pool smears its water outline
-- before its source SUBST turns the temporary edge glyph into vegetation.
-- The typed geometry operation uses the vault layout RNG at this DES site.
local effects = require("constants.vault_effects")

local handler = {}

-- Five rounds grow water into the current water, tree, or edge glyphs.
local function smear(api)
    api:record(effects.SMEAR_MAP, {
        iterations = 5,
        smear = "w",
        onto = 'wwt"',
        boxy = false,
    })
end

handler.smear = smear

return handler
