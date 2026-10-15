-- Generated from the pinned ordered DCSS mutation conflict table.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation.cc:conflict

local mutations = require("ids.mutations")
local outcomes = require("constants.mutation_conflict_outcomes")

local conflicts = {
    {
        first = mutations.MUT_REGENERATION,
        second = mutations.MUT_SLOW_METABOLISM,
        outcome = outcomes.IGNORE_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_REGENERATION,
        second = mutations.MUT_INHIBITED_REGENERATION,
        outcome = outcomes.IGNORE_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_FAST,
        second = mutations.MUT_SLOW,
        outcome = outcomes.IGNORE_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_STRONG_STIFF,
        second = mutations.MUT_FLEXIBLE_WEAK,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_STRONG,
        second = mutations.MUT_WEAK,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_CLEVER,
        second = mutations.MUT_DOPEY,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_AGILE,
        second = mutations.MUT_CLUMSY,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_ROBUST,
        second = mutations.MUT_FRAIL,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_HIGH_MAGIC,
        second = mutations.MUT_LOW_MAGIC,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_WILD_MAGIC,
        second = mutations.MUT_SUBDUED_MAGIC,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_CARNIVOROUS,
        second = mutations.MUT_HERBIVOROUS,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_SLOW_METABOLISM,
        second = mutations.MUT_FAST_METABOLISM,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_REGENERATION,
        second = mutations.MUT_INHIBITED_REGENERATION,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_BERSERK,
        second = mutations.MUT_CLARITY,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_FAST,
        second = mutations.MUT_SLOW,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_MUTATION_RESISTANCE,
        second = mutations.MUT_DEVOLUTION,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_EVOLUTION,
        second = mutations.MUT_DEVOLUTION,
        outcome = outcomes.TRADE_ONE,
    },
    {
        first = mutations.MUT_MUTATION_RESISTANCE,
        second = mutations.MUT_EVOLUTION,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_FANGS,
        second = mutations.MUT_BEAK,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_ANTENNAE,
        second = mutations.MUT_HORNS,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_HOOVES,
        second = mutations.MUT_TALONS,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_CLAWS,
        second = mutations.MUT_DEMONIC_TOUCH,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_TRANSLUCENT_SKIN,
        second = mutations.MUT_CAMOUFLAGE,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_ANTIMAGIC_BITE,
        second = mutations.MUT_ACIDIC_BITE,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_HEAT_RESISTANCE,
        second = mutations.MUT_HEAT_VULNERABILITY,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_COLD_RESISTANCE,
        second = mutations.MUT_COLD_VULNERABILITY,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_SHOCK_RESISTANCE,
        second = mutations.MUT_SHOCK_VULNERABILITY,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_STRONG_WILLED,
        second = mutations.MUT_WEAK_WILLED,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_NO_REGENERATION,
        second = mutations.MUT_INHIBITED_REGENERATION,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_NO_REGENERATION,
        second = mutations.MUT_REGENERATION,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_HP_CASTING,
        second = mutations.MUT_HIGH_MAGIC,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
    {
        first = mutations.MUT_HP_CASTING,
        second = mutations.MUT_LOW_MAGIC,
        outcome = outcomes.BLOCK_UNLESS_FORCED,
    },
}

return conflicts
