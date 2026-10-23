-- God spell wrath uses a temporary shadow at the player's feet. Only spells
-- whose effects finish within the cast can use this short-lived source.
local catalog = require("policy.catalog")
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local monster_spells = require("policy.combat.monster_spells")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local spell_flags = require("constants.spell_flags")
local target_kind = require("constants.target_kind")

local avatar = {}

local names = {
    [gods.TROG] = "the fiery rage of Trog",
    [gods.YREDELEMNUL] = "the anger of Yredelemnul",
}

local immediate = {
    [gods.TROG] = { [spells.SPELL_FIREBALL] = true },
    [gods.YREDELEMNUL] = { [spells.SPELL_BOLT_OF_DRAINING] = true },
}

-- Cloud spells and explosions save a cell target; other beams save the
-- player entity. Both preserve the source's zero-length feet aim.
local function feet_plan(ctx, player, spell_id)
    local profile = catalog.get(categories.MONSTER_BEAMS, spell_id)
    local spell = catalog.get(categories.SPELLS, spell_id)
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
        custom_name = names[god_id],
        name_adjective = false,
    })

    return shadow
end

-- Resolve one immediate source priest cast through the registered spell
-- effect. Persistent flames, clouds, and summons need durable god provenance
-- before they can be admitted to this owner.
function avatar.cast(ctx, player, god_id, spell_id, message)
    if not immediate[god_id] or not immediate[god_id][spell_id] then
        error("god avatar spell needs a durable source owner")
    end

    local position = ctx:get(player, component.POSITION)
    local occupant = ctx:actor_at(position.level_id, position.x, position.y)

    if occupant and occupant ~= player then
        local god = catalog.get(categories.GODS, god_id)

        ctx:emit(channels.RELIGION, god.name .. " has no time to deal with you just now.")
        return false
    end

    local shadow = create(ctx, player, god_id)
    local effect = monster_spells.effect(spell_id)

    ctx:emit(channels.RELIGION, message or names[god_id] .. " rains destruction down upon you!")
    local ok, result = pcall(effect.resolve, ctx, shadow, player, nil,
        feet_plan(ctx, player, spell_id))

    ctx:destroy(shadow)

    if not ok then
        error(result)
    end

    return true
end

return avatar
