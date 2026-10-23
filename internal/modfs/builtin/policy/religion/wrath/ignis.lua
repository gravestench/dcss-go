-- Ignis tries a shaft, then a fire champion, then fire elementals. Only
-- elemental summons have a complete saved effect owner in the Lua rules.
local gods = require("constants.gods")
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")

local ignis = {}

-- godspeak.txt gives six lines default weight ten and two lines weight five.
-- getSpeakString draws only after at least one fire elemental arrives.
local speeches = {
    '"Attack, my last stalwart servants!"',
    "Ignis wails with rage, and rains down burning fury!",
    "Ignis calls forth spirits of fire to unmake you!",
    '"Burn! Burn until nothing is left!"',
    '"These will know how to inflict the punishment due to you!"',
    '"Betrayer! Apostate! Perish!"',
    '"With a thousand fires I burned cities, but these will suffice for you!"',
    '"My hands, my teeth, my burning tears: these will never betray me!"',
}

-- Attempt both or all three permanent fire servants before reporting
-- success; only successful placement triggers the weighted speech draw.
local function summon_elementals(ctx, player)
    -- random_range(2, 3) consumes one card draw before placement attempts.
    local count = 2 + ctx:random(streams.CARDS, 2)
    local created = false

    for _ = 1, count do
        if summons.hostile(ctx, player, gods.IGNIS,
            monsters.MONS_FIRE_ELEMENTAL) then
            created = true
        end
    end

    if created then
        local draw = ctx:random(streams.CARDS, 70)
        local index = draw < 60 and math.floor(draw / 10) + 1 or
            math.floor((draw - 60) / 5) + 7

        ctx:emit(channels.RELIGION, speeches[index])
    else
        ctx:emit(channels.RELIGION,
            "Ignis' divine wrath fails to arrive.")
    end
end

-- A true shaft draw needs source shaftability and do_shaft, including the
-- Mountain Boots exception. A true champion draw needs ENCH_FIRE_CHAMPION.
-- Stop at each unsupported branch without consuming later branch draws.
function ignis.apply(ctx, player)
    if ctx:random(streams.CARDS, 3) == 0 then
        error("unimplemented Ignis wrath shaft eligibility and effect")
    end

    if ctx:random(streams.CARDS, 2) == 0 then
        error("unimplemented Ignis fire champion wrath")
    end

    summon_elementals(ctx, player)

    return true
end

return ignis
