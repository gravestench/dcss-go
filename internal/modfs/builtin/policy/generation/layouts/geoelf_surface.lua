-- Theory of operation: GeoElf draws symbolic source glyphs before resolving terrain.
-- These helpers reproduce l-dgnbld.cc's door, window, circle, and castle wall rules.
local surface = {}

-- Membership uses literal glyphs because several source glyphs are pattern metacharacters.
local function contains(glyphs, glyph)
    return glyph ~= nil and glyphs:find(glyph, 1, true) ~= nil
end

-- Clamp helper iteration to the interior, as l-dgnbld.cc does before neighborhood checks.
local function bounds(env, spec)
    return math.max(1, spec.x1 or 0), math.max(1, spec.y1 or 0),
        math.min(env.width - 2, spec.x2 or env.width - 1),
        math.min(env.height - 2, spec.y2 or env.height - 1)
end

-- Read the eight source neighbors in compass order for door and window classification.
local function neighbors(env, x, y, glyphs)
    return contains(glyphs, env.mapgrd[x][y + 1]),
        contains(glyphs, env.mapgrd[x][y - 1]),
        contains(glyphs, env.mapgrd[x + 1][y]),
        contains(glyphs, env.mapgrd[x - 1][y]),
        contains(glyphs, env.mapgrd[x + 1][y + 1]),
        contains(glyphs, env.mapgrd[x - 1][y - 1]),
        contains(glyphs, env.mapgrd[x - 1][y + 1]),
        contains(glyphs, env.mapgrd[x + 1][y - 1])
end

-- Retain only straight or corner doors satisfying the pinned C++ eight-neighbor cases.
function surface.remove_disconnected_doors(env, spec)
    local x1, y1, x2, y2 = bounds(env, spec)

    for y = y1, y2 do
        for x = x1, x2 do
            if contains(spec.door, env.mapgrd[x][y]) then
                local s, n, e, w, se, nw, sw, ne = neighbors(env, x, y, spec.open)
                local straight_ns = not s and not n and (e or w) and
                    (e or se or ne) and (w or sw or nw)
                local straight_ew = not e and not w and (s or n) and
                    (s or ne or nw) and (n or se or sw)
                local diagonal_se = se and nw and s == e and n == w and
                    (s ~= w or (not s and not w and not sw and not ne))
                local diagonal_sw = sw and ne and s == w and n == e and
                    (s ~= e or (not s and not e and not se and not nw))

                if not (straight_ns or straight_ew or diagonal_se or diagonal_sw) then
                    env.mapgrd[x][y] = spec.replace
                end
            end
        end
    end
end

-- Windows replace the source's straight, bent, and thick diagonal wall cases in scan order.
function surface.add_windows(env, spec)
    local x1, y1, x2, y2 = bounds(env, spec)

    for y = y1, y2 do
        for x = x1, x2 do
            if contains(spec.wall, env.mapgrd[x][y]) then
                local s, n, e, w, se, nw, sw, ne = neighbors(env, x, y, spec.open)
                local bs, bn, be, bw, bse, bnw, bsw, bne = neighbors(env, x, y, spec.wall)
                local straight = (s and n and be and bw) or (e and w and bs and bn)
                local bent = be and bw and ((se and nw and bsw and bne) or (sw and ne and bse and bnw))
                local thick = bs and bn and be and bw and ((se and nw) or (sw and ne))
                local thin = (bs and be and n and w and se) or (bs and bw and n and e and sw) or
                    (bn and bw and s and e and nw) or (bn and be and s and w and ne)

                if straight or bent or thick or thin then
                    env.mapgrd[x][y] = spec.window
                end
            end
        end
    end
end

-- Fill an inclusive rectangle, then replace its perimeter when a distinct border is requested.
function surface.fill_area(env, spec)
    for y = math.max(0, spec.y1), math.min(env.height - 1, spec.y2) do
        for x = math.max(0, spec.x1), math.min(env.width - 1, spec.x2) do
            local edge = x == spec.x1 or x == spec.x2 or y == spec.y1 or y == spec.y2
            env.mapgrd[x][y] = edge and (spec.border or spec.fill) or spec.fill
        end
    end
end

-- Source circles use a radius plus one half cell, giving turrets their rounded outer silhouette.
function surface.make_circle(env, spec)
    for dy = -spec.radius, spec.radius do
        for dx = -spec.radius, spec.radius do
            if dx * dx + dy * dy < (spec.radius + 0.5) ^ 2 then
                env.mapgrd[spec.x + dx][spec.y + dy] = spec.fill
            end
        end
    end
end

-- A castle divider gets one doorway per uninterrupted run, within the source check distance.
local function wall_empty(env, spec, x, y, horizontal)
    local nx = horizontal and 0 or 1
    local ny = horizontal and 1 or 0

    for sign = 1, -1, -2 do
        for distance = 1, spec.check_distance or 9999 do
            local px = x + (horizontal and sign * distance or 0)
            local py = y + (horizontal and 0 or sign * distance)

            if not contains(spec.floor, env.mapgrd[px + nx][py + ny]) or
                not contains(spec.floor, env.mapgrd[px - nx][py - ny]) then
                break
            end

            if not contains(spec.wall, env.mapgrd[px][py]) then
                return false
            end
        end
    end

    return true
end

-- Sample the rectangle without replacement and count inspected cells, as the source iterator does.
function surface.connect_adjacent_rooms(env, spec)
    local x1, y1, x2, y2 = bounds(env, spec)
    local cells = {}

    for y = y1, y2 do
        for x = x1, x2 do
            cells[#cells + 1] = {
              x = x,
              y = y,
            }
        end
    end

    local count = env.crawl.random_range(spec.min or spec.max, spec.max)

    local index = env.crawl.random2(#cells) + 1

    while #cells > 0 do
        if count <= 0 then
            return
        end

        local x = cells[index].x
        local y = cells[index].y

        if contains(spec.wall, env.mapgrd[x][y]) then
            local vertical = contains(spec.floor, env.mapgrd[x][y - 1]) and
                contains(spec.floor, env.mapgrd[x][y + 1]) and wall_empty(env, spec, x, y, true)
            local horizontal = contains(spec.floor, env.mapgrd[x - 1][y]) and
                contains(spec.floor, env.mapgrd[x + 1][y]) and wall_empty(env, spec, x, y, false)

            if vertical or horizontal then
                env.mapgrd[x][y] = spec.replace
            end
        end

        count = count - 1
        cells[index] = cells[#cells]
        cells[#cells] = nil

        if #cells > 0 then
            index = env.crawl.random2(#cells) + 1
        end
    end
end

-- Build a temporary ellipse before choosing doors, so exterior passability uses the old map.
function surface.make_round_box(env, spec)
    local width = spec.x2 - spec.x1 + 1
    local height = spec.y2 - spec.y1 + 1
    local rx = (width - 1) / 2
    local ry = (height - 1) / 2
    local cells = {}

    for x = 0, width - 1 do
        cells[x] = {}

        for y = 0, height - 1 do
            cells[x][y] = ((x - rx) / (rx + 0.5)) ^ 2 +
                ((y - ry) / (ry + 0.5)) ^ 2 <= 1 and 1 or 0
        end
    end

    for x = 1, width - 2 do
        for y = 1, height - 2 do
            local interior = cells[x][y] == 1

            for dx = -1, 1 do
                for dy = -1, 1 do
                    interior = interior and cells[x + dx][y + dy] ~= 0
                end
            end

            if interior then
                cells[x][y] = 2
            end
        end
    end

    local positions = {}

    for x = 0, width - 1 do
        for y = 0, height - 1 do
            if cells[x][y] == 1 then
                local xm = x > 0 and cells[x - 1][y] == 1
                local xp = x < width - 1 and cells[x + 1][y] == 1
                local ym = y > 0 and cells[x][y - 1] == 1
                local yp = y < height - 1 and cells[x][y + 1] == 1
                local real_x = spec.x1 + x
                local real_y = spec.y1 + y
                local horizontal = xm and xp and not ym and not yp and
                    ((contains(spec.passable, env.mapgrd[real_x][real_y - 1]) and
                        (y == 0 or cells[x][y - 1] == 0)) or
                    (contains(spec.passable, env.mapgrd[real_x][real_y + 1]) and
                        (y == height - 1 or cells[x][y + 1] == 0)))
                local vertical = not xm and not xp and ym and yp and
                    ((contains(spec.passable, env.mapgrd[real_x - 1][real_y]) and
                        (x == 0 or cells[x - 1][y] == 0)) or
                    (contains(spec.passable, env.mapgrd[real_x + 1][real_y]) and
                        (x == width - 1 or cells[x + 1][y] == 0)))

                if horizontal or vertical then
                    positions[#positions + 1] = {
                      x = x,
                      y = y,
                    }
                end
            end
        end
    end

    local doors = 0

    while doors < spec.door_count and #positions > 0 do
        local index = env.crawl.random2(#positions) + 1
        local point = positions[index]
        positions[index] = positions[#positions]
        positions[#positions] = nil
        cells[point.x][point.y] = 3
        doors = doors + 1
    end

    for x = 0, width - 1 do
        for y = 0, height - 1 do
            local glyph = cells[x][y]

            if glyph ~= 0 then
                env.mapgrd[spec.x1 + x][spec.y1 + y] =
                    glyph == 1 and spec.wall or (glyph == 2 and spec.floor or spec.door)
            end
        end
    end
end

return surface
