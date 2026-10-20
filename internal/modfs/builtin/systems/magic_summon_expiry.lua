local spells = require("ids.spells")
local component = require("constants.component")
local summons = require("policy.magic.effects.summons.common")
local spore = require("policy.combat.monster_plants.spore")
local visibility = require("policy.combat.monster_summons.visibility")
local channels = require("constants.message_channels")
local zap_ids = require("policy.magic.effects.zaps.ids")
local monsters = require("ids.monsters")

-- Theory of operation: Expired summons are torn down before ordinary death cleanup, preserving source-specific effects.
-- Source: monster::mark_summoned and ENCH_ABJ expiry. The component belongs
-- to the summoned actor, so its timeout and owner survive save and restore.
local system = {}

-- Source timeout kills an unspent ball lightning or charged prism rather
-- than dismissing it. Mark it dead here; actor.death owns the one blast.
local function pending_explosion(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)
    local state = ctx:get(entity, component.SUMMON_CONSTRUCT)

    if not actor or not state then
        return false
    end

    if actor.kind_id == monsters.MONS_BALL_LIGHTNING then
        return state.charge == 0
    end

    return actor.kind_id == monsters.MONS_FULMINANT_PRISM and
        state.charge > 0 and state.charge < 3
end

-- Summon teardown runs after constriction and before ordinary actor death cleanup.
function system.update(ctx, active)
    local player = ctx:player()

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)
        local health = ctx:get(entity, component.HEALTH)
        local haunting = ctx:get(entity, component.SUMMON_HAUNTING)

        if haunting then
            local victim = ctx:get(haunting.target, component.HEALTH)

            if not victim or victim.current <= 0 then
                ctx:remove(entity, component.SUMMON_HAUNTING)
            end
        end

        local owner_health = ctx:get(state.owner, component.HEALTH)
        local dead_owner = state.owner ~= player and
            (not owner_health or owner_health.current <= 0)

        -- The source monster orb keeps flying when its caster dies. The
        -- dead actor is about to be removed, so let this independent
        -- projectile own its remaining finite lifetime and saved link.
        if state.source_id == spells.SPELL_IOOD and
            ctx:has(entity, zap_ids.component.IOOD) and dead_owner then
            state.owner = entity
            ctx:set(entity, component.SUMMON, state)
            owner_health = health
        end

        local orphaned = state.owner ~= player and
            (not ctx:has(state.owner, component.ACTOR) or
                not owner_health or owner_health.current <= 0)
        local expired = active == player and state.expires_aut > 0 and
            ctx:aut() >= state.expires_aut

        local dead_vortex = state.source_id == spells.SPELL_FIRE_STORM and
            health and health.current <= 0
        local dead_spore = state.source_id == spells.SPELL_SPORULATE and
            health and health.current <= 0
        local dead_inferno = state.source_id == spells.SPELL_STOKE_FLAMES and
            health and health.current <= 0
        local explosive = pending_explosion(ctx, entity)

        if explosive and expired and health and health.current > 0 then
            health.current = 0
            ctx:set(entity, component.HEALTH, health)
        end

        local dead_explosive = explosive and health and
            health.current <= 0

        if (entity ~= active or orphaned) and
            not dead_vortex and not dead_spore and not dead_inferno and
            not dead_explosive and
            (orphaned or expired or not health or health.current <= 0) then
            local position = ctx:get(entity, component.POSITION)
            local seen = visibility.player_sees(ctx, position)

            if state.source_id == spells.SPELL_SPORULATE then
                spore.explode(ctx, entity)
            else
                summons.expire(ctx, entity)
            end

            if expired and seen then
                ctx:emit(channels.SPELL,
                    "A summoned creature fades away.")
            end
        end
    end
end

register.system({
    id = "magic.summon.expiry",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
