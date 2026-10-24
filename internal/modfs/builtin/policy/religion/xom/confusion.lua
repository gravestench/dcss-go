-- Xom's two confusion events share source monster eligibility and the
-- ordinary saved confusion status. Only their selection chances differ.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local holiness = require("constants.monster_holiness")
local status = require("policy.magic.effects.statuses.confusing_touch")
local targets = require("policy.ai.targets")
local vision = require("policy.character.vision")

local confusion = {}

-- Membership is checked on catalog lists, so new modded monsters inherit
-- the same immunity without being named in Xom's event file.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Source confusion ignores clarity, plants, and nonliving creatures.
-- The duration still uses the ordinary monster status component.
function confusion.monster(ctx, monster, severity, stream)
    local actor = ctx:get(monster, component.ACTOR)
    local health = ctx:get(monster, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if contains(definition.flags, flags.CLARITY) or
        contains(definition.holiness, holiness.NONLIVING) or
        contains(definition.holiness, holiness.PLANT) then
        return false
    end

    local turns = ctx:random(stream, math.max(1, severity))

    if turns == 0 then
        return false
    end

    status.apply_turns(ctx, monster, definition, turns)
    return true
end

-- The source near iterator uses LOS_NO_TRANS, which transparent walls
-- block for this action. Actual allegiance decides whether a creature is
-- a hostile target; catalog kind alone cannot tell us that.
function confusion.nearby(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        return {}
    end

    local radius = vision.radius(ctx, player)
    local result = {}

    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local distance = math.max(
                math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if position.level_id == origin.level_id and
                distance <= radius and
                ctx:visible_no_trans(origin.level_id,
                    origin.x, origin.y, radius,
                    position.x, position.y) then
                result[#result + 1] = monster
            end
        end
    end

    return result
end

-- Good confusion excludes nonhostile monsters before its one-in-twenty
-- skip. Bad confusion can affect every nearby creature, even an ally.
function confusion.hostile(ctx, monster)
    return targets.attitude(ctx, monster) == attitudes.HOSTILE
end

return confusion
