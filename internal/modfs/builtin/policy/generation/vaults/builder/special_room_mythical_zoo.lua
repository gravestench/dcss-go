-- Mythical zoos replace low-tier reptiles and rats with dangerous beasts
-- as effective depth rises. The current branch shifts that depth first.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local fill = require("policy.generation.vaults.builder.special_room_fill")

local room = {}

-- Preserve each source threshold and weight so the same room definition
-- spans shallow Dungeon, Lair, Elf, and Depths without a Go roster switch.
local function roster(level)
    local monsters = {
        "rime drake w:" .. math.max(38 - level * 2, 1),
        "basilisk w:" .. math.max(38 - level * 2, 1),
        "wyvern w:" .. math.max(44 - level * 2, 1),
        "hell rat w:" .. math.max(44 - level * 2, 1),
        "hell hound w:" .. math.max(level - 11, 1),
        "hydra w:" .. math.max(level * 2 - 26, 1),
    }

    if level >= 16 then
        monsters[#monsters + 1] = "manticore w:" .. (level * 2 - 24)
        monsters[#monsters + 1] = "harpy w:" .. (level - 15)
    end

    if level >= 19 then
        monsters[#monsters + 1] = "fire dragon w:" .. (level * 2 - 37)
        monsters[#monsters + 1] = "sphinx w:" .. (level - 16)
    end

    local lord

    if level >= 21 then
        lord = "catoblepas / sphinx w:60 / hell beast w:20"
    elseif level >= 16 then
        lord = "catoblepas / hydra w:40 / hell beast w:40"
    else
        lord = "catoblepas / manticore w:40 / hydra w:40"
    end

    return table.concat(monsters, " / "), lord
end

-- The gold and box-of-beasts lottery follows the monster choice.
local function fill_zoo(api)
    local level = api:absolute_depth()
    local branch = api:branch_id()

    if branch == branches.BRANCH_ELF then
        level = level + 5
    elseif branch == branches.BRANCH_LAIR then
        level = level - 2
    end

    local monsters, lord = roster(level)

    fill.room(api, monsters, lord, true)
    api:emit(directives.KITEM,
        "2 = gold good_item w:" .. (level - 7) ..
        " / gold w:" .. (level + 7) ..
        ", box of beasts w:3 / nothing w:17")
end

room.fill = fill_zoo

return room
