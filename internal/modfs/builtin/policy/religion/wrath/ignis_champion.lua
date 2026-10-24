-- Ignis chooses the strongest visible hostile body that can carry a
-- permanent fire champion enchantment. The effect itself lives on the
-- monster ECS actor and is read by ordinary action owners.
local attacks = require("constants.attack_flavours")
local attack_types = require("constants.monster_attack_types")
local awareness = require("policy.ai.awareness")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local flags = require("constants.monster_flags")
local groups = require("constants.monster_groups")
local monsters = require("ids.monsters")
local spellbooks = require("ids.monster_spellbooks")
local nearby = require("policy.religion.cards.effects.nearby")
local spell_flags = require("constants.monster_spell_flags")
local stats = require("policy.combat.monster_stats")
local profile = require("policy.combat.monster_profile")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local champion = {}

local cannot_use_stairs = {
    [monsters.MONS_SILENT_SPECTRE] = true,
    [monsters.MONS_GERYON] = true,
    [monsters.MONS_ROYAL_JELLY] = true,
    [monsters.MONS_BALL_LIGHTNING] = true,
    [monsters.MONS_FOXFIRE] = true,
    [monsters.MONS_ZOMBIE] = true,
    [monsters.MONS_SKELETON] = true,
    [monsters.MONS_SIMULACRUM] = true,
    [monsters.MONS_SPECTRAL_THING] = true,
}

-- Catalog flags and spell-slot flags are ordered lists, so one helper
-- makes both source exclusion checks explicit without changing content.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- A priest has at least one source MON_SPELL_PRIEST slot. The book is
-- loaded from the effective catalog, so mods can alter this eligibility.
local function priest(definition)
    if definition.spellbook_id == spellbooks.MST_NO_SPELLS then
        return false
    end

    local book = catalog.get(categories.MONSTER_SPELLBOOKS,
        definition.spellbook_id)

    for _, slot in ipairs(book.slots or {}) do
        if contains(slot.flags, spell_flags.PRIEST) then
            return true
        end
    end

    return false
end

-- Source guards prevent blessing allies, firewood, immobile conjurations,
-- summoned bodies, and bodies whose first strike is special. Every summon
-- fails the source stair check, regardless of whether it has a timer.
local function eligible(ctx, player, entry)
    local entity = entry.entity
    local definition = profile.definition(ctx, entity,
        entry.definition)
    local first = definition.attacks and definition.attacks[1]
    local summon = ctx:get(entity, component.SUMMON)
    local immobile = definition.speed == 0 or
        contains(definition.flags, flags.STATIONARY)
    local firewood = immobile and
        contains(definition.flags, flags.NO_THREAT)

    return targets.enemy(ctx, entity, player) and
        not ctx:has(entity, component.IGNIS_FIRE_CHAMPION) and
        not firewood and not immobile and
        not contains(definition.flags, flags.CONJURED) and
        not groups.tentacles[definition.id] and
        not cannot_use_stairs[definition.id] and
        not summon and
        not priest(definition) and
        first and first.type_id ~= attack_types.NONE and
        first.flavour_id == attacks.PLAIN
end

-- Highest-HD candidates replace weaker predecessors; ties use source
-- reservoir sampling so query or file load order cannot bias a seed.
function champion.target(ctx, player)
    local minimum = math.floor(ctx:get(player,
        component.PROGRESSION).level / 2)
    local chosen
    local seen = 0

    for _, entry in ipairs(nearby.monsters(ctx, player)) do
        if eligible(ctx, player, entry) then
            local hd = stats.hit_dice(ctx, entry.entity,
                entry.definition)

            if hd >= minimum then
                if hd > minimum then
                    minimum = hd
                    seen = 0
                end

                seen = seen + 1

                if ctx:random(streams.CARDS, seen) == 0 then
                    chosen = entry
                end
            end
        end
    end

    return chosen
end

-- Announce before adding the marker, then describe the now visible fire.
-- This keeps source message order even for an invisible target.
function champion.anoint(ctx, player)
    local entry = champion.target(ctx, player)

    if not entry then
        return false
    end

    local name = display.name(ctx, entry.entity)

    ctx:emit("religion", "Ignis anoints the " ..
        name .. " as an instrument of vengeance!")
    ctx:add(entry.entity, component.IGNIS_FIRE_CHAMPION, {
        active = true,
    })
    ctx:emit("monster", "The " .. name ..
        " is coated in flames, covering ground quickly and attacking fiercely!")
    awareness.alert(ctx, entry.entity, player)

    return true
end

-- ENCH_FIRE_CHAMPION replaces the first attack's flavour, including when
-- the body came from a modded monster definition after anointment.
function champion.attack_flavour(ctx, monster, original)
    if ctx:has(monster, component.IGNIS_FIRE_CHAMPION) then
        return attacks.FIRE
    end

    return original
end

-- Source mons_energy changes movement energy, not the actor's speed or
-- its attack cost. Swift and terrain effects run after this base cost.
function champion.movement_cost(ctx, monster, cost)
    if ctx:has(monster, component.IGNIS_FIRE_CHAMPION) then
        return math.max(1, math.floor(cost * 2 / 3))
    end

    return cost
end

return champion
