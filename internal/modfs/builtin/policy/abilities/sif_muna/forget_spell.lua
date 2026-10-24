-- Sif's amnesia power selects one known spell and lets the spell-record
-- owner free its slot. Library knowledge remains available for later study.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local learning = require("policy.character.spell_learning")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local registry = require("policy.abilities.registry")
local spells = require("policy.religion.sif_muna.spells")

local forget = {}

-- Innate casters have no ordinary memorized list to erase.
function forget.available(ctx, player)
    return costs.available(ctx, player, gods.SIF_MUNA, 3) and
        mutation_levels.base(ctx, player,
            mutations.MUT_INNATE_CASTER) == 0
end

-- Choosing and confirming are free. The player can leave either prompt
-- without creating a timed intent or paying divine piety.
function forget.prepare(ctx, player, input)
    if input.cancelled then
        return "Okay."
    end

    local spell, prompt = spells.choose(ctx, player,
        input.spell_id, true, "Forget which spell?")

    if prompt then
        return prompt
    end

    if not input.forced then
        return {
            confirmation = "Forget " .. spell.name .. "?",
        }
    end

    return nil
end

-- The source has no invocation failure tuple for this amnesia power.
-- Revalidate the chosen slot before mutating it, then spend its piety.
function forget.resolve(ctx, player, intent)
    local spell, prompt = spells.choose(ctx, player,
        intent.spell_id, true, "Forget which spell?")

    if not spell or prompt then
        error("selected spell is no longer known")
    end

    local result = learning.forget(ctx, player, spell.id)

    if not result.forgotten then
        error("Sif Muna failed to forget selected spell")
    end

    costs.spend(ctx, player, 0, costs.piety_cost(ctx, 8))
end

registry.add(abilities.SIF_MUNA_FORGET_SPELL, {
    name = "Forget Spell",
    available = forget.available,
    prepare = forget.prepare,
    resolve = forget.resolve,
})

return forget
