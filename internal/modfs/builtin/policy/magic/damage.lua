local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local forms = require("policy.magic.effects.forms.player")
local statuses = require("policy.magic.effects.statuses.player")
local monster_defense = require("policy.combat.monster_defense")

local damage = {}

function damage.monster(ctx, target)
    local actor = ctx:get(target, "core.actor")
    local health = ctx:get(target, "core.health")

    if not actor or not health then
        return nil
    end

    return catalog.get("monsters", actor.kind_id), health
end

local function resistance_level(definition, resistance_id)
    local resistance = 0

    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == resistance_id then
            resistance = entry.level
            break
        end
    end

    return resistance
end

-- Source: fight.cc:resist_adjust_damage for a wholly resistible flavour.
local function elemental(raw, resistance, resistance_id)

    if resistance >= 3 then
        return 0
    end

    if resistance > 0 then
        local boolean_bonus = resistance_id == "MR_RES_ELEC" and 1 or 0

        return math.floor(raw /
            (1 + boolean_bonus + resistance * resistance))
    end

    if resistance < 0 then
        return math.floor(raw * 15 / 10)
    end

    return raw
end

function damage.elemental(raw, definition, resistance_id)
    return elemental(raw, resistance_level(definition, resistance_id),
        resistance_id)
end

function damage.monster_elemental(ctx, target, raw, resistance_id)
    local definition = damage.monster(ctx, target)

    if not definition then
        error("elemental damage target is not a monster")
    end

    local resistance = resistance_level(definition, resistance_id)

    if resistance_id == "MR_RES_FIRE" then
        local vulnerability = ctx:get(target, "zap.fire_vulnerability")

        if vulnerability and vulnerability.remaining_aut > 0 then
            resistance = math.max(-3, resistance - 1)
        end
    end

    return elemental(raw, resistance, resistance_id)
end

local elemental_gear = {
    MR_RES_FIRE = {
        RING_PROTECTION_FROM_FIRE = 1,
        RING_FIRE = 1,
        RING_ICE = -1,
        STAFF_FIRE = 1,
    },
    MR_RES_COLD = {
        RING_PROTECTION_FROM_COLD = 1,
        RING_ICE = 1,
        RING_FIRE = -1,
        STAFF_COLD = 1,
    },
    MR_RES_ELEC = {
        STAFF_AIR = 1,
    },
}

local elemental_mutations = {
    MR_RES_FIRE = {
        { id = "MUT_HEAT_RESISTANCE", sign = 1 },
        { id = "MUT_HEAT_VULNERABILITY", sign = -1 },
        { id = "MUT_TEMPERATURE_SENSITIVITY", sign = -1 },
    },
    MR_RES_COLD = {
        { id = "MUT_COLD_RESISTANCE", sign = 1 },
        { id = "MUT_COLD_VULNERABILITY", sign = -1 },
        { id = "MUT_TEMPERATURE_SENSITIVITY", sign = -1 },
    },
    MR_RES_ELEC = {
        { id = "MUT_SHOCK_RESISTANCE", sign = 1 },
        { id = "MUT_SHOCK_VULNERABILITY", sign = -1 },
    },
}

function damage.player_resistance(ctx, player, resistance_id)
    local gear = elemental_gear[resistance_id]
    local mutations = elemental_mutations[resistance_id]

    if not gear or not mutations then
        error("unsupported player elemental resistance " .. resistance_id)
    end

    local value = 0

    for _, mutation in ipairs(mutations) do
        value = value + mutation.sign * fighter.mutation(ctx, mutation.id)
    end

    if resistance_id == "MR_RES_ELEC" and
        fighter.mutation(ctx, "MUT_THIN_METALLIC_SCALES") >= 3 then
        value = value + 1
    end

    local form = forms.modifiers(ctx, player)

    if resistance_id == "MR_RES_FIRE" then
        value = value + form.res_fire
    elseif resistance_id == "MR_RES_COLD" then
        value = value + form.res_cold
    else
        local active = ctx:get(player, "magic.player_form")

        if active and (active.form_id == "statue" or
            active.form_id == "storm") then
            value = value + 1
        end
    end

    for _, entity in ipairs(ctx:query({ "core.equipped", "core.carried_by" })) do
        local carrier = ctx:get(entity, "core.carried_by")

        if carrier.holder == player then
            local item = ctx:get(entity, "core.item")
            local definition = catalog.get("items", item.kind_id)

            value = value + (gear[item.kind_id] or 0)

            if definition.class == "OBJ_ARMOUR" then
                if resistance_id ~= "MR_RES_ELEC" and
                    (item.ego == "SPARM_RESISTANCE" or
                    item.ego == "SPARM_" ..
                        (resistance_id == "MR_RES_FIRE" and
                            "FIRE_RESISTANCE" or "COLD_RESISTANCE")) then
                    value = value + 1
                end
            end
        end
    end

    if resistance_id == "MR_RES_ELEC" then
        return math.min(1, value)
    end

    return math.max(-3, math.min(3, value))
end

-- fight.cc:resist_adjust_damage uses a weaker positive-resistance divisor
-- for players than monsters; rF/rC 3 still takes some damage.
function damage.player_elemental(ctx, player, raw, resistance_id)
    local resistance = damage.player_resistance(ctx, player, resistance_id)

    if resistance > 0 then
        local boolean_bonus = resistance_id == "MR_RES_ELEC" and 1 or 0

        return math.floor(raw /
            (math.floor((3 * resistance + 1) / 2) + boolean_bonus))
    end

    if resistance < 0 then
        return math.floor(raw * 15 / 10)
    end

    return raw
end

-- beam.cc:apply_AC uses beam-specific armour rules with no GDR. The
-- caller rolls raw damage first, then applies this before resistance.
function damage.player_armour(ctx, player, raw, ac_rule)
    local ac = fighter.defense(ctx).ac
    local saved = 0

    if ac_rule == "none" then
        return raw
    end

    if ac_rule == "triple" then
        saved = ctx:random("spell", ac + 1) +
            ctx:random("spell", ac + 1) +
            ctx:random("spell", ac + 1)
    else
        saved = ctx:random("spell", ac + 1)

        if ac_rule == "half" then
            saved = math.floor(saved / 2)
        elseif ac_rule ~= nil and ac_rule ~= "normal" then
            error("unknown player beam armour rule " .. tostring(ac_rule))
        end
    end

    return math.max(0, raw - saved)
end

-- Source: fight.cc:apply_chunked_AC and actor.cc:apply_ac. Each damage point
-- survives AC independently; GDR then sets a minimum amount absorbed.
function damage.proportional_armour(ctx, raw, ac, max_damage, gdr)
    local threshold = math.floor((80 / 81) ^ math.max(0, ac) * 4294967296)
    local hurt = 0

    for _ = 1, raw do
        local _, word = ctx:random_u64("spell")

        if word < threshold then
            hurt = hurt + 1
        end
    end

    local minimum = math.floor(max_damage * gdr / 100)
    local remainder = (max_damage * gdr) % 100

    if remainder > 0 and ctx:random("spell", 100) < remainder then
        minimum = minimum + 1
    end

    return math.max(0, raw - math.max(raw - hurt, minimum))
end

function damage.player_proportional_armour(ctx, player, raw, max_damage)
    local defense = fighter.defense(ctx)

    return damage.proportional_armour(ctx, raw, defense.ac,
        max_damage, defense.gdr)
end

function damage.monster_proportional_armour(ctx, monster, raw, max_damage)
    local definition = damage.monster(ctx, monster)

    if not definition then
        error("proportional armour target is not a monster")
    end

    local ac = monster_defense.armour(ctx, monster, definition)

    return damage.proportional_armour(ctx, raw, ac, max_damage, 0)
end

function damage.apply(ctx, target, amount)
    local health = ctx:get(target, "core.health")

    if not health then
        error("spell target has no health")
    end

    local was_alive = health.current > 0

    if was_alive then
        statuses.wake_hibernating(ctx, target)
        amount = statuses.petrified_damage(ctx, target, amount)
    end

    health.current = math.max(0, health.current - amount)
    ctx:set(target, "core.health", health)

    if was_alive and health.current == 0 and
        not ctx:has(target, "magic.summon") then
        ctx:signal("player_kill", target)
    end

    return health.current
end

return damage
