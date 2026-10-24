-- Source monster::stasis is an intrinsic trait of the Formicid genus.
-- Keep the optional catalog flag for mods that grant the same immunity.
local flags = require("constants.monster_flags")
local monsters = require("ids.monsters")

local stasis = {}

-- Enchantment callers use this before rolling willpower or duration.
function stasis.intrinsic(definition)
    if definition.genus_id == monsters.MONS_FORMICID then
        return true
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STASIS then
            return true
        end
    end

    return false
end

return stasis
