-- Theory of operation: the pit has one fiend at its center and lesser
-- demons around it. The source chooses those monster pools from the Hell
-- branch before the shared map substitutions and monster placement run.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

local pools = {
    [branches.BRANCH_DIS] = {
        "1 = hell sentinel",
        "2 = hell beast / hellion / reaper / tormentor / shadow demon / cacodemon",
    },
    [branches.BRANCH_GEHENNA] = {
        "1 = brimstone fiend",
        "2 = hell beast / hellion / reaper / tormentor / shadow demon / balrug",
    },
    [branches.BRANCH_COCYTUS] = {
        "1 = ice fiend",
        "2 = hell beast / hellion / reaper / tormentor / shadow demon / blizzard demon",
    },
    [branches.BRANCH_TARTARUS] = {
        "1 = tzitzimitl",
        "2 = hell beast / hellion / reaper / tormentor / shadow demon / green death / lorocyproca",
    },
}

-- Keep the source's two keyed declarations in their authored order. The
-- catalog branch ID, rather than the DES file name, selects the roster.
local function configure(api)
    local pool = pools[api:branch_id()]

    if not pool then
        error("Hell demon pit needs a Hell subbranch")
    end

    api:emit(directives.KMONS, pool[1])
    api:emit(directives.KMONS, pool[2])
end

handler.configure = configure

return handler
