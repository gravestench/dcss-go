local component = require("constants.component")
local habitat = require("policy.combat.monster_habitat")
local streams = require("constants.rng_streams")
local translocation = require("policy.scrolls.translocation")

local landing = {}
local sight = 7

-- Player and monster movement have different terrain rules. Reuse their
-- existing owners so a blink never invents a separate habitat exception.
local function legal(ctx, mover, origin, x, y)
    if ctx:actor_at(origin.level_id, x, y) then
        return false
    end

    if ctx:has(mover, component.PLAYER) then
        return translocation.can_land(ctx, mover, origin.level_id, x, y)
    end

    return habitat.at(ctx, mover, origin.level_id, x, y)
end

-- Source monster_blink samples a 13-by-13 square up to 150 times. Adjacent
-- cells do not count as a blink, and opaque walls block the old-to-new ray.
function landing.ordinary(ctx, mover, adjacent_only, stream)
    local origin = ctx:get(mover, component.POSITION)
    stream = stream or streams.MONSTER_SPELL

    if not origin then
        return nil, nil
    end

    for _ = 1, 150 do
        local width = adjacent_only and 3 or 13
        local offset = adjacent_only and 1 or 6
        local dx = ctx:random(stream, width) - offset
        local dy = ctx:random(stream, width) - offset
        local x = origin.x + dx
        local y = origin.y + dy
        local distance = math.max(math.abs(dx), math.abs(dy))

        local separated = adjacent_only and distance == 1 or
            not adjacent_only and distance > 1

        if separated and legal(ctx, mover, origin, x, y) and
            ctx:visible(origin.level_id, origin.x, origin.y,
                sight, x, y) then
            return x, y
        end
    end

    return nil, nil
end

-- Range/Away favor distant cells; Close favors nearby cells quadratically.
-- Source random_space_weighted considers every habitable cell in mover LOS.
function landing.weighted(ctx, mover, focus, close, keep_los, stream)
    local origin = ctx:get(mover, component.POSITION)
    stream = stream or streams.MONSTER_SPELL

    if not origin or not focus or origin.level_id ~= focus.level_id then
        return nil, nil
    end

    local choices = {}
    local total = 0

    for dy = -sight, sight do
        for dx = -sight, sight do
            if math.max(math.abs(dx), math.abs(dy)) <= sight then
                local x = origin.x + dx
                local y = origin.y + dy
                local distance = math.max(math.abs(x - focus.x),
                    math.abs(y - focus.y))
                local weight = close and math.max(0, sight - distance) ^ 2 or
                    distance

                if weight > 0 and legal(ctx, mover, origin, x, y) and
                    ctx:visible(origin.level_id, origin.x, origin.y,
                        sight, x, y) and
                    (not keep_los or ctx:visible(focus.level_id,
                        focus.x, focus.y, sight, x, y)) then
                    total = total + weight
                    choices[#choices + 1] = {
                        x = x,
                        y = y,
                        weight = weight,
                    }
                end
            end
        end
    end

    if total == 0 then
        return nil, nil
    end

    local chosen = ctx:random(stream, total)

    for _, cell in ipairs(choices) do
        if chosen < cell.weight then
            return cell.x, cell.y
        end

        chosen = chosen - cell.weight
    end

    error("monster blink weights did not select a destination")
end

-- Ally and recall effects need a free cell near a fixed anchor. Shuffle
-- candidate order by one saved draw instead of depending on table order.
function landing.near(ctx, mover, anchor, radius)
    local origin = ctx:get(mover, component.POSITION)

    if not origin or not anchor or origin.level_id ~= anchor.level_id then
        return nil, nil
    end

    local cells = {}

    for dy = -radius, radius do
        for dx = -radius, radius do
            if dx ~= 0 or dy ~= 0 then
                local x = anchor.x + dx
                local y = anchor.y + dy

                if legal(ctx, mover, origin, x, y) and
                    ctx:visible(anchor.level_id, anchor.x,
                        anchor.y, radius, x, y) then
                    cells[#cells + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    if #cells == 0 then
        return nil, nil
    end

    local chosen = ctx:random(streams.MONSTER_SPELL, #cells) + 1

    return cells[chosen].x, cells[chosen].y
end

return landing
