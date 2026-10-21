-- Theory of operation: the pinned source specifies room centers and crossing exclusions.
-- The private GeoElf engine chooses connected corridors and renders geometric rooms.
-- Source: crawl-ref/source/dat/des/builder/layout_geoelf.des
local family = require("policy.generation.layouts.geoelf")

local layout = {}

-- The source ring templates use fixed offsets and radius ranges around the layout center.
local ROOMS_TO_PLACE = {
  -- center room
  [0]  = {
    x =  0,
    y =  0,
    radius_min = 3,
    radius_max = 5,
    offset = 1
  },
  -- ring 1
  [1]  = {
    x =  0,
    y =  12,
    radius_min = 2,
    radius_max = 4,
    offset = 0
  },
  [2]  = {
    x =  8,
    y =  8,
    radius_min = 2,
    radius_max = 4,
    offset = 0
  },
  [3]  = {
    x =  12,
    y =  0,
    radius_min = 2,
    radius_max = 4,
    offset = 0
  },
  [4]  = {
    x =  8,
    y = -8,
    radius_min = 2,
    radius_max = 4,
    offset = 0
  },
  [5]  = {
    x =  0,
    y = -12,
    radius_min = 2,
    radius_max = 4,
    offset = 0
  },
  [6]  = {
    x = -8,
    y = -8,
    radius_min = 2,
    radius_max = 4,
    offset = 0
  },
  [7]  = {
    x = -12,
    y =  0,
    radius_min = 2,
    radius_max = 4,
    offset = 0
  },
  [8]  = {
    x = -8,
    y =  8,
    radius_min = 2,
    radius_max = 4,
    offset = 0
  },
  -- ring 2
  [9]  = {
    x =  8,
    y =  20,
    radius_min = 3,
    radius_max = 5,
    offset = 1
  },
  [10] = {
    x =  20,
    y =  8,
    radius_min = 3,
    radius_max = 5,
    offset = 1
  },
  [11] = {
    x =  20,
    y = -8,
    radius_min = 3,
    radius_max = 5,
    offset = 1
  },
  [12] = {
    x =  8,
    y = -20,
    radius_min = 3,
    radius_max = 5,
    offset = 1
  },
  [13] = {
    x = -8,
    y = -20,
    radius_min = 3,
    radius_max = 5,
    offset = 1
  },
  [14] = {
    x = -20,
    y = -8,
    radius_min = 3,
    radius_max = 5,
    offset = 1
  },
  [15] = {
    x = -20,
    y =  8,
    radius_min = 3,
    radius_max = 5,
    offset = 1
  },
  [16] = {
    x = -8,
    y =  20,
    radius_min = 3,
    radius_max = 5,
    offset = 1
  },
  -- ring 3
  [17] = {
    x =  0,
    y =  28,
    radius_min = 2,
    radius_max = 4,
    offset = 1
  },
  [18] = {
    x =  20,
    y =  20,
    radius_min = 2,
    radius_max = 4,
    offset = 1
  },
  [19] = {
    x =  28,
    y =   0,
    radius_min = 2,
    radius_max = 4,
    offset = 1
  },
  [20] = {
    x =  20,
    y = -20,
    radius_min = 2,
    radius_max = 4,
    offset = 1
  },
  [21] = {
    x =  0,
    y = -28,
    radius_min = 2,
    radius_max = 4,
    offset = 1
  },
  [22] = {
    x = -20,
    y = -20,
    radius_min = 2,
    radius_max = 4,
    offset = 1
  },
  [23] = {
    x = -28,
    y =   0,
    radius_min = 2,
    radius_max = 4,
    offset = 1
  },
  [24] = {
    x = -20,
    y =  20,
    radius_min = 2,
    radius_max = 4,
    offset = 1
  },
  -- ring 4
  [25] = {
    x =  12,
    y =  28,
    radius_min = 2,
    radius_max = 3,
    offset = 1
  },
  [26] = {
    x =  28,
    y =  12,
    radius_min = 2,
    radius_max = 3,
    offset = 1
  },
  [27] = {
    x =  28,
    y = -12,
    radius_min = 2,
    radius_max = 3,
    offset = 1
  },
  [28] = {
    x =  12,
    y = -28,
    radius_min = 2,
    radius_max = 3,
    offset = 1
  },
  [29] = {
    x = -12,
    y = -28,
    radius_min = 2,
    radius_max = 3,
    offset = 1
  },
  [30] = {
    x = -28,
    y = -12,
    radius_min = 2,
    radius_max = 3,
    offset = 1
  },
  [31] = {
    x = -28,
    y =  12,
    radius_min = 2,
    radius_max = 3,
    offset = 1
  },
  [32] = {
    x = -12,
    y =  28,
    radius_min = 2,
    radius_max = 3,
    offset = 1
  },
}


-- Choose ring count and source depth-dependent decoration weights, then allocate the graph.
local function choose_parameters(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl
  local you = env.you

  -- some paramters
  state.depth_fraction = you.depth_fraction()
  state.place_rings = crawl.random_range(2, 4)
  state.extra_corridor_fraction = 0.7 - state.depth_fraction * 0.2
  state.fancy_room_fraction = (0.025 + state.depth_fraction * 0.025) *
                              (7 - state.place_rings)

  state.DIRECTIONS_IN_ORDER = {
    [0] = geoelf.directions.S,
    [1] = geoelf.directions.SE,
    [2] = geoelf.directions.E,
    [3] = geoelf.directions.NE,
    [4] = geoelf.directions.N,
    [5] = geoelf.directions.NW,
    [6] = geoelf.directions.W,
    [7] = geoelf.directions.SW,
  }

  -- create the arrays
  state.room_data         = {
    count = 0
  }
  state.corridor_data     = {
    count = 0
  }
  state.rooms_by_position = {}
end

-- Place concentric ring rooms, expanding two-ring variants through the source position lookup.
local function place_rooms(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  -- add rooms from array
  for i = 0, state.place_rings * 8 do
    state.offset_max = ROOMS_TO_PLACE[i].offset
    local x_pos
    local y_pos
    local radius
    if (state.place_rings == 2) then
      -- if we are only placing two rings of rooms, we have the
      --  space to make everything bigger
      local ROOM_POSITION_LOOKUP =
        {
          [  0] = 0,
          [  8] = 10,
          [ -8] = -10,
          [ 12] = 14,
          [-12] = -14,
          [ 20] = 24,
          [-20] = -24,
          [ 28] = 34,
          [-28] = -34,
        }
      x_pos = state.gxm / 2 + ROOM_POSITION_LOOKUP[ROOMS_TO_PLACE[i].x] +
              crawl.random_range(-state.offset_max, state.offset_max)
      y_pos = state.gym / 2 + ROOM_POSITION_LOOKUP[ROOMS_TO_PLACE[i].y] +
              crawl.random_range(-state.offset_max, state.offset_max)
      radius = crawl.random_range(ROOMS_TO_PLACE[i].radius_min,
                                  ROOMS_TO_PLACE[i].radius_max + 1)
    else
      x_pos = state.gxm / 2 + ROOMS_TO_PLACE[i].x +
              crawl.random_range(-state.offset_max, state.offset_max)
      y_pos = state.gym / 2 + ROOMS_TO_PLACE[i].y +
              crawl.random_range(-state.offset_max, state.offset_max)
      radius = crawl.random_range(ROOMS_TO_PLACE[i].radius_min,
                                  ROOMS_TO_PLACE[i].radius_max)
    end

    -- we are only actually checking for vaults
    if (not env.find_in_area {
      x1 = x_pos - radius,
      y1 = y_pos - radius,
      x2 = x_pos + radius,
      y2 = y_pos + radius,
      find = "",
      find_vault = true
    }) then
      state.rooms_by_position[i] = geoelf.add_room(state.room_data, x_pos, y_pos, radius)
    else
      state.rooms_by_position[i] = nil
    end
  end
end

-- Connect center and inner rings, returning the crossing edge excluded by the outer spoke.
local function connect_inner_sector(env, state, i)
  local geoelf = env.geoelf

    local index_ring_1  = 1  + i
    local index_ring_2  = 9  + i
    local index_ring_2B = 9  + (i + 7) % 8
    local index_ring_3  = 17 + i
    local index_ring_4  = 25 + i
    local index_ring_4B = 25 + (i + 7) % 8

    -- connect center to ring 1
    if (state.rooms_by_position[0] ~= nil and
        state.rooms_by_position[index_ring_1] ~= nil) then
      geoelf.add_corridor(state.room_data, state.corridor_data,
                          state.rooms_by_position[0],
                          state.rooms_by_position[index_ring_1],
                          state.DIRECTIONS_IN_ORDER[i], nil)
    end

    -- connect ring 1 to ring 2
    if (state.rooms_by_position[index_ring_1] ~= nil and
        state.rooms_by_position[index_ring_2] ~= nil) then
      geoelf.add_corridor(state.room_data, state.corridor_data,
                          state.rooms_by_position[index_ring_1],
                          state.rooms_by_position[index_ring_2],
                          state.DIRECTIONS_IN_ORDER[(i + 1) % 8], nil)
    end
    if (state.rooms_by_position[index_ring_1] ~= nil and
        state.rooms_by_position[index_ring_2B] ~= nil) then
      geoelf.add_corridor(state.room_data, state.corridor_data,
                          state.rooms_by_position[index_ring_1],
                          state.rooms_by_position[index_ring_2B],
                          state.DIRECTIONS_IN_ORDER[(i + 7) % 8], nil)
    end

    -- connect ring 2 in a loop
    local c4  -- we will need this later
    if (state.rooms_by_position[index_ring_2B] ~= nil and
        state.rooms_by_position[index_ring_2] ~= nil) then
      c4 = geoelf.add_corridor(state.room_data, state.corridor_data,
                               state.rooms_by_position[index_ring_2B],
                               state.rooms_by_position[index_ring_2],
                               state.DIRECTIONS_IN_ORDER[(i + 2) % 8], nil)
    else
      c4 = nil
    end


    return c4
end

-- Connect the optional third and fourth rings while honoring the inner crossing exclusion.
local function connect_outer_sector(env, state, i, c4)
  local geoelf = env.geoelf

    local index_ring_1  = 1  + i
    local index_ring_2  = 9  + i
    local index_ring_2B = 9  + (i + 7) % 8
    local index_ring_3  = 17 + i
    local index_ring_4  = 25 + i
    local index_ring_4B = 25 + (i + 7) % 8

    if (state.place_rings >= 3) then
      -- connect ring 1 to ring 3
      if (state.rooms_by_position[index_ring_1] ~= nil and
          state.rooms_by_position[index_ring_3] ~= nil) then
        geoelf.add_corridor(state.room_data, state.corridor_data,
                            state.rooms_by_position[index_ring_1],
                            state.rooms_by_position[index_ring_3],
                            state.DIRECTIONS_IN_ORDER[i], c4)
      end

      -- connect ring 2 to ring 3
      if (state.rooms_by_position[index_ring_2B] ~= nil and
          state.rooms_by_position[index_ring_3] ~= nil) then
        geoelf.add_corridor(state.room_data, state.corridor_data,
                            state.rooms_by_position[index_ring_2B],
                            state.rooms_by_position[index_ring_3],
                            state.DIRECTIONS_IN_ORDER[(i + 1) % 8], nil)
      end
      if (state.rooms_by_position[index_ring_2] ~= nil and
          state.rooms_by_position[index_ring_3] ~= nil) then
        geoelf.add_corridor(state.room_data, state.corridor_data,
                            state.rooms_by_position[index_ring_2],
                            state.rooms_by_position[index_ring_3],
                            state.DIRECTIONS_IN_ORDER[(i + 7) % 8], nil)
      end

      if (state.place_rings >= 4) then
        -- connect ring 3 to ring 4
        if (state.rooms_by_position[index_ring_3] ~= nil and
            state.rooms_by_position[index_ring_4] ~= nil) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              state.rooms_by_position[index_ring_3],
                              state.rooms_by_position[index_ring_4],
                              state.DIRECTIONS_IN_ORDER[(i + 2) % 8], nil)
        end
        if (state.rooms_by_position[index_ring_3] ~= nil and
            state.rooms_by_position[index_ring_4B] ~= nil) then
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              state.rooms_by_position[index_ring_3],
                              state.rooms_by_position[index_ring_4B],
                              state.DIRECTIONS_IN_ORDER[(i + 6) % 8], nil)
        end
      end
    end
end

-- Generate concentric source room rings and connect each of the eight repeated sectors.
function layout.layout_geoelf_octagon(api)
  local env = family.new(api)
  local state = {
    gxm = env.width,
    gym = env.height,
  }

  choose_parameters(env, state)
  place_rooms(env, state)

  for sector = 0, 7 do
    local crossing = connect_inner_sector(env, state, sector)
    connect_outer_sector(env, state, sector, crossing)
  end

  env.geoelf.generate(env, state.room_data, state.corridor_data,
    state.extra_corridor_fraction, state.fancy_room_fraction, false, false)

  return env.result(state.room_data, state.corridor_data)
end

return layout
