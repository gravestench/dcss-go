-- Blinding and frenzy darts first test the target's life state and the
-- source HD-based dart resistance roll. Their player conditions then use
-- the same ECS owners as spells and other combat effects.
local holiness = require("policy.character.holiness")
local monster_stats = require("policy.combat.monster_stats")
local confusion = require("policy.magic.player_confusion")
local rage = require("policy.character.rage")
local streams = require("constants.rng_streams")

local mind = {}

-- Monster darts start at 85 percent, adjusted by the difference between
-- the player's XL and the shooter's HD; frenzy halves that chance.
local function succeeds(ctx, attacker, definition, frenzy)
    local player = ctx:player()

    if not holiness.natural(ctx, player) then
        return false
    end

    local progress = ctx:get(player, "core.progression")
    local player_hd = progress and progress.level or 1
    local attacker_hd = monster_stats.hit_dice(ctx, attacker, definition)
    local difference = math.modf((player_hd - attacker_hd) * 5 / 2)
    local chance = math.min(95, 85 - difference)

    if frenzy then
        chance = math.modf(chance / 2)
    end

    return ctx:random(streams.MELEE, 100) < chance
end

-- The same damage that got through on contact determines confusion time.
function mind.blinding(ctx, attacker, definition, _, damage)
    if succeeds(ctx, attacker, definition, false) then
        confusion.extend(ctx, ctx:player(), math.floor(damage / 3))
    end
end

-- The source resistance chance is stricter for a frenzy dart. Rage owns
-- species, form, clarity, and current berserk restrictions after that roll.
function mind.frenzy(ctx, attacker, definition)
    if succeeds(ctx, attacker, definition, true) then
        rage.begin(ctx, ctx:player(), streams.MELEE)
    end
end

return mind
