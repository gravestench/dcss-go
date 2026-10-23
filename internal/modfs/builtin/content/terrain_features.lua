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
local terrain = require("constants.terrain")

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
    DNGN_RANDOM_ALTAR = "DNGN_RANDOM_ALTAR",
    DNGN_ROCK_WALL = "DNGN_ROCK_WALL",
    DNGN_PERMAROCK_WALL = "DNGN_PERMAROCK_WALL",
    DNGN_STONE_WALL = "DNGN_STONE_WALL",
    [terrain.DNGN_STONE_ARCH] = terrain.DNGN_STONE_ARCH,
    DNGN_CLEAR_ROCK_WALL = "DNGN_CLEAR_ROCK_WALL",
    DNGN_CLEAR_STONE_WALL = "DNGN_CLEAR_STONE_WALL",
    DNGN_CLEAR_PERMAROCK_WALL = "DNGN_CLEAR_PERMAROCK_WALL",
    DNGN_METAL_WALL = "DNGN_METAL_WALL",
    DNGN_CRYSTAL_WALL = "DNGN_CRYSTAL_WALL",
    DNGN_TREE = "DNGN_TREE",
    [terrain.DNGN_FOUNTAIN_BLUE] = terrain.DNGN_FOUNTAIN_BLUE,
    [terrain.DNGN_FOUNTAIN_MAGIC] = terrain.DNGN_FOUNTAIN_MAGIC,
    [terrain.DNGN_FOUNTAIN_DRY] = terrain.DNGN_FOUNTAIN_DRY,
    [terrain.DNGN_FOUNTAIN_BLOOD] = terrain.DNGN_FOUNTAIN_BLOOD,
    DNGN_CLOSED_DOOR = "DNGN_CLOSED_DOOR",
    DNGN_CLOSED_CLEAR_DOOR = "DNGN_CLOSED_CLEAR_DOOR",
    DNGN_RUNED_DOOR = "DNGN_CLOSED_DOOR",
    DNGN_SHALLOW_WATER = "DNGN_SHALLOW_WATER",
    DNGN_DEEP_WATER = "DNGN_DEEP_WATER",
    DNGN_LAVA = "DNGN_LAVA",
    DNGN_OPEN_SEA = "DNGN_OPEN_SEA",
    DNGN_LAVA_SEA = "DNGN_LAVA_SEA",
    DNGN_ENDLESS_SALT = terrain.DNGN_ENDLESS_SALT,
    DNGN_STONE_STAIRS_UP_I = "DNGN_STONE_STAIRS_UP_I",
    DNGN_STONE_STAIRS_UP_II = "DNGN_STONE_STAIRS_UP_I",
    DNGN_STONE_STAIRS_UP_III = "DNGN_STONE_STAIRS_UP_I",
    DNGN_STONE_STAIRS_DOWN_I = "DNGN_STONE_STAIRS_DOWN_I",
    [terrain.DNGN_ENTER_BAZAAR] = terrain.DNGN_ENTER_BAZAAR,
    [terrain.DNGN_EXIT_BAZAAR] = terrain.DNGN_EXIT_BAZAAR,
    [terrain.DNGN_ENTER_SEWER] = terrain.DNGN_ENTER_SEWER,
    [terrain.DNGN_EXIT_SEWER] = terrain.DNGN_EXIT_SEWER,
    [terrain.DNGN_ENTER_OSSUARY] = terrain.DNGN_ENTER_OSSUARY,
    [terrain.DNGN_EXIT_OSSUARY] = terrain.DNGN_EXIT_OSSUARY,
    [terrain.DNGN_ENTER_WIZLAB] = terrain.DNGN_ENTER_WIZLAB,
    [terrain.DNGN_EXIT_WIZLAB] = terrain.DNGN_EXIT_WIZLAB,
    [terrain.DNGN_ENTER_GAUNTLET] = terrain.DNGN_ENTER_GAUNTLET,
    [terrain.DNGN_EXIT_GAUNTLET] = terrain.DNGN_EXIT_GAUNTLET,
    [terrain.DNGN_ENTER_ICE_CAVE] = terrain.DNGN_ENTER_ICE_CAVE,
    [terrain.DNGN_EXIT_ICE_CAVE] = terrain.DNGN_EXIT_ICE_CAVE,
    [terrain.DNGN_ENTER_VOLCANO] = terrain.DNGN_ENTER_VOLCANO,
    [terrain.DNGN_EXIT_VOLCANO] = terrain.DNGN_EXIT_VOLCANO,
    [terrain.DNGN_ENTER_TROVE] = terrain.DNGN_ENTER_TROVE,
    [terrain.DNGN_EXIT_TROVE] = terrain.DNGN_EXIT_TROVE,
    [terrain.DNGN_EXPIRED_PORTAL] = terrain.DNGN_EXPIRED_PORTAL,
    [terrain.DNGN_ENTER_PANDEMONIUM] = terrain.DNGN_ENTER_PANDEMONIUM,
    [terrain.DNGN_TRANSIT_PANDEMONIUM] = terrain.DNGN_TRANSIT_PANDEMONIUM,
    [terrain.DNGN_EXIT_PANDEMONIUM] = terrain.DNGN_EXIT_PANDEMONIUM,
    [terrain.DNGN_EXIT_THROUGH_ABYSS] = terrain.DNGN_EXIT_THROUGH_ABYSS,
    [terrain.DNGN_ENTER_HELL] = terrain.DNGN_ENTER_HELL,
    [terrain.DNGN_EXIT_HELL] = terrain.DNGN_EXIT_HELL,
    [terrain.DNGN_ENTER_DIS] = terrain.DNGN_ENTER_DIS,
    [terrain.DNGN_EXIT_DIS] = terrain.DNGN_EXIT_DIS,
    [terrain.DNGN_ENTER_GEHENNA] = terrain.DNGN_ENTER_GEHENNA,
    [terrain.DNGN_EXIT_GEHENNA] = terrain.DNGN_EXIT_GEHENNA,
    [terrain.DNGN_ENTER_COCYTUS] = terrain.DNGN_ENTER_COCYTUS,
    [terrain.DNGN_EXIT_COCYTUS] = terrain.DNGN_EXIT_COCYTUS,
    [terrain.DNGN_ENTER_TARTARUS] = terrain.DNGN_ENTER_TARTARUS,
    [terrain.DNGN_EXIT_TARTARUS] = terrain.DNGN_EXIT_TARTARUS,
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
    stone_arch = terrain.DNGN_STONE_ARCH,
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
    -- Bazaar's DES KFEAT names become live arches before the portal travel
    -- policy checks the cell under the player.
    enter_bazaar = terrain.DNGN_ENTER_BAZAAR,
    exit_bazaar = terrain.DNGN_EXIT_BAZAAR,
    enter_sewer = terrain.DNGN_ENTER_SEWER,
    exit_sewer = terrain.DNGN_EXIT_SEWER,
    enter_ossuary = terrain.DNGN_ENTER_OSSUARY,
    exit_ossuary = terrain.DNGN_EXIT_OSSUARY,
    enter_wizlab = terrain.DNGN_ENTER_WIZLAB,
    exit_wizlab = terrain.DNGN_EXIT_WIZLAB,
    enter_desolation = terrain.DNGN_ENTER_DESOLATION,
    exit_desolation = terrain.DNGN_EXIT_DESOLATION,
    enter_gauntlet = terrain.DNGN_ENTER_GAUNTLET,
    exit_gauntlet = terrain.DNGN_EXIT_GAUNTLET,
    enter_bailey = terrain.DNGN_ENTER_BAILEY,
    exit_bailey = terrain.DNGN_EXIT_BAILEY,
    enter_ice_cave = terrain.DNGN_ENTER_ICE_CAVE,
    exit_ice_cave = terrain.DNGN_EXIT_ICE_CAVE,
    enter_volcano = terrain.DNGN_ENTER_VOLCANO,
    exit_volcano = terrain.DNGN_EXIT_VOLCANO,
    expired_portal = terrain.DNGN_EXPIRED_PORTAL,
    open_sea = terrain.DNGN_OPEN_SEA,
    -- Pan KFEAT names become live arch cells. Their original source names
    -- are mapped once here so every authored vault and Lua hook agrees.
    enter_pandemonium = terrain.DNGN_ENTER_PANDEMONIUM,
    transit_pandemonium = terrain.DNGN_TRANSIT_PANDEMONIUM,
    exit_pandemonium = terrain.DNGN_EXIT_PANDEMONIUM,
    exit_through_abyss = terrain.DNGN_EXIT_THROUGH_ABYSS,
    -- Hell's source branch gates become live grid features. Lua travel
    -- chooses destinations from these IDs, including distinct return gates.
    enter_hell = terrain.DNGN_ENTER_HELL,
    exit_hell = terrain.DNGN_EXIT_HELL,
    enter_dis = terrain.DNGN_ENTER_DIS,
    exit_dis = terrain.DNGN_EXIT_DIS,
    enter_gehenna = terrain.DNGN_ENTER_GEHENNA,
    exit_gehenna = terrain.DNGN_EXIT_GEHENNA,
    enter_cocytus = terrain.DNGN_ENTER_COCYTUS,
    exit_cocytus = terrain.DNGN_EXIT_COCYTUS,
    enter_tartarus = terrain.DNGN_ENTER_TARTARUS,
    exit_tartarus = terrain.DNGN_EXIT_TARTARUS,
    enter_trove = terrain.DNGN_ENTER_TROVE,
    exit_trove = terrain.DNGN_EXIT_TROVE,
    endless_salt = terrain.DNGN_ENDLESS_SALT,
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
    elseif style == fill.ENDLESS_SALT then
        feature = terrain.DNGN_ENDLESS_SALT
    elseif style == fill.PERMAROCK_WALL then
        feature = terrain.DNGN_PERMAROCK_WALL
    elseif style == fill.TREE then
        feature = terrain.DNGN_TREE
    else
        error("unknown vault border fill " .. tostring(style))
    end

    local left = arguments.bounds_x
    local top = arguments.bounds_y
    local right = left + arguments.bounds_width
    local bottom = top + arguments.bounds_height
    local preserved = {}

    for coordinate in (arguments.preserve_cells or ""):gmatch("[^|]+") do
        preserved[coordinate] = true
    end

    for y, row in ipairs(cells) do
        for x in ipairs(row) do
            local world_x = x - 1
            local world_y = y - 1

            if (world_x < left or world_x >= right or
                world_y < top or world_y >= bottom) and
                not preserved[world_x .. ":" .. world_y] then
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
            local previous = record.base_glyph and
                features.from_source_glyph[record.base_glyph]
            local current = cells[record.y + 1][record.x + 1]

            -- An authored map drawn later may replace this layout cell.
            -- Its final glyph wins over the older source feature record.
            if previous and current ~= previous then
                keep = false
            elseif feature then
                cells[record.y + 1][record.x + 1] = feature

                if feature == record.identity and
                    not (record.arguments and record.arguments.god_id) then
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
        elseif record.kind == effects.FEATURE_NAME and not record.overridden then
            -- Resolve the source's local alias once during generation. The
            -- renderer reads this saved terrain ID without owning a Lua
            -- content table or changing the underlying collision feature.
            local arguments = record.arguments or {}
            local source = arguments.feature
            local feature = source and
                (features.named_vault_terrain[source] or
                    features.vault_terrain[source])

            if feature then
                arguments.feature_id = feature
                record.arguments = arguments
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
