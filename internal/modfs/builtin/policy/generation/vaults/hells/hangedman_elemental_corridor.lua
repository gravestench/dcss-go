-- The corridor spans fire, ice, Abyss, and Zot; each branch changes its
-- monster tables and terrain before common trap and fog directives apply.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve source branch precedence and the order of its roster directives.
function handler.configure(api)
    local branch_id = api:branch_id()

    if branch_id == branches.BRANCH_GEHENNA then
        api:emit(directives.MONS, "brimstone fiend / hellephant")
        api:emit(directives.MONS,
            "searing wretch / balrug / stoker w:5")
        api:emit(directives.SUBST,
            "w = l, f = F, %* = ., 2 = 1, 3456 = 2")
    elseif branch_id == branches.BRANCH_COCYTUS then
        api:emit(directives.MONS, "ice fiend / shard shrike")
        api:emit(directives.MONS,
            "wendigo band / simulacrum w:20")
        api:emit(directives.SUBST,
            "l = w, F = f, %* = ., 2 = 1, 3456 = 2")
    elseif branch_id == branches.BRANCH_ABYSS then
        api:emit(directives.MONS,
            "blizzard demon / frost giant / dancing weapon ; " ..
            "battleaxe ego:freezing ident:type w:5")
        api:emit(directives.MONS,
            "simulacrum w:12 / white draconian / water elemental w:5 / " ..
            "white very ugly thing w:15 / ice devil w:8")
        api:emit(directives.MONS,
            "balrug / hellion / fire crab w:5 / hellephant w:5")
        api:emit(directives.MONS,
            "hell hound w:8 / red draconian / fire elemental w:5 / " ..
            "red very ugly thing w:15 / efreet w:12")
        api:emit(directives.SUBST,
            "* = *||, {} = ***|, xc = xxxccb, 5 = 2, 6 = 4")
    elseif branch_id == branches.BRANCH_ZOT then
        api:emit(directives.KMONS, "123 = fire dragon")
        api:emit(directives.KMONS, "456 = ice dragon")
        api:emit(directives.KMONS,
            "789 = red draconian ; cloak . long sword ego:freezing ident:type")
        api:emit(directives.KMONS,
            "ABC = white draconian ; cloak . long sword ego:flaming ident:type")
        api:emit(directives.KMONS, "D = golden dragon")
        api:emit(directives.SUBST, "c : c:5 b:2 n:1")
        api:emit(directives.SHUFFLE, "123456 / 1784AB / 789ABC / 1D'4D'")
    else
        error("elemental corridor needs Gehenna, Cocytus, Abyss, or Zot")
    end
end

return handler
