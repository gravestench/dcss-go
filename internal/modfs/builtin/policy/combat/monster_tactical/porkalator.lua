local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local monsters = require("ids.monsters")
local tactical = require("constants.monster_tactical")

local pork = {}

-- Save the original body before fixed-form polymorph replaces it.
function pork.remember(ctx, target)
    if ctx:has(target, tactical.PORKALATOR_ORIGINAL) then
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)
    local marker = ctx:get(target, component.MONSTER_POLYMORPH)

    ctx:add(target, tactical.PORKALATOR_ORIGINAL, {
        kind_id = actor.kind_id,
        speed = actor.speed,
        max_hp = health.max,
        polymorph_original_kind_id = marker and
            marker.original_kind_id or "",
    })
end

-- dactions.cc restores every porkalated hog when Kirke dies and carries
-- its current fractional injury into the original body's HP scale.
function pork.restore_on_kirke_death(ctx, _, definition)
    if definition.id ~= monsters.MONS_KIRKE then
        return false
    end

    for _, target in ipairs(ctx:query({
        tactical.PORKALATOR_ORIGINAL,
        component.ACTOR,
        component.HEALTH,
    })) do
        local original = ctx:get(target, tactical.PORKALATOR_ORIGINAL)
        local actor = ctx:get(target, component.ACTOR)
        local health = ctx:get(target, component.HEALTH)

        if health.current > 0 and
            (actor.kind_id == monsters.MONS_HOG or
                actor.kind_id == monsters.MONS_HELL_HOG or
                actor.kind_id == monsters.MONS_HOLY_SWINE) then
            local ratio = health.current / health.max

            actor.kind_id = original.kind_id
            actor.speed = original.speed
            health.max = original.max_hp
            health.current = math.max(1, math.floor(ratio * health.max))
            ctx:set(target, component.ACTOR, actor)
            ctx:set(target, component.HEALTH, health)

            local old_kind = original.polymorph_original_kind_id

            if old_kind ~= "" then
                ctx:set(target, component.MONSTER_POLYMORPH, {
                    original_kind_id = old_kind,
                })
            else
                ctx:remove(target, component.MONSTER_POLYMORPH)
            end

            ctx:remove(target, tactical.PORKALATOR_ORIGINAL)
        end
    end

    return false
end

death_hooks.add("porkalator.kirke", pork.restore_on_kirke_death)

return pork
