-- Kobold rooms gain more brigands as absolute Dungeon depth rises. The
-- monster recipe stays local to this DES helper rather than a Go selector.
local fill = require("policy.generation.vaults.builder.special_room_fill")

local room = {}

-- Source uses absdepth minus one and three depth bands for brigand weight.
local function fill_kobolds(api)
    local level = api:absolute_depth() - 1
    local level_monsters = 6

    if level < 6 then
        level_monsters = 2
    elseif level < 9 then
        level_monsters = 4
    end

    local brigands = 3 + level_monsters
    local kobolds = 12 - brigands
    local monsters = "kobold w:" .. kobolds ..
        " / kobold brigand w:" .. brigands

    fill.room(api, monsters, "kobold demonologist", false)
end

room.fill = fill_kobolds

return room
