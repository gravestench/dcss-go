-- Theory of operation: source clear-stone cells and their saved ECS seal
-- markers form one Slime:5 gate. The Royal Jelly's death or Jiyva's
-- one-time sixth-star reward opens it through this same terrain owner.
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local piety_limits = require("constants.piety")
local senses = require("policy.character.senses")
local statuses = require("policy.magic.effects.statuses.player")
local terrain = require("constants.terrain")

local seals = {}

-- The source changes its message according to the current patron and
-- silence, even when an earlier Jiyva reward caused the delayed release.
local function announce(ctx, seen)
    local player = ctx:player()
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local devoted = worship and worship.god_id == gods.JIYVA and
        worship.piety >= piety_limits.BREAKPOINTS[6]

    if devoted then
        if statuses.silence_radius(ctx, player) >= 0 then
            ctx:emit(channels.RELIGION,
                "You feel a strange vibration for a moment.")
        else
            ctx:emit(channels.RELIGION,
                "You hear the sound of toppling stones.")
        end

        return
    end

    if seen then
        ctx:emit(channels.MONSTER,
            "The stone walls suddenly crumble and collapse.")
    else
        ctx:emit(channels.MONSTER,
            "You feel a strange vibration for a moment.")
    end
end

-- Keep markers after release for save validation. A repeated trigger finds
-- no unopened cells and therefore cannot emit a duplicate announcement.
function seals.release(ctx, level_id)
    local found = 0
    local released = 0
    local seen = false

    for _, entity in ipairs(ctx:query({ component.SLIME_SEAL })) do
        local state = ctx:get(entity, component.SLIME_SEAL)

        if state.level_id == level_id then
            found = found + 1

            if not state.released then
                local feature = ctx:cell(level_id, state.x, state.y)

                -- Source seen_destroy_feat tests live sight as each wall
                -- falls. A wall mapped on a prior visit is not "seen" now.
                if feature == terrain.DNGN_CLEAR_STONE_WALL and
                    senses.player_sees_cell(ctx, {
                        level_id = level_id,
                        x = state.x,
                        y = state.y,
                    }) then
                    seen = true
                end

                if feature == terrain.DNGN_CLEAR_STONE_WALL then
                    ctx:set_cell(level_id, state.x, state.y,
                        terrain.DNGN_FLOOR)
                end

                state.released = true
                ctx:set(entity, component.SLIME_SEAL, state)
                released = released + 1
            end
        end
    end

    if released > 0 then
        announce(ctx, seen)
    end

    return found, released
end

-- The source DES marker retries on every entry. The one-time capstone bit
-- is already saved, so an unopened future Slime:5 floor can fall on entry.
function seals.enter(ctx, level_id)
    local player = ctx:player()
    local position = ctx:get(player, component.POSITION)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not position or position.level_id ~= level_id or
        not worship or
        not worship.one_time_abilities or
        not worship.one_time_abilities[gods.JIYVA] then
        return false
    end

    local _, released = seals.release(ctx, level_id)

    return released > 0
end

return seals
