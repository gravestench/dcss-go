-- Theory of operation: expand a suitable primary vault with inner rooms, a perimeter
-- hall, moat, turrets, and a gate on its widest side. A modified GeoElf grid occupies
-- the remaining space; dummy rooms connect that grid to the castle's open surround.
-- Source: crawl-ref/source/dat/des/builder/layout_geoelf_castle.des
local family = require("policy.generation.layouts.geoelf")

local layout = {}

--
-- Constants
--
-- Source constants are module-local so the generator and veto
-- share the same rules without mutating the global environment.
--

-- size of castle
local CASTLE_INNER        = 4
local CASTLE_HALLWAY      = 3
local CASTLE_MOAT         = 2
local CASTLE_OPEN         = 1
local CASTLE_OVERWRITABLE = 3
local CASTLE_TOTAL        = CASTLE_INNER + CASTLE_HALLWAY      + CASTLE_MOAT +
                        CASTLE_OPEN  + CASTLE_OVERWRITABLE
local CASTLE_TURRET_RADIUS      = 4
local CASTLE_TURRET_MOAT_RADIUS = CASTLE_TURRET_RADIUS + CASTLE_MOAT
local CASTLE_TURRET_OPEN_RADIUS = CASTLE_TURRET_MOAT_RADIUS + CASTLE_OPEN
local CASTLE_TURRET_OVERWRITABLE_RADIUS = CASTLE_HALLWAY + CASTLE_MOAT         +
                                      CASTLE_OPEN    + CASTLE_OVERWRITABLE - 1

local INNER_WALL_SPACING_MIN = 6
local INNER_WALL_SPACING_MAX = 12

local GATE_FROM_CORNER_MIN = 8
local GATE_SIZE_MIN = 2
local GATE_SIZE_MAX = 3

-- room parameters
local ROOMS_OFFSET_MAX      = 1
local ROOMS_RADIUS_MIN      = 3
local ROOMS_RADIUS_MAX      = 5
local ROOMS_RADIUS_EDGE_MIN = 2
local ROOMS_RADIUS_EDGE_MAX = 4
local ROOMS_EXTRA_CORRIDOR_FRACTION = 0.5
local ROOMS_FANCY_ROOM_FRACTION     = 0.2

-- room placement
local ROOMS_BORDER_MIN  = ROOMS_OFFSET_MAX + ROOMS_RADIUS_MAX + 1
local ROOMS_FROM_CASTLE = ROOMS_OFFSET_MAX + ROOMS_RADIUS_MAX + 1
local ROOMS_SPACING_MIN = ROOMS_OFFSET_MAX + ROOMS_RADIUS_MAX * 2 + 2
local ROOMS_INTO_CASTLE = ROOMS_SPACING_MIN - ROOMS_FROM_CASTLE
local ROOMS_MIN_SPACE   = CASTLE_TOTAL + ROOMS_BORDER_MIN + ROOMS_FROM_CASTLE

-- veto tests
local PRIMARY_VAULT_MIN_PADDING = ROOMS_MIN_SPACE + 1
local PRIMARY_VAULT_MIN_SIZE    = GATE_FROM_CORNER_MIN + GATE_SIZE_MAX
                              - CASTLE_HALLWAY - CASTLE_INNER

-- edge rows of rooms have no individual offset to allow
--  for maximum distance from grid
local ROOMS_SPACING_EDGE   = math.ceil(ROOMS_SPACING_MIN / 2) + 1
local ROOMS_MIN_SPACE_EDGE = ROOMS_SPACING_EDGE + ROOMS_RADIUS_EDGE_MAX + 2


-- Source veto requires a primary of sufficient size and room for at least one outer row.
function layout.veto(api)
  local primary = api.primary_vault
  local width = api.width or (api.builder and api.builder.width) or 80
  local height = api.height or (api.builder and api.builder.height) or 70

  if not primary then
    return true
  end

  for _, field in ipairs({
    "x1",
    "x2",
    "y1",
    "y2",
  }) do
    if type(primary[field]) ~= "number" or primary[field] % 1 ~= 0 then
      return true
    end
  end

  if primary.x1 < 0 or primary.x2 >= width or primary.x1 > primary.x2 or
      primary.y1 < 0 or primary.y2 >= height or primary.y1 > primary.y2 then
    return true
  end

  local env = family.new(api)
  local dgn = env.dgn
  local crawl = env.crawl
  -- Only allow this layout if there is a primary vault with
  --  enough space around it for at least one line of rooms

  local gxm, gym = dgn.max_bounds()
  local p_x_min, p_x_max, p_y_min, p_y_max = env.primary_vault_dimensions()

  if (p_x_min == nil) then
    return true  -- no primary vault
  elseif (p_x_max - p_x_min < PRIMARY_VAULT_MIN_SIZE or
          p_y_max - p_y_min < PRIMARY_VAULT_MIN_SIZE) then
    -- primary vault is too small
    return true
  elseif (p_x_min <           PRIMARY_VAULT_MIN_PADDING and
          p_x_max > gxm - 1 - PRIMARY_VAULT_MIN_PADDING and
          p_y_min <           PRIMARY_VAULT_MIN_PADDING and
          p_y_max > gym - 1 - PRIMARY_VAULT_MIN_PADDING) then
    -- not enough room around primary vault on any side
    return true
  else
    return false
  end
end

local INSIDE_GLYPH = "'"
local WALL_GLYPH = "c"
local DOOR_GLYPH = "="
local MOAT_GLYPH = "w"

-- Choose castle sides and the gate by the primary vault's available padding.
local function choose_castle_sides(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  local p_x_min, p_x_max, p_y_min, p_y_max = env.primary_vault_dimensions()
  if (p_x_min == nil) then
    crawl.mpr("layout_geoelf_castle didn't veto for no primary vault")
    return true  -- no primary vault
  end

  state.primary_vault = {
    bounds = {},
    border = {}
  }
  state.primary_vault.bounds[geoelf.directions.W] = p_x_min
  state.primary_vault.bounds[geoelf.directions.E] = p_x_max
  state.primary_vault.bounds[geoelf.directions.N] = p_y_min
  state.primary_vault.bounds[geoelf.directions.S] = p_y_max
  state.primary_vault.border[geoelf.directions.W] =       p_x_min - 1
  state.primary_vault.border[geoelf.directions.E] = state.gxm - p_x_max - 2
  state.primary_vault.border[geoelf.directions.N] =       p_y_min - 1
  state.primary_vault.border[geoelf.directions.S] = state.gym - p_y_max - 2

  state.is_castle = {}
  state.is_rooms  = {}
  state.gate_best = nil
  state.gate_best_space = 0
  for i = 0, geoelf.directions.COUNT_STRAIGHT - 1 do
    state.is_castle[i] = (state.primary_vault.border[i] >= CASTLE_TOTAL)
    state.is_rooms[i]  = (state.primary_vault.border[i] >= ROOMS_MIN_SPACE)

    -- put the castle gate on the side with most space
    if (state.primary_vault.border[i] > state.gate_best_space) then
      state.gate_best = i
      state.gate_best_space = state.primary_vault.border[i]
    end
  end


end

-- Expand the primary bounds through inner rooms, hallway, moat, and outer open rings.
local function design_castle(env, state)
  local geoelf = env.geoelf

  state.castle = {
    base = {},
    inner = {},
    hallway = {},
    moat = {},
    open = {},
    overwritable = {},
    turret = {}
  }

  for i = 0, geoelf.directions.COUNT_STRAIGHT - 1 do
    state.castle.base[i] = state.primary_vault.bounds[i]
  end

  if (state.castle.base[geoelf.directions.W] < 1) then
    state.castle.base[geoelf.directions.W] = 1
  end
  if (state.castle.base[geoelf.directions.E] > state.gxm - 2) then
    state.castle.base[geoelf.directions.E] = state.gxm - 2
  end
  if (state.castle.base[geoelf.directions.N] < 1) then
    state.castle.base[geoelf.directions.N] = 1
  end
  if (state.castle.base[geoelf.directions.S] > state.gym - 2) then
    state.castle.base[geoelf.directions.S] = state.gym - 2
  end

  for i = 0, geoelf.directions.COUNT_STRAIGHT - 1 do
    local step_sign = geoelf.directions.STEP_SIGN[i]

    if (state.is_castle[i]) then
      state.castle.inner[i]        = state.castle.base[i]    + CASTLE_INNER     * step_sign
      state.castle.hallway[i]      = state.castle.inner[i]   + CASTLE_HALLWAY   * step_sign
      state.castle.moat[i]         = state.castle.hallway[i] + CASTLE_MOAT      * step_sign
      state.castle.open[i]         = state.castle.moat[i]    + CASTLE_OPEN      * step_sign
      state.castle.overwritable[i] = state.castle.open[i] + CASTLE_OVERWRITABLE * step_sign
    else
      state.castle.inner[i]        = state.castle.base[i] + step_sign
      state.castle.hallway[i]      = state.castle.base[i] + step_sign
      state.castle.moat[i]         = state.castle.base[i]
      state.castle.open[i]         = state.castle.base[i]
      state.castle.overwritable[i] = state.castle.base[i]
    end
  end


  -- choose which turrets to add
  for i = geoelf.directions.COUNT_STRAIGHT, geoelf.directions.COUNT - 1 do
    local component_x = geoelf.directions.COMPONENT_X[i]
    local component_y = geoelf.directions.COMPONENT_Y[i]

    state.castle.turret[i] = {}
    state.castle.turret[i].is_placed = (    state.is_castle[component_x]
                                  and state.is_castle[component_y])
    -- turret position is linked to inner rooms, not hallway
    state.castle.turret[i].x = state.castle.inner[component_x]
                         + geoelf.directions.STEP_SIGN[component_x]
    state.castle.turret[i].y = state.castle.inner[component_y]
                         + geoelf.directions.STEP_SIGN[component_y]
  end


end

-- Choose source horizontal room spacing, allowing stretched rows beside the castle.
local function choose_horizontal_spacing(env, state)
  local geoelf = env.geoelf

  state.edge_rooms = {}

  -- spacing of north and south rooms along x axis
  local min_x = state.castle.overwritable[geoelf.directions.W] + ROOMS_INTO_CASTLE
  local max_x = state.castle.overwritable[geoelf.directions.E] - ROOMS_INTO_CASTLE
  local range_x = max_x - min_x
  state.edge_rooms.count_x = math.floor(range_x / ROOMS_SPACING_MIN) + 1
  local range_x_min = (state.edge_rooms.count_x - 1) * ROOMS_SPACING_MIN
  state.edge_rooms.spacing_x = ROOMS_SPACING_MIN
  state.edge_rooms.allow_diagonals_x = true

  if (state.is_rooms[geoelf.directions.W]) then
    if (state.is_rooms[geoelf.directions.E]) then
      -- spread out the rooms to connect on both sides
      --  -> this prevents diagonal connections on the side
      state.edge_rooms.min_x = min_x
      state.edge_rooms.spacing_x = range_x / (state.edge_rooms.count_x - 1)
      state.edge_rooms.allow_diagonals_x = false
    else
      -- pack the rooms against the west side
      state.edge_rooms.min_x = min_x
    end
  else
    if (state.is_rooms[geoelf.directions.E]) then
      -- pack the rooms against the east side
      state.edge_rooms.min_x = max_x - range_x_min
    else
      -- center the rooms
      local min_x_max = max_x - range_x_min
      state.edge_rooms.min_x = math.floor((min_x + min_x_max) / 2)
    end
  end
end

-- Choose source vertical spacing independently, preserving the axis-specific room choices.
local function choose_vertical_spacing(env, state)
  local geoelf = env.geoelf

  local min_y = state.castle.overwritable[geoelf.directions.N] + ROOMS_INTO_CASTLE
  local max_y = state.castle.overwritable[geoelf.directions.S] - ROOMS_INTO_CASTLE
  local range_y = max_y - min_y
  state.edge_rooms.count_y = math.floor(range_y / ROOMS_SPACING_MIN) + 1
  local range_y_min = (state.edge_rooms.count_y - 1) * ROOMS_SPACING_MIN
  state.edge_rooms.spacing_y = ROOMS_SPACING_MIN
  state.edge_rooms.allow_diagonals_y = true

  if (state.is_rooms[geoelf.directions.N]) then
    if (state.is_rooms[geoelf.directions.S]) then
      -- spread out the rooms to connect on both sides
      --  -> this prevents diagonal connections on the side
      state.edge_rooms.min_y = min_y
      state.edge_rooms.spacing_y = range_y / (state.edge_rooms.count_y - 1)
      state.edge_rooms.allow_diagonals_y = false
    else
      -- pack the rooms against the east side
      state.edge_rooms.min_y = min_y
    end
  else
    if (state.is_rooms[geoelf.directions.S]) then
      -- pack the rooms against the west side
      state.edge_rooms.min_y = max_y - range_y_min
    else
      -- center the rooms
      local min_y_max = max_y - range_y_min
      state.edge_rooms.min_y = math.floor((min_y + min_y_max) / 2)
    end
  end
end

-- Count and position complete main-grid rows in each available strip outside the castle.
local function choose_main_rows(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  state.edge_rooms.row_base = {}
  state.edge_rooms.row_base[geoelf.directions.W] =
                   state.castle.overwritable[geoelf.directions.W] - ROOMS_FROM_CASTLE
  state.edge_rooms.row_base[geoelf.directions.E] =
                   state.castle.overwritable[geoelf.directions.E] + ROOMS_FROM_CASTLE
  state.edge_rooms.row_base[geoelf.directions.N] =
                   state.castle.overwritable[geoelf.directions.N] - ROOMS_FROM_CASTLE
  state.edge_rooms.row_base[geoelf.directions.S] =
                   state.castle.overwritable[geoelf.directions.S] + ROOMS_FROM_CASTLE

  state.edge_rooms.row_count = {}
  for i = 0, geoelf.directions.COUNT_STRAIGHT - 1 do
    if (state.is_rooms[i] == false) then
      state.edge_rooms.row_count[i] = 0
    else
      local available_space = state.primary_vault.border[i]
                              - (ROOMS_FROM_CASTLE + ROOMS_BORDER_MIN) + 1
      state.edge_rooms.row_count[i] = math.floor(available_space / ROOMS_SPACING_MIN)
      if (state.edge_rooms.row_count[i] <= 0) then
        crawl.mpr("Error in layout_geoelf_castle: 0 rows in direction " ..
                  i .. " filling " .. ROOMS_SPACING_MIN .. " / " ..
                  available_space .. " space")
      end
    end
  end
end

-- Combine west, central, and east columns with their source diagonal-connection permissions.
local function position_columns(env, state)
  local geoelf = env.geoelf

  state.room_pos_x = {}
  state.room_pos_x.begin_center = state.edge_rooms.row_count[geoelf.directions.W]
  state.room_pos_x.begin_east   = state.room_pos_x.begin_center + state.edge_rooms.count_x
  state.room_pos_x.total        = state.room_pos_x.begin_east
                            + state.edge_rooms.row_count[geoelf.directions.E]
  state.room_pos_x.last         = state.room_pos_x.total - 1
  state.is_room_diagonals_x = {}
  for i = 0, state.room_pos_x.total - 1 do
    state.is_room_diagonals_x[i] = true
    if (i < state.room_pos_x.begin_center) then
      local rows_out = state.room_pos_x.begin_center - i - 1
      state.room_pos_x[i] = state.edge_rooms.row_base[geoelf.directions.W]
                      - rows_out * ROOMS_SPACING_MIN
    elseif (i < state.room_pos_x.begin_east) then
      local rows_along = i - state.room_pos_x.begin_center
      state.room_pos_x[i] = state.edge_rooms.min_x
                      + math.floor(rows_along * state.edge_rooms.spacing_x)
      state.is_room_diagonals_x[i] = state.edge_rooms.allow_diagonals_x
    else
      local rows_out = i - state.room_pos_x.begin_east
      state.room_pos_x[i] = state.edge_rooms.row_base[geoelf.directions.E]
                      + rows_out * ROOMS_SPACING_MIN
    end
  end
end

-- Combine north, central, and south rows with their source diagonal-connection permissions.
local function position_rows(env, state)
  local geoelf = env.geoelf

  state.room_pos_y = {}
  state.room_pos_y.begin_center = state.edge_rooms.row_count[geoelf.directions.N]
  state.room_pos_y.begin_south  = state.room_pos_y.begin_center + state.edge_rooms.count_y
  state.room_pos_y.total        = state.room_pos_y.begin_south
                            + state.edge_rooms.row_count[geoelf.directions.S]
  state.room_pos_y.last         = state.room_pos_y.total - 1
  state.is_room_diagonals_y = {}
  for i = 0, state.room_pos_y.total - 1 do
    state.is_room_diagonals_y[i] = true
    if (i < state.room_pos_y.begin_center) then
      local rows_out = state.room_pos_y.begin_center - i - 1
      state.room_pos_y[i] = state.edge_rooms.row_base[geoelf.directions.N]
                      - rows_out * ROOMS_SPACING_MIN
    elseif (i < state.room_pos_y.begin_south) then
      local rows_along = i - state.room_pos_y.begin_center
      state.room_pos_y[i] = state.edge_rooms.min_y
                      + math.floor(rows_along * state.edge_rooms.spacing_y)
      state.is_room_diagonals_y[i] = state.edge_rooms.allow_diagonals_y
    else
      local rows_out = i - state.room_pos_y.begin_south
      state.room_pos_y[i] = state.edge_rooms.row_base[geoelf.directions.S]
                      + rows_out * ROOMS_SPACING_MIN
    end
  end


  --
end

-- Reserve half-offset outer rows and their corner rooms wherever the border has enough space.
local function choose_edge_rows(env, state)
  local geoelf = env.geoelf

  --

  state.is_edge_row = {}
  state.is_edge_row[geoelf.directions.W] = (state.room_pos_x[0] >= ROOMS_MIN_SPACE_EDGE)
  state.is_edge_row[geoelf.directions.E] = (state.gxm - state.room_pos_x[state.room_pos_x.last]
                                                    >= ROOMS_MIN_SPACE_EDGE)
  state.is_edge_row[geoelf.directions.N] = (state.room_pos_y[0] >= ROOMS_MIN_SPACE_EDGE)
  state.is_edge_row[geoelf.directions.S] = (state.gym - state.room_pos_y[state.room_pos_y.last]
                                                    >= ROOMS_MIN_SPACE_EDGE)

  -- setting these all is easier than working out which ones we need
  state.edge_row_at = {}
  state.edge_row_at[geoelf.directions.W] = state.room_pos_x[0] - ROOMS_SPACING_EDGE
  state.edge_row_at[geoelf.directions.E] = state.room_pos_x[state.room_pos_x.last]
                                                   + ROOMS_SPACING_EDGE
  state.edge_row_at[geoelf.directions.N] = state.room_pos_y[0] - ROOMS_SPACING_EDGE
  state.edge_row_at[geoelf.directions.S] = state.room_pos_y[state.room_pos_y.last]
                                                   + ROOMS_SPACING_EDGE

  -- add a corner edge rooms if we have both edge sides
  state.is_edge_corner = {}
  for i = geoelf.directions.COUNT_STRAIGHT, geoelf.directions.COUNT - 1 do
    local component_x = geoelf.directions.COMPONENT_X[i]
    local component_y = geoelf.directions.COMPONENT_Y[i]
    state.is_edge_corner[i] = state.is_edge_row[component_x] and
                        state.is_edge_row[component_y] and
                        (state.edge_rooms.row_count[component_x] >= 1 or
                         state.edge_rooms.row_count[component_y] >= 1   )
  end


end

-- Add geometric rooms outside the castle and dummy anchors inside its open surround.
local function add_main_rooms(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  state.room_data     = {
    count = 0
  }
  state.corridor_data = {
    count = 0
  }
  state.grid_rooms_by_position = {}

  -- add rooms for the main grid
  for y = 0, state.room_pos_y.total - 1 do
    state.grid_rooms_by_position[y] = {}
    for x = 0, state.room_pos_x.total - 1 do
      local x_pos = state.room_pos_x[x] +
                    crawl.random_range(-ROOMS_OFFSET_MAX, ROOMS_OFFSET_MAX)
      local y_pos = state.room_pos_y[y] +
                    crawl.random_range(-ROOMS_OFFSET_MAX, ROOMS_OFFSET_MAX)
      local radius = crawl.random_range(ROOMS_RADIUS_MIN, ROOMS_RADIUS_MAX)

      if (x <  state.room_pos_x.begin_center or
          x >= state.room_pos_x.begin_east   or
          y <  state.room_pos_y.begin_center or
          y >= state.room_pos_y.begin_south    ) then
        state.grid_rooms_by_position[y][x] = geoelf.add_room(state.room_data,
                                                       x_pos, y_pos, radius)
      else
        state.grid_rooms_by_position[y][x] = geoelf.add_room_dummy(state.room_data,
                                                             x_pos, y_pos)
      end
    end
  end
end

-- Specify straight and noncrossing diagonal links while requiring at least one real endpoint.
local function add_main_corridors(env, state)
  local geoelf = env.geoelf

  --  -> at least one room must be non-dummy
  --  -> only add diagonals if at least one room allows them
  --     (we don't need both)
  for y = 0, state.room_pos_y.total - 1 do
    for x = 0, state.room_pos_x.total - 1 do
      local index = state.grid_rooms_by_position[y][x]
      local allow_diagonals = state.is_room_diagonals_x[x] and
                              state.is_room_diagonals_y[y]

      -- east-west
      if (x >= 1) then
        local other_index = state.grid_rooms_by_position[y][x - 1]
        if (not geoelf.is_room_dummy(state.room_data, index) or
            not geoelf.is_room_dummy(state.room_data, other_index)) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              other_index, index,
                              geoelf.directions.E, nil)
        end
      end

      -- south-north
      if (y >= 1) then
        local other_index = state.grid_rooms_by_position[y - 1][x]
        if (not geoelf.is_room_dummy(state.room_data, index) or
            not geoelf.is_room_dummy(state.room_data, other_index)) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              other_index, index,
                              geoelf.directions.S, nil)
        end
      end

      -- southeast-northwest
      if (y >= 1 and x >= 1) then
        local other_index = state.grid_rooms_by_position[y - 1][x - 1]
        local allow_diagonals_other = state.is_room_diagonals_x[x - 1] and
                                      state.is_room_diagonals_y[y - 1]
        if (not geoelf.is_room_dummy(state.room_data, index) or
            not geoelf.is_room_dummy(state.room_data, other_index)) then
          if(allow_diagonals or allow_diagonals_other) then

            -- determine if there is another corridor that would
            --  block this one (i.e. an NE-SW one)
            local block_index = nil
            local old_index = state.grid_rooms_by_position[y][x - 1]
            if (not geoelf.is_room_dummy(state.room_data, old_index)) then
              block_index = state.room_data[old_index].corridor[geoelf.directions.NE]
            end

            geoelf.add_corridor(state.room_data, state.corridor_data,
                                other_index, index,
                                geoelf.directions.SE, block_index)
          end
        end
      end

      -- southwest-northeast
      if (y >= 1 and x + 1 < state.room_pos_x.total) then
        local other_index = state.grid_rooms_by_position[y - 1][x + 1]
        local allow_diagonals_other = state.is_room_diagonals_x[x + 1] and
                                      state.is_room_diagonals_y[y - 1]
        if (not geoelf.is_room_dummy(state.room_data, index) or
            not geoelf.is_room_dummy(state.room_data, other_index)) then
          if(allow_diagonals or allow_diagonals_other) then
            geoelf.add_corridor(state.room_data, state.corridor_data,
                                other_index, index,
                                geoelf.directions.SW, nil)
          end
        end
      end

      -- done this room
    end
  end


end

-- Add corner rooms where two optional outer rows meet.
local function add_edge_corners(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  state.corner_index = {}

  for i = geoelf.directions.COUNT_STRAIGHT, geoelf.directions.COUNT - 1 do
    if (state.is_edge_corner[i]) then
      local component_x = geoelf.directions.COMPONENT_X[i]
      local component_y = geoelf.directions.COMPONENT_Y[i]

      local radius = crawl.random_range(ROOMS_RADIUS_EDGE_MIN,
                                        ROOMS_RADIUS_EDGE_MAX)
      state.corner_index[i] = geoelf.add_room(state.room_data,
                                        state.edge_row_at[component_x],
                                        state.edge_row_at[component_y], radius)

      local other_index_x = (component_x == geoelf.directions.W)
                            and 0 or state.room_pos_x.last
      local other_index_y = (component_y == geoelf.directions.N)
                            and 0 or state.room_pos_y.last
      local other_index = state.grid_rooms_by_position[other_index_y][other_index_x]
      geoelf.add_corridor(state.room_data, state.corridor_data,
                          other_index, state.corner_index[i], i, nil)
    end
  end

  --
  -- NOTE: I tried combining these four cases into a single
  --       loop, but it ended up longer than the 4 cases,
  --       very hard to understand (even by the standards of my
  --       convoluted code), and didn't work reliably.
  --                                                ~ infiniplex
  --
end

-- Link west edge rooms to their two diagonal neighbors and to the preceding edge room.
local function add_west_edge(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  if (state.is_edge_row[geoelf.directions.W]) then
    local x_pos = state.edge_row_at[geoelf.directions.W]
    local previous_index = state.corner_index[geoelf.directions.NW]
    for y = 0, state.room_pos_y.total - 2 do
      local other_index_NE = state.grid_rooms_by_position[y    ][0]
      local other_index_SE = state.grid_rooms_by_position[y + 1][0]
      if (not geoelf.is_room_dummy(state.room_data, other_index_NE) and
          not geoelf.is_room_dummy(state.room_data, other_index_SE)) then
        local y_pos = math.floor((state.room_pos_y[y] + state.room_pos_y[y + 1]) / 2)
                      crawl.random_range(-ROOMS_OFFSET_MAX, ROOMS_OFFSET_MAX)
        local radius = crawl.random_range(ROOMS_RADIUS_EDGE_MIN,
                                          ROOMS_RADIUS_EDGE_MAX)
        local new_index = geoelf.add_room(state.room_data, x_pos, y_pos, radius)

        local allow_diagonals_here = true
        if (y >= state.room_pos_y.begin_center and
            y <  state.room_pos_y.begin_south - 1) then
          allow_diagonals_here = state.edge_rooms.allow_diagonals_y
        end
        local allow_diagonals_NE = state.is_room_diagonals_y[y]
        local allow_diagonals_SE = state.is_room_diagonals_y[y + 1]

        if (allow_diagonals_here or allow_diagonals_NE) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, other_index_NE,
                              geoelf.directions.NE, nil)
        end
        if (allow_diagonals_here or allow_diagonals_SE) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, other_index_SE,
                              geoelf.directions.SE, nil)
        end
        if (previous_index ~= nil) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, previous_index,
                              geoelf.directions.N, nil)
        end

        previous_index = new_index
      end
    end
    if (state.corner_index[geoelf.directions.SW] ~= nil and
        previous_index ~= nil) then
      geoelf.add_corridor(state.room_data, state.corridor_data,
                          state.corner_index[geoelf.directions.SW], previous_index,
                          geoelf.directions.N, nil)
    end
  end
end

-- Link east edge rooms to their two diagonal neighbors and to the preceding edge room.
local function add_east_edge(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  if (state.is_edge_row[geoelf.directions.E]) then
    local x_pos = state.edge_row_at[geoelf.directions.E]
    local previous_index = state.corner_index[geoelf.directions.NE]
    for y = 0, state.room_pos_y.total - 2 do
      local other_index_NW = state.grid_rooms_by_position[y    ][state.room_pos_x.last]
      local other_index_SW = state.grid_rooms_by_position[y + 1][state.room_pos_x.last]
      if (not geoelf.is_room_dummy(state.room_data, other_index_NW) and
          not geoelf.is_room_dummy(state.room_data, other_index_SW)) then
        local y_pos = math.floor((state.room_pos_y[y] + state.room_pos_y[y + 1]) / 2)
                      crawl.random_range(-ROOMS_OFFSET_MAX, ROOMS_OFFSET_MAX)
        local radius = crawl.random_range(ROOMS_RADIUS_EDGE_MIN,
                                          ROOMS_RADIUS_EDGE_MAX)
        local new_index = geoelf.add_room(state.room_data, x_pos, y_pos, radius)

        local allow_diagonals_here = true
        if (y >= state.room_pos_y.begin_center and
            y <  state.room_pos_y.begin_south - 1) then
          allow_diagonals_here = state.edge_rooms.allow_diagonals_y
        end
        local allow_diagonals_NW = state.is_room_diagonals_y[y]
        local allow_diagonals_SW = state.is_room_diagonals_y[y + 1]

        if (allow_diagonals_here or allow_diagonals_NW) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, other_index_NW,
                              geoelf.directions.NW, nil)
        end
        if (allow_diagonals_here or allow_diagonals_SW) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, other_index_SW,
                              geoelf.directions.SW, nil)
        end
        if (previous_index ~= nil) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, previous_index,
                              geoelf.directions.N, nil)
        end

        previous_index = new_index
      end
    end
    if (state.corner_index[geoelf.directions.SE] ~= nil and
        previous_index ~= nil) then
      geoelf.add_corridor(state.room_data, state.corridor_data,
                          state.corner_index[geoelf.directions.SE], previous_index,
                          geoelf.directions.N, nil)
    end
  end
end

-- Link north edge rooms to their two diagonal neighbors and to the preceding edge room.
local function add_north_edge(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  if (state.is_edge_row[geoelf.directions.N]) then
    local y_pos = state.edge_row_at[geoelf.directions.N]
    local previous_index = state.corner_index[geoelf.directions.NW]
    for x = 0, state.room_pos_x.total - 2 do
      local other_index_SW = state.grid_rooms_by_position[0][x]
      local other_index_SE = state.grid_rooms_by_position[0][x + 1]
      if (not geoelf.is_room_dummy(state.room_data, other_index_SW) and
          not geoelf.is_room_dummy(state.room_data, other_index_SE)) then
        local x_pos = math.floor((state.room_pos_x[x] + state.room_pos_x[x + 1]) / 2)
                      crawl.random_range(-ROOMS_OFFSET_MAX, ROOMS_OFFSET_MAX)
        local radius = crawl.random_range(ROOMS_RADIUS_EDGE_MIN,
                                          ROOMS_RADIUS_EDGE_MAX)
        local new_index = geoelf.add_room(state.room_data, x_pos, y_pos, radius)

        local allow_diagonals_here = true
        if (x >= state.room_pos_x.begin_center and
            x <  state.room_pos_x.begin_east - 1) then
          allow_diagonals_here = state.edge_rooms.allow_diagonals_x
        end
        local allow_diagonals_SW = state.is_room_diagonals_x[x]
        local allow_diagonals_SE = state.is_room_diagonals_x[x + 1]

        if (allow_diagonals_here or allow_diagonals_SW) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, other_index_SW,
                              geoelf.directions.SW, nil)
        end
        if (allow_diagonals_here or allow_diagonals_SE) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, other_index_SE,
                              geoelf.directions.SE, nil)
        end
        if (previous_index ~= nil) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, previous_index,
                              geoelf.directions.W, nil)
        end

        previous_index = new_index
      end
    end
    if (state.corner_index[geoelf.directions.NE] ~= nil and
        previous_index ~= nil) then
      geoelf.add_corridor(state.room_data, state.corridor_data,
                          state.corner_index[geoelf.directions.NE], previous_index,
                          geoelf.directions.W, nil)
    end
  end
end

-- Link south edge rooms to their two diagonal neighbors and to the preceding edge room.
local function add_south_edge(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  if (state.is_edge_row[geoelf.directions.S]) then
    local y_pos = state.edge_row_at[geoelf.directions.S]
    local previous_index = state.corner_index[geoelf.directions.SW]
    for x = 0, state.room_pos_x.total - 2 do
      local other_index_NW = state.grid_rooms_by_position[state.room_pos_y.last][x]
      local other_index_NE = state.grid_rooms_by_position[state.room_pos_y.last][x + 1]
      if (not geoelf.is_room_dummy(state.room_data, other_index_NW) and
          not geoelf.is_room_dummy(state.room_data, other_index_NE)) then
        local x_pos = math.floor((state.room_pos_x[x] + state.room_pos_x[x + 1]) / 2)
                      crawl.random_range(-ROOMS_OFFSET_MAX, ROOMS_OFFSET_MAX)
        local radius = crawl.random_range(ROOMS_RADIUS_EDGE_MIN,
                                          ROOMS_RADIUS_EDGE_MAX)
        local new_index = geoelf.add_room(state.room_data, x_pos, y_pos, radius)

        local allow_diagonals_here = true
        if (x >= state.room_pos_x.begin_center and
            x <  state.room_pos_x.begin_east - 1) then
          allow_diagonals_here = state.edge_rooms.allow_diagonals_x
        end
        local allow_diagonals_NW = state.is_room_diagonals_x[x]
        local allow_diagonals_NE = state.is_room_diagonals_x[x + 1]

        if (allow_diagonals_here or allow_diagonals_NW) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, other_index_NW,
                              geoelf.directions.NW, nil)
        end
        if (allow_diagonals_here or allow_diagonals_NE) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, other_index_NE,
                              geoelf.directions.NE, nil)
        end
        if (previous_index ~= nil) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              new_index, previous_index,
                              geoelf.directions.W, nil)
        end

        previous_index = new_index
      end
    end
    if (state.corner_index[geoelf.directions.SE] ~= nil and
        previous_index ~= nil) then
      geoelf.add_corridor(state.room_data, state.corridor_data,
                          state.corner_index[geoelf.directions.SE], previous_index,
                          geoelf.directions.W, nil)
    end
  end


end

-- Draw the overwritable surround before GeoElf corridors and shuffled rooms interact with it.
local function draw_surrounding_rooms(env, state)
  local geoelf = env.geoelf


  env.fill_area {
    x1 = state.castle.hallway[geoelf.directions.W] + 1,
    x2 = state.castle.hallway[geoelf.directions.E] - 1,
    y1 = state.castle.overwritable[geoelf.directions.N],
    y2 = state.castle.overwritable[geoelf.directions.S],
    fill = geoelf.glyphs.FLOOR
  }
  env.fill_area {
    x1 = state.castle.overwritable[geoelf.directions.W],
    x2 = state.castle.overwritable[geoelf.directions.E],
    y1 = state.castle.hallway[geoelf.directions.N] + 1,
    y2 = state.castle.hallway[geoelf.directions.S] - 1,
    fill = geoelf.glyphs.FLOOR
  }

  for i = geoelf.directions.COUNT_STRAIGHT, geoelf.directions.COUNT - 1 do
    if (state.castle.turret[i].is_placed) then
      env.make_circle {
        x = state.castle.turret[i].x,
        y = state.castle.turret[i].y,
        radius = CASTLE_TURRET_OVERWRITABLE_RADIUS,
        fill = geoelf.glyphs.FLOOR
      }
    end
  end

  -- run the geoelf generator to add the rooms
  --    -> note that this can interact with the castle area
  geoelf.generate(env, state.room_data, state.corridor_data, ROOMS_EXTRA_CORRIDOR_FRACTION,
                  ROOMS_FANCY_ROOM_FRACTION, false, false)


end

-- Draw the protected open area, moat, outer hall, and inner chamber boundary in source order.
local function draw_castle_rings(env, state)
  local geoelf = env.geoelf

  env.fill_area {
    x1 = state.castle.open[geoelf.directions.W],
    x2 = state.castle.open[geoelf.directions.E],
    y1 = state.castle.open[geoelf.directions.N],
    y2 = state.castle.open[geoelf.directions.S],
    fill = INSIDE_GLYPH
  }

  for i = geoelf.directions.COUNT_STRAIGHT, geoelf.directions.COUNT - 1 do
    if (state.castle.turret[i].is_placed) then
      env.make_circle {
        x = state.castle.turret[i].x,
        y = state.castle.turret[i].y,
        radius = CASTLE_TURRET_OPEN_RADIUS,
        fill = INSIDE_GLYPH
      }
    end
  end

  -- draw the moat
  env.fill_area {
    x1 = state.castle.moat[geoelf.directions.W],
    x2 = state.castle.moat[geoelf.directions.E],
    y1 = state.castle.moat[geoelf.directions.N],
    y2 = state.castle.moat[geoelf.directions.S],
    fill = MOAT_GLYPH
  }

  for i = geoelf.directions.COUNT_STRAIGHT, geoelf.directions.COUNT - 1 do
    if (state.castle.turret[i].is_placed) then
      env.make_circle {
        x = state.castle.turret[i].x,
        y = state.castle.turret[i].y,
        radius = CASTLE_TURRET_MOAT_RADIUS,
        fill = MOAT_GLYPH
      }
    end
  end

  -- draw the hallways
  env.fill_area {
    x1 = state.castle.hallway[geoelf.directions.W],
    x2 = state.castle.hallway[geoelf.directions.E],
    y1 = state.castle.hallway[geoelf.directions.N],
    y2 = state.castle.hallway[geoelf.directions.S],
    border = WALL_GLYPH,
    fill = INSIDE_GLYPH
  }

  -- draw the inner rooms
  env.fill_area {
    x1 = state.castle.inner[geoelf.directions.W],
    x2 = state.castle.inner[geoelf.directions.E],
    y1 = state.castle.inner[geoelf.directions.N],
    y2 = state.castle.inner[geoelf.directions.S],
    border = WALL_GLYPH,
    fill = INSIDE_GLYPH
  }
end

-- Partition the inner chamber with independently spaced horizontal and vertical dividers.
local function draw_inner_walls(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  local wall_at  = state.castle.inner[geoelf.directions.W]
  local wall_end = state.castle.inner[geoelf.directions.E] - INNER_WALL_SPACING_MIN
  while (wall_at < wall_end) do
    env.fill_area {
      x1 = wall_at,
      x2 = wall_at,
      y1 = state.castle.inner[geoelf.directions.N],
      y2 = state.castle.inner[geoelf.directions.S],
      fill = WALL_GLYPH
    }
    wall_at = wall_at + crawl.random_range(INNER_WALL_SPACING_MIN,
                                           INNER_WALL_SPACING_MAX)
  end

  -- draw vertical walls
  wall_at  = state.castle.inner[geoelf.directions.N]
  wall_end = state.castle.inner[geoelf.directions.S] - INNER_WALL_SPACING_MIN
  while (wall_at < wall_end) do
    env.fill_area {
      x1 = state.castle.inner[geoelf.directions.W],
      x2 = state.castle.inner[geoelf.directions.E],
      y1 = wall_at,
      y2 = wall_at,
      fill = WALL_GLYPH
    }
    wall_at = wall_at + crawl.random_range(INNER_WALL_SPACING_MIN,
                                           INNER_WALL_SPACING_MAX)
  end
end

-- Choose one shared turret-center ornament, then place round turrets with two to four doors.
local function draw_turrets(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl
  local util = env.util

  local turret_center_weights = {}
  for i,p in ipairs(geoelf.glyphs.PLANTLIKE_OPTIONS) do
    table.insert(turret_center_weights, p)
  end
  for i,p in ipairs(geoelf.glyphs.FEATURE_OPTIONS) do
    table.insert(turret_center_weights, {
      p[1],
      p[2] * 5
    })
  end
  table.insert(turret_center_weights, {
    INSIDE_GLYPH,
    15
  })

  local turret_center = util.random_choose_weighted(turret_center_weights)

  for i = geoelf.directions.COUNT_STRAIGHT, geoelf.directions.COUNT - 1 do
    if (state.castle.turret[i].is_placed) then
      env.make_round_box {
        x1 = state.castle.turret[i].x - CASTLE_TURRET_RADIUS,
        x2 = state.castle.turret[i].x + CASTLE_TURRET_RADIUS,
        y1 = state.castle.turret[i].y - CASTLE_TURRET_RADIUS,
        y2 = state.castle.turret[i].y + CASTLE_TURRET_RADIUS,
        floor = INSIDE_GLYPH,
        wall = WALL_GLYPH,
        door = DOOR_GLYPH,
        door_count = crawl.random_range(2, 4),
        passable = INSIDE_GLYPH,
        veto_gates = false
      }
      env.mapgrd[state.castle.turret[i].x][state.castle.turret[i].y] = turret_center
    end
  end
end

-- Place the source two- or three-cell gate and its causeway on the widest castle side.
local function draw_gate(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  local gate_size = crawl.random_range(GATE_SIZE_MIN, GATE_SIZE_MAX)

  if (state.gate_best == geoelf.directions.S or
      state.gate_best == geoelf.directions.N) then
    local gate_x_min = state.castle.hallway[geoelf.directions.W]
                       + GATE_FROM_CORNER_MIN
    local gate_x_max = state.castle.hallway[geoelf.directions.E]
                       - GATE_FROM_CORNER_MIN
    local gate_x = crawl.random_range(gate_x_min, gate_x_max - gate_size)

    local gate_y
    if (state.gate_best == geoelf.directions.S) then
      gate_y = state.castle.hallway[geoelf.directions.S]
      env.fill_area {
        x1 = gate_x,
        x2 = gate_x + gate_size - 1,
        y1 = gate_y + 1,
        y2 = gate_y + 1 + CASTLE_MOAT,
        fill = INSIDE_GLYPH
      }
    else
      gate_y = state.castle.hallway[geoelf.directions.N]
      env.fill_area {
        x1 = gate_x,
        x2 = gate_x + gate_size - 1,
        y1 = gate_y - 1 - CASTLE_MOAT,
        y2 = gate_y - 1,
        fill = INSIDE_GLYPH
      }
    end
    env.fill_area {
      x1 = gate_x,
      x2 = gate_x + gate_size - 1,
      y1 = gate_y,
      y2 = gate_y,
      fill = DOOR_GLYPH
    }
  else
    local gate_y_min = state.castle.hallway[geoelf.directions.N]
                       + GATE_FROM_CORNER_MIN
    local gate_y_max = state.castle.hallway[geoelf.directions.S]
                       - GATE_FROM_CORNER_MIN
    local gate_y = crawl.random_range(gate_y_min, gate_y_max - gate_size)

    local gate_x
    if (state.gate_best == geoelf.directions.E) then
      gate_x = state.castle.hallway[geoelf.directions.E]
      env.fill_area {
        x1 = gate_x + 1,
        x2 = gate_x + 1 + CASTLE_MOAT,
        y1 = gate_y,
        y2 = gate_y + gate_size - 1,
        fill = INSIDE_GLYPH
      }
    else
      gate_x = state.castle.hallway[geoelf.directions.W]
      env.fill_area {
        x1 = gate_x - 1 - CASTLE_MOAT,
        x2 = gate_x - 1,
        y1 = gate_y,
        y2 = gate_y + gate_size - 1,
        fill = INSIDE_GLYPH
      }
    end
    env.fill_area {
      x1 = gate_x,
      x2 = gate_x,
      y1 = gate_y,
      y2 = gate_y + gate_size - 1,
      fill = DOOR_GLYPH
    }
  end
end

-- Hide the primary footprint from door checks, then connect adjacent inner chambers.
local function connect_inner_rooms(env, state)
  local geoelf = env.geoelf
  local dgn = env.dgn

  --  -> this area will be overridden
  --  -> we need to make sure the map is connected without going
  --     into this area
  for y = 1, state.gym - 2 do
    for x = 1, state.gxm - 2 do
      if dgn.in_vault(x, y) then
        env.mapgrd[x][y] = WALL_GLYPH
      end
    end
  end

  -- add doors
  local inner_area = (state.castle.inner[geoelf.directions.E] -
                      state.castle.inner[geoelf.directions.W] + 1) *
                     (state.castle.inner[geoelf.directions.S] -
                      state.castle.inner[geoelf.directions.N] + 1)
  env.connect_adjacent_rooms {
    wall = WALL_GLYPH,
    floor = INSIDE_GLYPH,
    replace = DOOR_GLYPH,
    max = inner_area,
    check_distance = 8,
    x1 = state.castle.inner[geoelf.directions.W] - 1,
    x2 = state.castle.inner[geoelf.directions.E] + 1,
    y1 = state.castle.inner[geoelf.directions.N] - 1,
    y2 = state.castle.inner[geoelf.directions.S] + 1
  }


end

-- Mask the castle, place external up stairs, and restore plain floor beside the primary.
local function finish_castle(env, state)
  local geoelf = env.geoelf
  local dgn = env.dgn

  --  -> remember that the "=" must be the first glyph for parsing reasons
  --  -> the castle cannot be overwritten
  env.kmask(DOOR_GLYPH .. INSIDE_GLYPH .. MOAT_GLYPH .. WALL_GLYPH .. " = vault")
  env.kfeat(DOOR_GLYPH .. " = closed_door")
  env.kfeat(INSIDE_GLYPH .. " = floor")

  -- place the stairs outside the vault area
  env.nsubst(geoelf.glyphs.FLOOR .. " = 1:{ / 1:( / 1:[ / *:" ..
         geoelf.glyphs.FLOOR)

  -- Replace all floor cells around primary vault with "."s.
  --  This is needed to prevent vetos
  --  I think it is related to ensuring the primary vault is
  --    connected to the layout
  --  TODO: Why does it have to be "."s? Can this be fixed?
  for y = 1, state.gym - 2 do
    for x = 1, state.gxm - 2 do
      if dgn.in_vault(x, y) then
        for dy = -1, 1 do
          for dx = -1, 1 do
            if env.mapgrd[x + dx][y + dy] == INSIDE_GLYPH then
              env.mapgrd[x + dx][y + dy] = "."
            end
          end
        end
      end
    end
  end

end

-- Execute the source design, graph, drawing, and cleanup phases in their original order.
function layout.layout_geoelf_castle(api)
  if layout.veto(api) then
    error("GeoElf castle requires a suitable preplaced primary vault")
  end

  local env = family.new(api)
  local state = {
    gxm = env.width,
    gym = env.height,
  }

  choose_castle_sides(env, state)
  design_castle(env, state)
  choose_horizontal_spacing(env, state)
  choose_vertical_spacing(env, state)
  choose_main_rows(env, state)
  position_columns(env, state)
  position_rows(env, state)
  choose_edge_rows(env, state)
  add_main_rooms(env, state)
  add_main_corridors(env, state)
  add_edge_corners(env, state)
  add_west_edge(env, state)
  add_east_edge(env, state)
  add_north_edge(env, state)
  add_south_edge(env, state)
  draw_surrounding_rooms(env, state)
  draw_castle_rings(env, state)
  draw_inner_walls(env, state)
  draw_turrets(env, state)
  draw_gate(env, state)
  connect_inner_rooms(env, state)
  finish_castle(env, state)

  local result = env.result(state.room_data, state.corridor_data)
  result.castle = state.castle

  return result
end

return layout
