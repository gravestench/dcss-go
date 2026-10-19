local catalog = require("policy.catalog")
local component = require("constants.component")
local monsters = require("ids.monsters")
local monster_form = require("policy.magic.effects.statuses.polymorph")
local player_form = require("policy.magic.effects.forms.player")
local hex = require("policy.combat.monster_spells.hex")
local streams = require("constants.rng_streams")
local original = require("policy.combat.monster_tactical.porkalator")

local pork = {}

local ghost_demons = {
    [monsters.MONS_PLAYER_GHOST] = true,
    [monsters.MONS_PANDEMONIUM_LORD] = true,
}

local function hog_kind(definition)
    for _, holiness in ipairs(definition.holiness or {}) do
        if holiness == "MH_DEMONIC" then
            return monsters.MONS_HELL_HOG
        elseif holiness == "MH_HOLY" then
            return monsters.MONS_HOLY_SWINE
        elseif holiness == "MH_NATURAL" then
            return monsters.MONS_HOG
        end
    end

    return nil
end

-- beam.cc allows natural, demonic, and holy bodies, excluding existing
-- hogs and ghost demons whose original form cannot be restored.
function pork.viable(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        return player_form.can_polymorph(ctx, defender)
    end

    local actor = ctx:get(defender, component.ACTOR)

    if not actor or ghost_demons[actor.kind_id] then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local hog = hog_kind(definition)

    return hog ~= nil and hog ~= actor.kind_id
end

-- Porkalator uses the hex will contest, then forces a fixed pig form.
function pork.apply(ctx, caster, defender, profile)
    if ctx:has(defender, component.PLAYER) then
        local power = hex.enchantment_power(ctx, caster, profile)

        if not player_form.porkalator(ctx, defender, power) then
            ctx:emit("spell", "You feel a momentary urge to oink.")
        end

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    original.remember(ctx, defender)
    monster_form.fixed(ctx, defender,
        catalog.get("monsters", hog_kind(definition)),
        streams.MONSTER_SPELL)
end

return pork
