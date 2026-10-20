-- Theory of operation: three Cheibriados maps and two mausoleum maps use
-- identical source branch choices. They call these shared methods at their
-- own DES positions, preserving both map ownership and one place for each
-- repeated rule. Every emitted monster spec is interpreted by the same
-- vault engine as a literal MONS or KMONS directive.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Depths replaces the slower early-Dungeon guardians with an iron golem.
local function cheibriados(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.KMONS, "_ = iron golem")
    else
        api:emit(directives.KMONS, "_ = worm / mummy / iron imp")
    end
end

-- Crypt's native undead are stronger than the same mausoleum in Dungeon.
local function mausoleum(api)
    if api:branch_id() == branches.BRANCH_CRYPT then
        api:emit(directives.MONS,
            "zombie, guardian mummy, skeletal warrior, ghoul")
    else
        api:emit(directives.MONS,
            "zombie, mummy, wight, necrophage")
    end
end

handler.cheibriados = cheibriados
handler.mausoleum = mausoleum

return handler
