local spells = require("ids.spells")
local monsters = require("ids.monsters")
local items = require("ids.items")
local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local traps = require("ids.traps")
local net = require("policy.combat.net")
local poison = require("policy.combat.monster_poison")
local slow = require("policy.combat.monster_slow")
local sticky_flame = require("policy.magic.effects.zaps.sticky_flame")
local brands = require("constants.weapon_brands")

local summons = {}

-- Summoned creatures belong to their caster, not the scenario's starting
-- population. Their ownership and expiry survive a save and restore.
function summons.validate(ctx, entity, actor, position, ai, state, current_aut)
    local permanent_spell = state.source_category == categories.SPELLS and
        (state.source_id == spells.SPELL_SIMULACRUM or
            state.source_id == spells.SPELL_DEATH_CHANNEL or
            state.source_id == spells.SPELL_ANIMATE_DEAD or
            state.source_id == spells.SPELL_NECROTISE)
    local trap_source = state.source_category == categories.TRAPS and
        state.source_id == traps.TRAP_ZOT
    local permanent = (permanent_spell or trap_source) and
        state.expires_aut == 0

    if state.owner ~= ctx:player() or state.source_id == "" or
        (not permanent and state.expires_aut <= current_aut) or
        state.heads < 0 then
        error("summon " .. ctx:id(entity) .. " has invalid ownership or expiry")
    end

    local spectral = ctx:get(entity, component.SPECTRAL_WEAPON)
    local item_source = state.source_category == categories.ITEMS and
        actor.kind_id == monsters.MONS_SPECTRAL_WEAPON and spectral
    local scroll_source = state.source_category == categories.ITEMS and
        (state.source_id == items.SCR_SUMMONING or
            state.source_id == items.SCR_BUTTERFLIES)

    if state.source_category ~= categories.SPELLS and
        state.source_category ~= categories.MUTATIONS and
        not trap_source and
        not item_source and not scroll_source then
        error("summon " .. ctx:id(entity) .. " has invalid origin category")
    end

    catalog.get(state.source_category, state.source_id)

    if spectral then
        local source = ctx:get(spectral.source_weapon, component.ITEM)
        local carrier = ctx:get(spectral.source_weapon,
            component.CARRIED_BY)
        local equipped = ctx:get(spectral.source_weapon,
            component.EQUIPPED)
        local energy = ctx:get(entity, component.MONSTER_ENERGY)

        if not item_source or not source or not carrier or not equipped or
            source.kind_id ~= state.source_id or
            source.ego ~= brands.SPECTRAL or
            carrier.holder ~= state.owner or
            equipped.slot ~= "weapon" or
            not energy or energy.points ~= 0 or
            spectral.triggered_aut > current_aut then
            error("summon " .. ctx:id(entity) .. " has invalid spectral bond")
        end
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

        if (state.source_id ~= spells.SPELL_MALIGN_GATEWAY and
            not trap_source) or
            actor.kind_id ~= monsters.MONS_ELDRITCH_TENTACLE_SEGMENT or
            not head or head.source_id ~= state.source_id or
            head.source_category ~= state.source_category or
            head.owner ~= state.owner or
            not marker or marker.tentacle_id ~= ctx:id(segment.head) or
            marker.source_id ~= state.source_id or
            marker.source_category ~= state.source_category or
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
