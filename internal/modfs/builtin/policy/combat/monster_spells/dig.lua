local beam_power = require("policy.combat.monster_beams.power")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local digging = require("policy.world.digging")
local spells = require("ids.spells")
local target_kind = require("constants.target_kind")
local target = require("policy.combat.monster_spell_target")
local senses = require("policy.character.senses")

local dig = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_DIG)

-- Monster Dig is offered only when the ray toward its foe reaches breakable wall terrain.
-- Example: dig.plan(ctx, caster, foe) with breakable wall toward foe -> entity plan aimed through that wall
-- Requires a breakable wall on the foe-directed ray.
function dig.plan(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)
    local destination = ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id then
        return nil
    end

    local reach = beam_power.spell_range(ctx, caster, profile)
    local wall = digging.first_wall(ctx, source.level_id,
        source.x, source.y, destination.x, destination.y, reach)

    if not wall or not digging.can_break(wall.feature) then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
        dx = destination.x - source.x,
        dy = destination.y - source.y,
    }
end

-- Recheck direction at resolution so a moved foe cannot redirect a planned Dig ray.
function dig.resolve(ctx, caster, foe, _, plan)
    target.require_entity(plan, foe)

    local source = ctx:get(caster, component.POSITION)
    local destination = ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id or
        plan.dx ~= destination.x - source.x or
        plan.dy ~= destination.y - source.y then
        error("Dig target moved after planning")
    end

    local reach = beam_power.spell_range(ctx, caster, profile)
    local changed, removed = digging.ray(ctx, source.level_id,
        source.x, source.y, destination.x, destination.y, reach)

    if changed == 0 then
        return
    end

    -- A hidden caster can still break a visible wall. Describe the rock
    -- only if at least one removed wall was in the player's view.
    for _, cell in ipairs(removed) do
        if senses.player_sees_cell(ctx, cell) then
            ctx:emit("spell", "Some rock shatters into small pieces.")
            return
        end
    end
end

return dig
