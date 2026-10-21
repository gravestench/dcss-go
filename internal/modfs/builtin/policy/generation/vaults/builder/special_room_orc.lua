-- Orc rooms scale from common Orcs to priests and warlords. The source
-- adds loot and may turn the leader glyph into a Beogh altar.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local fill = require("policy.generation.vaults.builder.special_room_fill")

local room = {}

-- Each depth band changes the entire weighted roster, so retain the
-- source's four explicit choices next to the hook that emits them.
local function roster(api)
    local level = api:absolute_depth() - 1
    local branch = api:branch_id()

    if level > 20 or branch == branches.BRANCH_ELF then
        return "orc priest w:7 / orc warrior w:12 / orc knight w:8 / " ..
            "orc high priest w:2 / two-headed ogre w:1", "orc warlord"
    end

    if level > 14 or branch == branches.BRANCH_ORC then
        return "orc w:6 / orc warrior w:8 / orc priest w:2 / " ..
            "orc knight w:3 / troll w:1",
            "orc knight / orc high priest w:6 / orc warlord w:4"
    end

    if level > 9 then
        return "orc w:25 / orc warrior / orc priest w:3 / ogre w:2",
            "orc priest w:7 / orc knight w:3"
    end

    return "orc w:44 / orc warrior w:5 / ogre w:1", "orc priest"
end

-- The source Beogh chance and both gold slots occur after population.
local function fill_orcs(api)
    local monsters, lord = roster(api)
    local level = api:absolute_depth() - 1

    fill.room(api, monsters, lord, true)

    if api:coinflip() then
        api:emit(directives.KFEAT, "2 = altar_beogh")
    end

    api:emit(directives.KITEM,
        "1. = gold level:" .. (level - 4) .. " w:1 / nothing w:8")
    api:emit(directives.KITEM, "2 = gold")
end

room.fill = fill_orcs

return room
