-- Theory of operation: this rats' nest has separate Lair and Dungeon
-- density rules. The late Dungeon branch makes the fourth slot more likely.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Source uses NSUBST for exact slot counts before ordinary substitutions.
local function configure(api)
    if api:branch_id() == branches.BRANCH_LAIR then
        api:emit(directives.NSUBST,
            "4 = 1:4 / * = 40, 3 = 2:3 / * = 34.")
        api:emit(directives.NSUBST,
            "2 = 2:2 / * = 224., 1 = 2:1 / * = 13.")
        api:emit(directives.CLEAR, "\"")

        return
    end

    api:emit(directives.SUBST, "\" = x")
    api:emit(directives.NSUBST,
        "1 = 2:1 / * = 1., 2 = 2:2 / * = 2., 3 = 2:3 / * = 3.")

    if api:absolute_depth() > 6 then
        api:emit(directives.SUBST, "4 = 430")
    else
        api:emit(directives.SUBST, "4 = 30")
    end
end

handler.configure = configure

return handler
