local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local player_attributes = require("policy.character.attributes")
local roll = require("policy.combat.roll")
local brands = require("constants.weapon_brands")
local items = require("policy.inventory.items")
local component = require("constants.component")
local artefact_properties = require("policy.item_generation.artefacts.properties")
local artefact_ids = require("ids.artefact_properties")
local okawaru_status = require("policy.religion.okawaru.status")

local delay = {}

-- Represent source random rounding as weighted neighboring integers so all
-- delay modifiers can be combined before the single melee-stream draw.
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

-- Source applies Finesse after shield and armour delay. If Haste already
-- shortened the player's turn, its 3/2 inverse runs before the halving
-- so two speed grants do not compound. Keep both rounding distributions.
local function finesse_values(action, active, hasted)
    if not active then
        return { { value = action, weight = 1 } }
    end

    local before = hasted and rounded_values(action * 3, 2) or
        { { value = action, weight = 1 } }
    local values = {}

    for _, boosted in ipairs(before) do
        for _, halved in ipairs(rounded_values(boosted.value, 2)) do
            values[#values + 1] = {
                value = halved.value,
                weight = boosted.weight * halved.weight,
            }
        end
    end

    return values
end

-- Both melee and projectile attacks read one patron timer and the same
-- Haste duration. Throwing, launchers, and unarmed blows then share policy.
local function okawaru_mode(ctx)
    local player = ctx:player()
    local durations = ctx:get(player, component.DURATIONS)

    return okawaru_status.active(ctx, player, "finesse"),
        durations and durations.haste_aut > 0 or false
end

-- Clamp base delay by weapon speed, with Short Blades' lower five-aut cap.
function delay.minimum_weapon(speed, skill_id)
    local minimum = math.floor(speed / 2)

    if skill_id == "SK_SHORT_BLADES" then
        minimum = math.min(minimum, 5)
    end

    return math.max(3, math.min(minimum, 7), speed - 14)
end

-- Two skill levels remove one aut until the weapon's minimum delay.
function delay.minimum_skill(speed, skill_id)
    return 2 * (speed - delay.minimum_weapon(speed, skill_id))
end

-- Crossbow and longbow minimums override the generic weapon-speed floor.
function delay.minimum_launcher(kind, speed)
    local weapon = kind.weapon
    local minimum = delay.minimum_weapon(speed or weapon.speed,
        weapon.skill_id)

    -- fight.cc gives crossbows a 10 aut minimum and longbows 6.
    if weapon.ammo_id == "MI_BOLT" then
        return math.max(10, minimum)
    end

    if kind.id == "WPN_LONGBOW" then
        return 6
    end

    return minimum
end

-- Convolve skill, shield, armour, speed brand, and action-time rounding;
-- drawing once preserves the exact resulting AUT distribution.
local function action_cost(ctx, time_taken, base, reduction, denominator,
    shield_penalty20, minimum, armour_penalty20, speed_brand,
    finesse_active, hasted)
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

                    for _, adjusted in ipairs(finesse_values(action,
                        finesse_active, hasted)) do
                        for _, scaled in ipairs(rounded_values(
                            adjusted.value * time_taken, 10)) do
                            local value = math.max(2, scaled.value)

                            weights[value] = (weights[value] or 0) +
                                skill.weight * shield.weight *
                                armour.weight * speed.weight *
                                adjusted.weight * scaled.weight
                            low = math.min(low, value)
                            high = math.max(high, value)
                        end
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

-- Shields add delay from encumbrance after Shields skill reduces the cost.
local function shield_penalty(ctx)
    local worn = equipment.worn(ctx, ctx:player(), { shield = true })
    local shield_ev = worn.shield and worn.shield.definition.armour.ev or 0
    local shields10 = fighter.skill(ctx, "SK_SHIELDS", 10)
    local shield_base = math.floor(-shield_ev / 10)

    return math.floor(
        2 * shield_base ^ 2 * (270 - shields10) * 20 / 100 / 270)
end

-- Example: delay.player(ctx, time_taken) with player attack action -> aut cost adjusted by weapon skill
-- Convert one player action into elapsed aut for timed combat effects and reactions.
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
    local finesse_active, hasted = okawaru_mode(ctx)

    return action_cost(ctx, time_taken, base, reduction, denominator,
        shield_penalty(ctx), 3, nil,
        attack.using_weapon and attack.weapon_brand == brands.SPEED,
        finesse_active, hasted)
end

-- Thrown missiles and launchers use different skill reductions; launcher
-- delay also includes body-armour encumbrance and artefact base delay.
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
        base = kind.weapon.speed + artefact_properties.value(ctx,
            entity, artefact_ids.BASE_DELAY)
        local skill_id = kind.weapon.skill_id
        local skill10 = fighter.skill(ctx, skill_id, 10)
        local minimum_delay = delay.minimum_launcher(kind, base)

        reduction = math.min(skill10, 20 * (base - minimum_delay))
        minimum = 3
        local artefact = ctx:get(entity, component.ITEM_ARTEFACT)
        local effective_brand = artefact and artefact.brand ~= "" and
            artefact.brand or item.ego

        speed_brand = effective_brand == brands.SPEED

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

    local finesse_active, hasted = okawaru_mode(ctx)

    return action_cost(ctx, time_taken, base, reduction, 20,
        shield_penalty(ctx), minimum, armour_penalty20, speed_brand,
        finesse_active, hasted)
end

return delay
