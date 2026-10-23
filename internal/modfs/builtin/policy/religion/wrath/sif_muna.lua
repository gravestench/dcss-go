-- Sif Muna punishes magical competence through Int loss, confusion, MP
-- draining, or debuffing. These are the four source switch branches.
local component = require("constants.component")
local confusion = require("policy.magic.player_confusion")
local attributes = require("policy.character.attributes")
local cancellation = require("policy.potions.cancellation")
local channels = require("constants.message_channels")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")

local sif_muna = {}

-- The source chooses one of ten equally likely cases before any branch
-- roll. All outcomes write existing saveable player resources or statuses.
function sif_muna.apply(ctx, player)
    ctx:emit(channels.RELIGION, "Sif Muna's wrath finds you.")

    local choice = ctx:random(streams.CARDS, 10)

    if choice <= 2 then
        local current = attributes.current(ctx, player)
        local bound = math.floor(current.intelligence / 5)
        local amount = 1 + (bound > 1 and
            ctx:random(streams.CARDS, bound) or 0)

        stat_loss.drain(ctx, player, stats.INTELLIGENCE, amount)
    elseif choice <= 5 then
        confusion.extend(ctx, player,
            5 + ctx:random(streams.CARDS, 3))
    elseif choice <= 8 then
        local magic = ctx:get(player, component.MAGIC)

        if magic.current > 0 then
            magic.current = 0
            ctx:set(player, component.MAGIC, magic)
            ctx:emit(channels.RELIGION, "Your magic is drained!")
        end
    else
        -- Sif invokes the shared debuff operation without the potion's
        -- separate contamination roll or reduction.
        cancellation.debuff(ctx, player)
    end

    return true
end

return sif_muna
