-- Theory of operation: the pinned source specifies room centers and crossing exclusions.
-- The private GeoElf engine chooses connected corridors and renders geometric rooms.
-- Source: crawl-ref/source/dat/des/builder/layout_geoelf.des
local family = require("policy.generation.layouts.geoelf")

local layout = {}

-- Choose the source grid size, radii, offsets, and decoration probabilities.
local function choose_parameters(env, state)
  local crawl = env.crawl

  -- some paramters
  state.rooms_across = 7
  state.room_spacing = 9
  state.offset_max = 1
  state.radius_min = 2
  state.radius_max = math.floor(4 + state.depth_fraction + crawl.random_real())
  state.extra_corridor_fraction = 0.7 - state.depth_fraction * 0.2
  state.fancy_room_fraction = 0.1 + state.depth_fraction * 0.1

  if (state.depth_fraction * 2 + crawl.random_real() * 4 >= 3) then
    state.rooms_across = 6
    state.room_spacing = crawl.random_range(9, 11)
    state.radius_min = math.floor(2 + state.depth_fraction + crawl.random_real())
    state.radius_max = math.floor(4 + state.depth_fraction + crawl.random_real() * 2)
    state.fancy_room_fraction = 0.15 + state.depth_fraction * 0.1
  end

  -- create the arrays
  state.room_data         = {
    count = 0
  }
  state.corridor_data     = {
    count = 0
  }
  state.rooms_by_position = {}
end

-- Place every allowed source grid slot unless it overlaps the primary vault.
local function place_rooms(env, state)
  local geoelf = env.geoelf
  local crawl = env.crawl

  -- choose the room positions
  for y = 0, state.rooms_across - 1 do
    state.rooms_by_position[y] = {}
    for x = 0, state.rooms_across - 1 do    -- checkerboard test
      if ((x + y) % 2 == 1) then
        local x_pos = state.gxm / 2 +
                      math.floor(state.room_spacing * (x - (state.rooms_across - 1) / 2)) +
                      crawl.random_range(-state.offset_max, state.offset_max)
        local y_pos = state.gym / 2 +
                      math.floor(state.room_spacing * (y - (state.rooms_across - 1) / 2)) +
                      crawl.random_range(-state.offset_max, state.offset_max)
        local radius = crawl.random_range(state.radius_min, state.radius_max)

        -- we are only actually checking for vaults
        if (not env.find_in_area {
          x1 = x_pos - radius,
          y1 = y_pos - radius,
          x2 = x_pos + radius,
          y2 = y_pos + radius,
          find = "",
          find_vault = true
        }) then
          state.rooms_by_position[y][x] = geoelf.add_room(state.room_data,
                                                    x_pos, y_pos, radius)
        else
          state.rooms_by_position[y][x] = nil
        end
      else
        state.rooms_by_position[y][x] = nil
      end
    end
  end
end

-- Specify neighbor links and crossing exclusions before the engine chooses its spanning tree.
local function add_corridors(env, state)
  local geoelf = env.geoelf

  -- add potential corridors
  for y = 0, state.rooms_across - 1 do
    for x = 0, state.rooms_across - 1 do
      if (state.rooms_by_position[y][x] ~= nil) then
        -- we have impliclitly passed the checkerboard test if we gwt here

        local index = state.rooms_by_position[y][x]

        -- east-west
        if (x >= 2 and state.rooms_by_position[y][x - 2] ~= nil) then
          local other_index = state.rooms_by_position[y][x - 2]
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              other_index, index,
                              geoelf.directions.E, nil)
        end

        -- south-north
        if (y >= 2 and state.rooms_by_position[y - 2][x] ~= nil) then
          local other_index = state.rooms_by_position[y - 2][x]

          -- determine if there is another corridor that would
          --  block this one (i.e. an E-W one)
          local block_index = nil
          if (x >= 1 and state.rooms_by_position[y - 1][x - 1] ~= nil) then
            local old_index = state.rooms_by_position[y - 1][x - 1]
            block_index = state.room_data[old_index].corridor[geoelf.directions.E]
          end

          geoelf.add_corridor(state.room_data, state.corridor_data,
                              other_index, index,
                              geoelf.directions.S, block_index)
        end

        -- southeast-northwest
        if (x >= 1 and y >= 1 and
            state.rooms_by_position[y - 1][x - 1] ~= nil) then
          local other_index = state.rooms_by_position[y - 1][x - 1]
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              other_index, index,
                              geoelf.directions.SE, nil)
        end

        -- southwest-northeast
        if (x + 1 < state.rooms_across and y >= 1 and
            state.rooms_by_position[y - 1][x + 1] ~= nil) then
          local other_index = state.rooms_by_position[y - 1][x + 1]
          geoelf.add_corridor(state.room_data, state.corridor_data,
                              other_index, index,
                              geoelf.directions.SW, nil)
        end
      end
    end
  end
end

-- Run source parameter, room, and corridor choices in their pinned order.
function layout.layout_geoelf_diagonals(api)
  local env = family.new(api)
  local state = {
    gxm = env.width,
    gym = env.height,
    depth_fraction = env.you.depth_fraction(),
  }

  choose_parameters(env, state)
  place_rooms(env, state)
  add_corridors(env, state)
  env.geoelf.generate(env, state.room_data, state.corridor_data,
    state.extra_corridor_fraction, state.fancy_room_fraction, false, false)

  return env.result(state.room_data, state.corridor_data)
end

return layout
