local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local liquefaction = require("policy.magic.effects.translocation.liquefaction")
local statuses = require("policy.magic.effects.statuses.player")
local ammunition = require("ids.ammunition")
local component = require("constants.component")
local brands = require("constants.weapon_brands")
local chaos_status = require("policy.combat.player_brands.chaos_status")

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

-- Scheduler points and costs must be integral to preserve deterministic action order.
local function valid_integer(value)
    return type(value) == "number" and value == math.floor(value)
end

-- Example: energy.grant(ctx, { elapsed = 10 }) credits each active monster for ten aut.
-- Credit only actors on the active level and retain fractional speed through
-- a named RNG draw, so fast and slow monsters keep their source cadence.
function energy.grant(ctx, input)
    local elapsed = input.elapsed

    if not valid_integer(elapsed) or elapsed <= 0 then
        error("invalid player action time " .. tostring(elapsed))
    end

    local points = {}

    for index, monster in ipairs(input.monsters) do
        local current = monster.points
        local active = monster.level_id == input.active_level
        local actor = active and monster.entity and
            ctx:entity(monster.entity)
        local passive = actor and ctx:has(actor,
            component.SPECTRAL_WEAPON)

        if active and not passive then
            local speed = monster.speed

            if actor then
                speed = statuses.frenzy_speed(ctx, actor, speed)
                speed = chaos_status.speed(ctx, actor, speed)
            end

            if not valid_integer(speed) or speed < 0 then
                error("invalid monster speed " .. tostring(speed))
            end

            if speed == 0 then
                -- Source stationary actors keep their energy below the
                -- action threshold, even while other monsters take turns.
                points[index] = current
            else
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
            end
        else
            points[index] = current
        end
    end

    return { points = points }
end

-- Keep the first equal-score monster in host entity order for a stable tie break.
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

-- The speed brand changes melee and launcher costs with the monster-energy RNG stream.
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
                weapon.ammo_id ~= ammunition.NONE then
                brand = selected.ego
                break
            end
        end
    end

    if brand ~= brands.SPEED then
        return base_cost
    end

    -- monster.cc applies speed to melee and launcher shots,
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

-- Deduct the selected intent's cost after terrain, brand, and status modifiers.
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
    elseif field == "move" and input.actor then
        local actor = ctx:entity(input.actor)
        local position = ctx:get(actor, "core.position")

        if position and liquefaction.at(ctx, position.level_id,
            position.x, position.y) then
            cost = cost + 6
        end

        -- monster.cc:monster::energy_cost adds four movement energy while
        -- ENCH_FROZEN is active. Attacks and spells keep their usual cost.
        if ctx:has(actor, component.FLASH_FROZEN) then
            cost = cost + 4
        end
    end

    if input.actor and statuses.petrifying(ctx,
        ctx:entity(input.actor)) then
        cost = math.floor(cost * 3 / 2)
    end

    return { points = input.points - cost, cost = cost }
end

-- Adapt the scheduler's policy signature without a second readiness rule.
function energy.next_ready_policy(_, input)
    return energy.next_ready(input)
end

register.policy({
    id = "scheduler.grant",
    run = energy.grant,
})

register.policy({
    id = "scheduler.next_ready",
    run = energy.next_ready_policy,
})

register.policy({
    id = "scheduler.spend",
    run = energy.spend,
})

return energy
