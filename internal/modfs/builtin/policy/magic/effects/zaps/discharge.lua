local component = require("constants.component")
local spells = require("ids.spells")
local damage = require("policy.magic.damage")
local player_health = require("policy.combat.player_health")
local registry = require("policy.magic.effects.registry")

local discharge = {}

local directions = {
    { -1, -1 }, { 0, -1 }, { 1, -1 },
    { -1, 0 },               { 1, 0 },
    { -1, 1 },  { 0, 1 },  { 1, 1 },
}

local function random_round(ctx, numerator, denominator)
    local value = math.floor(numerator / denominator)

    if ctx:random("spell", denominator) < numerator % denominator then
        value = value + 1
    end

    return value
end

local function adjacent(ctx, position)
    local found = {}

    for _, delta in ipairs(directions) do
        local x = position.x + delta[1]
        local y = position.y + delta[2]
        local target = ctx:actor_at(position.level_id, x, y)

        if target then
            found[#found + 1] = target
        end
    end

    return found
end

local function select(ctx, found, count)
    -- spl-util.cc:apply_random_around_square chooses a uniform subset.
    for index = #found, 2, -1 do
        local other = 1 + ctx:random("spell", index)

        found[index], found[other] = found[other], found[index]
    end

    local chosen = {}

    for index = 1, math.min(count, #found) do
        chosen[#chosen + 1] = found[index]
    end

    return chosen
end

local function resistance(definition)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == "MR_RES_ELEC" then
            return entry.level
        end
    end

    return 0
end

local function arc(ctx, player, target, power, remaining)
    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return 0
    end

    local amount

    if target == player then
        local sides = 2 + random_round(ctx, power, 15)

        amount = 1 + ctx:random("spell", sides)
        amount = damage.player_elemental(ctx, player,
            amount, "MR_RES_ELEC")
        player_health.damage(ctx, player, amount)
        ctx:emit("spell", "You are struck by an arc of lightning!")
    else
        local definition = damage.monster(ctx, target)

        -- spl-damage.cc:_discharge_monsters does not hit or propagate
        -- through any monster with positive rElec.
        if resistance(definition) > 0 then
            return 0
        end

        local sides = 4 + random_round(ctx, power, 8)

        amount = 3 + ctx:random("spell", sides)
        amount = damage.monster_elemental(ctx, target,
            amount, "MR_RES_ELEC")
        damage.apply(ctx, target, amount)
        ctx:emit("spell", "The " .. definition.name ..
            " is struck by an arc of lightning!")
    end

    if remaining > 0 then
        local position = ctx:get(target, component.POSITION)

        if position then
            local around = select(ctx, adjacent(ctx, position), 1)

            for _, next_target in ipairs(around) do
                amount = amount + arc(ctx, player, next_target,
                    power, remaining - 1)
            end
        end
    elseif amount > 0 then
        ctx:emit("spell", "The lightning grounds out.")
    end

    return amount
end

function discharge.resolve(ctx, player, _, _, power)
    local position = ctx:get(player, component.POSITION)
    local limit = 2 + random_round(ctx, power, 20)
    local targets = select(ctx, adjacent(ctx, position),
        1 + ctx:random("spell", limit))
    local total = 0

    for _, target in ipairs(targets) do
        local remaining = 1 + ctx:random("spell", limit)

        total = total + arc(ctx, player, target, power, remaining)
    end

    if total == 0 then
        ctx:emit("spell", "The air crackles with electrical energy.")
    end
end

registry.add(spells.SPELL_DISCHARGE, discharge)

return discharge
