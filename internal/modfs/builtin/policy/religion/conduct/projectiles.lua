-- Theory of operation: throw.cc reports god conduct once after a shot's
-- flight, including a miss or a shot into empty space. The saved item ego
-- distinguishes launcher brands from missile brands; knowledge is read
-- from the launcher before a chaos offense is classified.
local conduct = require("policy.religion.conduct")
local identification = require("policy.items.identification")
local kinds = require("constants.religion_conduct")
local missile_egos = require("constants.missile_egos")
local streams = require("constants.rng_streams")
local weapon_brands = require("constants.weapon_brands")

local projectiles = {}

-- Chaos can come from either piece of equipment. The launcher brand is
-- knowable through item identification; this game's missile ego is treated
-- as an unrecognized consumable at the moment of firing, as in the source.
local function chaos(ctx, player, entity, launched, ego)
    local launcher = launched and ego == weapon_brands.CHAOS
    local missile = not launched and ego == missile_egos.CHAOS

    if not launcher and not missile then
        return
    end

    local known = launcher and
        identification.known(ctx, player, entity).properties or false

    conduct.record(ctx, {
        id = kinds.CHAOS,
        level = 2 + ctx:random(streams.RELIGION, 3),
        known = known,
    })
end

-- Speed launchers and frenzy missiles both hurry combat. Their severity
-- differs in the source, so each reports its own named event after flight.
local function haste(ctx, launched, ego)
    if launched and ego == weapon_brands.SPEED then
        conduct.record(ctx, {
            id = kinds.HASTY,
            level = 1,
            known = true,
        })
    elseif not launched and ego == missile_egos.FRENZY then
        conduct.record(ctx, {
            id = kinds.HASTY,
            level = 6 + ctx:random(streams.RELIGION, 3),
            known = true,
        })
    end
end

-- The firing action calls this once, independent of the number of actors
-- crossed by a penetrating shot. Contact offenses belong to each target.
function projectiles.on_shot(ctx, player, entity, launched, item)
    chaos(ctx, player, entity, launched, item.ego)
    haste(ctx, launched, item.ego)
end

return projectiles
