-- Lugonu accepts ordinary kills and banishments. Source conduct does not
-- reward Lucy while the player is already in the Abyss; that gate belongs
-- here because it is specific to Lugonu, not to shared piety math.
local common = require("policy.religion.conduct.common")
local component = require("constants.component")
local kinds = require("constants.religion_conduct")
local branches = require("ids.branches")

local likes = common.kills()

-- Actions in the Abyss already serve Lugonu's realm, so source conduct
-- cannot farm piety there. Check the saved player floor for every event.
local function outside_abyss(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if not position then
        error("Lugonu conduct requires player position")
    end

    return ctx:level_branch(position.level_id) ~= branches.BRANCH_ABYSS
end

likes[kinds.BANISH] = {
    description = "you banish creatures to the Abyss",
    bonus = -6,
    denom_bonus = 18,
    xl_denom = 2,
    message = " claims a new guest.",
}

local lugonu = {
    before = outside_abyss,
    likes = likes,
}

return lugonu
