local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local senses = require("policy.character.senses")

local repulsion = {}

-- A saved marker distinguishes dispellable magical repulsion from innate EV.
function repulsion.active(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_REPULSION)

    return state ~= nil and state.active
end

-- The caster cannot stack or refresh source ENCH_REPEL_MISSILES.
function repulsion.apply(ctx, monster)
    if repulsion.active(ctx, monster) then
        return false
    end

    ctx:add(monster, component.MONSTER_REPULSION, {
        active = true,
    })

    if senses.player_sees_actor(ctx, monster) then
        ctx:emit("spell", "The " .. display.name(ctx, monster) ..
            " begins repelling missiles!")
    end

    return true
end

return repulsion
