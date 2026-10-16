local basic = require("policy.generation.basic")
local nearest = require("policy.generation.nearest")
local branches = require("ids.branches")
local vault_catalog = require("policy.generation.vaults.catalog")
local vault_selection = require("policy.generation.vaults.selection")
local vault_placement = require("policy.generation.vaults.placement")
local vault_connect = require("policy.generation.vaults.connect")
local vault_glyphs = require("constants.vault_glyphs")
local vault_effects = require("constants.vault_effects")

local generated = {}

local exit_unavailable = "Leaving the Dungeon is unavailable in the Go port."
local third_unavailable = "Dungeon:3 is unavailable in the Go port."

local function monster_count(ctx, depth)
    local die_size = depth == 1 and 12 or 10
    local count = 0

    for _ = 1, 3 do
        count = count + ctx:random("population-count", die_size) + 1
    end

    return count
end

local function source_stairs(placed)
    local up = {}
    local down = {}

    for _, exit in ipairs(placed.exits) do
        if vault_glyphs.up[exit.source] then
            up[#up + 1] = exit
        elseif vault_glyphs.down[exit.source] then
            down[#down + 1] = exit
        end
    end

    return up, down
end

local function add_second_level_arrivals(second, count)
    local arrivals = {}

    for y = 1, 68 do
        for x = 1, 78 do
            if #arrivals == count then
                second.rows = second.builder:rows()

                return arrivals
            end

            if second.builder:cell(x, y) == "." then
                second.builder:set(x, y, "<")
                arrivals[#arrivals + 1] = { x = x, y = y }
            end
        end
    end

    error("Dungeon:2 has too few floor cells for source arrival stairs")
end

local function stair_links(first, second, placed)
    local first_links = {}
    local second_links = {}
    local source_up, source_down = source_stairs(placed)
    local extra_arrivals = add_second_level_arrivals(second, #source_down)

    for index, first_pair in ipairs(first.stairs) do
        local second_pair = second.stairs[index]

        first_links[#first_links + 1] = {
            x = first_pair.up.x,
            y = first_pair.up.y,
            to_level_id = 0,
            to_x = 0,
            to_y = 0,
            unavailable = exit_unavailable,
        }
        first_links[#first_links + 1] = {
            x = first_pair.down.x,
            y = first_pair.down.y,
            to_level_id = 2,
            to_x = second_pair.up.x,
            to_y = second_pair.up.y,
            unavailable = "",
        }
        second_links[#second_links + 1] = {
            x = second_pair.up.x,
            y = second_pair.up.y,
            to_level_id = 1,
            to_x = first_pair.down.x,
            to_y = first_pair.down.y,
            unavailable = "",
        }
        second_links[#second_links + 1] = {
            x = second_pair.down.x,
            y = second_pair.down.y,
            to_level_id = 0,
            to_x = 0,
            to_y = 0,
            unavailable = third_unavailable,
        }
    end

    for _, up in ipairs(source_up) do
        first_links[#first_links + 1] = {
            x = up.x,
            y = up.y,
            to_level_id = 0,
            to_x = 0,
            to_y = 0,
            unavailable = exit_unavailable,
        }
    end

    for index, down in ipairs(source_down) do
        local arrival = extra_arrivals[index]

        first_links[#first_links + 1] = {
            x = down.x,
            y = down.y,
            to_level_id = 2,
            to_x = arrival.x,
            to_y = arrival.y,
            unavailable = "",
        }
        second_links[#second_links + 1] = {
            x = arrival.x,
            y = arrival.y,
            to_level_id = 1,
            to_x = down.x,
            to_y = down.y,
            unavailable = "",
        }
    end

    return first_links, second_links
end

local function place_first_level(ctx, player)
    for _ = 1, 32 do
        local first = basic.generate(ctx, 1)
        local selected = vault_selection.choose_catalog(first.builder)
        local vault = vault_catalog.get(selected.id)
        local ok, placed = pcall(vault_placement.place, ctx, first.builder, vault, player)

        if ok then
            return first, placed, vault
        end

        if not tostring(placed):find("fixed orientation conflicts with an existing stair", 1, true) then
            error(placed)
        end
    end

    error("Dungeon:1 could not fit a fixed-orientation arrival after 32 layouts")
end

local function spawn_exclusions(placed, vault)
    local excluded = {}
    local points = {}

    local function add(x, y)
        local key = x .. ":" .. y

        if not excluded[key] then
            excluded[key] = true
            points[#points + 1] = {
                x = x,
                y = y,
            }
        end
    end

    if vault.tags.no_monster_gen then
        for _, point in ipairs(placed.occupied) do
            add(point.x, point.y)
        end
    end

    for _, record in ipairs(placed.records) do
        if record.kind == vault_effects.MASK and
            record.identity:find("no_monster_gen", 1, true) then
            add(record.x, record.y)
        end
    end

    return points
end

generated.spawn_exclusions = spawn_exclusions

function generated.generate(ctx, input)
    local player = {
        species_id = input.player_species_id,
        name = input.player_name,
        started = false,
    }
    local first, placed, vault = place_first_level(ctx, player)
    local second = basic.generate(ctx, 2)

    local original_stairs = {}

    for _, pair in ipairs(first.stairs) do
        original_stairs[#original_stairs + 1] = pair.up
        original_stairs[#original_stairs + 1] = pair.down
    end

    vault_connect.finish(ctx, first.builder, placed, original_stairs)
    first.rows = first.builder:rows()

    local first_links, second_links = stair_links(first, second, placed)
    local first_budget = monster_count(ctx, 1)
    local second_budget = monster_count(ctx, 2)
    local entry = first.stairs[1].up

    for _, exit in ipairs(placed.exits) do
        if exit.source == "{" then
            entry = exit

            break
        end
    end
    local second_entry = second.stairs[1].up

    local curing = nearest.open_floor(first.rows, entry, nil, 1)
    local heal = nearest.open_floor(second.rows, second_entry, nil, 2)
    local haste = nearest.open_floor(second.rows, second_entry, heal, 2)

    curing.level_id = 1
    heal.level_id = 2
    haste.level_id = 2

    return {
        levels = {
            {
                id = 1,
                branch_id = branches.BRANCH_DUNGEON,
                rows = first.rows,
                stairs = first_links,
                entry_x = entry.x,
                entry_y = entry.y,
                initial_monsters = first_budget,
                vault_id = placed.id,
                vault_records = placed.records,
                spawn_exclusions = spawn_exclusions(placed, vault),
            },
            {
                id = 2,
                branch_id = branches.BRANCH_DUNGEON,
                rows = second.rows,
                stairs = second_links,
                entry_x = second_entry.x,
                entry_y = second_entry.y,
                initial_monsters = second_budget,
            },
        },
        entry = {
            x = entry.x,
            y = entry.y,
        },
        curing = curing,
        heal = heal,
        haste = haste,
    }
end

return generated
