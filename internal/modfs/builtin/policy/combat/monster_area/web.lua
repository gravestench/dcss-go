-- A magical web sticks after beam damage has already reached the actor.
-- It does not make the random pass-through roll used by stepping into a
-- permanent web trap. Source: traps.cc:ensnare and beam.cc:BEAM_ENSNARE.
-- Example: web.after_hit(ctx, caster, monster) gives a medium monster
-- a saved web hold and leaves a disposable trap on ordinary floor.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local form_ids = require("constants.form_ids")
local forms = require("policy.magic.effects.forms.player")
local held = require("policy.traps.held")
local placement = require("policy.traps.placement")
local size = require("constants.size")
local terrain = require("constants.terrain")

local web = {}

-- Monster flags can come from either the kind or its genus catalog.
-- This source predicate also covers insubstantial bodies.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Giant actors, web-immune monsters, and actors already held cannot gain
-- another web. The player's current species supplies body size here.
local function eligible(ctx, defender)
    if ctx:has(defender, component.TRAP_HELD) then
        return false
    end

    local definition
    local body_size

    if ctx:has(defender, component.PLAYER) then
        local identity = ctx:get(defender, component.PLAYER)
        local active = ctx:get(defender, component.PLAYER_FORM)

        -- Source player::is_web_immune grants Spider Form immunity. Other
        -- transformations change body size without changing species.
        if active and active.remaining_aut > 0 and
            active.form_id == form_ids.SPIDER then
            return false
        end

        definition = catalog.get("species", identity.species_id)
        body_size = forms.modifiers(ctx, defender).size or definition.size
    else
        local actor = ctx:get(defender, component.ACTOR)

        definition = catalog.get("monsters", actor.kind_id)
        body_size = definition.size_id

        if has_flag(definition, flags.WEB_IMMUNE) or
            has_flag(definition, flags.INSUBSTANTIAL) then
            return false
        end
    end

    return (size.rank[body_size] or 0) < size.rank[size.GIANT]
end

-- Hold the actor first, then leave a temporary web only on floor terrain.
-- Non-floor terrain can still hold the actor for one escape attempt.
function web.after_hit(ctx, _, defender)
    local health = ctx:get(defender, component.HEALTH)

    -- Beam damage has already run. A lethal hit may have removed the actor,
    -- and a corpse cannot own a new web restraint or temporary trap.
    if not health or health.current <= 0 or
        not eligible(ctx, defender) or
        not held.catch_web(ctx, defender) then
        return false
    end

    local position = ctx:get(defender, component.POSITION)

    if position and ctx:cell(position.level_id,
        position.x, position.y) == terrain.DNGN_FLOOR then
        placement.temporary_web(ctx, position.level_id,
            position.x, position.y)
    end

    if ctx:has(defender, component.PLAYER) then
        ctx:emit("spell", "You are caught in a web!")
    else
        ctx:emit("spell", "A monster is caught in a web!")
    end

    return true
end

return web
