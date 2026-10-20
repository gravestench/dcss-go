-- The saved Temple map owns its whole floor. It is not a secondary vault
-- inside a generic Dungeon layout, so its authored geometry stays primary.
local altars = require("policy.generation.temple.altars")
local branches = require("ids.branches")
local catalog = require("policy.generation.temple.catalog")
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")
local categories = require("constants.catalog")
local grid = require("policy.generation.grid")
local levels = require("policy.generation.branch_levels")
local placement = require("policy.generation.vaults.placement")
local settings = require("constants.temple_settings")
local glyphs = require("constants.vault_glyphs")

local floor = {}

-- Attach the authored bounds to a whole-level border instruction. Terrain
-- decoding applies the exact open-sea or lava-sea feature outside the MAP.
local function prepare_border(placed)
    for _, record in ipairs(placed.records) do
        if record.kind == effects.BORDER_FILL then
            local style = record.arguments and record.arguments.style

            if style ~= fill.OPEN_SEA and style ~= fill.ENDLESS_LAVA then
                error("unknown Temple border fill " .. tostring(style))
            end

            record.arguments.bounds_x = placed.bounds.x
            record.arguments.bounds_y = placed.bounds.y
            record.arguments.bounds_width = placed.bounds.width
            record.arguments.bounds_height = placed.bounds.height
        end
    end
end

-- Prefer a source-authored up stair. A few maps leave that choice to the
-- branch builder; for those, use the map's traversable entry as one return.
local function return_stair(builder, placed)
    for _, exit in ipairs(placed.exits) do
        if glyphs.up[exit.source] then
            return exit
        end
    end

    local point = placed.entry

    builder:set(point.x, point.y, "{")
    placed.exits[#placed.exits + 1] = {
        x = point.x,
        y = point.y,
        source = "{",
    }

    return point
end

-- Keep every authored exit available to the shared reciprocal stair pass.
local function source_exits(placed)
    local up = {}
    local down = {}

    for _, exit in ipairs(placed.exits) do
        if glyphs.up[exit.source] then
            up[#up + 1] = exit
        elseif glyphs.down[exit.source] then
            down[#down + 1] = exit
        end
    end

    return up, down
end

-- Place the exact saved main map, attach its saved god identities, and
-- return the same floor shape that ordinary branch stair pairing consumes.
function floor.build(ctx, chosen, player)
    local definition = catalog.main(chosen.map_id)

    if not definition then
        error("saved Temple map is absent from the effective catalog")
    end

    local builder = grid.new(ctx)
    local branch = register.get(categories.BRANCHES,
        branches.BRANCH_TEMPLE)
    local placement_player = {
        branch_id = branches.BRANCH_TEMPLE,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = branch.absolute_depth,
        species_id = player.species_id,
        name = player.name,
        started = player.started,
        settings = {
            [settings.ALTAR_COUNT] = chosen.altar_count,
        },
    }
    local placed = placement.place(ctx, builder, definition,
        placement_player)

    altars.assign(builder, placed, chosen)
    prepare_border(placed)

    local landing = return_stair(builder, placed)
    local source_up, source_down = source_exits(placed)
    local protected = {}

    for _, point in ipairs(placed.occupied) do
        protected[point.x .. ":" .. point.y] = true
    end

    protected[landing.x .. ":" .. landing.y] = true

    return {
        id = levels.id(branches.BRANCH_TEMPLE, 1),
        branch_id = branches.BRANCH_TEMPLE,
        depth = 1,
        layout = {
            id = definition.id,
            builder = builder,
            stairs = {
                {
                    up = landing,
                },
            },
        },
        arrival = placed,
        arrival_vault = definition,
        extra = {},
        vault_ids = {},
        records = placed.records,
        protected = protected,
        source_up = source_up,
        source_down = source_down,
        links = {},
    }
end

return floor
