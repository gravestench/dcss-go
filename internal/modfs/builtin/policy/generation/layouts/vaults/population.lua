-- Theory of operation: a Vaults layout supplies the broad floor motif, then
-- this pass attaches source room maps and small generated floor chambers.
-- Each candidate is tried on a copy; a failed fit or connector leaves the
-- current grid and earlier room records alone. Source room IDs are drawn in
-- sorted catalog order, so filesystem discovery never changes a seed.
local branches = require("ids.branches")
local glyphs = require("constants.vault_glyphs")
local tags = require("constants.vault_tags")
local connect = require("policy.generation.vaults.connect")
local cell_graph = require("policy.generation.layouts.cell_graph")
local geometry = require("policy.generation.layouts.vaults.geometry")
local grid = require("policy.generation.grid")
local rooms = require("policy.generation.layouts.vaults.rooms")
local catalog = require("policy.generation.vaults.catalog")
local used = require("policy.generation.vaults.used")

local population = {}

local generators = {
    {
        kind = "code",
        weight = 80,
    },
    {
        kind = "tagged",
        tag = tags.VAULTS_ROOM,
        weight = 50,
        limit = 6,
    },
    {
        kind = "tagged",
        tag = tags.VAULTS_EMPTY,
        weight = 40,
    },
    {
        kind = "tagged",
        tag = tags.VAULTS_HARD,
        weight = 10,
        limit = 1,
    },
}

-- Keep the source generator weights while removing a category once its
-- per-floor limit is reached. One weighted draw chooses the next attempt.
local function choose_generator(builder, counts)
    local total = 0

    for _, generator in ipairs(generators) do
        if not generator.limit or counts[generator.tag] < generator.limit then
            total = total + generator.weight
        end
    end

    local draw = builder:roll(total)

    for _, generator in ipairs(generators) do
        if not generator.limit or counts[generator.tag] < generator.limit then
            if draw < generator.weight then
                return generator
            end

            draw = draw - generator.weight
        end
    end

    error("Vaults room generator weight draw exceeded its catalog")
end

-- Find a rectangle whose cells belong to one broad paint region. A wall
-- chamber expands the layout; a floor chamber can interrupt an open city.
-- The outer two-cell margin keeps authored rooms off the immutable border.
local function origin(builder, width, height, protected)
    if width > grid.width - 6 or height > grid.height - 6 then
        return nil
    end

    for _ = 1, 50 do
        local left = 2 + builder:roll(grid.width - width - 4)
        local top = 2 + builder:roll(grid.height - height - 4)
        local walls = 0
        local floors = 0
        local collision = false

        for y = top, top + height - 1 do
            for x = left, left + width - 1 do
                local cell = builder:cell(x, y)

                if protected[x .. ":" .. y] then
                    collision = true
                elseif glyphs.wall[cell] then
                    walls = walls + 1
                elseif cell == "." then
                    floors = floors + 1
                end
            end
        end

        local area = width * height

        if not collision and
            (walls >= area * 0.7 or floors >= area * 0.7) then
            return {
                x = left,
                y = top,
            }
        end
    end

    return nil
end

-- A source code room is a small empty floor chamber. The source biases both
-- dimensions toward six cells by drawing the size bound twice.
local function code_size(builder)
    local span = 10
    local width = 6 + builder:roll(builder:roll(span) + 1)
    local height = 6 + builder:roll(builder:roll(span) + 1)

    return width, height
end

-- Keep a generated chamber private until its connector is accepted, just as
-- the ordinary DES placer keeps a source room private during fit checks.
local function copy_cells(builder)
    local copy = {}

    for y = 1, grid.height do
        copy[y] = {}

        for x = 1, grid.width do
            copy[y][x] = builder.cells[y][x]
        end
    end

    return copy
end

-- The existing DES connector owns exits and post-placement vetoes. Check
-- its terrain changes against already accepted rooms before publishing this
-- trial; connectors may carve through old rooms even when the MAP did not.
local function connect_trial(api, builder, placed, before, protected, anchor)
    local ok, reason = pcall(connect.finish, api.ctx, builder, placed,
        { anchor })

    if not ok then
        builder.cells = before

        error(reason)
    end

    for key in pairs(protected) do
        local x, y = key:match("^(%d+):(%d+)$")
        x = tonumber(x)
        y = tonumber(y)

        if builder:cell(x, y) ~= before[y + 1][x + 1] then
            builder.cells = before

            return false
        end
    end

    -- Keep the accepted connector as well as the room itself. A later
    -- attempt cannot close the only passage to an earlier chamber.
    for y = 1, grid.height do
        for x = 1, grid.width do
            if builder.cells[y][x] ~= before[y][x] then
                protected[(x - 1) .. ":" .. (y - 1)] = true
            end
        end
    end

    return true
end

-- A code room has no authored records. The connector still gives its new
-- floor a route to the motif, and the stair postpass pairs its source exit.
local function place_code(api, builder, protected, anchor)
    local width, height = code_size(builder)
    local point = origin(builder, width, height, protected)

    if not point then
        return false
    end

    local before = builder.cells

    builder.cells = copy_cells(builder)

    geometry.rectangle(builder, point.x, point.y,
        point.x + width - 1, point.y + height - 1, ".")

    local middle = {
        x = point.x + math.floor(width / 2),
        y = point.y + math.floor(height / 2),
    }

    if builder:chance_in(80, 100) then
        builder:set(middle.x, middle.y, "}")
    end

    local placed = {
        id = "vaults_code_room",
        path = api.definition.path,
        tags = {},
        entry = middle,
        exits = {},
        records = {},
        bounds = {
            x = point.x,
            y = point.y,
            width = width,
            height = height,
        },
    }

    if not connect_trial(api, builder, placed, before, protected,
        anchor) then
        return false
    end

    for y = point.y, point.y + height - 1 do
        for x = point.x, point.x + width - 1 do
            protected[x .. ":" .. y] = true
        end
    end

    return placed
end

-- Restore the previous cell array if a source map cannot connect without
-- changing a previously placed room. Its random draws still count as an
-- unsuccessful source attempt, exactly as they do for a failed room fit.
local function place_tagged(api, builder, generator, protected, state,
    anchor)
    local context = {
        branch_id = branches.BRANCH_VAULTS,
        branch_bottom = api.branch_bottom,
        depth = api.depth,
        absolute_depth = api.absolute_depth,
        layout_family = "vaults",
        used = state,
    }
    local definition = rooms.choose(builder, generator.tag, context)

    if not definition then
        return nil
    end

    local turns = builder:roll(4)
    local width = 0

    for _, row in ipairs(definition.rows) do
        width = math.max(width, #row)
    end

    local height = #definition.rows

    if turns % 2 == 1 then
        width, height = height, width
    end

    local point = origin(builder, width, height, protected)

    if not point then
        return nil
    end

    local before = builder.cells
    local player = {
        branch_id = api.branch_id,
        depth = api.depth,
        absolute_depth = api.absolute_depth,
    }
    local placed = rooms.place(api.ctx, builder, definition.id, point,
        turns, protected, player)

    if not placed then
        return nil
    end

    if not connect_trial(api, builder, placed, before, protected,
        anchor) then
        return nil
    end

    for _, cell in ipairs(placed.occupied) do
        protected[cell.x .. ":" .. cell.y] = true
    end

    return placed
end

-- The source bounds this stage by total rooms and consecutive failures.
-- Tagged records are returned flat because population and saves consume
-- the same typed placement records as other DES maps.
function population.run(api, builder)
    -- A connector can otherwise stop at an isolated floor pocket created
    -- by an earlier source room. Anchor every accepted entrance to the
    -- motif's original main region, which remains protected throughout.
    local regions = cell_graph.regions(builder)

    if not regions[1] then
        error(api.definition.id .. " has no walkable primary motif")
    end

    local anchor = regions[1][1]
    local records = {}
    local ids = {}
    local entries = {}
    local protected = {
        [anchor.x .. ":" .. anchor.y] = true,
    }
    local state = used.new(api.prior_vault_ids)
    local counts = {
        [tags.VAULTS_ROOM] = 0,
        [tags.VAULTS_EMPTY] = 0,
        [tags.VAULTS_HARD] = 0,
    }
    local placed_count = 0
    local failures = 0

    while placed_count < 27 and failures < 20 do
        local generator = choose_generator(builder, counts)
        local placed

        if generator.kind == "code" then
            placed = place_code(api, builder, protected, anchor)
        else
            placed = place_tagged(api, builder, generator, protected,
                state, anchor)
        end

        if placed then
            placed_count = placed_count + 1
            failures = 0
            entries[#entries + 1] = placed.entry

            if generator.tag then
                counts[generator.tag] = counts[generator.tag] + 1
                ids[#ids + 1] = placed.id
                state:add(catalog.get(placed.id))

                for _, record in ipairs(placed.records) do
                    records[#records + 1] = record
                end
            end
        else
            failures = failures + 1
        end
    end

    return records, ids, protected, entries
end

return population
