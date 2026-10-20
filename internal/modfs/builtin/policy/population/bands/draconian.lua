-- Theory of operation: Tiamat's source band is eight to fifteen
-- draconians. At Zot depth, each follower has a 13/40 chance to be a
-- classed draconian; otherwise it is an ordinary draconian species. The
-- leader's monster file owns the count and names this member policy.
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local policy = {}

local species = {
    monsters.MONS_WHITE_DRACONIAN,
    monsters.MONS_RED_DRACONIAN,
    monsters.MONS_PURPLE_DRACONIAN,
    monsters.MONS_YELLOW_DRACONIAN,
    monsters.MONS_BLACK_DRACONIAN,
    monsters.MONS_GREEN_DRACONIAN,
    monsters.MONS_GREY_DRACONIAN,
    monsters.MONS_PALE_DRACONIAN,
}

local classed = {
    monsters.MONS_DRACONIAN_STORMCALLER,
    monsters.MONS_DRACONIAN_KNIGHT,
    monsters.MONS_DRACONIAN_KNIGHT,
    monsters.MONS_DRACONIAN_MONK,
    monsters.MONS_DRACONIAN_MONK,
    monsters.MONS_DRACONIAN_SHIFTER,
    monsters.MONS_DRACONIAN_SHIFTER,
    monsters.MONS_DRACONIAN_ANNIHILATOR,
    monsters.MONS_DRACONIAN_ANNIHILATOR,
    monsters.MONS_DRACONIAN_SCORCHER,
    monsters.MONS_DRACONIAN_SCORCHER,
}

-- The authored Tiamat vault occurs only in Zot, which always satisfies the
-- source's absolute-depth threshold for the classed draw.
function policy.choose(ctx)
    local pool = species

    if ctx:random(streams.BANDS, 40) < 13 then
        pool = classed
    end

    return pool[ctx:random(streams.BANDS, #pool) + 1]
end

return policy
