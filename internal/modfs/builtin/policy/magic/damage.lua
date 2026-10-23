local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local forms = require("policy.magic.effects.forms.player")
local statuses = require("policy.magic.effects.statuses.player")
local monster_defense = require("policy.combat.monster_defense")
local monster_profile = require("policy.combat.monster_profile")
local mutation_capabilities = require("constants.mutation_capabilities")
local mutation_effects = require("policy.mutations.effects.registry")
local resistances = require("constants.resistance_ids")
local armour_flags = require("constants.armour_flags")
local armour_egos = require("constants.armour_egos")
local staves = require("policy.inventory.staves")
local object_classes = require("ids.object_classes")
local icy_defense = require("policy.character.icy_defense")
local cold_blooded = require("policy.character.cold_blooded")
local monster_health = require("policy.combat.monster_health")
local component = require("constants.component")
local form_ids = require("constants.form_ids")
local potion_resistance = require("policy.potions.resistance")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local artefacts = require("policy.item_generation.artefacts.properties")
local artefact_properties = require("ids.artefact_properties")
local jiyva_defenses = require("policy.religion.jiyva.defenses")

local damage = {}

local artefact_resistances = {
    [resistances.FIRE] = artefact_properties.FIRE,
    [resistances.COLD] = artefact_properties.COLD,
    [resistances.ELECTRICITY] = artefact_properties.ELECTRICITY,
    [resistances.ACID] = artefact_properties.RCORR,
    [resistances.NEGATIVE_ENERGY] = artefact_properties.NEGATIVE_ENERGY,
}

-- Example: a target without health returns nil before an elemental zap reads its species.
-- Return species and live HP together so elemental callers cannot damage a missing actor.
function damage.monster(ctx, target)
    local actor = ctx:get(target, "core.actor")
    local health = ctx:get(target, "core.health")

    if not actor or not health then
        return nil
    end

    local definition = catalog.get("monsters", actor.kind_id)

    return monster_profile.definition(ctx, target, definition), health
end

-- Catalog entries default to zero when a monster lacks an explicit resistance.
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

-- Environmental effects sometimes need to skip all RNG for a fully
-- immune monster. Read its live profile, including per-actor overrides.
function damage.monster_resistance(ctx, target, resistance_id)
    local definition = damage.monster(ctx, target)

    if not definition then
        error("resistance target is not a monster")
    end

    return resistance_level(definition, resistance_id)
end

-- Source: fight.cc:resist_adjust_damage for a wholly resistible flavour.
local function elemental(raw, resistance, resistance_id)

    if resistance >= 3 then
        return 0
    end

    if resistance > 0 then
        local boolean_bonus = resistance_id == resistances.ELECTRICITY and 1 or 0

        return math.floor(raw /
            (1 + boolean_bonus + resistance * resistance))
    end

    if resistance < 0 then
        return math.floor(raw * 15 / 10)
    end

    return raw
end

-- Apply monster flavour resistance using the species level rather than player modifiers.
function damage.elemental(raw, definition, resistance_id)
    return elemental(raw, resistance_level(definition, resistance_id),
        resistance_id)
end

-- Temporary Fire Vulnerability shifts the monster's fire level before damage scaling.
function damage.monster_elemental(ctx, target, raw, resistance_id)
    local definition = damage.monster(ctx, target)

    if not definition then
        error("elemental damage target is not a monster")
    end

    local resistance = resistance_level(definition, resistance_id)

    if resistance_id == resistances.FIRE then
        local vulnerability = ctx:get(target, "zap.fire_vulnerability")

        if vulnerability and vulnerability.remaining_aut > 0 then
            resistance = math.max(-3, resistance - 1)
        end
    end

    return elemental(raw, resistance, resistance_id)
end

local jewellery_resistance = {
    [resistances.FIRE] = jewellery_capabilities.FIRE_RESISTANCE,
    [resistances.COLD] = jewellery_capabilities.COLD_RESISTANCE,
    [resistances.ACID] = jewellery_capabilities.CORROSION_RESISTANCE,
    [resistances.NEGATIVE_ENERGY] =
        jewellery_capabilities.NEGATIVE_ENERGY_RESISTANCE,
}

local elemental_capabilities = {
    [resistances.FIRE] = mutation_capabilities.FIRE_RESISTANCE,
    [resistances.COLD] = mutation_capabilities.COLD_RESISTANCE,
    [resistances.ELECTRICITY] = mutation_capabilities.ELECTRICITY_RESISTANCE,
    [resistances.ACID] = mutation_capabilities.ACID_RESISTANCE,
    [resistances.STEAM] = mutation_capabilities.STEAM_RESISTANCE,
    [resistances.NEGATIVE_ENERGY] =
        mutation_capabilities.NEGATIVE_ENERGY_RESISTANCE,
}

-- Only authored armour flags contribute special body resistance; absent flags give zero.
local function armour_flag_level(definition, wanted)
    local armour = definition.armour
    local flags = armour and type(armour.flags) == "table" and
        armour.flags or {}

    for _, flag in ipairs(flags) do
        if flag.id == wanted then
            return flag.level
        end
    end

    return 0
end

-- Sum mutation, jewellery, potion, form, gear, and artefact sources before source caps.
function damage.player_resistance(ctx, player, resistance_id)
    local capability = elemental_capabilities[resistance_id]

    if not capability then
        error("unsupported player elemental resistance " .. resistance_id)
    end

    local value = mutation_effects.sum(ctx, player, capability)
    local jewellery_capability = jewellery_resistance[resistance_id]

    if jewellery_capability then
        value = value + jewellery_effects.sum(ctx, player,
            jewellery_capability)
    end

    if resistance_id == resistances.ACID then
        value = value + jiyva_defenses.acid_resistance(ctx, player)
    end

    if potion_resistance.active(ctx, player) and
        (resistance_id == resistances.FIRE or
            resistance_id == resistances.COLD or
            resistance_id == resistances.ELECTRICITY or
            resistance_id == resistances.ACID) then
        value = value + 1
    end

    local form = forms.modifiers(ctx, player)

    if resistance_id == resistances.STEAM then
        value = value + 2 * damage.player_resistance(ctx, player,
            resistances.FIRE)
    elseif resistance_id == resistances.FIRE then
        value = value + form.res_fire

        local vulnerability = ctx:get(player,
            component.FIRE_VULNERABILITY)

        if vulnerability and vulnerability.remaining_aut > 0 then
            value = value - 1
        end
    elseif resistance_id == resistances.COLD then
        value = value + form.res_cold
    elseif resistance_id == resistances.ELECTRICITY then
        local active = ctx:get(player, "magic.player_form")

        if active and (active.form_id == "statue" or
            active.form_id == "storm") then
            value = value + 1
        end
    elseif resistance_id == resistances.NEGATIVE_ENERGY then
        local active = ctx:get(player, "magic.player_form")
        local petrification = ctx:get(player,
            component.PLAYER_PETRIFICATION)

        if active and (active.form_id == form_ids.LICH or
            active.form_id == form_ids.FUNGUS) then
            value = value + 3
        end

        if petrification and petrification.petrified_aut > 0 then
            value = value + 3
        end
    end

    local worn = equipment.worn(ctx, player, {
        weapon = true,
        body = true,
        cloak = true,
        head = true,
        gloves = true,
        boots = true,
    })

    for slot, entry in pairs(worn) do
        local definition = entry.definition

        if slot == "weapon" then
            value = value + staves.resistance(definition, resistance_id)
        end

        if definition.class == object_classes.OBJ_ARMOUR then
            if resistance_id == resistances.ACID and
                entry.ego == armour_egos.PRESERVATION then
                value = value + 1
            end

            if resistance_id == resistances.FIRE and
                (entry.ego == armour_egos.RESISTANCE or
                    entry.ego == armour_egos.FIRE_RESISTANCE) then
                value = value + 1
            elseif resistance_id == resistances.COLD and
                (entry.ego == armour_egos.RESISTANCE or
                    entry.ego == armour_egos.COLD_RESISTANCE) then
                value = value + 1
            elseif resistance_id == resistances.NEGATIVE_ENERGY and
                entry.ego == armour_egos.POSITIVE_ENERGY then
                value = value + 1
            end

            if slot == "body" and resistance_id == resistances.ACID then
                value = value + armour_flag_level(definition,
                    armour_flags.RES_CORROSION)
            elseif slot == "body" and
                resistance_id == resistances.STEAM then
                value = value + 2 * armour_flag_level(definition,
                    armour_flags.RES_STEAM)
            elseif slot == "body" and
                resistance_id == resistances.NEGATIVE_ENERGY then
                value = value + armour_flag_level(definition,
                    armour_flags.RES_NEGATIVE_ENERGY)
            end
        end
    end

    local property = artefact_resistances[resistance_id]

    if property then
        value = value + artefacts.sum_worn(ctx, player, property)
    end

    if resistance_id == resistances.ELECTRICITY then
        return math.min(1, value)
    end

    if resistance_id == resistances.ACID then
        return math.min(1, value)
    end

    if resistance_id == resistances.STEAM then
        return math.min(2, value)
    end

    if resistance_id == resistances.NEGATIVE_ENERGY then
        return math.min(3, value)
    end

    return math.max(-3, math.min(3, value))
end

-- fight.cc:resist_adjust_damage uses a weaker positive-resistance divisor
-- for players than monsters; rF/rC 3 still takes some damage.
function damage.player_elemental(ctx, player, raw, resistance_id)
    if not resistance_id then
        return raw
    end

    icy_defense.melt(ctx, player, resistance_id)

    local resistance = damage.player_resistance(ctx, player, resistance_id)

    if resistance_id == resistances.COLD then
        cold_blooded.expose(ctx, player, raw, resistance)
    end

    if resistance_id == resistances.NEGATIVE_ENERGY and resistance >= 3 then
        return 0
    end

    if resistance > 0 then
        if resistance_id == resistances.NEGATIVE_ENERGY then
            return math.floor(raw / (2 * resistance))
        end

        local boolean_bonus = resistance_id == resistances.ELECTRICITY and 1 or 0

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
function damage.player_armour(ctx, player, raw, ac_rule, stream)
    local ac = fighter.defense(ctx).ac
    local saved = 0
    stream = stream or "spell"

    if ac_rule == "none" then
        return raw
    end

    if ac_rule == "triple" then
        saved = ctx:random(stream, ac + 1) +
            ctx:random(stream, ac + 1) +
            ctx:random(stream, ac + 1)
    else
        saved = ctx:random(stream, ac + 1)

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

-- Player chunked AC uses current GDR to cap how much can be absorbed.
function damage.player_proportional_armour(ctx, player, raw, max_damage)
    local defense = fighter.defense(ctx)

    return damage.proportional_armour(ctx, raw, defense.ac,
        max_damage, defense.gdr)
end

-- Monster chunked AC has no GDR floor, using species armour alone.
function damage.monster_proportional_armour(ctx, monster, raw, max_damage)
    local definition = damage.monster(ctx, monster)

    if not definition then
        error("proportional armour target is not a monster")
    end

    local ac = monster_defense.armour(ctx, monster, definition)

    return damage.proportional_armour(ctx, raw, ac, max_damage, 0)
end

-- Credit the player kill signal only for lethal dealt damage against a nonsummon.
function damage.apply(ctx, target, amount, source)
    local credited_source = source or ctx:query({ component.PLAYER })[1]
    local health, dealt = monster_health.damage(ctx, target, amount,
        credited_source)

    if dealt > 0 and health.current == 0 and
        ctx:has(credited_source, component.PLAYER) and
        not ctx:has(target, "magic.summon") then
        ctx:signal("player_kill", target)
    end

    return health.current
end

return damage
