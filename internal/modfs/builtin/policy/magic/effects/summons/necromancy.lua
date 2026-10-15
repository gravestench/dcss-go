local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local death_hooks = require("policy.combat.death_hooks")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local necromancy = {}

local function aura(ctx, player)
    return ctx:get(player, component.SUMMON_NECROMANCY) or {
        death_channel_expires_aut = 0,
        animate_dead_expires_aut = 0,
        animate_power = 0,
    }
end

local function increase(ctx, current, amount, cap)
    return ctx:aut() + math.min(cap, math.max(0, current - ctx:aut()) + amount)
end

local function natural(definition)
    for _, kind in ipairs(definition.holiness or {}) do
        if kind == "MH_NATURAL" then
            return true
        end
    end

    return false
end

function necromancy.raise(ctx, owner, spell_id, kind_id, base_kind_id, position)
    local base = catalog.get("monsters", base_kind_id)
    local hp = math.max(1, math.floor(base.average_hp_10x / 10))
    local options = {
        anchor = position,
        exact = { x = position.x, y = position.y },
        hp = hp,
        hd = math.max(1, base.hd),
        expires_aut = 0,
    }
    local creature = summons.spawn(ctx, owner, spell_id, kind_id, 0, 999,
        options)

    if not creature then
        options.exact = nil
        creature = summons.spawn(ctx, owner, spell_id, kind_id, 0, 999,
            options)
    end

    if creature then
        ctx:add(creature, "magic.summon_undead", {
            base_kind_id = base.id,
        })
    end

    return creature
end

-- Called after the dying actor leaves its grid cell, before its corpse roll.
-- Source: mon-death.cc:_animate_dead_reap and Death Channel branch.
function necromancy.on_death(ctx, definition, position, player_kill,
    consumed_corpse)
    if not player_kill then
        return false
    end

    local player = ctx:player()
    local state = ctx:get(player, component.SUMMON_NECROMANCY)

    if not state then
        return false
    end

    local player_position = ctx:get(player, component.POSITION)

    if player_position.level_id ~= position.level_id or
        not ctx:visible(position.level_id, player_position.x, player_position.y,
            7, position.x, position.y) then
        return false
    end

    if ctx:aut() < state.death_channel_expires_aut then
        if necromancy.raise(ctx, player, spells.SPELL_DEATH_CHANNEL,
            monsters.MONS_SPECTRAL_THING, definition.id, position) then
            ctx:emit("spell", "A spectral shape rises from the fallen monster.")
        end
    end

    if not consumed_corpse and ctx:aut() < state.animate_dead_expires_aut and
        natural(definition) and definition.leaves_corpse and
        summons.roll(ctx, 200) < 150 + math.floor(state.animate_power / 2) then
        if necromancy.raise(ctx, player, spells.SPELL_ANIMATE_DEAD,
            monsters.MONS_ZOMBIE, definition.id, position) then
            ctx:emit("spell", "The dead monster rises as a zombie.")
            return true
        end
    end

    return false
end

function necromancy.death_hook(ctx, _, definition, position, credited,
    consumed_corpse)
    return necromancy.on_death(ctx, definition, position, credited,
        consumed_corpse)
end

death_hooks.add("magic.summon.necromancy", necromancy.death_hook)

-- Source: spl-other.cc:cast_death_channel. Source duration units are turns;
-- Akara clocks are aut, so one source turn is ten aut.
function necromancy.resolve_death_channel(ctx, player, _, _, power)
    local state = aura(ctx, player)
    local amount = (30 + summons.roll(ctx,
        1 + math.floor(2 * power / 3))) * 10
    state.death_channel_expires_aut = increase(ctx,
        state.death_channel_expires_aut, amount, 2000)

    if ctx:has(player, component.SUMMON_NECROMANCY) then
        ctx:set(player, component.SUMMON_NECROMANCY, state)
    else
        ctx:add(player, component.SUMMON_NECROMANCY, state)
    end

    ctx:emit("spell", "Malign forces permeate your being, awaiting release.")
end

registry.add(spells.SPELL_DEATH_CHANNEL, {
    resolve = necromancy.resolve_death_channel,
})

-- Source: spl-other.cc:cast_animate_dead. The aura remains active for later
-- kills, rather than consuming existing floor corpses on cast.
function necromancy.resolve_animate_dead(ctx, player, _, _, power)
    local dismissed = false

    -- Source: spl-other.cc:_dismiss_dead. Recasting removes older
    -- permanent friendly zombies before refreshing the aura.
    for _, entity in ipairs(ctx:query({ component.SUMMON, component.ACTOR })) do
        local state = ctx:get(entity, component.SUMMON)
        local actor = ctx:get(entity, component.ACTOR)

        if state.owner == player and state.spell_id ==
            spells.SPELL_ANIMATE_DEAD and actor.kind_id == monsters.MONS_ZOMBIE then
            summons.expire(ctx, entity)
            dismissed = true
        end
    end

    local state = aura(ctx, player)
    local amount = (20 + summons.roll(ctx, 1 + power)) * 10
    state.animate_dead_expires_aut = increase(ctx,
        state.animate_dead_expires_aut, amount, 1000)
    state.animate_power = power

    if ctx:has(player, component.SUMMON_NECROMANCY) then
        ctx:set(player, component.SUMMON_NECROMANCY, state)
    else
        ctx:add(player, component.SUMMON_NECROMANCY, state)
    end

    if dismissed then
        ctx:emit("spell", "You dismiss your zombies and call upon the dead to rise afresh.")
    else
        ctx:emit("spell", "You call upon the dead to rise.")
    end
end

registry.add(spells.SPELL_ANIMATE_DEAD, {
    resolve = necromancy.resolve_animate_dead,
})

return necromancy
