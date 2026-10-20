-- Theory of operation: a monster's death cloud depends on its source
-- species and, for summons, the spell that created it. Ordinary lethal
-- death and early summon teardown both enter this policy before deleting
-- the actor. The cloud itself is a saved ECS entity owned by cloud placement.
-- Source: mon-death.cc:_monster_die_cloud and summoned_poof_msg.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_ids = require("ids.clouds")
local clouds = require("policy.clouds.placement")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local holiness = require("constants.monster_holiness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local death_clouds = {}

local shadow_sources = {
    [spells.SPELL_SHADOW_CREATURES] = true,
    [spells.SPELL_SPECTRAL_CLOUD] = true,
    [spells.SPELL_CALL_LOST_SOUL] = true,
    [spells.SPELL_SUMMON_BUTTERFLIES] = true,
    [items.SCR_SUMMONING] = true,
}

-- Holy species dissolve into light rather than smoke. Keep this check
-- against the registered monster definition so overlays can change it.
local function holy(definition)
    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.HOLY then
            return true
        end
    end

    return false
end

-- The source poof message selects a cloud: shadow, light, lost souls,
-- mirrors, drowned souls, and living spells leave none. Chaos spawn is
-- handled by its innate cloud even when it was never summoned.
local function smoke_poof(ctx, entity, definition, summon)
    if not summon or shadow_sources[summon.source_id] or
        holy(definition) or
        ctx:has(entity, component.SUMMON_MIRROR) or
        definition.id == monsters.MONS_LIVING_SPELL or
        definition.id == monsters.MONS_DROWNED_SOUL or
        definition.id == monsters.MONS_CHAOS_SPAWN then
        return false
    end

    return true
end

-- Source fire vortices and simulacra leave an elemental field even when
-- they are natural monsters. The first cloud wins over later smoke because
-- the shared placement policy will not replace a harmful field with smoke.
local function elemental_cloud(ctx, definition, source, position)
    local kind

    if definition.id == monsters.MONS_FIRE_VORTEX then
        kind = cloud_ids.CLOUD_FIRE
    elseif definition.species_id == monsters.MONS_SIMULACRUM then
        kind = cloud_ids.CLOUD_COLD
    elseif definition.id == monsters.MONS_CHAOS_SPAWN then
        kind = cloud_ids.CLOUD_CHAOS
    end

    if not kind then
        return
    end

    local duration

    if kind == cloud_ids.CLOUD_CHAOS then
        duration = 10 + 10 * ctx:random(streams.CLOUDS, 3)
    else
        duration = 20 + 10 * ctx:random(streams.CLOUDS, 4)
    end

    clouds.place(ctx, kind, source, position.level_id,
        position.x, position.y, duration)
end

-- The caller still owns actor removal. This function only leaves the
-- source cloud and consumes no corpse; it can also run for a timed expiry.
function death_clouds.leave(ctx, entity, definition, position)
    if not position or not ctx:walkable(position.level_id,
        position.x, position.y) then
        return false
    end

    local summon = ctx:get(entity, component.SUMMON)

    -- Source Crawl credits the dying monster, whose saved summon attitude
    -- still identifies its side even if the original caster has vanished.
    local source = entity

    elemental_cloud(ctx, definition, source, position)

    if smoke_poof(ctx, entity, definition, summon) then
        local smoke = clouds.random_smoke_kind(ctx)

        clouds.place(ctx, smoke, source,
            position.level_id, position.x, position.y,
            10 + 10 * ctx:random(streams.CLOUDS, 3))
    end

    return false
end

-- The common summon owner already handles carried gear and spatial
-- removal. Call the same policy before that teardown drops the position.
function death_clouds.before_expiry(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)
    local position = ctx:get(entity, component.POSITION)

    if not actor or not position then
        return
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    death_clouds.leave(ctx, entity, definition, position)
end

death_hooks.add("monster.death_clouds", death_clouds.leave)

return death_clouds
