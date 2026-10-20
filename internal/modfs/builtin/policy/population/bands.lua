-- Theory of operation: a monster definition owns its band size and the
-- weighted follower choices for each slot. This policy only chooses nearby
-- legal cells, creates ordinary ECS actors, and links them to their leader.
-- A mod can change a band in one monster definition without editing this
-- placement code or a central monster-ID switch.
local catalog = require("policy.catalog")
local component = require("constants.component")
local factory = require("policy.population.factory")
local history = require("policy.population.unique_history")
local streams = require("constants.rng_streams")

local bands = {}

-- Recheck cells after each follower, since prior actors now occupy some of
-- them. Exclusions preserve authored no-spawn squares around vault leaders.
local function candidates(ctx, level, origin, excluded)
    local cells = {}

    for y = origin.y - 3, origin.y + 3 do
        for x = origin.x - 3, origin.x + 3 do
            if ctx:walkable(level.id, x, y) and
                not excluded[x .. ":" .. y] and
                not ctx:actor_at(level.id, x, y) and
                ctx:visible(level.id, origin.x, origin.y, 7, x, y) then
                cells[#cells + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return cells
end

-- The source repeats its last declared slot for all later followers. This
-- permits a compulsory first member followed by a weighted common pool.
local function member(ctx, profile, index, level)
    if profile.member_policy then
        return require(profile.member_policy).choose(ctx, level, index)
    end

    local slot = profile.slots[math.min(index, #profile.slots)]
    local total = 0

    for _, choice in ipairs(slot) do
        total = total + (type(choice) == "string" and 1 or choice.weight)
    end

    local draw = ctx:random(streams.BANDS, total)

    for _, choice in ipairs(slot) do
        local weight = type(choice) == "string" and 1 or choice.weight

        if draw < weight then
            return type(choice) == "string" and choice or choice.id
        end

        draw = draw - weight
    end

    error("band choice exceeded its weighted slot")
end

-- Spawn a source band around a placed leader. A full or blocked vicinity
-- shortens the group, as in the original placement path. A previously seen
-- unique follower is skipped while later slots can still take their turn.
function bands.spawn(ctx, leader, level, excluded)
    local actor = ctx:get(leader, component.ACTOR)
    local profile = catalog.get("monsters", actor.kind_id).band

    if not profile then
        return 0
    end

    local origin = ctx:get(leader, component.POSITION)
    local count = profile.min +
        ctx:random(streams.BANDS, profile.max - profile.min + 1)
    local placed = 0

    for index = 1, count do
        local kind_id = member(ctx, profile, index, level)

        if not history.is_unique(kind_id) or
            not history.seen(ctx, kind_id) then
            local cells = candidates(ctx, level, origin, excluded or {})

            if #cells == 0 then
                break
            end

            local cell = cells[ctx:random(streams.PLACEMENT, #cells) + 1]
            local follower = factory.spawn(ctx, kind_id, level.id,
                cell.x, cell.y)

            ctx:add(follower, component.FOLLOWER, {
                leader = leader,
            })
            ctx:add(follower, component.BAND_ORIGIN, {
                leader_kind_id = actor.kind_id,
                member_kind_id = kind_id,
            })

            if profile.origin_component then
                ctx:add(follower, profile.origin_component, {
                    band_member = true,
                })
            end

            placed = placed + 1
        end
    end

    return placed
end

return bands
