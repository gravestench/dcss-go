-- Cheibriados measures the player's present danger before taking away
-- speed. More tension permits noise, sleep, and Slow; quiet turns cost stats.
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local noise = require("policy.world.noise")
local sleep = require("policy.combat.monster_beams.sleep")
local slow = require("policy.character.slow")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")
local tension = require("policy.combat.monster_seal_tension")

local cheibriados = {}

-- Source random2avg(5, 2) begins with a five-sided draw and ends with
-- a six-sided draw. Their averaged result is zero to four before adding one.
local function drained_amount(ctx)
    local first = ctx:random(streams.CARDS, 5)
    local second = ctx:random(streams.CARDS, 6)

    return 1 + math.floor((first + second) / 2)
end

-- The source chooses STAT_RANDOM after its amount expression. Keep that
-- order and write the saved recovery debt through the shared stat owner.
local function drain_stat(ctx, player)
    ctx:emit(channels.RELIGION, "Time shudders.")

    local amount = drained_amount(ctx)
    local field = stats.ORDER[ctx:random(streams.CARDS,
        #stats.ORDER) + 1]

    stat_loss.drain(ctx, player, field, amount)
end

-- dec_haste_player(10000) crosses the expiry-warning threshold when the
-- timer exceeded six turns. Its coinflip still belongs to source draw order
-- even though the enormous reduction consumes the remaining Haste.
local function strip_haste(ctx, player)
    local durations = ctx:get(player, component.DURATIONS)

    if not durations or durations.haste_aut <= 0 then
        return
    end

    if durations.haste_aut > 60 then
        ctx:emit(channels.DURATION,
            "Your extra speed is starting to run out.")
        ctx:random(streams.CARDS, 2)
    elseif durations.haste_aut <= 10 then
        ctx:emit(channels.DURATION, "You feel yourself slow down.")
    end

    durations.haste_aut = 0
    ctx:set(player, component.DURATIONS, durations)
end

-- High-tension cases pay one extra unit before falling into the next
-- effect. The shared retribution owner later applies its usual mollification.
local function mollify_extra(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.penance[gods.CHEIBRIADOS] = math.max(0,
        (worship.penance[gods.CHEIBRIADOS] or 0) - 1)
    ctx:set(player, component.RELIGION_WORSHIP, worship)
end

-- The source switch intentionally falls through. At severity four, noise
-- always precedes Sleep; its one-in-three stop can prevent the final Slow.
local function punish(ctx, player, severity)
    if severity == 4 then
        ctx:emit(channels.RELIGION,
            "Cheibriados strikes the hour.")
        noise.emit(ctx, ctx:get(player, component.POSITION),
            40, player)
        mollify_extra(ctx, player)
    end

    if severity >= 3 then
        ctx:emit(channels.RELIGION,
            "You lose track of time.")
        sleep.apply_unresisted(ctx, player,
            30 + ctx:random(streams.CARDS, 20))

        if ctx:random(streams.CARDS, severity - 1) == 0 then
            return
        end

        mollify_extra(ctx, player)
    end

    if severity >= 2 then
        ctx:emit(channels.WARNING,
            "You feel the world leave you behind!")
        slow.apply(ctx, player,
            91 + ctx:random(streams.CARDS, 10))
    else
        drain_stat(ctx, player)
    end
end

-- get_tension is sampled before Haste is stripped. random2(0) yields zero
-- without an RNG draw, so a peaceful turn enters the low-tension stat path.
function cheibriados.apply(ctx, player)
    local score = tension.current(ctx, player)
    local value = score > 0 and
        ctx:random(streams.CARDS, score) or 0
    local severity = 0

    if value >= 16 then
        severity = 4
    elseif value >= 8 then
        severity = 3
    elseif value >= 4 then
        severity = 2
    elseif value >= 2 then
        severity = 1
    end

    strip_haste(ctx, player)
    punish(ctx, player, severity)

    return true
end

return cheibriados
