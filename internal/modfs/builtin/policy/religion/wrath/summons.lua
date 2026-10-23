-- Divine wrath creatures are hostile and have no abjuration timeout.
-- The shared summon owner records source god, allegiance, and placement.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local streams = require("constants.rng_streams")
local common = require("policy.magic.effects.summons.common")

local summons = {}

-- A source-god summon has zero expiry, matching mgen_data's duration zero.
-- The card stream owns placement draws, while the summon remains saved ECS.
function summons.hostile(ctx, player, god_id, monster_id)
    return common.spawn(ctx, player, god_id, monster_id, 0, nil, {
        attitude = attitudes.HOSTILE,
        source_category = categories.GODS,
        stream = streams.CARDS,
        silent_failure = true,
        silent_hostility = true,
    })
end

return summons
