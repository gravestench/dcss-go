-- Theory of operation: paint nested octagonal corridors, then walk each
-- perimeter placing radial connectors and alternating source-shaped plugs.
-- Outside Zot, smear rock into the halls and retain the center-connected zone.
local runtime = require("policy.generation.layouts.halls_runtime")

local layout = {}

--   xx
--  xxxx
--  xxxx
--   xx
-- Paint the clipped twelve-cell plug that blocks one outward ring connection.
local function draw_plug(mapgrd, x, y, fill)
    for x1 = x - 1, x + 2 do
        for y1 = y - 1, y + 2 do
            if (x1 ~= x - 1 and x1 ~= x + 2) or (y1 ~= y - 1 and y1 ~= y + 2) then
                mapgrd[x1][y1] = fill
            end
        end
    end
end
-- Reject a connection whose twelve-cell footprint overlaps an existing plug.
local function is_plug(mapgrd, x, y, check)
    for x1 = x - 1, x + 2 do
        for y1 = y - 1, y + 2 do
            if (x1 ~= x - 1 and x1 ~= x + 2) or (y1 ~= y - 1 and y1 ~= y + 2) then
                if mapgrd[x1][y1] == check then
                    return true
                end
            end
        end
    end
    return false
end

-- Choose the source traversal direction for inclusive hallway loops.
local function sign(n)
    if n > 0 then
        return 1
    elseif n < 0 then
        return -1
    else
        return 0
    end
end

-- Resolve one perimeter offset to the correct straight or diagonal octagon side.
local function resolve_position(layer, position, out_straight, out_diagonal)
    local x
    local y
    if position < layer.side_start[1] then
        -- north
        local offset = position - layer.side_start[0]
        x = layer.x2 + offset
        y = layer.y1 - out_straight
    elseif position < layer.side_start[2] then
        -- northeast
        local offset = position - layer.side_start[1]
        out_diagonal = math.floor(out_diagonal)
        x = layer.x3 + offset + out_diagonal
        y = layer.y1 + offset - out_diagonal + 1
    elseif position < layer.side_start[3] then
        -- east
        local offset = position - layer.side_start[2]
        x = layer.x4 + out_straight - 1
        y = layer.y2 + offset
    elseif position < layer.side_start[4] then
        -- southeast
        local offset = position - layer.side_start[3]
        out_diagonal = math.floor(out_diagonal)
        x = layer.x4 - offset + out_diagonal - 1
        y = layer.y3 + offset + out_diagonal
    elseif position < layer.side_start[5] then
        -- south
        local offset = position - layer.side_start[4]
        x = layer.x3 - offset - 1
        y = layer.y4 + out_straight - 1
    elseif position < layer.side_start[6] then
        -- southwest
        local offset = position - layer.side_start[5]
        out_diagonal = math.floor(out_diagonal)
        x = layer.x2 - offset - out_diagonal
        y = layer.y4 - offset + out_diagonal - 1
    elseif position < layer.side_start[7] then
        -- west
        local offset = position - layer.side_start[6]
        x = layer.x1 - out_straight
        y = layer.y3 - offset - 1
    else
        -- northwest
        local offset = position - layer.side_start[7]
        out_diagonal = math.ceil(out_diagonal) -- otherwise blocks miss hallway
        x = layer.x1 + offset - out_diagonal + 1
        y = layer.y2 - offset - out_diagonal
    end
    return x, y
end

-- draw hallways of the correct width, length, and direction
-- Carve the two-cell north/south hall with both source endpoints included.
local function draw_hallway_s_n(mapgrd, x, y, length, fill)
    local sign_val = sign(length)
    for y1 = y, y + length, sign(length) do
        mapgrd[x][y1] = fill
        mapgrd[x + 1][y1] = fill
    end
end
-- Carve the two-cell east/west hall with both source endpoints included.
local function draw_hallway_e_w(mapgrd, x, y, length, fill)
    local sign_val = sign(length)
    for x1 = x, x + length, sign(length) do
        mapgrd[x1][y] = fill
        mapgrd[x1][y + 1] = fill
    end
end
-- Carve the stepped southeast/northwest hall without diagonal-only gaps.
local function draw_hallway_se_nw(mapgrd, x, y, length, fill)
    local sign_val = sign(length)
    for i = 0, length, sign_val do
        local x1 = x + i
        local y1 = y + i
        mapgrd[x1][y1] = fill
        if i ~= 0 then
            mapgrd[x1 - sign_val][y1] = fill
            mapgrd[x1][y1 - sign_val] = fill
        end
    end
end
-- Carve the stepped southwest/northeast hall without diagonal-only gaps.
local function draw_hallway_sw_ne(mapgrd, x, y, length, fill)
    local sign_val = sign(length)
    for i = 0, length, sign_val do
        local x1 = x - i
        local y1 = y + i
        mapgrd[x1][y1] = fill
        if i ~= 0 then
            mapgrd[x1 + sign_val][y1] = fill
            mapgrd[x1][y1 - sign_val] = fill
        end
    end
end

-- Draw every source size, border, separation, and plug parameter before carving.
local function parameters(env, gxm, gym)
    local crawl = env.crawl
    local CENTER_X = gxm / 2
    local CENTER_Y = gym / 2

    local HALLWAY_SIZE = env.you.in_branch("Zot") and 2 or 3
    local layer_size = 2 * crawl.random_range(HALLWAY_SIZE, HALLWAY_SIZE + 2)
    local center_radius = 2 * crawl.random_range(2, 3)
    local layer_size_diagonal = layer_size * 3 / 4 -- can have a .5 on it

    local border = crawl.random_range(2, 8 - (layer_size - 4))
    local max_radius = math.min(CENTER_X, CENTER_Y) - border
    local layer_count = math.floor((max_radius - center_radius) / layer_size)

    local radial_separation_min = crawl.random_range(4, 8)
    local radial_separation_max = crawl.random_range(radial_separation_min + 4, 20)
    local plug_percent = crawl.random_range(0, 100)

    return {
        center_x = CENTER_X,
        center_y = CENTER_Y,
        hallway_size = HALLWAY_SIZE,
        layer_size = layer_size,
        center_radius = center_radius,
        layer_size_diagonal = layer_size_diagonal,
        layer_count = layer_count,
        radial_separation_min = radial_separation_min,
        radial_separation_max = radial_separation_max,
        plug_percent = plug_percent,
    }
end

-- Paint outer-to-inner source octagons; only the innermost ring rolls a center fill.
local function paint_layers(env, settings)
    local crawl = env.crawl
    local octa_room = env.octa_room
    local CENTER_X = settings.center_x
    local CENTER_Y = settings.center_y
    local HALLWAY_SIZE = settings.hallway_size
    local center_radius = settings.center_radius
    local layer_size = settings.layer_size
    local layer_count = settings.layer_count

    -- make the octagon layers
    local layer = {}
    for i = layer_count, 0, -1 do
        -- calculate octagon properties
        --
        --    ....    y1
        --   ......
        --  ...  ...  y2
        --  ..    ..
        --  ..    ..
        --  ...  ...  y3
        --   ......
        --    ....    y4
        --
        layer[i] = {}
        layer[i].radius = center_radius + layer_size * i
        layer[i].oblique = layer[i].radius / 2
        layer[i].x1 = CENTER_X - layer[i].radius
        layer[i].x4 = CENTER_X + layer[i].radius - 1
        layer[i].x2 = layer[i].x1 + layer[i].oblique
        layer[i].x3 = layer[i].x4 - layer[i].oblique
        layer[i].y1 = CENTER_Y - layer[i].radius
        layer[i].y4 = CENTER_Y + layer[i].radius - 1
        layer[i].y2 = layer[i].y1 + layer[i].oblique
        layer[i].y3 = layer[i].y4 - layer[i].oblique

        -- where each of the 8 sides start
        --  -> needed for placing connections between rings
        layer[i].side_straight = layer[i].x3 - layer[i].x2 - 1
        layer[i].side_diagonal = layer[i].x4 - layer[i].x3 - 1
        layer[i].side_start = {}
        layer[i].side_start[0] = 0
        for j = 1, 8 do
            if j % 2 == 0 then
                layer[i].side_start[j] = layer[i].side_start[j - 1] + layer[i].side_diagonal
            else
                layer[i].side_start[j] = layer[i].side_start[j - 1] + layer[i].side_straight
            end
        end

        -- draw the octagons
        --   -> inner room has chance of being open
        octa_room({
            x1 = layer[i].x1,
            y1 = layer[i].y1,
            x2 = layer[i].x4,
            y2 = layer[i].y4,
            oblique = layer[i].oblique,
            replace = "x",
            inside = ".",
            outside = "x",
        })

        if i > 0 or (crawl.one_chance_in(3) and layer[i].radius >= 3) then
            octa_room({
                x1 = layer[i].x1 + HALLWAY_SIZE,
                y1 = layer[i].y1 + HALLWAY_SIZE,
                x2 = layer[i].x4 - HALLWAY_SIZE,
                y2 = layer[i].y4 - HALLWAY_SIZE,
                oblique = layer[i].oblique - HALLWAY_SIZE / 2,
                replace = ".",
                inside = "x",
                outside = ".",
            })
        end
    end

    return layer
end

-- Walk each inner perimeter and alternate connectors with source plug blocks.
local function connect_layers(env, settings, layer)
    local crawl = env.crawl
    local mapgrd = env.mapgrd
    local layer_size = settings.layer_size
    local layer_size_diagonal = settings.layer_size_diagonal
    local layer_count = settings.layer_count
    local radial_separation_min = settings.radial_separation_min
    local radial_separation_max = settings.radial_separation_max
    local plug_percent = settings.plug_percent

    -- connect the layers
    for i = 0, layer_count - 1 do
        local total_distance = layer[i].side_start[8]
        local hallway_pos = crawl.random2(total_distance)
        local hallway_pos_end = hallway_pos + total_distance - radial_separation_min
        local is_next_plug = false

        while hallway_pos < hallway_pos_end do
            -- find a spot for the hallway
            local hallway_pos_fixed = hallway_pos % total_distance
            local good_spot = false
            while not good_spot and hallway_pos < hallway_pos_end do
                local x, y = resolve_position(layer[i], hallway_pos_fixed, 0, 0)
                if not is_plug(mapgrd, x, y, "c") then
                    good_spot = true
                else
                    hallway_pos = hallway_pos + crawl.random_range(1, 4)
                    hallway_pos_fixed = hallway_pos % total_distance
                end
            end

            if good_spot then
                if is_next_plug then
                    -- draw a plug
                    local x, y =
                        resolve_position(layer[i], hallway_pos_fixed, layer_size, layer_size_diagonal)
                    is_next_plug = false -- 2 blocks in a row can disconnect map

                    draw_plug(mapgrd, x, y, "c")
                else
                    -- draw a hallway
                    local x, y = resolve_position(layer[i], hallway_pos_fixed, 0, 0)
                    is_next_plug = crawl.x_chance_in_y(plug_percent, 100)

                    if hallway_pos_fixed < layer[i].side_start[1] then
                        draw_hallway_s_n(mapgrd, x, y, -layer_size, ".") -- north
                    elseif hallway_pos_fixed < layer[i].side_start[2] then
                        draw_hallway_sw_ne(mapgrd, x, y, -layer_size_diagonal, ".") -- northeast
                    elseif hallway_pos_fixed < layer[i].side_start[3] then
                        draw_hallway_e_w(mapgrd, x, y, layer_size, ".") -- east
                    elseif hallway_pos_fixed < layer[i].side_start[4] then
                        draw_hallway_se_nw(mapgrd, x, y, layer_size_diagonal, ".") -- southeast
                    elseif hallway_pos_fixed < layer[i].side_start[5] then
                        draw_hallway_s_n(mapgrd, x, y, layer_size, ".") -- south
                    elseif hallway_pos_fixed < layer[i].side_start[6] then
                        draw_hallway_sw_ne(mapgrd, x, y, layer_size_diagonal, ".") -- southwest
                    elseif hallway_pos_fixed < layer[i].side_start[7] then
                        draw_hallway_e_w(mapgrd, x, y, -layer_size, ".") -- west
                    else
                        draw_hallway_se_nw(mapgrd, x, y, -layer_size_diagonal, ".") -- northwest
                    end
                end
            end

            hallway_pos = hallway_pos + crawl.random_range(radial_separation_min, radial_separation_max)
        end
    end
end

-- Smear only non-Zot maps, then keep the source component containing the center.
local function roughen(env)
    -- Smear the layout a la layout_big_octagon outside Zot.
    -- (Actually, that's where this code originates.)
    if not env.you.in_branch("Zot") then
        local gxm, gym = env.dgn.max_bounds()
        local iterations = 50 + env.crawl.random2(50) + env.crawl.random2(50)
        env.smear_map({
            iterations = iterations,
            boxy = false,
        })

        env.mapgrd[gxm / 2][gym / 2] = "@"
        env.fill_disconnected({ wanted = "@" })
        env.mapgrd[gxm / 2][gym / 2] = "."
    end
end

-- Keep source phase order explicit: parameters, rings, connectors, plugs, roughening.
function layout.layout_concentric_octagons(api)
    local env = runtime.new(api)
    local gxm, gym = env.dgn.max_bounds()

    env.extend_map({
        width = gxm,
        height = gym,
    })
    env.fill_area({ fill = "x" })

    local settings = parameters(env, gxm, gym)
    local layer = paint_layers(env, settings)

    connect_layers(env, settings, layer)
    env.subst("c = x")
    roughen(env)

    return env.result()
end

-- Source minimum_map_area requires strictly more than 10% floor before stairs.
function layout.validate(result)
    return runtime.minimum_area(result, 10, ".{([})]<>")
end

return layout
