-- Nemelex's summon cards share one source owner and RNG stream. This small
-- bridge delegates entity creation, lifetime, placement, and allegiance to
-- the game's ordinary summon policy instead of duplicating those fields.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local streams = require("constants.rng_streams")
local summon_policy = require("policy.magic.effects.summons.common")

local summons = {}

-- Place one friendly card creature for its source abjuration degree.
-- A blocked placement stays silent so a multi-summon card can try others.
function summons.friendly(ctx, player, card_id, kind_id, degree)
    local options = {
        attitude = attitudes.FRIENDLY,
        source_category = categories.CARDS,
        stream = streams.CARDS,
        silent_failure = true,
    }

    return summon_policy.spawn(ctx, player, card_id,
        kind_id, degree, nil, options)
end

-- A Pentagram's first creature sometimes turns hostile. Keep its owner and
-- card source for expiry while letting ordinary AI see hostile allegiance.
function summons.hostile(ctx, player, card_id, kind_id, degree)
    local options = {
        attitude = attitudes.HOSTILE,
        source_category = categories.CARDS,
        stream = streams.CARDS,
        silent_failure = true,
    }

    return summon_policy.spawn(ctx, player, card_id,
        kind_id, degree, nil, options)
end

return summons
