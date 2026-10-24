-- Xom enchants one hostile through the ordinary saved monster statuses.
local catalog = require("policy.catalog")
local component = require("constants.component")
local confusion = require("policy.religion.xom.confusion")
local constructs = require("constants.monster_construct_components")
local events = require("ids.xom_events")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local boon_eligibility = require("policy.combat.monster_support.boon_eligibility")
local boons = require("policy.combat.monster_support.boons")
local chaos_effects = require("constants.chaos_effects")
local chaos_status = require("policy.combat.monster_target_brands.chaos_status")
local duration = require("policy.combat.monster_support.duration")
local invisibility = require("policy.combat.monster_support.invisibility")
local paralysis = require("policy.magic.effects.zaps.paralysis")
local slow = require("policy.combat.monster_slow")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local streams = require("constants.rng_streams")
local willpower = require("constants.willpower")

local effect = {}

-- A divine enchant targets one random nearby hostile with finite will.
-- Return the same list to the selector before it spends the action gate.
function effect.enchant_candidates(ctx, player)
    local candidates = {}

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        if confusion.hostile(ctx, monster) then
            local actor = ctx:get(monster, component.ACTOR)
            local definition = actor and catalog.get("monsters",
                actor.kind_id)

            if definition and definition.willpower ~=
                willpower.INVULNERABLE then
                candidates[#candidates + 1] = monster
            end
        end
    end

    return candidates
end

-- The four helpful-to-player flavors share existing saved monster statuses.
-- Xom bypasses ordinary spell targeting and chooses the flavor himself.
local function good_enchantment(ctx, monster, definition, index, stream)
    if index == 1 then
        return stasis.apply_petrify(ctx, monster)
    end

    if index == 2 then
        return slow.apply(ctx, monster, definition, nil, stream)
    end

    if index == 3 then
        return paralysis.apply_unresisted(ctx, monster, definition, 50)
    end

    return allegiance.apply_charm(ctx, monster, stream)
end

-- Beneficial monster flavors use ordinary Haste, Might, Chaos Agility,
-- Invisibility, and resistance timers. No Xom-only status can drift from
-- the combat rules that consume those components.
local function bad_enchantment(ctx, monster, index, stream)
    if index == 1 and boon_eligibility.haste(ctx, monster) then
        return boons.haste(ctx, monster,
            duration.beneficial(ctx, monster, stream))
    end

    if index == 2 and boon_eligibility.might(ctx, monster) then
        return boons.might(ctx, monster,
            duration.beneficial(ctx, monster, stream))
    end

    if index == 3 and boon_eligibility.might(ctx, monster) then
        return chaos_status.apply(ctx, monster,
            chaos_effects.AGILITY,
            duration.beneficial(ctx, monster, stream))
    end

    if index == 4 then
        return invisibility.grant(ctx, monster,
            duration.beneficial(ctx, monster, stream))
    end

    if index == 5 and
        not ctx:has(monster, constructs.RESISTANCE) then
        return ctx:add(monster, constructs.RESISTANCE, {
            remaining_aut = duration.beneficial(ctx, monster, stream),
        })
    end
end

-- Draw the target before the flavor, as source choose_random_nearby_monster
-- does. A modded resistant monster may make the chosen flavor ineffective;
-- Xom still spent his action on it.
local function enchant_monster(ctx, player, helpful, stream)
    local candidates = effect.enchant_candidates(ctx, player)

    if #candidates == 0 then
        return false
    end

    local monster = candidates[ctx:random(stream, #candidates) + 1]
    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if helpful then
        local index = ctx:random(stream, 4) + 1

        good_enchantment(ctx, monster, definition, index, stream)
    else
        local index = ctx:random(stream, 5) + 1

        bad_enchantment(ctx, monster, index, stream)
    end

    return true
end

-- Event definitions select this owner directly; no cross-family switch.
function effect.apply(ctx, player, event_id, _, request)
    local stream = request and request.stream or streams.RELIGION

    if event_id == events.GOOD_ENCHANT_MONSTER then
        return enchant_monster(ctx, player, true, stream)
    end

    if event_id == events.BAD_ENCHANT_MONSTER then
        return enchant_monster(ctx, player, false, stream)
    end

    error("enchantment effect received another Xom event")
end

return effect
