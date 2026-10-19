-- Wind Blast is a directional physical gale, not an ordinary beam hit.
-- Its actor, cloud, collision, and landing passes mirror evoke.cc:wind_blast.
local actors = require("policy.combat.monster_wind_actors")
local catalog = require("policy.catalog")
local clouds = require("policy.combat.monster_wind_clouds")
local component = require("constants.component")
local geometry = require("policy.combat.monster_wind_geometry")
local noise = require("policy.world.noise")
local stats = require("policy.combat.monster_stats")
local streams = require("constants.rng_streams")
local target = require("policy.combat.monster_summons.target")
local targets = require("policy.ai.targets")
local trajectory = require("policy.combat.trajectory")

local effect = {}

-- The source AI offers this slot only while the foe is inside four cells
-- and no aligned actor is between caster and foe on the cast ray.
function effect.plan(ctx, caster, foe)
    if not foe or not targets.enemy(ctx, caster, foe) then
        return nil
    end

    local plan = target.plan(ctx, caster, foe)

    if not plan then
        return nil
    end

    local source = ctx:get(caster, component.POSITION)

    if geometry.distance(source, plan) >= 4 or
        not geometry.visible_solid(ctx, source, plan) then
        return nil
    end

    local ray = trajectory.to_target(ctx, source.level_id,
        source.x, source.y, plan.x, plan.y, 7)

    if ray.blocked then
        return nil
    end

    for _, other in ipairs(ray.actors) do
        if other ~= foe and targets.aligned(ctx, caster, other) then
            return nil
        end
    end

    return plan
end

-- Default monster spell power is 12 times spell HD; brilliance changes
-- spell HD before this physical effect calculates its push and collision.
local function caster_power(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return stats.spell_hit_dice(ctx, caster, definition) * 12
end

-- Source radius is four cells, with a rounded power/60 chance of a fifth.
local function radius_for(ctx, power)
    local radius = 4 + math.floor(power / 60)
    local remainder = power % 60

    if remainder > 0 and
        ctx:random(streams.MONSTER_SPELL, 60) < remainder then
        radius = radius + 1
    end

    return math.min(5, radius)
end

-- The spell intent retains the foe's original cell. Push actors farthest
-- first, then clouds; collision and landing effects run after both passes.
function effect.resolve(ctx, caster, foe, _, plan)
    target.require_cell(ctx, caster, plan)

    if plan.entity ~= foe then
        error("Wind Blast target differs from selected foe")
    end

    local source = ctx:get(caster, component.POSITION)

    if not geometry.visible_solid(ctx, source, plan) then
        return false
    end

    local power = caster_power(ctx, caster)
    local radius = radius_for(ctx, power)
    local moved, blocked = actors.push(ctx, caster, source,
        plan, radius, power)

    clouds.push(ctx, source, plan, radius)
    noise.emit(ctx, source, 8, caster)
    actors.collisions(ctx, caster, blocked, power)
    actors.land(ctx, moved)

    return true
end

return effect
