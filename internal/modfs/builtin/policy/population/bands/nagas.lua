-- A Naga warrior's first two followers may be elite, while later slots
-- favour ordinary naga. This is source BAND_NAGAS membership policy and
-- is shared by ambient generation and god-sourced wrath arrivals.
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local nagas = {}

local elite = {
    { id = monsters.MONS_NAGA_WARRIOR, weight = 8 },
    { id = monsters.MONS_NAGA_MAGE, weight = 11 },
    { id = monsters.MONS_NAGA_RITUALIST, weight = 6 },
    { id = monsters.MONS_NAGA_SHARPSHOOTER, weight = 8 },
    { id = monsters.MONS_SALAMANDER_MYSTIC, weight = 6 },
}

local allowed = {
    [monsters.MONS_NAGA] = true,
    [monsters.MONS_SALAMANDER] = true,
}

for _, entry in ipairs(elite) do
    allowed[entry.id] = true
end

-- Save validation asks whether a follower belongs to this source roster.
function nagas.allows(kind_id)
    return allowed[kind_id] == true
end

-- Source chooses an elite on a half-chance for slot one and a quarter-
-- chance for slot two. The remaining weighted draw is then independent.
function nagas.choose(ctx, _, index)
    local special = index == 1 and
        ctx:random(streams.BANDS, 2) == 0 or
        index == 2 and ctx:random(streams.BANDS, 4) == 0

    if special then
        local total = 0

        for _, entry in ipairs(elite) do
            total = total + entry.weight
        end

        local draw = ctx:random(streams.BANDS, total)

        for _, entry in ipairs(elite) do
            if draw < entry.weight then
                return entry.id
            end

            draw = draw - entry.weight
        end
    end

    if ctx:random(streams.BANDS, 7) == 0 then
        return monsters.MONS_SALAMANDER
    end

    return monsters.MONS_NAGA
end

return nagas
