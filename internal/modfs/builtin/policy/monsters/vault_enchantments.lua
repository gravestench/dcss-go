-- Theory of operation: DES perm_ench: installs an ordinary live status and
-- marks its source as permanent on the same ECS actor. Existing combat and
-- AI read the status components; only their expiry systems need the marker.
local component = require("constants.component")
local enchantments = require("constants.vault_monster_enchantments")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")

local vault_enchantments = {}

-- Check one source status without relying on presence of unrelated statuses.
function vault_enchantments.active(ctx, actor, name)
    local state = ctx:get(actor, component.VAULT_PERMANENT_ENCHANTMENTS)

    return state ~= nil and state.active[name] == true
end

-- Dispel removes a live status and its permanent claim together. Otherwise
-- a later temporary application could inherit the old vault lifetime.
function vault_enchantments.clear(ctx, actor, name)
    local state = ctx:get(actor, component.VAULT_PERMANENT_ENCHANTMENTS)

    if not state or not state.active[name] then
        return
    end

    state.active[name] = nil

    if next(state.active) then
        ctx:set(actor, component.VAULT_PERMANENT_ENCHANTMENTS, state)
    else
        ctx:remove(actor, component.VAULT_PERMANENT_ENCHANTMENTS)
    end
end

-- The factory validates the complete list before allocating an actor, so
-- a bad mod cannot leave half a monster or equipment on the level.
function vault_enchantments.validate(names)
    for _, name in ipairs(names or {}) do
        if not enchantments.VALID[name] then
            error("unknown permanent monster enchantment " .. tostring(name))
        end
    end
end

-- Paralysis and source dumbness both stop the monster from acting.
local function paralyze(ctx, actor)
    if not ctx:has(actor, component.PARALYSIS) then
        ctx:add(actor, component.PARALYSIS, { remaining_aut = 1 })
    end
end

-- Source madness follows confusion's movement and action rules.
local function confuse(ctx, actor)
    if not ctx:has(actor, component.MONSTER_CONFUSION) then
        ctx:add(actor, component.MONSTER_CONFUSION, { remaining_aut = 1 })
    end
end

-- Blindness shares a component with corrosion and invisibility, so only
-- initialize its field and keep the siblings at their schema defaults.
local function blind(ctx, actor)
    ctx:add(actor, component.MONSTER_ENCHANT, { blind_aut = 1 })
end

-- Backlighting is read from the same hex status as temporary Corona.
local function corona(ctx, actor)
    ctx:add(actor, component.HEX_STATUS, { corona_aut = 1 })
end

-- A permanent mute blocks the same spell and shout paths as temporary mute.
local function mute(ctx, actor)
    ctx:add(actor, component.MONSTER_MUTE, { remaining_aut = 1 })
end

-- Use the source speed division and retain the unslowed speed for saves.
local function slow(ctx, actor)
    local identity = ctx:get(actor, component.ACTOR)

    if identity.speed == 0 then
        return
    end

    local base_speed = identity.speed

    identity.speed = roll.random_divide(ctx, base_speed * 2, 3,
        streams.MELEE)
    ctx:set(actor, component.ACTOR, identity)
    ctx:add(actor, component.PROJECTILE_SLOW, {
        base_speed = base_speed,
        remaining_aut = 1,
    })
end

-- An authored petrified plant begins fully stonebound. The ordinary stasis
-- component gives combat and AI their existing petrification behavior;
-- the permanent claim below prevents its clock from releasing the plant.
local function petrified(ctx, actor)
    ctx:add(actor, component.MONSTER_STASIS, {
        petrified_aut = 1,
    })
end

local installers = {
    [enchantments.BLIND] = blind,
    [enchantments.CONFUSION] = confuse,
    [enchantments.CORONA] = corona,
    [enchantments.DUMB] = paralyze,
    [enchantments.MAD] = confuse,
    [enchantments.MUTE] = mute,
    [enchantments.PARALYSIS] = paralyze,
    [enchantments.PETRIFIED] = petrified,
    [enchantments.SLOW] = slow,
}

-- Deduplicate source tags before attaching components. The marker survives
-- saves and lets the ordinary status clocks skip only these authored effects.
function vault_enchantments.install(ctx, actor, names)
    if not names or #names == 0 then
        return
    end

    vault_enchantments.validate(names)

    local active = {}
    local unique = {}

    for _, name in ipairs(names) do
        if not active[name] then
            active[name] = true
            unique[#unique + 1] = name
        end
    end

    ctx:add(actor, component.VAULT_PERMANENT_ENCHANTMENTS, {
        active = active,
    })

    for _, name in ipairs(unique) do
        installers[name](ctx, actor)
    end
end

return vault_enchantments
