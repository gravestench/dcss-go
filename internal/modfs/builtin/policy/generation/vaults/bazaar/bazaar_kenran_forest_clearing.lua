-- The forest clearing is usually living woods but rarely a dead grove.
-- This one-in-four source choice changes the trees, floor tint, and F cell together.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the dead-tree feature and colours paired, or choose their living counterparts.
local function choose_forest(api)
    if api:one_in(4) then
        api:emit(directives.KFEAT, [=[F = V]=])
        api:emit(directives.TILE,
            "t = dngn_tree_dead w:10 / dngn_tree_red w:3 / " ..
            "dngn_tree_lightred w:2")
        api:emit(directives.COLOUR, [=[. = brown, t = brown w:10 / red w:3 / lightred w:2]=])
    else
        api:emit(directives.TILE,
            "t = dngn_tree w:3 / dngn_tree_yellow w:2 / " ..
            "dngn_tree_lightred w:2 / dngn_tree_red w:3")
        api:emit(directives.KFEAT, [=[F = T]=])
        api:emit(directives.COLOUR,
            ". = green, t = green w:3 / lightgreen w:2 / " ..
            "lightred w:3 / red w:2 / brown w:1")
    end
end

handler.choose_forest = choose_forest

return handler
