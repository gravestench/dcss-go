-- Theory of operation: the pinned GeoElf scripts draw into a symbolic grid and emit
-- glyph declarations. A private environment adapts those operations to the production
-- grid and typed placement records without sharing generation state between levels.
local grid = require("policy.generation.grid")
local surface = require("policy.generation.layouts.geoelf_surface")
local effects = require("constants.vault_effects")
local directives = require("constants.vault_directives")
local glyphs = require("constants.vault_glyphs")
local monsters = require("ids.monsters")

local family = {}

-- Parse declarations literally: castle door '=' is itself the first target glyph.
local function declaration(spec)
    local targets, value = spec:match("^(.-)%s+=%s+(.-)%s*$")

    if not targets then
        error("invalid GeoElf glyph declaration: " .. spec)
    end

    return targets:match("^%s*(.-)%s*$"), value
end

-- Store declarations by glyph until final drawing determines which cells survive overlap.
local function assign(target, spec)
    local targets, value = declaration(spec)

    for glyph in targets:gmatch(".") do
        target[glyph] = value
    end
end

-- Source util.random_choose_weighted consumes one draw after summing all ordered weights.
local function weighted(env, choices)
    local total = 0

    for _, choice in ipairs(choices) do
        total = total + choice[2]
    end

    local draw = env.crawl.random2(total)

    for _, choice in ipairs(choices) do
        if draw < choice[2] then
            return choice[1]
        end

        draw = draw - choice[2]
    end
end

-- Allocate a source-style x/y grid with harmless rock outside its drawing extent.
local function map_columns(width, height)
    local map = {}

    for x = -1, width do
        map[x] = {}

        for y = -1, height do
            map[x][y] = "x"
        end
    end

    return map
end

-- Typed records retain glyph identities and decorations after symbolic glyphs become terrain.
local function record(env, records, kind, source, identity, x, y, directive, arguments)
    records[#records + 1] = {
      kind = kind,
      identity = identity,
      source = source,
      x = x,
      y = y,
      vault_id = env.id,
      directive = directive,
      arguments = arguments,
      pending = kind ~= effects.SOURCE_FEATURE,
      base_glyph = kind == effects.SOURCE_FEATURE and env.builder:cell(x, y) or nil,
    }
end

-- Preserve custom glyph features as standard source feature identities for decoding and saves.
local function source_feature(env, source)
    local name = env.features[source]
    local keyed = {
      floor = "DNGN_FLOOR",
      closed_door = "DNGN_CLOSED_DOOR",
      closed_clear_door = "DNGN_CLOSED_CLEAR_DOOR",
      clear_rock_wall = "DNGN_CLEAR_ROCK_WALL",
    }

    return name and keyed[name] or glyphs.terrain[source]
end

-- Convert only collision semantics here; typed source features preserve the complete terrain identity.
local function collision_glyph(feature, source)
    if feature and (feature:find("WALL", 1, true) or
        feature == "DNGN_TREE" or feature == "DNGN_GRANITE_STATUE") then
        return "#"
    elseif feature == "DNGN_CLOSED_DOOR" or feature == "DNGN_CLOSED_CLEAR_DOOR" then
        return "+"
    elseif feature == "DNGN_DEEP_WATER" then
        return "w"
    elseif glyphs.up[source] then
        return "<"
    end

    return "."
end

local style_kinds = {
  {
    declarations = "colours",
    kind = effects.COLOUR,
    directive = directives.COLOUR,
  },

  {
    declarations = "tiles",
    kind = effects.TILE,
    directive = directives.TILE,
  },

  {
    declarations = "masks",
    kind = effects.MASK,
    directive = directives.KMASK,
  },
}

-- Preserve decorations and source glyph meanings after later room overlaps have settled.
local function cell_records(env, records, source, feature, x, y)
    if feature and feature ~= "DNGN_FLOOR" then
        record(env, records, effects.SOURCE_FEATURE, source, feature, x, y)
    end

    if env.monsters[source] then
        local identity = env.monsters[source]
        local plant_ids = {
          bush = monsters.MONS_BUSH,
          plant = monsters.MONS_PLANT,
          fungus = monsters.MONS_FUNGUS,
        }

        record(env, records, effects.MONSTER, source, identity, x, y,
            directives.KMONS, {
              kind_id = plant_ids[identity],
              path = "vaults/layout/" .. env.id .. ".des",
              expression = identity,
              selected_expression = identity,
              monster_slots = 1,
              no_spawn = false,
            })
    end

    for _, entry in ipairs(style_kinds) do
        local identity = env[entry.declarations][source]

        if identity then
            record(env, records, entry.kind, source, identity, x, y, entry.directive)
        end
    end
end

-- Project the final symbols while retaining the preplaced primary's terrain and ownership.
local function finish(env, room_data, corridor_data)
    local records = {}
    local protected = {}
    local spawn_exclusions = {}

    for y = 0, env.height - 1 do
        for x = 0, env.width - 1 do
            if not env.dgn.in_vault(x, y) then
                local source = env.mapgrd[x][y]
                local feature = source_feature(env, source)

                env.builder:set(x, y, collision_glyph(feature, source))
                cell_records(env, records, source, feature, x, y)

                if env.masks[source] == "vault" or env.monsters[source] then
                    protected[x .. ":" .. y] = true
                    spawn_exclusions[#spawn_exclusions + 1] = {
                      x = x,
                      y = y,
                    }
                end
            end
        end
    end

    if env.builder.bad_random then
        error("GeoElf random source failed to provide a bounded draw")
    end

    return {
      rows = env.builder:rows(),
      builder = env.builder,
      room_data = room_data,
      corridor_data = corridor_data,
      records = records,
      protected = protected,
      spawn_exclusions = spawn_exclusions,
    }
end

-- Bind all source random operations to the production stream and preserve source draw semantics.
local function bind_random(env, api)
    local builder = env.builder

    -- Bounded source integer choices use the production layout RNG stream.
    function env.crawl.random2(bound)
        return builder:roll(bound)
    end

    -- Source random_range includes both endpoints and truncates integer arguments.
    function env.crawl.random_range(first, last)
        first = math.floor(first)
        last = math.floor(last)

        return first + builder:roll(last - first + 1)
    end

    -- Source random_real uses the low 52 random bits as an IEEE mantissa in [0,1).
    function env.crawl.random_real()
        local hi, lo = api.ctx:random_u64("layout")

        return ((hi % 1048576) * 4294967296 + lo) / 4503599627370496
    end

    -- Source coinflip shares the same layout stream as room geometry decisions.
    function env.crawl.coinflip()
        return builder:one_in(2)
    end

    -- Source one-in-N choices avoid independent state in the adapted engine.
    function env.crawl.one_chance_in(bound)
        return builder:one_in(bound)
    end

    -- Weighted reservoir shape selection uses source chance-in-total semantics.
    function env.crawl.x_chance_in_y(chance, total)
        return builder:chance_in(chance, total)
    end

    -- Source diagnostics indicate an invariant failure and must stop generation visibly.
    function env.crawl.mpr(message)
        error(message)
    end
end

-- Expose generation-local dimensions and primary ownership through the source map contract.
local function bind_map(env, api)
    local primary = api.primary_vault

    -- Source geometry uses this generation's dimensions, including ordinary 80 by 70 levels.
    function env.dgn.max_bounds()
        return env.width, env.height
    end

    -- Inclusive primary bounds describe cells already owned by the preplaced source vault.
    function env.dgn.in_vault(x, y)
        return primary ~= nil and x >= primary.x1 and x <= primary.x2 and
            y >= primary.y1 and y <= primary.y2
    end

    -- Depth fraction is branch-local progress, with zero at entry and one at its bottom.
    function env.you.depth_fraction()
        local bottom = api.branch_bottom or 3

        if bottom <= 1 then
            return 1
        end

        return ((api.depth or 1) - 1) / (bottom - 1)
    end

    -- Source weighted choices consume one bounded draw over the sum of ordered weights.
    function env.util.random_choose_weighted(choices)
        return weighted(env, choices)
    end

    -- Match source map extension without changing the already allocated grid owner.
    function env.extend_map(spec)
        for y = 0, env.height - 1 do
            for x = 0, env.width - 1 do
                env.mapgrd[x][y] = spec.fill
            end
        end
    end

    -- Layout room omission checks only primary ownership when find is the empty string.
    function env.find_in_area(spec)
        for y = spec.y1, spec.y2 do
            for x = spec.x1, spec.x2 do
                if spec.find_vault and env.dgn.in_vault(x, y) then
                    return true
                end
            end
        end

        return false
    end

    -- Missing primary dimensions intentionally return nil for the castle's source veto.
    function env.primary_vault_dimensions()
        if primary then
            return primary.x1, primary.x2, primary.y1, primary.y2
        end
    end
end

-- Bind source per-cell substitution and exact external stair reservation operations.
local function bind_substitutions(env, api)
    local builder = env.builder

    -- Glyph substitutions choose per cell, retaining repeated alternatives as source weights.
    function env.subst(spec)
        local targets, choices = declaration(spec)

        for y = 0, env.height - 1 do
            for x = 0, env.width - 1 do
                if targets:find(env.mapgrd[x][y], 1, true) then
                    local index = builder:roll(#choices) + 1
                    env.mapgrd[x][y] = choices:sub(index, index)
                end
            end
        end
    end

    -- The castle reserves one of each up-stair glyph outside its protected interior.
    function env.nsubst(_)
        local candidates = {}

        for y = 1, env.height - 2 do
            for x = 1, env.width - 2 do
                if env.mapgrd[x][y] == "." and not env.dgn.in_vault(x, y) then
                    candidates[#candidates + 1] = {
                      x = x,
                      y = y,
                    }
                end
            end
        end

        for _, glyph in ipairs({
          "{",
          "(",
          "[",
        }) do
            if #candidates > 0 then
                local index = builder:roll(#candidates) + 1
                local point = candidates[index]
                candidates[index] = candidates[#candidates]
                candidates[#candidates] = nil
                env.mapgrd[point.x][point.y] = glyph
            end
        end
    end
end

-- Collect source glyph meanings until overlap has determined the final surviving cells.
local function bind_declarations(env, api)
    -- Keyed source terrain meanings are applied only after the final glyph drawing pass.
    function env.kfeat(spec)
        assign(env.features, spec)
    end

    -- Decorative plants become authored monster records rather than collision terrain.
    function env.kmons(spec)
        assign(env.monsters, spec)
    end

    -- Source vault masks preserve castle and decorative plant cells from later placement.
    function env.kmask(spec)
        assign(env.masks, spec)
    end

    -- Stained glass colours survive terrain projection as typed display records.
    function env.colour(spec)
        assign(env.colours, spec)
    end

    -- Source stained glass tile identities remain available to rendering and saves.
    function env.tile(spec)
        assign(env.tiles, spec)
    end
end

-- Bind source drawing helpers to the current map and keep every generation isolated.
local function bind_surface(env, api)
    for _, name in ipairs({
      "remove_disconnected_doors",
      "add_windows",
      "fill_area",
      "make_circle",
      "make_round_box",
      "connect_adjacent_rooms",
    }) do
        -- Bind one surface helper to this generation without sharing the mutable map.
        env[name] = function(spec)
            return surface[name](env, spec)
        end
    end
end

-- Capture builder, RNG, glyph declarations, and primary bounds in one generation environment.
function family.new(api)
    local builder = api.builder or grid.new(api.ctx, api.width, api.height)
    local env = {
      builder = builder,
      width = builder.width,
      height = builder.height,
      id = api.definition and api.definition.id or api.layout_id or "layout_geoelf",
      mapgrd = map_columns(builder.width, builder.height),
      geoelf = {},
      crawl = {},
      dgn = {},
      you = {},
      util = {},
      features = {},
      monsters = {},
      colours = {},
      tiles = {},
      masks = {},
    }

    bind_random(env, api)
    bind_map(env, api)
    bind_substitutions(env, api)
    bind_declarations(env, api)
    bind_surface(env, api)

    -- Return the builder and retained records only after every source drawing phase finishes.
    function env.result(room_data, corridor_data)
        return finish(env, room_data, corridor_data)
    end

    require("policy.generation.layouts.geoelf_engine")(env)

    return env
end

return family
