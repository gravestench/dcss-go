local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local net = require("policy.combat.net")
local poison = require("policy.combat.monster_poison")
local slow = require("policy.combat.monster_slow")
local sticky_flame = require("policy.magic.effects.zaps.sticky_flame")

local summons = {}

-- Summoned creatures belong to their caster, not the scenario's starting
-- population. Their ownership and expiry survive a save and restore.
function summons.validate(ctx, entity, actor, position, ai, state, current_aut)
    local permanent_spell = state.spell_id == spells.SPELL_SIMULACRUM or
        state.spell_id == spells.SPELL_DEATH_CHANNEL or
        state.spell_id == spells.SPELL_ANIMATE_DEAD or
        state.spell_id == spells.SPELL_NECROTISE
    local permanent = permanent_spell and state.expires_aut == 0

    if state.owner ~= ctx:player() or state.spell_id == "" or
        (not permanent and state.expires_aut <= current_aut) or
        state.heads < 0 then
        error("summon " .. ctx:id(entity) .. " has invalid ownership or expiry")
    end

    if not catalog.get("spells", state.spell_id) then
        error("summon " .. ctx:id(entity) .. " has unknown origin spell")
    end

    local wander = ai.behavior == "wander" and
        ai.memory_until_aut == 0 and
        ((ai.target_x == 0 and ai.target_y == 0) or
            ctx:walkable(position.level_id, ai.target_x, ai.target_y))
    local seek = ai.behavior == "seek" and
        ctx:walkable(position.level_id, ai.target_x, ai.target_y) and
        ai.memory_until_aut >= 0 and
        ai.memory_until_aut <= current_aut + 550

    if not wander and not seek then
        error("summon " .. ctx:id(entity) .. " has invalid saved AI role")
    end

    local segment = ctx:get(entity, component.SUMMON_SEGMENT)

    if segment then
        local head = ctx:get(segment.head, component.SUMMON)
        local marker = ctx:get(segment.gateway, component.SUMMON_GATEWAY)
        local head_actor = ctx:get(segment.head, component.ACTOR)

        if state.spell_id ~= spells.SPELL_MALIGN_GATEWAY or
            actor.kind_id ~= monsters.MONS_ELDRITCH_TENTACLE_SEGMENT or
            not head or head.spell_id ~= state.spell_id or
            head.owner ~= state.owner or
            not marker or marker.tentacle_id ~= ctx:id(segment.head) or
            not head_actor or head_actor.kind_id ~= monsters.MONS_ELDRITCH_TENTACLE or
            state.expires_aut ~= head.expires_aut or
            segment.index < 1 or segment.index > 4 then
            error("summon " .. ctx:id(entity) .. " has an invalid tentacle link")
        end
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if not slow.validate(ctx, entity, definition, actor) then
        error("summon " .. ctx:id(entity) .. " has invalid speed")
    end

    net.validate(ctx, entity, position)
    poison.validate(ctx, entity)
    sticky_flame.validate(ctx, entity)
end

return summons
