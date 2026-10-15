local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local player_attributes = require("policy.character.attributes")
local roll = require("policy.combat.roll")
local items = require("policy.inventory.items")

local delay = {}

local function rounded_values(numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator
    local values = {
        { value = whole, weight = denominator - remainder },
    }

    if remainder > 0 then
        values[#values + 1] = { value = whole + 1, weight = remainder }
    end

    return values
end

function delay.minimum_weapon(speed, skill_id)
    local minimum = math.floor(speed / 2)

    if skill_id == "SK_SHORT_BLADES" then
        minimum = math.min(minimum, 5)
    end

    return math.max(3, math.min(minimum, 7), speed - 14)
end

function delay.minimum_skill(speed, skill_id)
    return 2 * (speed - delay.minimum_weapon(speed, skill_id))
end

function delay.minimum_launcher(kind)
    local weapon = kind.weapon
    local minimum = delay.minimum_weapon(weapon.speed, weapon.skill_id)

    -- fight.cc:912-960 gives crossbows a 10 aut minimum and longbows 6.
    if weapon.ammo_id == "MI_BOLT" then
        return math.max(10, minimum)
    end

    if kind.id == "WPN_LONGBOW" then
        return 6
    end

    return minimum
end

local function action_cost(ctx, time_taken, base, reduction, denominator,
    shield_penalty20, minimum, armour_penalty20, speed_brand)
    local weights = {}
    local low = math.huge
    local high = 0
    local armour_values = armour_penalty20 and
        rounded_values(armour_penalty20, 20) or { { value = 0, weight = 1 } }

    for _, skill in ipairs(rounded_values(reduction, denominator)) do
        for _, shield in ipairs(rounded_values(shield_penalty20, 20)) do
            for _, armour in ipairs(armour_values) do
                local attack = math.max(minimum, base - skill.value)
                local speed_values = speed_brand and
                    rounded_values(attack * 2, 3) or { { value = attack, weight = 1 } }

                for _, speed in ipairs(speed_values) do
                    local action = math.max(2, speed.value + shield.value + armour.value)

                    for _, scaled in ipairs(rounded_values(action * time_taken, 10)) do
                        local value = math.max(2, scaled.value)
                        weights[value] = (weights[value] or 0) +
                            skill.weight * shield.weight * armour.weight *
                            speed.weight * scaled.weight
                        low = math.min(low, value)
                        high = math.max(high, value)
                    end
                end
            end
        end
    end

    local total = 0

    for value = low, high do
        total = total + (weights[value] or 0)
    end

    local draw = roll.melee(ctx, total)

    for value = low, high do
        if draw < (weights[value] or 0) then
            return value
        end

        draw = draw - (weights[value] or 0)
    end

    error("attack delay distribution was empty")
end

local function shield_penalty(ctx)
    local worn = equipment.worn(ctx, ctx:player(), { shield = true })
    local shield_ev = worn.shield and worn.shield.definition.armour.ev or 0
    local shields10 = fighter.skill(ctx, "SK_SHIELDS", 10)
    local shield_base = math.floor(-shield_ev / 10)

    return math.floor(
        2 * shield_base ^ 2 * (270 - shields10) * 20 / 100 / 270)
end

function delay.player(ctx, time_taken)
    local attack = fighter.attack(ctx, { ev = 0, ac = 0 })
    local weapon10 = fighter.skill(ctx, attack.weapon_skill, 10)
    local base = attack.unarmed and 10 or attack.weapon_speed
    local reduction = weapon10
    local denominator = 54

    if attack.held_non_melee then
        base = 15
        reduction = 0
        denominator = 20
    elseif not attack.unarmed then
        local minimum = delay.minimum_weapon(attack.weapon_speed, attack.weapon_skill)
        reduction = math.min(weapon10, 20 * (attack.weapon_speed - minimum))
        denominator = 20
    end

    -- The source combines random_var distributions before making one melee draw.
    return action_cost(ctx, time_taken, base, reduction, denominator,
        shield_penalty(ctx), 3, nil, false)
end

function delay.projectile(ctx, time_taken, item_id)
    local entity = ctx:entity(item_id)
    local item = ctx:get(entity, "core.item")

    if not item then
        error("ranged action has no projectile item")
    end

    local kind = items.kind(item)
    local base = 0
    local reduction = 0
    local minimum = 7
    local armour_penalty20
    local speed_brand = false

    if kind.class == "OBJ_MISSILES" then
        base = 10 + math.floor(kind.missile.damage / 2)
        reduction = fighter.skill(ctx, "SK_THROWING", 10)
    elseif kind.class == "OBJ_WEAPONS" and kind.weapon then
        base = kind.weapon.speed
        local skill_id = kind.weapon.skill_id
        local skill10 = fighter.skill(ctx, skill_id, 10)
        local minimum_delay = delay.minimum_launcher(kind)

        reduction = math.min(skill10, 20 * (base - minimum_delay))
        minimum = 3
        speed_brand = item.ego == "SPWPN_SPEED"

        local worn = equipment.worn(ctx, ctx:player(), { body = true })
        local body = worn.body and worn.body.definition.armour or nil
        local encumbrance = body and math.max(0, math.floor(-body.ev / 10)) or 0
        local attributes = player_attributes.current(ctx, ctx:player())
        local armour10 = fighter.skill(ctx, "SK_ARMOUR", 10)
        armour_penalty20 = math.floor(2 * encumbrance ^ 2 *
            (450 - armour10) * 20 / (5 * (attributes.strength + 3)) / 450)
    else
        error("ranged action has invalid projectile item")
    end

    return action_cost(ctx, time_taken, base, reduction, 20,
        shield_penalty(ctx), minimum, armour_penalty20, speed_brand)
end

return delay
