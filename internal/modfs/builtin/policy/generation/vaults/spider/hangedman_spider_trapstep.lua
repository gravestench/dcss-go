-- Trapstep is shared by shallow Spider and Zot. Source branches on the
-- placement branch: Zot gets zot traps and ghost moths, while Spider
-- keeps shaft, web, tarantella, and orb-spider choices.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve source directive order within each branch because later
-- substitutions and keyed records refer to the chosen earlier glyphs.
local function zot(api)
    api:emit(directives.KMONS,
        "2* = jumping spider / orb spider w:5")
    api:emit(directives.KMONS,
        "3| = ghost moth / moth of wrath")
    api:emit(directives.KITEM, "| = any good_item")
    api:emit(directives.KFEAT, "` = zot trap")
    api:emit(directives.KFEAT,
        "^ = web trap w:8 / any trap w:1 / . w:7")

    if api:depth() == api:branch_bottom() - 1 then
        api:emit(directives.KFEAT,
            "~ = zot trap w:20 / web trap / . w:5")
    else
        api:emit(directives.KFEAT,
            "~ = zot trap w:15 / shaft trap / web trap w:5 / . w:5")
    end

    api:emit(directives.NSUBST, "4 = 1:122 / 1:112")
    api:emit(directives.SUBST, "X = c")
end

-- The Spider arm is independent of Zot depth and makes shallow floors
-- visibly webbed while still allowing a shaft in some source slots.
local function spider(api)
    api:emit(directives.KMONS, "2 = tarantella")
    api:emit(directives.KMONS, "3 = orb spider")
    api:emit(directives.KITEM,
        "| = superb_item / any good_item w:5")
    api:emit(directives.KFEAT, "` = shaft trap")
    api:emit(directives.KFEAT,
        "^ = web w:9 / web trap w:1 / . w:6")
    api:emit(directives.KFEAT,
        "~ = shaft trap w:15 / web / . w:5")
    api:emit(directives.NSUBST, "4 = 1:2 / *:W")
    api:emit(directives.SUBST, "X = x")
end

-- The DES retains unconditional treasure, water, mask, and floor rules.
local function configure(api)
    if api:branch_id() == branches.BRANCH_ZOT then
        zot(api)
    else
        spider(api)
    end
end

handler.configure = configure

return handler
