-- Source: spl-summoning.cc:cast_infestation, beam.cc:BEAM_INFESTATION,
-- mon-death.cc:_infestation_create_scarab, and fineff.cc.
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local time = require("constants.time")
local component = require("constants.component")
local catalog = require("policy.catalog")
local death = require("policy.death")
local death_hooks = require("policy.combat.death_hooks")
local summons = require("policy.magic.effects.summons.common")
local common = require("policy.magic.effects.statuses.common")

local infestation = {}

local function duration(ctx, power)
    local bound = math.max(1, math.floor(power / 2))
    local average = math.floor((ctx:random("spell", bound) +
        ctx:random("spell", bound + 1)) / 2)

    return (5 + average) * time.AUT_PER_TURN
end

local function eligible(ctx, monster, definition, health)
    return not ctx:has(monster, component.SUMMON) and
        death.experience(definition, health.max) > 0
end

function infestation.prepare(ctx, player, _, dx, dy)
    local origin = ctx:get(player, component.POSITION)
    local x, y = origin.x + dx, origin.y + dy

    if not ctx:walkable(origin.level_id, x, y) then
        return "Something is in the way."
    end
end

function infestation.cast(ctx, player, intent, _, power)
    local origin = ctx:get(player, component.POSITION)
    local x, y = origin.x + intent.dx, origin.y + intent.dy
    ctx:emit("spell", "You call forth a plague of scarabs!")

    for _, monster in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local health = ctx:get(monster, component.HEALTH)
            local center = {
                x = x,
                y = y,
            }
            local distance = common.distance(position, center)

            if position.level_id == origin.level_id and
                health.current > 0 and distance <= 2 and
                ctx:visible(origin.level_id, x, y, 2,
                    position.x, position.y) then
                local actor = ctx:get(monster, component.ACTOR)
                local definition = catalog.get("monsters", actor.kind_id)

                if eligible(ctx, monster, definition, health) and
                    not ctx:has(monster, component.MONSTER_INFESTATION) then
                    ctx:add(monster, component.MONSTER_INFESTATION, {
                        remaining_aut = duration(ctx, power),
                    })
                    ctx:emit("spell", "The " .. definition.name ..
                        " is infested!")
                end
            end
        end
    end
end

function infestation.on_death(ctx, monster, definition, position)
    local mark = ctx:get(monster, component.MONSTER_INFESTATION)

    if not mark or mark.remaining_aut <= 0 then
        return false
    end

    local owner = ctx:player()
    local options = {
        anchor = position,
        exact = {
            x = position.x,
            y = position.y,
        },
        expires_aut = ctx:aut() + 50,
    }
    local scarab = summons.spawn(ctx, owner, spells.SPELL_INFESTATION,
        monsters.MONS_DEATH_SCARAB, 5, 999, options)

    if scarab then
        ctx:emit("spell", "A death scarab bursts from the " ..
            definition.name .. "!")
    end

    return true
end

function infestation.tick(ctx, monster)
    local mark = ctx:get(monster, component.MONSTER_INFESTATION)

    if not mark then
        return
    end

    mark.remaining_aut = math.max(0,
        mark.remaining_aut - time.AUT_PER_TURN)

    if mark.remaining_aut == 0 then
        ctx:remove(monster, component.MONSTER_INFESTATION)
    else
        ctx:set(monster, component.MONSTER_INFESTATION, mark)
    end
end

death_hooks.add("magic.status.infestation", infestation.on_death)

return infestation
