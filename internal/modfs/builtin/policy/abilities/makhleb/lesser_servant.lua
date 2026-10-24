-- Lesser Servant owns Makhleb's third-star demon invocation. The shared
-- servant owner performs its source selection and hostile failure behavior.
local abilities = require("ids.abilities")
local registry = require("policy.abilities.registry")
local servant = require("policy.abilities.makhleb.servant")

local lesser = {}

-- Live worship and No Love decide whether the menu may offer this power.
function lesser.available(ctx, player)
    return servant.available(ctx, player, 3)
end

-- Four fixed HP must leave at least one point before a turn begins.
function lesser.prepare(ctx, player)
    return servant.prepare(ctx, player, 4)
end

-- The source failure tuple is 40,5,20. Generic piety base two draws
-- two or three points only after a demon has been attempted.
function lesser.resolve(ctx, player)
    servant.resolve(ctx, player, "lesser", 4, 2, 40, 5, 20)
end

registry.add(abilities.MAKHLEB_LESSER_SERVANT, {
    name = "Lesser Servant of Makhleb",
    available = lesser.available,
    prepare = lesser.prepare,
    resolve = lesser.resolve,
})

return lesser
