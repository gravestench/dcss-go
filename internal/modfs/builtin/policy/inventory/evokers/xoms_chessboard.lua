-- Xom's chessboard draws one hostile and one weighted move. Beneficial
-- moves are intentional: the source item is a gamble, not a safe hex.
-- Every move delegates durable state to the ordinary monster rule owner.
local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.inventory.evokers.effects")
local ids = require("constants.evoker_chessboard")
local items = require("ids.items")
local targets = require("policy.inventory.evokers.targets")
local power = require("policy.magic.power")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local will = require("policy.magic.effects.zaps.will")
local boons = require("policy.combat.monster_support.boons")
local duration = require("policy.combat.monster_support.duration")
local invisibility = require("policy.combat.monster_support.invisibility")
local status = require("policy.combat.monster_hexes.status")
local slow = require("policy.combat.monster_slow")
local malmutation = require("policy.monsters.malmutation")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local paralysis = require("policy.magic.effects.zaps.paralysis")
local confusion = require("policy.magic.effects.statuses.confusing_touch")
local sleep = require("policy.combat.monster_beams.sleep")

local chessboard = {}

-- A prepared move with no visible foe needs explicit confirmation. If
-- accepted, even a move that finds no target spends one piece's charge.
function chessboard.prepare(ctx, player, _, _, forced)
    local _, visible = targets.nearby(ctx, player)

    return targets.warn_if_unseen(visible, forced,
        "You can't see anything. Try to make a move anyway?")
end

-- Helpful moves use the same timers as monster Haste, Invisibility, and
-- Might. Each can affect a hostile, which is the chessboard's price.
local function haste(ctx, target)
    boons.haste(ctx, target,
        duration.beneficial(ctx, target, streams.EVOKER))
end

local function invisible(ctx, target)
    invisibility.grant(ctx, target,
        duration.beneficial(ctx, target, streams.EVOKER))
end

local function might(ctx, target)
    boons.might(ctx, target,
        duration.beneficial(ctx, target, streams.EVOKER))
end

-- A luminous target loses the benefit of invisibility; Corona remains a
-- saved hex status consumed by the ordinary visibility policy.
local function corona(ctx, target)
    status.corona(ctx, target, 200 + ctx:random(streams.EVOKER, 110))
end

-- The slow owner keeps the original speed for later restoration.
local function slowing(ctx, target, definition)
    slow.apply(ctx, target, definition, nil, streams.EVOKER)
end

-- Permanent malmutation is handled by the same monster body policy as
-- spell malmutation, including monsters that cannot be mutated.
local function mutate(ctx, target, definition)
    malmutation.apply(ctx, target, definition, streams.EVOKER)
end

-- Petrification starts the normal multi-turn stone transition.
local function petrify(ctx, target)
    stasis.apply_petrify(ctx, target)
end

-- Paralysis persists through the ordinary monster action timer.
local function paralyse(ctx, target, definition, strength)
    paralysis.apply_unresisted(ctx, target, definition, strength)
end

-- Confusion uses the normal enchantment duration and message path.
local function confuse(ctx, target, definition, strength)
    confusion.apply_unresisted(ctx, target, definition, strength)
end

-- Sleep changes the monster's saved alertness, not its HP or allegiance.
local function sleeping(ctx, target, _, strength)
    sleep.apply_unresisted(ctx, target, strength)
end

local moves = {
    {
        id = ids.HASTE,
        weight = 5,
        apply = haste,
        helpful = true,
    },
    {
        id = ids.INVISIBILITY,
        weight = 5,
        apply = invisible,
        helpful = true,
    },
    {
        id = ids.MIGHT,
        weight = 5,
        apply = might,
        helpful = true,
    },
    {
        id = ids.CORONA,
        weight = 10,
        apply = corona,
    },
    {
        id = ids.SLOW,
        weight = 15,
        apply = slowing,
    },
    {
        id = ids.MALMUTATE,
        weight = 15,
        apply = mutate,
    },
    {
        id = ids.PETRIFY,
        weight = 15,
        apply = petrify,
    },
    {
        id = ids.PARALYSE,
        weight = 10,
        apply = paralyse,
    },
    {
        id = ids.CONFUSE,
        weight = 10,
        apply = confuse,
    },
    {
        id = ids.SLEEP,
        weight = 10,
        apply = sleeping,
    },
}

-- One roll over exactly 100 source weight points selects the move. The
-- returned rule exposes its name for diagnostics and extension tests.
function chessboard.pick(ctx)
    local roll = ctx:random(streams.EVOKER, 100)

    for _, move in ipairs(moves) do
        roll = roll - move.weight

        if roll < 0 then
            return move
        end
    end

    error("chessboard move picker exhausted")
end

-- A selected monster still gets its ordinary willpower defense against
-- harmful magic. The charge is spent even when that monster resists.
function chessboard.resolve(ctx, player)
    local enemies = targets.nearby(ctx, player)

    ctx:emit("evoke", "You make a move on Xom's chessboard...")

    if #enemies == 0 then
        ctx:emit("evoke", "Nothing happens.")

        return {
            charge = true,
            practice = 1,
        }
    end

    local chosen = enemies[ctx:random(streams.EVOKER, #enemies) + 1]
    local actor = ctx:get(chosen.actor, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local move = chessboard.pick(ctx)
    local training = power.training(ctx, player,
        skills.SK_EVOCATIONS, 7)
    local strength = 15 + math.floor(training / 2)

    if not move.helpful and will.resists(ctx, definition,
        strength, chosen.actor, streams.EVOKER, player) then
        ctx:emit("evoke", "The " .. definition.name .. " resists.")
    else
        move.apply(ctx, chosen.actor, definition, strength)
    end

    return {
        charge = true,
        practice = 1,
    }
end

effects.add(items.MISC_XOMS_CHESSBOARD, chessboard)

return chessboard
