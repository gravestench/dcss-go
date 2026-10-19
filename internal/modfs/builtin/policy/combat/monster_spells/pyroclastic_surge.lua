-- Pyroclastic Surge ignites each visible enemy on or beside visible lava.
-- Every eligible actor gets a separate Bolt of Fire damage roll; the
-- source does not trace a travelling ray from the caster to that actor.
-- Source: mon-cast.cc:_near_visible_lava and _cast_pyroclastic_surge.
-- Example: two foes beside one lava pool receive independent fire hits.
local actors = require("policy.combat.monster_area.actors")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local calculators = require("policy.combat.monster_beams.calculators")
local power = require("policy.combat.monster_beams.power")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_PYROCLASTIC_SURGE)
local SIGHT_RADIUS = 7

-- The source lava predicate includes the victim's own cell and its eight
-- neighbors. Both victim and lava cell must be in the caster's clear sight.
local function near_visible_lava(ctx, caster, victim)
    local source = ctx:get(caster, component.POSITION)
    local destination = ctx:get(victim, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id or
        not ctx:visible_no_trans(source.level_id,
            source.x, source.y, SIGHT_RADIUS,
            destination.x, destination.y) then
        return false
    end

    for y = destination.y - 1, destination.y + 1 do
        for x = destination.x - 1, destination.x + 1 do
            local feature = ctx:cell(destination.level_id, x, y)
            local lava = feature == terrain.DNGN_LAVA or
                feature == terrain.DNGN_LAVA_SEA

            if lava and
                ctx:visible_no_trans(source.level_id,
                    source.x, source.y, SIGHT_RADIUS, x, y) then
                return true
            end
        end
    end

    return false
end

-- The source AI offers this cast only when its selected foe can be hit.
-- The later cast may also catch other enemy actors beside visible lava.
function effect.plan(ctx, caster, foe)
    if not foe or not targets.enemy(ctx, caster, foe) or
        not near_visible_lava(ctx, caster, foe) then
        return nil
    end

    return self_target.plan(caster)
end

-- Recheck live geometry, then reuse the shared zap dice, armour,
-- resistance, and attributed HP owners for each enemy independently.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local spell_power = power.caster_power(ctx, caster, profile)
    local to_hit = calculators.to_hit(profile, spell_power)

    for _, victim in ipairs(actors.los(ctx, caster, SIGHT_RADIUS)) do
        if targets.enemy(ctx, caster, victim) and
            near_visible_lava(ctx, caster, victim) then
            contact.resolve(ctx, caster, victim,
                profile, spell_power, to_hit)
        end
    end
end

return effect
