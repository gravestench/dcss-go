-- The Serpent of Hell casts three existing zaps in head order during one
-- monster action. Each head keeps its own damage, cloud, and status policy.
-- Source: mon-cast.cc:mons_cast, spl-util.cc:soh_breath_spells.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local spell_flags = require("constants.spell_flags")
local spells = require("ids.spells")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")

local serpent_breath = {}

local heads = {
    [spells.SPELL_SERPENT_OF_HELL_GEH_BREATH] = {
        spells.SPELL_FIRE_BREATH,
        spells.SPELL_FLAMING_CLOUD,
        spells.SPELL_FIREBALL,
    },
    [spells.SPELL_SERPENT_OF_HELL_COC_BREATH] = {
        spells.SPELL_COLD_BREATH,
        spells.SPELL_FREEZING_CLOUD,
        spells.SPELL_FLASH_FREEZE,
    },
    [spells.SPELL_SERPENT_OF_HELL_DIS_BREATH] = {
        spells.SPELL_METAL_SPLINTERS,
        spells.SPELL_QUICKSILVER_BOLT,
        spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
    },
    [spells.SPELL_SERPENT_OF_HELL_TAR_BREATH] = {
        spells.SPELL_BOLT_OF_DRAINING,
        spells.SPELL_MIASMA_BREATH,
        spells.SPELL_CORROSIVE_BOLT,
    },
}

-- The source plans all four variants as Fire Breath, but uses the composite
-- spell's seven-cell range. Copy the profile so no catalog fact is mutated.
local function tracer_profile(spell_id)
    local source = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_FIRE_BREATH)
    local profile = {}

    for key, value in pairs(source) do
        profile[key] = value
    end

    profile.id = spell_id

    return profile
end

-- Cloud and explosion heads aim at a cell; other zaps retain the enemy
-- handle. Source order and the chosen direction stay independent of VFS order.
local function head_plan(head_spell, foe, aim, dx, dy)
    local profile = catalog.get(categories.MONSTER_BEAMS, head_spell)
    local definition = catalog.get(categories.SPELLS, head_spell)
    local area = profile.is_explosion

    for _, flag in ipairs(definition.flags or {}) do
        if flag == spell_flags.CLOUD then
            area = true
            break
        end
    end

    if area then
        return {
            kind = target_kind.CELL,
            level_id = aim.level_id,
            x = aim.x,
            y = aim.y,
            dx = dx,
            dy = dy,
        }
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
        dx = dx,
        dy = dy,
    }
end

-- One source tracer checks the full ray and friendly-fire risk before the
-- action is spent. The three heads do not make independent AI decisions.
function serpent_breath.plan(ctx, caster, foe, spell_id)
    if not heads[spell_id] then
        error("unknown Serpent of Hell breath " .. tostring(spell_id))
    end

    return beam.plan(ctx, caster, foe, tracer_profile(spell_id))
end

-- Reuse each existing zap's resolver without drawing a new spell prospect.
-- A dead foe or caster ends the remaining heads, as source casts do.
function serpent_breath.resolve(ctx, caster, foe, slot, plan, spell_id)
    local selected_heads = heads[spell_id]

    if not selected_heads then
        error("unknown Serpent of Hell breath " .. tostring(spell_id))
    end

    target.require_entity(plan, foe)

    local source = ctx:get(caster, component.POSITION)
    local aim = ctx:get(foe, component.POSITION)

    if not source or not aim or source.level_id ~= aim.level_id or
        plan.dx ~= aim.x - source.x or
        plan.dy ~= aim.y - source.y then
        error("Serpent of Hell breath direction changed after planning")
    end

    local outcomes = {}

    for _, head_spell in ipairs(selected_heads) do
        local foe_health = ctx:get(foe, component.HEALTH)
        local caster_health = ctx:get(caster, component.HEALTH)

        if not foe_health or foe_health.current <= 0 or
            not caster_health or caster_health.current <= 0 then
            break
        end

        local effect = effects.effect(head_spell)
        local selected = head_plan(head_spell, foe, aim,
            plan.dx, plan.dy)

        outcomes[#outcomes + 1] = {
            spell_id = head_spell,
            result = effect.resolve(ctx, caster, foe, slot, selected),
        }
    end

    return outcomes
end

return serpent_breath
