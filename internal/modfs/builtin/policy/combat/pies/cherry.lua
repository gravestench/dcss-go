local component = require("constants.component")
local damage = require("policy.magic.damage")
local fillings = require("constants.pie_fillings")
local resistances = require("constants.resistance_ids")

local cherry = {
    id = fillings.CHERRY,
    weight = 6,
}

function cherry.valid(ctx, target)
    if ctx:has(target, component.PLAYER) then
        return true
    end

    return damage.monster_elemental(ctx, target,
        10, resistances.FIRE) > 0
end

function cherry.apply(ctx, _, target)
    local player = ctx:has(target, component.PLAYER)
    local draw = ctx:random("monster_spell", 11)
    local added = player and (15 + draw) * 10 or 15 + draw * 10
    local state = ctx:get(target, component.FIRE_VULNERABILITY)
    local remaining = (state and state.remaining_aut or 0) + added

    if player then
        remaining = math.min(500, remaining)
    end

    if state then
        state.remaining_aut = remaining
        ctx:set(target, component.FIRE_VULNERABILITY, state)
    else
        ctx:add(target, component.FIRE_VULNERABILITY, {
            remaining_aut = remaining,
        })
    end

    if player then
        ctx:emit("combat", "Cherry flames burn away your fire resistance!")
    else
        ctx:emit("combat", "The monster looks more vulnerable to fire.")
    end
end

return cherry
