local abilities = require("policy.commands.abilities")
local cast = require("policy.commands.cast")
local commands = require("policy.input.commands")
local intent = require("constants.intent")
local registry = require("policy.commands.registry")
local spell_learning = require("policy.character.spell_learning")

local entries = {}

-- Magic command entries keep memorisation, casting, and mutation abilities on distinct preparation paths.
function entries.memorise(ctx, player, input)
    local spell_id = input.spell_id
    local rejection = spell_learning.cannot_begin(ctx, player, spell_id)

    if rejection then
        return {
            message = rejection,
        }
    end

    return {
        intent = {
            kind = intent.MEMORISE,
            spell_id = spell_id,
        },
        cost = 10,
    }
end

-- Delegate cast validation to the spell command before the entry point commits action time.
-- Example: entries.cast(ctx, player, { spell_id = spell_id }) delegates spell checks before time is spent.
function entries.cast(ctx, player, input)
    return cast.prepare(ctx, player, input)
end

-- Ability preparation checks availability before a timed resolve intent is emitted.
function entries.ability(ctx, player, input)
    return abilities.prepare(ctx, player, input)
end

registry.register(commands.memorise, entries.memorise)
registry.register(commands.cast, entries.cast)
registry.register(commands.force_cast, entries.cast)
registry.register(commands.ability, entries.ability)

return entries
