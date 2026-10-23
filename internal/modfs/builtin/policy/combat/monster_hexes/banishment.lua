local catalog = require("policy.catalog")
local component = require("constants.component")
local abyss = require("policy.world.abyss")

local banishment = {}

-- Example: banishment.apply(ctx, nil, defender) with player defender -> player moves to Abyss
-- Banishment uses different world transitions for a player and a monster defender.
function banishment.apply(ctx, caster, defender)
    if ctx:has(defender, component.PLAYER) then
        abyss.banish(ctx, defender)

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    abyss.banish_monster(ctx, defender, definition, caster)
end

return banishment
