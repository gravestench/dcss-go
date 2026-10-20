-- Theory of operation: Xom's map changes its trap menu on the last branch
-- floor, where a shaft cannot lead lower. Depths also upgrades two monster
-- slot glyphs after the map's shared random substitutions have run.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Source ~ traps omit shafts only at the local branch bottom.
local function choose_traps(api)
    if api:depth() == api:branch_bottom() then
        api:emit(directives.KFEAT,
            "~ = teleport trap w:20 / alarm trap w:3 / dispersal trap")
    else
        api:emit(directives.KFEAT,
            "~ = shaft trap / teleport trap / alarm trap w:3 / dispersal trap")
    end
end

-- The late source substitution changes monster slots only in Depths.
local function deepen_monsters(api)
    if api:branch_id() == branches.BRANCH_DEPTHS then
        api:emit(directives.SUBST, "2 = 4, 3 = 5")
    end
end

handler.choose_traps = choose_traps
handler.deepen_monsters = deepen_monsters

return handler
