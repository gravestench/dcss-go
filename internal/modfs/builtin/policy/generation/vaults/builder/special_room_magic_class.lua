-- The Depths magic class fills one room with source-weighted spellcasters
-- and a leader chosen from liches, uniques, or draconians by depth.
local directives = require("constants.vault_directives")
local fill = require("policy.generation.vaults.builder.special_room_fill")

local room = {}

local casters = {
    "wizard w:8",
    "ogre mage w:7",
    "deep elf annihilator w:6",
    "deep troll earth mage w:5",
    "vampire knight w:5",
    "spriggan air mage w:5",
    "necromancer w:4",
    "deep elf death mage w:3",
    "deep elf sorcerer w:3",
    "deep elf demonologist w:2",
    "deep elf elementalist w:1",
    "vampire mage w:1",
}

-- A source one-in-five scaling check only matters above absolute depth 20.
local function leader(api, depth)
    if depth == 27 then
        return "draconian shifter / ancient lich / Jory w:1 / " ..
            "Frederick w:1 / Boris w:1, draconian shifter / " ..
            "ancient lich / dread lich"
    end

    if api:chance(depth - 20, 5) then
        return "ancient lich / Jory w:1 / Frederick w:1 / Boris w:1, " ..
            "ancient lich / dread lich"
    end

    return "lich / tengu reaver"
end

-- Place the source book on the leader glyph after monster setup.
local function fill_casters(api)
    local depth = api:absolute_depth()
    local monsters = {}

    for index, caster in ipairs(casters) do
        monsters[index] = caster
    end

    if depth == 27 then
        monsters[#monsters + 1] = "draconian annihilator w:5"
    end

    fill.room(api, table.concat(monsters, " / "), leader(api, depth), true)
    api:emit(directives.KITEM, "2 = any randbook")
end

room.fill = fill_casters

return room
