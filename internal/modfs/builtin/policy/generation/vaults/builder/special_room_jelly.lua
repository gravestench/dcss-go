-- Jelly pits change their species mix with Lair and Slime. The leader
-- remains a separate keyed glyph, so ordinary vault population owns it.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local fill = require("policy.generation.vaults.builder.special_room_fill")

local room = {}

-- Keep the source branch choices in one place for the room's own hook.
local function roster(branch)
    if branch == branches.BRANCH_LAIR then
        return "jelly w:60 / large slime creature w:20 / " ..
            "quicksilver ooze / great orb of eyes w:5 / azure jelly w:5 / " ..
            "rockslime w:2 / acid blob w:2",
            "azure jelly / rockslime / acid blob"
    end

    if branch == branches.BRANCH_SLIME then
        return "large slime creature w:20 / great orb of eyes / " ..
            "golden eye w:5 / shining eye w:5 / quicksilver ooze / " ..
            "azure jelly / rockslime w:5 / acid blob w:5",
            "rockslime / acid blob"
    end

    return "great orb of eyes / golden eye w:5 / shining eye w:5 / " ..
        "quicksilver ooze / azure jelly / rockslime w:5 / acid blob w:5",
        "rockslime / acid blob"
end

-- A later substitution may add Jiyva's altar outside the Slime branch.
local function fill_jellies(api)
    local branch = api:branch_id()
    local monsters, lord = roster(branch)

    fill.room(api, monsters, lord, true)
    api:emit(directives.NSUBST, "1. = 2 = x1")

    if branch ~= branches.BRANCH_SLIME and api:coinflip() then
        api:emit(directives.NSUBST, "1. = 1:A")
        api:emit(directives.KFEAT, "A = altar_jiyva")
    end
end

room.fill = fill_jellies

return room
