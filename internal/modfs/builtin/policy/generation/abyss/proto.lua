-- Theory of operation: an Abyss arrival carries a small impression of
-- the outside floor. Source Crawl copies the 17x17 view around departure,
-- sanitizes gates and stairs, then paints it over unprotected sampled
-- terrain after vaults. Distance makes the impression fade toward its edge.
local abyss = require("constants.abyss")
local terrain = require("constants.terrain")

local proto = {}

-- Portals and stairs cannot retain their outside destination inside the
-- moving Abyss. The source turns them into inert arches; altars lose their
-- allegiance and the remaining ordinary terrain keeps its type.
local function sanitize(feature)
    if not feature or feature == terrain.DNGN_UNSEEN then
        return nil
    end

    if feature == terrain.DNGN_PERMAROCK_WALL then
        return terrain.DNGN_ROCK_WALL
    end

    if feature == terrain.DNGN_CLEAR_PERMAROCK_WALL then
        return terrain.DNGN_CLEAR_ROCK_WALL
    end

    if feature == terrain.DNGN_RANDOM_ALTAR or
        feature == terrain.DNGN_ALTAR_LUGONU then
        return terrain.DNGN_FLOOR
    end

    if feature:find("^DNGN_ENTER_") or
        feature:find("^DNGN_EXIT_") or
        feature:find("^DNGN_STONE_STAIRS_") or
        feature == terrain.DNGN_ABYSSAL_STAIR then
        return terrain.DNGN_STONE_ARCH
    end

    return feature
end

-- A keyed vault cell wins over the impression. At Chebyshev distance
-- zero or one the source always copies; farther cells use its 0.98^(d²)
-- falloff on a 255-part roll. Failed rolls leave safe floor instead.
function proto.apply(ctx, cells, site, protected)
    if not site then
        return cells
    end

    for offset_x = -abyss.PROTO_RADIUS, abyss.PROTO_RADIUS do
        for offset_y = -abyss.PROTO_RADIUS, abyss.PROTO_RADIUS do
            local x = abyss.CENTRE_X + offset_x
            local y = abyss.CENTRE_Y + offset_y
            local key = x .. ":" .. y

            if not protected[key] then
                local distance = math.max(math.abs(offset_x),
                    math.abs(offset_y))
                local chance = math.floor(
                    abyss.PROTO_FALLOFF ^ (distance * distance) *
                    abyss.PROTO_CHANCE_SCALE)
                local copy = distance < 2 or
                    ctx:random("abyss-features",
                        abyss.PROTO_CHANCE_SCALE) < chance

                if copy then
                    local feature = sanitize(ctx:cell(site.level_id,
                        site.x + offset_x, site.y + offset_y))

                    if feature then
                        cells[y + 1][x + 1] = feature
                        protected[key] = true
                    end
                else
                    cells[y + 1][x + 1] = terrain.DNGN_FLOOR
                end
            end
        end
    end

    return cells
end

return proto
