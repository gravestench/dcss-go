-- Automatic XP evokers inspect the live level rather than the terminal
-- view. This includes unseen actors, which explains the source warning
-- when a player evokes with no visible target.
local component = require("constants.component")
local catalog = require("policy.catalog")
local flags = require("constants.monster_flags")
local senses = require("policy.character.senses")
local allegiance = require("policy.ai.targets")

local targets = {}
local SIGHT_RADIUS = 7

-- Source firewood is a stationary, nonthreatening body. These actors are
-- deliberately skipped by Tin and Chessboard target collection.
local function firewood(definition)
    local stationary = false
    local no_threat = false

    for _, flag in ipairs(definition.flags or {}) do
        stationary = stationary or flag == flags.STATIONARY
        no_threat = no_threat or flag == flags.NO_THREAT
    end

    return stationary and no_threat
end

-- Condenser needs the stronger source mons_is_threatening check. The
-- shared scan already removes firewood from every automatic evoker.
function targets.threatening(ctx, actor)
    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get("monsters", state.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.NO_THREAT then
            return false
        end
    end

    return true
end

-- Gather eligible enemies in stable entity order. Stable traversal keeps
-- the same seed independent of component storage and Lua table order.
function targets.nearby(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local result = {}
    local any_visible = false

    for _, actor in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local position = ctx:get(actor, component.POSITION)
        local health = ctx:get(actor, component.HEALTH)
        local distance = math.max(math.abs(position.x - origin.x),
            math.abs(position.y - origin.y))

        if actor ~= player and health.current > 0 and
            position.level_id == origin.level_id and
            distance <= SIGHT_RADIUS and
            ctx:visible_no_trans(origin.level_id, origin.x, origin.y,
                SIGHT_RADIUS, position.x, position.y) and
            allegiance.enemy(ctx, player, actor) and
            not firewood(catalog.get("monsters",
                ctx:get(actor, component.ACTOR).kind_id)) then
            result[#result + 1] = {
                actor = actor,
                position = position,
            }
            any_visible = any_visible or
                senses.player_sees_actor(ctx, actor)
        end
    end

    table.sort(result, function(a, b)
        return ctx:id(a.actor) < ctx:id(b.actor)
    end)

    return result, any_visible
end

-- The prompt is a free command decision. Forced input resumes the same
-- prepared action only after the player explicitly accepts the warning.
function targets.warn_if_unseen(visible, forced, prompt)
    if not visible and not forced then
        return { confirmation = prompt }
    end
end

return targets
