-- Source: item-use.cc:SCR_IMMOLATION marks finite-will monsters in LOS.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flame = require("policy.magic.effects.zaps.inner_flame")
local item_ids = require("ids.items")
local scrolls = require("policy.scrolls")
local will = require("policy.magic.effects.zaps.will")

local effect = {}
local SIGHT_RADIUS = 7

-- Immolation chooses visible monsters during execution, so preparation needs no menu.
function effect.prepare()
    return nil
end

-- Example: Immolation marks a living visible rat but skips an invulnerable monster.
-- Mark only living, visible, finite-will monsters; report whether any mark took hold.
function effect.apply(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local marked = false

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)

            if health.current > 0 and
                position.level_id == origin.level_id and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    SIGHT_RADIUS, position.x, position.y) and
                not will.invulnerable(definition) and
                flame.mark(ctx, player, target) then
                marked = true
            end
        end
    end

    if marked then
        ctx:emit("read", "The creatures around you are filled with an inner flame!")
    else
        ctx:emit("read", "The air around you briefly surges with heat, but it dissipates.")
    end
end

scrolls.register(item_ids.SCR_IMMOLATION, effect)

return effect
