-- Theory of operation: this forgotten Yredelemnul altar places a spectral
-- guard at its altar glyph. Depths gets a juggernaut; Dungeon gets an orc.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- The chosen KMONS remains keyed to _, beside its source altar feature.
local function choose_guard(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.KMONS, "_ = spectral juggernaut")
    else
        api:emit(directives.KMONS, "_ = spectral orc")
    end
end

handler.choose_guard = choose_guard

return handler
