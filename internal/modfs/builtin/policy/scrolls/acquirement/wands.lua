-- Trove DES can request wand acquirement even though acquirement scrolls do
-- not offer a wand menu choice. Keep that source picker beside the other
-- acquirement subtype rules so both paths use the same item generator.
local ids = require("ids.items")
local item_sets = require("policy.item_generation.item_sets")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local selection = require("policy.scrolls.acquirement.selection")
local sets = require("constants.item_sets")

local wands = {}

-- Source acquirement favors the three saved wand-set representatives and
-- doubles the weight of a type the character has not identified or seen.
-- Ru's no-love sacrifice removes charming because it cannot provide allies.
function wands.pick(ctx, player)
    local hex = item_sets.choice(ctx, player, sets.HEX_WANDS)
    local no_allies = mutation_levels.effective(ctx, player,
        mutations.MUT_NO_LOVE) > 0
    local rows = {
        {
            id = item_sets.choice(ctx, player, sets.BEAM_WANDS),
            weight = 20,
        },
        {
            id = item_sets.choice(ctx, player, sets.BLAST_WANDS),
            weight = 20,
        },
        {
            id = hex,
            weight = hex == ids.WAND_CHARMING and no_allies and 0 or 20,
        },
        {
            id = ids.WAND_MINDBURST,
            weight = 8,
        },
        {
            id = ids.WAND_POLYMORPH,
            weight = 5,
        },
        {
            id = ids.WAND_DIGGING,
            weight = 5,
        },
        {
            id = ids.WAND_FLAME,
            weight = 2,
        },
    }

    for _, row in ipairs(rows) do
        if row.weight > 0 and not selection.seen(ctx, player, row.id) then
            row.weight = row.weight * 2
        end
    end

    return selection.weighted(ctx, rows)
end

return wands
