-- Gazes select a visible actor by identity and apply a status at the end
-- of the cast. A creature between endpoints cannot intercept eye contact.
local catalog = require("policy.catalog")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local flags = require("constants.monster_flags")
local hex_status = require("policy.combat.monster_hexes.status")
local monster_stats = require("policy.combat.monster_stats")
local monster_invisibility = require(
    "policy.combat.monster_support.invisibility")
local player_invisibility = require("policy.potions.invisibility")

local gazes = {}

-- Source `can_see` checks creature invisibility as well as map geometry.
-- Temporary Corona reveals an invisible monster; see-invisible is a
-- species trait of the caster rather than a property of the ray.
local function visible_actor(ctx, caster, foe)
    local caster_actor = ctx:get(caster, component.ACTOR)
    local caster_def = catalog.get("monsters", caster_actor.kind_id)
    local enchant = ctx:get(caster, component.MONSTER_ENCHANT)

    if enchant and enchant.blind_aut > 0 then
        return false
    end

    if ctx:has(foe, component.PLAYER) then
        return player_invisibility.visible_to(ctx, foe, caster)
    end

    local foe_actor = ctx:get(foe, component.ACTOR)

    if not foe_actor then
        return false
    end

    local foe_def = catalog.get("monsters", foe_actor.kind_id)
    local invisible = monster_invisibility.active(ctx, foe)

    for _, flag in ipairs(foe_def.flags or {}) do
        invisible = invisible or flag == flags.INVISIBLE
    end

    if not invisible or hex_status.backlit(ctx, foe) then
        return true
    end

    for _, flag in ipairs(caster_def.flags or {}) do
        if flag == flags.SEE_INVISIBLE then
            return true
        end
    end

    return false
end

-- Example: gazes.plan(ctx, eye, player, SPELL_PARALYSIS_GAZE) returns an
-- entity plan through another actor but refuses a hidden or invisible foe.
function gazes.plan(ctx, caster, foe, spell_id)
    if not foe or not visible_actor(ctx, caster, foe) then
        return nil
    end

    return direct.plan(ctx, caster, foe, spell_id)
end

-- The saved target handle must still name an actor on the caster's level.
function gazes.require(ctx, caster, foe, plan)
    direct.require(ctx, caster, foe, plan)

    if not ctx:has(foe, component.HEALTH) then
        error("gaze target has no health")
    end

    return foe
end

-- Source spell HD includes temporary spell empowerment, but ordinary HD
-- remains separate for Weakening Gaze's `get_hit_dice()` call.
function gazes.hit_dice(ctx, caster, spell)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if spell then
        return monster_stats.spell_hit_dice(ctx, caster, definition)
    end

    return monster_stats.hit_dice(ctx, caster, definition)
end

return gazes
