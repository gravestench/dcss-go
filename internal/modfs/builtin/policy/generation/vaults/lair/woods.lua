-- Theory of operation: Wad's woods maps share authored vegetation, terrain,
-- and fog in DES. This hook chooses only the monster population that depends
-- on the current branch and absolute depth. Each map calls it at the same
-- source position as wad_woods_setup so later MONS directives keep order.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local woods = {}

-- Lair forests use spriggans with beasts that grow tougher deeper in the
-- world. Dungeon forests instead use four depth bands from the source.
local function populate(api)
    local absolute_depth = api:absolute_depth()

    if api:branch_id() == branches.BRANCH_LAIR then
        api:emit(directives.MONS, "spriggan")

        if absolute_depth >= 14 then
            api:emit(directives.MONS, "wolf / black bear w:4 / yak w:2")
        else
            api:emit(directives.MONS,
                "wyvern / elephant w:4 / dream sheep w:2")
        end

        return
    end

    if absolute_depth >= 12 then
        api:emit(directives.MONS, "centaur warrior / two-headed ogre")
        api:emit(directives.MONS, "hell rat")
    elseif absolute_depth >= 8 then
        api:emit(directives.MONS, "centaur / troll")
        api:emit(directives.MONS, "elephant")
    elseif absolute_depth >= 5 then
        api:emit(directives.MONS, "gnoll / ogre w:1")
        api:emit(directives.MONS, "river rat")
    else
        api:emit(directives.MONS, "gnoll")
        api:emit(directives.MONS, "quokka")
    end
end

woods.populate = populate

return woods
