-- Divine wrath creatures are hostile; most persist, while source cases
-- with an abjuration degree expire. The shared owner records source god,
-- allegiance, and placement before ordinary monster gear is added.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local component = require("constants.component")
local common = require("policy.magic.effects.summons.common")
local factory = require("policy.population.factory")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local summons = {}

-- Most source-god summons are permanent; callers with a source abjuration
-- degree can request its saved timer. All arrivals carry ordinary gear.
function summons.hostile(ctx, player, god_id, monster_id, degree,
    gear_depth)
    local creature = common.spawn(ctx, player, god_id, monster_id,
        degree or 0, nil, {
        attitude = attitudes.HOSTILE,
        source_category = categories.GODS,
        stream = streams.CARDS,
        silent_failure = true,
        silent_hostility = true,
    })

    -- Beogh and Wu Jian build a dancing weapon from their own subtype and
    -- brand draws. The ordinary monster gear table would attach a second,
    -- unrelated weapon before that construction runs.
    if creature and monster_id ~= monsters.MONS_DANCING_WEAPON then
        local position = ctx:get(player, component.POSITION)

        factory.equip_generated(ctx, creature, monster_id,
            gear_depth or position.level_id)
    end

    return creature
end

return summons
