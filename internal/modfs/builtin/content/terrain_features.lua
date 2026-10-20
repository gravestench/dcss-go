-- Translate vault terrain into the level grid without discarding instructions
-- that still need population or gameplay handling. DCSS feature names remain
-- the saved vocabulary; map glyphs are only source syntax. The reduced stair
-- variants use the same travel rule, while their vault records keep the
-- original feature identity for later rules and save inspection.
local features = {}
local effects = require("constants.vault_effects")
local trap_placement = require("policy.traps.placement")
local glyphs = require("constants.vault_glyphs")
local fill = require("constants.vault_border_fill")

features.from_source_glyph = {
    ["#"] = "DNGN_ROCK_WALL",
    ["."] = "DNGN_FLOOR",
    ["+"] = "DNGN_CLOSED_DOOR",
    ["~"] = "DNGN_CLOSED_CLEAR_DOOR",
    -- The Swamp heightmap emits this private procedural glyph. Authored
    -- DES files keep their normal keyed-glyph semantics and may override it.
    q = "DNGN_MANGROVE",
    ["'"] = "DNGN_OPEN_DOOR",
    ["<"] = "DNGN_STONE_STAIRS_UP_I",
    [">"] = "DNGN_STONE_STAIRS_DOWN_I",
    -- Source KFEAT resolves this layout-only placeholder through a typed
    -- feature record after the base grid is decoded.
    L = "DNGN_ROCK_WALL",
}

-- Some source stair and hatch variants share the current kernel's travel
-- behavior. Their original identity remains in the saved vault record.
features.vault_terrain = {
    DNGN_FLOOR = "DNGN_FLOOR",
    DNGN_ROCK_WALL = "DNGN_ROCK_WALL",
    DNGN_PERMAROCK_WALL = "DNGN_PERMAROCK_WALL",
    DNGN_STONE_WALL = "DNGN_STONE_WALL",
    DNGN_CLEAR_ROCK_WALL = "DNGN_CLEAR_ROCK_WALL",
    DNGN_CLEAR_STONE_WALL = "DNGN_CLEAR_STONE_WALL",
    DNGN_CLEAR_PERMAROCK_WALL = "DNGN_CLEAR_PERMAROCK_WALL",
    DNGN_METAL_WALL = "DNGN_METAL_WALL",
    DNGN_CRYSTAL_WALL = "DNGN_CRYSTAL_WALL",
    DNGN_TREE = "DNGN_TREE",
    DNGN_CLOSED_DOOR = "DNGN_CLOSED_DOOR",
    DNGN_CLOSED_CLEAR_DOOR = "DNGN_CLOSED_CLEAR_DOOR",
    DNGN_RUNED_DOOR = "DNGN_CLOSED_DOOR",
    DNGN_SHALLOW_WATER = "DNGN_SHALLOW_WATER",
    DNGN_DEEP_WATER = "DNGN_DEEP_WATER",
    DNGN_LAVA = "DNGN_LAVA",
    DNGN_OPEN_SEA = "DNGN_OPEN_SEA",
    DNGN_LAVA_SEA = "DNGN_LAVA_SEA",
    DNGN_STONE_STAIRS_UP_I = "DNGN_STONE_STAIRS_UP_I",
    DNGN_STONE_STAIRS_UP_II = "DNGN_STONE_STAIRS_UP_I",
    DNGN_STONE_STAIRS_UP_III = "DNGN_STONE_STAIRS_UP_I",
    DNGN_STONE_STAIRS_DOWN_I = "DNGN_STONE_STAIRS_DOWN_I",
    DNGN_STONE_STAIRS_DOWN_II = "DNGN_STONE_STAIRS_DOWN_I",
    DNGN_STONE_STAIRS_DOWN_III = "DNGN_STONE_STAIRS_DOWN_I",
    DNGN_ESCAPE_HATCH_UP = "DNGN_STONE_STAIRS_UP_I",
    DNGN_ESCAPE_HATCH_DOWN = "DNGN_STONE_STAIRS_DOWN_I",
    DNGN_GRANITE_STATUE = "DNGN_GRANITE_STATUE",
    DNGN_ORCISH_IDOL = "DNGN_ORCISH_IDOL",
}

-- A generated layout uses the same DES glyph vocabulary as placed vaults.
-- Resolve source variants through the kernel's current travel features so
-- alternate stairs remain usable while the layout retains its authored map.
for glyph, identity in pairs(glyphs.terrain) do
    local feature = features.vault_terrain[identity]

    if feature and features.from_source_glyph[glyph] == nil then
        features.from_source_glyph[glyph] = feature
    end
end

features.named_vault_terrain = {
    -- KFEAT names denote explicit terrain choices, while source features
    -- above already carry the original DNGN_* identity.
    floor = "DNGN_FLOOR",
    rock_wall = "DNGN_ROCK_WALL",
    stone_wall = "DNGN_STONE_WALL",
    perma_rock_wall = "DNGN_PERMAROCK_WALL",
    clear_rock_wall = "DNGN_CLEAR_ROCK_WALL",
    clear_stone_wall = "DNGN_CLEAR_STONE_WALL",
    metal_wall = "DNGN_METAL_WALL",
    crystal_wall = "DNGN_CRYSTAL_WALL",
    tree = "DNGN_TREE",
    petrified_tree = "DNGN_PETRIFIED_TREE",
    granite_statue = "DNGN_GRANITE_STATUE",
    closed_door = "DNGN_CLOSED_DOOR",
    closed_clear_door = "DNGN_CLOSED_CLEAR_DOOR",
    open_door = "DNGN_OPEN_DOOR",
    shallow_water = "DNGN_SHALLOW_WATER",
    deep_water = "DNGN_DEEP_WATER",
    lava = "DNGN_LAVA",
}

-- BORDER_FILL is a single typed instruction for the whole map exterior.
-- Decoding it here preserves the distinction between deep water and the
-- source's open sea, and between ordinary lava and endless lava sea.
local function apply_border_fill(cells, record)
    local arguments = record.arguments or {}
    local style = arguments.style
    local feature

    if style == fill.OPEN_SEA then
        feature = "DNGN_OPEN_SEA"
    elseif style == fill.ENDLESS_LAVA then
        feature = "DNGN_LAVA_SEA"
    else
        error("unknown vault border fill " .. tostring(style))
    end

    local left = arguments.bounds_x
    local top = arguments.bounds_y
    local right = left + arguments.bounds_width
    local bottom = top + arguments.bounds_height

    for y, row in ipairs(cells) do
        for x in ipairs(row) do
            local world_x = x - 1
            local world_y = y - 1

            if world_x < left or world_x >= right or
                world_y < top or world_y >= bottom then
                row[x] = feature
            end
        end
    end

    record.pending = false
end

-- Apply terrain now; retain records needed for later trap and gameplay passes.
function features.apply_vault_terrain(cells, records, ctx, depth)
    local retained = {}

    for _, record in ipairs(records or {}) do
        local keep = true

        if record.kind == effects.SOURCE_FEATURE and record.overridden then
            -- An explicit replacement wins over an earlier source glyph.
            keep = false
        elseif record.kind == effects.SOURCE_FEATURE then
            local feature = features.vault_terrain[record.identity]

            if feature then
                cells[record.y + 1][record.x + 1] = feature

                if feature == record.identity then
                    -- The grid now fully represents this unchanged feature.
                    keep = false
                end
            end
        elseif record.kind == effects.FEATURE and not record.overridden then
            if trap_placement.is_trap(record) then
                if not ctx then
                    error("trap feature selection needs a generation context")
                end

                local kind_id, name = trap_placement.resolve(ctx, record, depth)

                -- Select KFEAT alternatives while the terrain grid is built.
                -- The saved record then carries the result into population.
                record.identity = kind_id or name
            end

            local feature = features.named_vault_terrain[record.identity]

            if feature then
                cells[record.y + 1][record.x + 1] = feature
                record.pending = false
                keep = false
            end
        elseif record.kind == effects.BORDER_FILL then
            apply_border_fill(cells, record)
        end

        if keep then
            retained[#retained + 1] = record
        end
    end

    return retained
end

-- Decode glyph rows while keeping diagnostics in zero-based vault coordinates.
function features.decode_source_rows(rows)
    local cells = {}

    for y, row in ipairs(rows) do
        local cell_row = {}

        for x = 1, #row do
            local glyph = row:sub(x, x)
            local feature = features.from_source_glyph[glyph]

            if not feature then
                -- Keep source coordinates zero based in diagnostics, matching
                -- the vault record format rather than Lua's table indices.
                error(string.format("unknown source terrain glyph %q at (%d,%d)", glyph, x - 1, y - 1))
            end

            cell_row[x] = feature
        end

        cells[y] = cell_row
    end

    return cells
end

return features
