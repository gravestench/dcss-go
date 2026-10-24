-- Divine wrath creatures are hostile; most persist, while source cases
-- with an abjuration degree expire. The shared owner records source god,
-- allegiance, and placement before ordinary monster gear is added.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local component = require("constants.component")
local common = require("policy.magic.effects.summons.common")
local factory = require("policy.population.factory")
local bands = require("policy.population.bands")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local summons = {}

-- Most source-god summons are permanent; callers with a source abjuration
-- degree can request its saved timer. All arrivals carry ordinary gear.
function summons.hostile(ctx, player, god_id, monster_id, degree,
    gear_depth, options)
    local creature = common.spawn(ctx, player, god_id, monster_id,
        degree or 0, nil, {
        attitude = attitudes.HOSTILE,
        source_category = categories.GODS,
        stream = streams.CARDS,
        exact = options and options.exact,
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

    if creature and options and options.permit_band then
        local position = ctx:get(creature, component.POSITION)
        local level = {
            id = position.level_id,
            local_depth = ctx:level_depth(position.level_id),
        }

        -- The ordinary band owner chooses source members and positions.
        -- Its creation callback gives each follower the same permanent
        -- hostile god source and normal generated gear as its leader.
        bands.spawn(ctx, creature, level, {},
            function(kind_id, _, x, y)
                return summons.hostile(ctx, player, god_id,
                    kind_id, 0, gear_depth, {
                        exact = { x = x, y = y },
                    })
            end)
    end

    return creature
end

return summons
