local catalog = require("policy.catalog")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local habitats = require("constants.monster_habitats")
local habitat = require("policy.combat.monster_habitat")
local holiness = require("constants.monster_holiness")
local intelligence = require("constants.monster_intelligence")
local monsters = require("ids.monsters")
local self_target = require("policy.combat.monster_support.self_target")
local shifter = require("policy.monsters.shapeshifter")
local stats = require("policy.combat.monster_stats")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}

-- mon-util.cc:mons_is_beast excludes magical animals and most dragons.
local function beast(definition)
    local natural = false

    for _, kind in ipairs(definition.holiness or {}) do
        natural = natural or kind == holiness.NATURAL
    end

    return natural and definition.intelligence_id == intelligence.ANIMAL and
        (definition.genus_id ~= monsters.MONS_DRAGON or
            definition.id == monsters.MONS_SWAMP_DRAGON) and
        definition.genus_id ~= monsters.MONS_UGLY_THING and
        definition.id ~= monsters.MONS_ICE_BEAST and
        definition.id ~= monsters.MONS_SKY_BEAST and
        definition.id ~= monsters.MONS_BUTTERFLY
end

-- Calling recruits existing animals outside the druid's sight. Recruited
-- animals are excluded while their saved patrol is still in progress.
local function candidates(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)
    local found = {}

    for _, target in ipairs(ctx:query({ component.ACTOR, component.POSITION,
        component.HEALTH })) do
        local actor = ctx:get(target, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)
        local position = ctx:get(target, component.POSITION)
        local health = ctx:get(target, component.HEALTH)

        if target ~= caster and health.current > 0 and
            origin.level_id == position.level_id and beast(definition) and
            targets.aligned(ctx, caster, target) and
            stats.hit_dice(ctx, target, definition) <= 20 and
            definition.habitat_id ~= habitats.WATER and
            definition.habitat_id ~= habitats.LAVA and
            not shifter.active(ctx, target) and
            not ctx:has(target, constructs.CALLED_BEAST) and
            not ctx:visible(origin.level_id, origin.x, origin.y,
                7, position.x, position.y) then
            found[#found + 1] = target
        end
    end

    return found
end

function effect.plan(ctx, caster, foe)
    local origin = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)

    if destination and destination.level_id == origin.level_id and
        #candidates(ctx, caster) > 0 then
        return self_target.plan(caster)
    end
end

-- mon-place.cc:find_habitable_spot_near uses reservoir sampling over
-- the full square, excluding its center and cells hidden from the area.
local function habitable_spot(ctx, target, level_id, x, y)
    local chosen
    local count = 0

    for dy = -3, 3 do
        for dx = -3, 3 do
            local px = x + dx
            local py = y + dy

            if (dx ~= 0 or dy ~= 0) and
                not ctx:actor_at(level_id, px, py) and
                ctx:visible_no_trans(level_id, x, y, 3, px, py) and
                habitat.at(ctx, target, level_id, px, py) then
                count = count + 1

                if ctx:random(streams.MONSTER_SPELL, count) == 0 then
                    chosen = {
                        x = px,
                        y = py,
                    }
                end
            end
        end
    end

    return chosen
end

-- Source tries twenty random areas within eleven squares of the foe,
-- looking for a free habitable cell within three squares outside its LOS.
local function relocate(ctx, caster, target, foe)
    local goal = ctx:get(foe, component.POSITION)
    local width, height = ctx:level_size(goal.level_id)

    for _ = 1, 20 do
        local x = goal.x + ctx:random(streams.MONSTER_SPELL, 23) - 11
        local y = goal.y + ctx:random(streams.MONSTER_SPELL, 23) - 11

        x = math.max(1, math.min(width - 2, x))
        y = math.max(1, math.min(height - 2, y))

        if not ctx:visible(goal.level_id, goal.x, goal.y, 7, x, y) then
            for _ = 1, 10 do
                local spot = habitable_spot(ctx, target, goal.level_id, x, y)

                if spot and not ctx:visible(goal.level_id, goal.x, goal.y,
                    7, spot.x, spot.y) then
                    ctx:move_actor(target, goal.level_id, spot.x, spot.y)
                    stasis.wake_hibernating(ctx, target)
                    ctx:add(target, constructs.CALLED_BEAST, {
                        target_id = ctx:id(foe),
                        x = goal.x,
                        y = goal.y,
                    })

                    return true
                end
            end
        end
    end

    return false
end

function effect.resolve(ctx, caster, foe, _, plan)
    self_target.require_caster(plan, caster)

    local found = candidates(ctx, caster)

    for index = #found, 2, -1 do
        local other = 1 + ctx:random(streams.MONSTER_SPELL, index)

        found[index], found[other] = found[other], found[index]
    end

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local minimum = stats.hit_dice(ctx, caster, definition) > 10 and 2 or 1
    local count = math.min(#found, minimum + ctx:random(streams.MONSTER_SPELL, 2))

    for index = 1, count do
        relocate(ctx, caster, found[index], foe)
    end
end

return effect
