-- Jiyva's defensive ranks are live queries over the saved worship owner.
-- No extra flag can outlive penance, renunciation, or a change of patron.
local component = require("constants.component")
local gods = require("constants.gods")
local piety = require("policy.religion.piety")

local defenses = {}

local HP_PIP = 80
local MP_PIP = 25

-- The source gates nonnegative-rank passives under penance. Rank zero still
-- requires actual Jiyva worship, while a rank-one benefit starts at 30.
function defenses.active(ctx, player, rank)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    return state and state.god_id == gods.JIYVA and
        (state.penance[gods.JIYVA] or 0) == 0 and
        piety.rank(gods.JIYVA, state.piety) >= rank or false
end

-- One HP pip at the first star grows to two by the sixth. The bonus is
-- separate from natural recovery so illness or inhibited regeneration
-- cannot silently remove Jiyva's independent healing.
function defenses.hp_bonus(ctx, player)
    if not defenses.active(ctx, player, 1) then
        return 0
    end

    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local rank = piety.rank(gods.JIYVA, state.piety)

    return HP_PIP + math.floor(HP_PIP * (rank - 1) / 5)
end

-- The MP contribution follows the same rank slope but starts at 25 units;
-- HP-casting species still have no MP pool for this bonus to refill.
function defenses.mp_bonus(ctx, player)
    if not defenses.active(ctx, player, 1) then
        return 0
    end

    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local rank = piety.rank(gods.JIYVA, state.piety)

    return MP_PIP + math.floor(MP_PIP * (rank - 1) / 5)
end

-- The two-star source resistance contributes one rCorr/acid level. The
-- shared resistance owner still applies its ordinary cap and gear effects.
function defenses.acid_resistance(ctx, player)
    return defenses.active(ctx, player, 2) and 1 or 0
end

return defenses
