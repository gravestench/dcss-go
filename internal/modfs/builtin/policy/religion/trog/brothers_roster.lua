-- Brothers in Arms uses one source roster for selection and save checks.
-- Keeping the nine legal monster IDs here prevents a modded choice and
-- its restored actor from drifting between separate lists.
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local roster = {}

local bears = {
    monsters.MONS_BLACK_BEAR,
    monsters.MONS_POLAR_BEAR,
}

local ogres = {
    monsters.MONS_TWO_HEADED_OGRE,
    monsters.MONS_OGRE,
    monsters.MONS_OGRE,
}

local trolls = {
    monsters.MONS_TROLL,
    monsters.MONS_TROLL,
    monsters.MONS_TROLL,
    monsters.MONS_DEEP_TROLL,
    monsters.MONS_DEEP_TROLL,
    monsters.MONS_DEEP_TROLL,
    monsters.MONS_IRON_TROLL,
    monsters.MONS_IRON_TROLL,
}

local giants = {
    monsters.MONS_CYCLOPS,
    monsters.MONS_STONE_GIANT,
}

roster.allowed = {}

for _, choices in ipairs({ bears, ogres, trolls, giants }) do
    for _, kind_id in ipairs(choices) do
        roster.allowed[kind_id] = true
    end
end

-- Source power thresholds are inclusive; each repeated entry represents
-- one weight rather than a later filter that could shift RNG ordering.
function roster.pick(ctx, power)
    local choices = giants

    if power <= 100 then
        choices = bears
    elseif power <= 140 then
        choices = ogres
    elseif power <= 180 then
        choices = trolls
    end

    return choices[ctx:random(streams.RELIGION, #choices) + 1]
end

return roster
