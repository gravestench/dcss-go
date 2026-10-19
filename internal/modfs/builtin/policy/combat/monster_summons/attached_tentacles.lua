local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local intent = require("constants.intent")
local monsters = require("ids.monsters")
local targets = require("policy.ai.targets")
local tentacle = require("policy.magic.effects.summons.tentacle")

local attached = {}

-- The limb's own turn may attack an adjacent foe, but movement belongs to
-- its parent turn. Do not run a mutating retraction during melee selection.
function attached.attack(ctx, child, position)
    local target, distance = targets.nearest(ctx, child, position, 1)

    if target and distance == 1 then
        local destination = ctx:get(target, component.POSITION)

        return {
            kind = intent.MONSTER_MELEE,
            dx = destination.x - position.x,
            dy = destination.y - position.y,
        }
    end

    return { kind = intent.MONSTER_WAIT }
end

-- Parent movement owns the limb's extension; its own scheduled action is
-- reserved for melee. mon-act.cc uses movement speeds 10 and 18 plus a
-- saved fractional spurt, independently of ordinary child attack speed.
function attached.move(ctx, parent, aut)
    local actor = ctx:get(parent, component.ACTOR)

    local health = ctx:get(parent, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return
    end

    local speed = actor.kind_id == monsters.MONS_KRAKEN and 10 or 18

    for _, child in ipairs(ctx:query({ constructs.TENTACLE })) do
        local link = ctx:get(child, constructs.TENTACLE)

        if link.parent == parent then
            link.move_spurt = link.move_spurt + aut * speed

            local steps = 1 + math.floor(link.move_spurt / 100)

            link.move_spurt = link.move_spurt % 100
            ctx:set(child, constructs.TENTACLE, link)

            for _ = 1, steps do
                local position = ctx:get(child, component.POSITION)

                if not position then
                    break
                end

                tentacle.refresh(ctx, child)

                local action = tentacle.act(ctx, child, position)

                if action.kind == intent.MONSTER_MOVE then
                    local grip = ctx:get(ctx:player(), component.CONSTRICTION)

                    ctx:move_actor(child, position.level_id,
                        position.x + action.dx, position.y + action.dy)

                    if grip and grip.by == child and
                        ctx:walkable(position.level_id, position.x, position.y) then
                        ctx:move_actor(ctx:player(), position.level_id,
                            position.x, position.y)
                    end

                    tentacle.refresh(ctx, child)
                end
            end
        end
    end
end

return attached
