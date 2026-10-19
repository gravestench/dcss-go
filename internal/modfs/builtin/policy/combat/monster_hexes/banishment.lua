local catalog = require("policy.catalog")
local component = require("constants.component")
local abyss = require("policy.world.abyss")

local banishment = {}

function banishment.apply(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        abyss.banish(ctx, defender)

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    abyss.banish_monster(ctx, defender, definition)
end

return banishment
