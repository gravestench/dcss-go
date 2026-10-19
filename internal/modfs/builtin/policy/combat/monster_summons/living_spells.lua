-- A walking tome creates ordinary summoned actors whose one magical slot
-- comes from a saved component. Source: mon-cast.cc:CONJURE_LIVING_SPELLS.
local catalog = require("policy.catalog")
local component = require("constants.component")
local targets = require("policy.ai.targets")
local hit_points = require("policy.population.hit_points")
local monsters = require("ids.monsters")
local roll = require("policy.combat.roll")
local spells = require("ids.spells")
local strength = require("policy.combat.monster_summons.strength")
local summons = require("policy.magic.effects.summons.common")
local streams = require("constants.rng_streams")

local living = {}
local SUMMON_CAP = 6

-- Restore accepts a spell only when a currently loaded tome declares it.
-- This keeps a new modded tome self-contained in its own content file.
function living.valid_spell(id)
    if type(id) ~= "string" or id == "" then
        return false
    end

    for _, definition in ipairs(catalog.all("monsters")) do
        if definition.living_spell_id == id then
            return true
        end
    end

    return false
end

-- Source monster AI refuses a capped summon before committing a turn.
-- Count only this owner's live actors from Conjure Living Spells.
function living.at_cap(ctx, caster)
    local count = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.owner == caster and
            state.source_id == spells.SPELL_CONJURE_LIVING_SPELLS and
            targets.aligned(ctx, caster, entity) then
            count = count + 1
        end
    end

    return count >= SUMMON_CAP
end

-- Read the spell from the caster's definition. The shared tome spellbook
-- cannot determine the living spell's eventual effect on its own.
function living.spell_for(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)
    local spell_id = definition and definition.living_spell_id

    if not spell_id then
        error("Conjure Living Spells needs a walking tome caster")
    end

    return spell_id
end

-- Source attempts two or three degree-one summons, each with the caster's
-- spell HD and its own HP roll scaled from the living-spell base profile.
function living.spawn(ctx, caster)
    local spell_id = living.spell_for(ctx, caster)
    local hd = strength.spell_hd(ctx, caster)
    local definition = catalog.get("monsters",
        monsters.MONS_LIVING_SPELL)
    local count = 2 + roll.draw(ctx, streams.MONSTER_SPELL, 2)
    local created = {}

    for _ = 1, count do
        local actor = summons.spawn(ctx, caster,
            spells.SPELL_CONJURE_LIVING_SPELLS,
            monsters.MONS_LIVING_SPELL, 1, SUMMON_CAP, {
                hd = hd,
            })

        if actor then
            -- Source creates the base monster, then rerolls its HP after
            -- applying the summoned HD override. A failed placement draws
            -- no monster HP or custom-state RNG.
            local average_hp = math.floor(
                definition.average_hp_10x * hd / definition.hd)
            local hp = hit_points.roll(ctx, average_hp)

            ctx:set(actor, component.HEALTH, {
                current = hp,
                max = hp,
            })

            ctx:add(actor, component.SUMMON_LIVING_SPELL, {
                spell_id = spell_id,
            })

            created[#created + 1] = actor
        end
    end

    return created
end

return living
