-- Gehenna, Cocytus, and Zot share this stream geometry but populate it
-- with different threats and substitute its liquid by branch.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the branch-specific source directives before common shuffles run.
function handler.configure(api)
    local branch_id = api:branch_id()

    if branch_id == branches.BRANCH_GEHENNA then
        api:emit(directives.KMONS, "1 = brimstone fiend")
        api:emit(directives.KMONS, "2 = searing wretch / balrug")
        api:emit(directives.KMONS, "34 = fire giant / hellephant w:5")
        api:emit(directives.KMONS,
            "56 = ancient champion ; broad axe ego:flaming ident:type | " ..
            "halberd ego:flaming ident:type w:7 | " ..
            "morningstar ego:flaming ident:type")
        api:emit(directives.KMONS, "7 = hell hog")
        api:emit(directives.SUBST, "w = l, W = .")
        api:emit(directives.KPROP, "l = no_cloud_gen")
    elseif branch_id == branches.BRANCH_COCYTUS then
        api:emit(directives.KMONS, "1 = ice fiend")
        api:emit(directives.KMONS, "2 = wendigo band / nargun")
        api:emit(directives.KMONS, "34 = frost giant / shard shrike w:5")
        api:emit(directives.KMONS,
            "56 = reaper ; halberd itemname:scythe tile:wpn_scythe " ..
            "wtile:scythe ego:freezing ident:type")
        api:emit(directives.KMONS, "7 = simulacrum")
        api:emit(directives.SUBST, "l = w, W = .")
    elseif branch_id == branches.BRANCH_ZOT then
        api:emit(directives.KMONS, "1 = shard shrike")
        api:emit(directives.KMONS,
            "2 = seven-headed hydra simulacrum / " ..
            "eight-headed hydra simulacrum")
        api:emit(directives.KMONS, "3 = orb of fire / hellephant w:5")
        api:emit(directives.KMONS, "4 = draconian scorcher")
        api:emit(directives.KMONS,
            "5 = red draconian ; cloak . mace ego:freezing ident:type")
        api:emit(directives.KMONS,
            "6 = white draconian ; cloak . mace ego:flaming ident:type")
        api:emit(directives.KFEAT, "1 = w")
        api:emit(directives.KFEAT, "3 = l")
        api:emit(directives.NSUBST, "0 = 1:5 / 1:6")
        api:emit(directives.SUBST, "x : x:9 b:1, 7 = .")
    else
        error("elemental grid stream needs Gehenna, Cocytus, or Zot")
    end
end

return handler
