-- Theory of operation: Sif Muna's overflow guardian changes at source
-- absolute-depth thresholds. Jessica appears first, then wizardly orcs;
-- Depths substitutes a deep elf annihilator for the ordinary late orc.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Evaluate source branches in order; the Depths check only follows the
-- early-depth checks, so overlapping contexts keep the same precedence.
local function choose_scholar(api)
    if api:absolute_depth() <= 3 then
        api:emit(directives.MONS, "Jessica")
    elseif api:absolute_depth() <= 6 then
        api:emit(directives.MONS,
            "orc wizard w:15 / Blork the orc")
    elseif api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.MONS, "deep elf annihilator")
    else
        api:emit(directives.MONS, "orc wizard")
    end
end

handler.choose_scholar = choose_scholar

return handler
