-- Okawaru rewards the actual difficulty of a slain foe. The common kill
-- classes select eligible victims, while this god's method owns the
-- source's two-draw fuzzed difficulty instead of a fixed kill curve.
local common = require("policy.religion.conduct.common")
local component = require("constants.component")
local experience_limit = require("policy.character.experience_limit")
local kinds = require("constants.religion_conduct")

local likes = common.kills()

-- Source difficulty fuzzes the victim's XP with two separate draws, then
-- discounts it by the square root of the player's level XP threshold.
-- Keeping the draws here preserves their position in the religion stream.
local function difficulty(ctx, player, event)
    if type(event.experience) ~= "number" then
        error("Okawaru kill requires the victim's XP value")
    end

    local progress = ctx:get(player, component.PROGRESSION)
    local identity = ctx:get(player, "core.player")

    if not progress or not identity then
        error("Okawaru kill requires player level and species")
    end

    local needed = experience_limit.needed(ctx, player,
        progress.level)
    local factor = math.sqrt(needed / 30)
    local bound = event.experience * 100
    local fuzzed = 0

    if bound > 0 then
        fuzzed = ctx:random("religion", bound) +
            ctx:random("religion", bound)
    end

    local numerator = math.floor(fuzzed / (1 + factor))
    local message

    if numerator > 3200 then
        message = " is honoured by your kill."
    elseif numerator > 9 then
        message = " accepts your kill."
    end

    return numerator, 550, message
end

for _, id in ipairs({
    kinds.KILL_LIVING,
    kinds.KILL_UNDEAD,
    kinds.KILL_DEMON,
    kinds.KILL_HOLY,
    kinds.KILL_NONLIVING,
}) do
    likes[id].bonus = 0
    likes[id].denom_bonus = 0
    likes[id].xl_denom = 0
    likes[id].message = nil
    likes[id].special = difficulty
end

local okawaru = {
    likes = likes,
}

return okawaru
