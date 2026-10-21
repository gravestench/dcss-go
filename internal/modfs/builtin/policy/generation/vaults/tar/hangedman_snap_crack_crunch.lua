-- The source chooses one keyed monster set for Tartarus and another for Zot.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit only the branch's declarations at their original position before
-- the shared monster slots and terrain substitutions are applied.
local function branch_monsters(api)
    if api:branch_id() == branches.BRANCH_TARTARUS then
        api:emit(directives.KMONS, "12 = patrolling bone dragon")
        api:emit(directives.KMONS, "34 = patrolling tormentor")
        api:emit(directives.KMONS, "56 = patrolling profane servitor")
        api:emit(directives.KMONS, "7 = eidolon")
        api:emit(directives.KMONS, "8 = patrolling shadow wraith")
        api:emit(directives.KMONS, "AB = ancient lich / dread lich")
        api:emit(directives.KMONS, "CD : doom hound")
        api:emit(directives.KMONS, "EF : putrid mouth")
        api:emit(directives.KITEM, "| = nothing")

        return
    end

    api:emit(directives.KMONS,
        "12 = patrolling lich / ancient lich / dread lich")
    api:emit(directives.KMONS, "34 = patrolling curse toe")
    api:emit(directives.KMONS, "56 = patrolling bone dragon")
    api:emit(directives.KMONS,
        "7 = death cob w:12 / zombie w:4 / skeleton w:4 / guardian mummy w:4")
    api:emit(directives.KMONS, "8 = patrolling death cob")
    api:emit(directives.KMONS, "ABCD = shadow dragon")
    api:emit(directives.KMONS, "EF = death drake")
end

handler.branch_monsters = branch_monsters

return handler
