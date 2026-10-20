-- Theory of operation: this second Okawaru gauntlet draws one equipped
-- attacker from a branch-specific pool. Keep each source equipment string
-- with its monster so the vault engine can materialize the complete guard.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit one MONS slot; a later draw chooses an attacker within that slot.
local function choose_attacker(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.MONS,
            "spriggan defender ; flail . robe . buckler . boomerang w:3 / " ..
            "tengu warrior ; long sword . leather armour . buckler . boomerang")
    else
        api:emit(directives.MONS,
            "goblin; stone q:5 / hobgoblin; stone q:5 / " ..
            "gnoll; stone q:5 / orc; stone q:5 / kobold; stone q:5")
    end
end

handler.choose_attacker = choose_attacker

return handler
