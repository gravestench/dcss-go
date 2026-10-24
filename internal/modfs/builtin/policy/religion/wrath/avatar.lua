-- God spell wrath casts through a shadow at the player's feet. The shadow
-- becomes an inert ECS source if a burn, cloud, terrain change, or summon
-- still needs its attribution after the spell ends.
local catalog = require("policy.catalog")
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local monster_spells = require("policy.combat.monster_spells")
local monsters = require("ids.monsters")
local spell_flags = require("constants.spell_flags")
local target_kind = require("constants.target_kind")

local avatar = {}

local names = {
    [gods.TROG] = "the fiery rage of Trog",
    [gods.YREDELEMNUL] = "the anger of Yredelemnul",
    [gods.MAKHLEB] = "the fury of Makhleb",
    [gods.VEHUMET] = "the wrath of Vehumet",
    [gods.FEDHAS] = "the enmity of Fedhas Madash",
}

-- Mods may introduce a god without adding a central avatar name entry.
-- Source gods keep their exact authored wrath phrasing above.
local function source_name(god_id)
    local known = names[god_id]

    if known then
        return known
    end

    return "the wrath of " ..
        catalog.get(categories.GODS, god_id).name
end

-- Only these effects keep an actor reference after the cast. Every query
-- uses production component schemas, so a save cannot silently orphan a
-- continuing burn, cloud, terrain change, or summoned creature.
local references = {
    {
        id = component.STICKY_FLAME,
        field = "source",
        entity = true,
    },
    {
        id = component.SUMMON,
        field = "owner",
        entity = true,
    },
    {
        id = component.WORLD_CLOUD,
        field = "source_actor_id",
    },
    {
        id = component.TEMPORARY_TERRAIN,
        field = "source_actor_id",
    },
}

-- A retained source lives only while a saved effect names it. This check
-- also works immediately after casting, before the next ECS system tick.
local function referenced(ctx, source)
    local source_id = ctx:id(source)

    for _, reference in ipairs(references) do
        for _, entity in ipairs(ctx:query({ reference.id })) do
            local state = ctx:get(entity, reference.id)
            local value = state[reference.field]

            if value == source or
                not reference.entity and value == source_id then
                return true
            end
        end
    end

    return false
end

-- Remove one inert source only after all ongoing effects have expired.
-- The cleanup system calls this each turn; tests can call it directly.
function avatar.cleanup(ctx)
    for _, source in ipairs(ctx:query({
        component.RELIGION_AVATAR_SOURCE,
    })) do
        if not referenced(ctx, source) then
            ctx:destroy(source)
        end
    end
end

-- Saves must not turn an inert source into a second map actor or silently
-- redirect its god credit. Require a real ongoing effect to own the source.
function avatar.validate(ctx)
    for _, source in ipairs(ctx:query({
        component.RELIGION_AVATAR_SOURCE,
    })) do
        local state = ctx:get(source,
            component.RELIGION_AVATAR_SOURCE)
        local override = ctx:get(source,
            component.VAULT_ACTOR_OVERRIDES)

        if not override or
            override.god_id ~= state.god_id or
            override.attitude ~= attitudes.HOSTILE or
            override.custom_name ~= source_name(state.god_id) or
            ctx:has(source, component.ACTOR) or
            ctx:has(source, component.HEALTH) or
            ctx:has(source, component.POSITION) or
            not referenced(ctx, source) then
            error("invalid saved god avatar source " .. ctx:id(source))
        end
    end
end

-- Cloud spells and explosions save a cell target; other beams save the
-- player entity. Both preserve the source's zero-length feet aim.
local function feet_plan(ctx, shadow, player, spell_id, effect)
    local spell = catalog.get(categories.SPELLS, spell_id)

    -- Some spells carry per-cast data in their own plan. Give those
    -- effects first chance to build a feet plan without a central switch.
    if effect.feet_plan then
        return effect.feet_plan(ctx, shadow, player)
    end

    -- Self enchant spells have no beam profile. Use their own registered
    -- plan, whose target is the temporary source rather than the player.
    for _, flag in ipairs(spell.flags or {}) do
        if flag == spell_flags.SELF_ENCHANT then
            return effect.plan(ctx, shadow, player)
        end
    end

    local profile = catalog.get(categories.MONSTER_BEAMS, spell_id)
    local area = profile.is_explosion

    for _, flag in ipairs(spell.flags or {}) do
        area = area or flag == spell_flags.CLOUD
    end

    local position = ctx:get(player, component.POSITION)

    if area then
        return {
            kind = target_kind.CELL,
            level_id = position.level_id,
            x = position.x,
            y = position.y,
            dx = 0,
            dy = 0,
            at_feet = true,
        }
    end

    return {
        kind = target_kind.ENTITY,
        entity = player,
        dx = 0,
        dy = 0,
        at_feet = true,
    }
end

-- A source shadow has the player's HD and position, but is never placed in
-- the grid. Its separate identity credits this god rather than the player.
local function create(ctx, player, god_id)
    local position = ctx:get(player, component.POSITION)
    local health = ctx:get(player, component.HEALTH)
    local level = ctx:get(player, component.PROGRESSION).level
    local shadow = ctx:create()

    ctx:add(shadow, component.ACTOR, {
        kind_id = monsters.MONS_PLAYER_SHADOW,
        speed = 10,
    })
    ctx:add(shadow, component.POSITION, position)
    ctx:add(shadow, component.HEALTH, {
        current = health.current,
        max = health.max,
    })
    ctx:add(shadow, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.HOSTILE,
        god_id = god_id,
        hit_dice = level,
        custom_name = source_name(god_id),
        name_adjective = false,
    })

    return shadow
end

-- Keep module loading, plan construction, and effect resolution inside one
-- failure boundary. A missing mod spell must not leave a shadow behind.
local function resolve(ctx, shadow, player, god_id, spell_id, message)
    local effect = monster_spells.effect(spell_id)
    local plan = feet_plan(ctx, shadow, player, spell_id, effect)

    ctx:emit(channels.RELIGION,
        message or source_name(god_id) ..
            " rains destruction down upon you!")

    return effect.resolve(ctx, shadow, player, nil, plan)
end

-- Source get_avatar may fail before spell selection if another actor owns
-- the player's cell. Check first so branch RNG stays in source order.
function avatar.available(ctx, player, god_id)
    local position = ctx:get(player, component.POSITION)
    local occupant = ctx:actor_at(position.level_id, position.x, position.y)

    if occupant and occupant ~= player then
        local god = catalog.get(categories.GODS, god_id)

        ctx:emit(channels.RELIGION, god.name .. " has no time to deal with you just now.")
        return false
    end

    return true
end

-- Resolve a priest cast through its registered spell effect. The caster
-- starts at the player's feet, then leaves the grid; ongoing effects keep
-- its god credit. Recheck availability for direct casts and mod abilities.
function avatar.cast(ctx, player, god_id, spell_id, message)
    if not avatar.available(ctx, player, god_id) then
        return false
    end

    local shadow = create(ctx, player, god_id)
    local ok, result = pcall(resolve, ctx, shadow, player,
        god_id, spell_id, message)

    if not ok then
        ctx:destroy(shadow)
        error(result)
    end

    if referenced(ctx, shadow) then
        ctx:remove(shadow, component.POSITION)
        ctx:remove(shadow, component.HEALTH)
        ctx:remove(shadow, component.ACTOR)
        ctx:add(shadow, component.RELIGION_AVATAR_SOURCE, {
            god_id = god_id,
        })
    else
        ctx:destroy(shadow)
    end

    return true
end

return avatar
