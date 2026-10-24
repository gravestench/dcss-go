-- Divine Exegesis casts an existing library spell once. It uses the same
-- targeting, spell resource, effect, and conduct owners as ordinary casting;
-- only learned-slot eligibility, power, and failure differ.
local abilities = require("ids.abilities")
local cast_command = require("policy.commands.cast")
local casting = require("policy.magic.cast")
local channels = require("constants.message_channels")
local command_kind = require("constants.command_kind")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local registry = require("policy.abilities.registry")
local spells = require("policy.religion.sif_muna.spells")
local selection_kinds = require("constants.selection_kinds")

local exegesis = {}

-- The source unlocks library casting at four Sif stars.
function exegesis.available(ctx, player)
    return costs.available(ctx, player, gods.SIF_MUNA, 4)
end

-- Reuse ordinary spell preflight after a free library selection. Setting
-- FORCE_CAST suppresses only the optional no-hostile prompt, as in source.
function exegesis.prepare(ctx, player, input)
    if input.cancelled then
        return "Okay."
    end

    local spell, prompt = spells.choose(ctx, player,
        input.spell_id, false, "Cast which spell?")

    if prompt then
        return prompt
    end

    -- The spell choice is free. A targeted spell needs a second, equally
    -- free cell choice before ordinary cast preflight can check its range.
    if cast_command.requires_aim(spell) and
        (input.dx or 0) == 0 and (input.dy or 0) == 0 then
        return {
            selection = {
                kind = selection_kinds.CELL,
                title = "Aiming: " .. spell.name,
            },
        }
    end

    local request = {
        kind = command_kind.FORCE_CAST,
        spell_id = spell.id,
        dx = input.dx,
        dy = input.dy,
        forced = input.forced,
    }
    local decision = cast_command.prepare(ctx, player,
        request, true)

    if decision.message then
        return decision.message
    end

    if decision.confirmation then
        return { confirmation = decision.confirmation }
    end

    return nil
end

-- Invocation failure consumes time but refunds the attempted spell cost.
-- Success pays the spell's real resource through casting and one rolled
-- twelve-point piety cost after its existing effect dispatch.
function exegesis.resolve(ctx, player, intent, aut)
    local spell = spells.choose(ctx, player,
        intent.spell_id, false, "Cast which spell?")

    if not spell then
        error("selected Exegesis spell is no longer in the library")
    end

    if costs.failed(ctx, player, 80, 4, 25) then
        ctx:emit(channels.RELIGION, "You fail to use your ability.")

        return
    end

    casting.resolve(ctx, player, intent, aut, true)
    costs.spend(ctx, player, 0, costs.piety_cost(ctx, 12))
end

registry.add(abilities.SIF_MUNA_DIVINE_EXEGESIS, {
    name = "Divine Exegesis",
    available = exegesis.available,
    prepare = exegesis.prepare,
    resolve = exegesis.resolve,
})

return exegesis
