local spells = require("ids.spells")
local component = require("constants.component")
local summons = require("policy.magic.effects.summons.common")
local vortex = require("policy.magic.effects.summons.fire_vortex")
local spore = require("policy.combat.monster_plants.spore")
local visibility = require("policy.combat.monster_summons.visibility")
local channels = require("constants.message_channels")

-- Theory of operation: Expired summons are torn down before ordinary death cleanup, preserving source-specific effects.
-- Source: monster::mark_summoned and ENCH_ABJ expiry. The component belongs
-- to the summoned actor, so its timeout and owner survive save and restore.
local system = {}

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

        if (entity ~= active or orphaned) and
            not dead_vortex and not dead_spore and not dead_inferno and
            (orphaned or expired or not health or health.current <= 0) then
            local position = ctx:get(entity, component.POSITION)
            local seen = visibility.player_sees(ctx, position)

            if state.source_id == spells.SPELL_SPORULATE then
                spore.explode(ctx, entity)
            elseif expired and state.source_id == spells.SPELL_FIRE_STORM then
                vortex.dissipate(ctx, entity)
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
