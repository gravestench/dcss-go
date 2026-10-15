local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")

local energy = {}

energy.threshold = 80
energy.initial = 70

local costs = {
    [1] = "move",
    [2] = "attack",
    [6] = "wait",
    [12] = "spell",
    [13] = "missile",
}

local function valid_integer(value)
    return type(value) == "number" and value == math.floor(value)
end

function energy.grant(ctx, input)
    local elapsed = input.elapsed

    if not valid_integer(elapsed) or elapsed <= 0 then
        error("invalid player action time " .. tostring(elapsed))
    end

    local points = {}

    for index, monster in ipairs(input.monsters) do
        local current = monster.points

        if monster.level_id == input.active_level then
            local speed = monster.speed

            if not valid_integer(speed) or speed <= 0 then
                error("invalid monster speed " .. tostring(speed))
            end

            local product = speed * elapsed

            if not valid_integer(product) then
                error("invalid monster energy product")
            end

            local gain = math.floor(product / 10)
            local remainder = product % 10

            if remainder ~= 0 then
                local roll = ctx:random("monster_energy", 10)

                if not valid_integer(roll) or roll < 0 or roll >= 10 then
                    error("monster energy draw " .. tostring(roll) .. " outside [0,10)")
                end

                if roll < remainder then
                    gain = gain + 1
                end
            end

            points[index] = current + math.max(1, gain)
        else
            points[index] = current
        end
    end

    return { points = points }
end

function energy.next_ready(input)
    local chosen = 0
    local most = energy.threshold - 1

    -- Candidates arrive in ascending entity order; retaining the first
    -- equal score reproduces the source pointer-order tie break.
    for index, monster in ipairs(input.monsters) do
        if monster.level_id == input.active_level and monster.points > most then
            chosen = index
            most = monster.points
        end
    end

    return { index = chosen }
end

local function speed_brand_cost(ctx, input, field, base_cost)
    if not input.actor then
        return base_cost
    end

    local actor = ctx:entity(input.actor)
    local brand

    if field == "attack" then
        local weapon = equipment.monster_melee(ctx, actor)
        brand = weapon and weapon.brand
    elseif field == "missile" and input.item_id and input.item_id ~= 0 then
        local item = ctx:entity(input.item_id)
        local worn = equipment.worn(ctx, actor, {
            weapon = true,
            alternate_weapon = true,
            missile = true,
        })

        for _, slot in ipairs({ "weapon", "alternate_weapon" }) do
            local selected = worn[slot]
            local weapon = selected and selected.definition.weapon

            if selected and selected.entity == item and weapon and
                weapon.ammo_id ~= "MI_NONE" then
                brand = selected.item.ego
                break
            end
        end
    end

    if brand ~= "SPWPN_SPEED" then
        return base_cost
    end

    -- monster.cc:400-411 applies speed to melee and launcher shots,
    -- but not thrown missiles. The 10-aut delay becomes random 6/7.
    local delay = ctx:random("monster_energy", 3) < 2 and 7 or 6
    local product = base_cost * delay
    local cost = math.floor(product / 10)
    local remainder = product % 10

    if remainder > 0 and ctx:random("monster_energy", 10) < remainder then
        cost = cost + 1
    end

    return math.max(1, cost)
end

function energy.spend(ctx, input)
    if input.points < energy.threshold then
        error("monster lacks action energy")
    end

    local field = costs[input.intent]

    if not field then
        error("unsupported monster action " .. tostring(input.intent))
    end

    local usage = catalog.get("monsters", input.kind_id).energy
    local cost = field == "wait" and math.min(usage.move, usage.swim) or usage[field]

    if not valid_integer(cost) or cost <= 0 then
        error("monster action " .. input.intent .. " has invalid energy cost " .. tostring(cost))
    end

    if field == "attack" or field == "missile" then
        cost = speed_brand_cost(ctx, input, field, cost)
    end

    return { points = input.points - cost, cost = cost }
end

register.policy({
    id = "scheduler.grant",
    run = function(ctx, input)
        return energy.grant(ctx, input)
    end,
})

register.policy({
    id = "scheduler.next_ready",
    run = function(_, input)
        return energy.next_ready(input)
    end,
})

register.policy({
    id = "scheduler.spend",
    run = function(ctx, input)
        return energy.spend(ctx, input)
    end,
})

return energy
