local shape = require("policy.generation.room_shape")

local rooms = {}

local function random_rooms(builder, count, max_doors, door_level, max_x, max_y, max_size)
    local failures = 0
    local completed = 0

    while completed < count do
        local left = 8 + builder:roll(max_x)
        local top = 8 + builder:roll(max_y)
        local right = left + 2 + builder:roll(max_size)
        local bottom = top + 2 + builder:roll(max_size)

        if shape.make(builder, left, top, right, bottom, max_doors, door_level) then
            completed = completed + 1
        else
            failures = failures + 1

            if failures > 30 then
                failures = 0
                completed = completed + 1
            end
        end
    end
end

function rooms.make(builder)
    local door_level = builder:roll(11)
    local room_size = 4 + builder:roll(5)
    room_size = room_size + builder:roll(6)

    local first_count_die = builder:roll(29)
    local second_count_die = builder:roll(30)
    local ordinary_count = 5 + math.floor((first_count_die + second_count_die) / 2)
    local room_count = ordinary_count

    if builder:roll(636 + 49) < 49 then
        room_count = 100
    end

    if builder:roll(636 + 49 + 15) < 15 then
        room_count = 1
    end

    local ordinary_max_doors = 2 + builder:roll(8)
    random_rooms(builder, room_count, ordinary_max_doors, door_level, 50, 40, room_size)

    local small_count = 1 + builder:roll(3)
    random_rooms(builder, small_count, 1, door_level, 55, 45, 6)
end

return rooms
