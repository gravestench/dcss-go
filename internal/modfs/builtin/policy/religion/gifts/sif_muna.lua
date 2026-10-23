-- Theory of operation: Sif offers a divine-quality book at high
-- piety. The source gate is sparse and a failed book roll consumes neither
-- timeout nor lifetime gift count. The item owner places a real god-marked
-- book; the count of spells in that exact item determines the cooldown.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local classes = require("ids.object_classes")
local component = require("constants.component")
local draws = require("policy.religion.gifts.draws")
local gifts = require("policy.religion.gifts")
local gods = require("constants.gods")
local items = require("policy.religion.gifts.items")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local piety = require("policy.religion.piety")
local streams = require("constants.rng_streams")

local sif = {}

local PIETY_ROLL_MIN = 101
local COIN_SIDES = 2
local TIMEOUT_BASE = 10
local TIMEOUT_PER_SPELL = 6

-- Source _give_sif_gift rejects innate casters and unsafe terrain before
-- spending chance RNG. At five stars, its piety roll and coin flip both
-- need to pass before the book selector runs.
local function due(ctx, player, worship)
    if mutation_levels.base(ctx, player,
        mutations.MUT_INNATE_CASTER) > 0 or
        not items.safe_floor(ctx, player) or
        worship.piety < piety.breakpoint(5) then
        return false
    end

    if ctx:random(streams.RELIGION, worship.piety) <
        PIETY_ROLL_MIN then
        return false
    end

    return ctx:random(streams.RELIGION, COIN_SIDES) ~= 0
end

-- Fixed books use imported templates; random books use their saved spell
-- payload. Count the resulting item, not a proposed book type, because
-- source cooldown depends on what actually appeared.
local function spell_count(ctx, entity)
    local item = ctx:get(entity, component.ITEM)
    local random_book = ctx:get(entity, component.ITEM_RANDOM_BOOK)

    if random_book then
        return #random_book.spells
    end

    local definition = catalog.get(categories.ITEMS, item.kind_id)

    return #(definition.generation.spells or {})
end

-- Example: after a successful high-piety check, one named book appears at
-- the player's feet and slows later gift checks by its spell count.
function sif.check(ctx, player, worship)
    if not due(ctx, player, worship) then
        return false
    end

    local item = items.grant(ctx, player, classes.OBJ_BOOKS, gods.SIF_MUNA)

    if not item then
        return false
    end

    local timeout = TIMEOUT_BASE +
        spell_count(ctx, item) * TIMEOUT_PER_SPELL +
        draws.average(ctx, 19)

    gifts.record(ctx, player, timeout)
    ctx:emit(channels.RELIGION, "Sif Muna grants you a gift!")

    return true
end

return sif
