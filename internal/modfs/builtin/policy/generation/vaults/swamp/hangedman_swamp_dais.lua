-- Theory of operation: the dais is shared by Swamp and Zot. Source Lua
-- chooses an entire branch-specific actor and terrain palette at one
-- declaration site. The DES MAP itself remains the same in both branches.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Swamp uses native swamp creatures and mangroves; Zot uses draconians,
-- abominations, and their source shuffle before common map operations.
local function configure_branch(api)
    if api:branch_id() == branches.BRANCH_SWAMP then
        api:emit(directives.MONS,
            "swamp drake, hydra, swamp dragon")
        api:emit(directives.KMONS, "A = swamp dragon")
        api:emit(directives.KMONS, "B = green draconian")
        api:emit(directives.SUBST, "x = t")
        api:emit(directives.NSUBST,
            "1 = 2 / 3 / * = 1:80 23")

        return
    end

    api:emit(directives.KMONS, "1 = green draconian")
    api:emit(directives.KMONS, "a = death drake")
    api:emit(directives.KMONS,
        "A = tentacled monstrosity / green death")
    api:emit(directives.KMONS,
        "B = green draconian stormcaller")
    api:emit(directives.KMONS,
        "% = ugly thing / orange demon")
    api:emit(directives.KMONS,
        "*d = swamp dragon w:8 / seven-headed hydra w:5 / " ..
        "eight-headed hydra w:5")
    api:emit(directives.KMONS,
        "| = large abomination / tentacled monstrosity w:5")
    api:emit(directives.SHUFFLE, "A%| / ad*")
end

handler.configure_branch = configure_branch

return handler
