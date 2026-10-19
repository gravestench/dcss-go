-- Source: actor.cc:actor::angry and melee-attack.cc:check_autoberserk.
local capabilities = require("constants.mutation_capabilities")
local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local flags = require("constants.monster_flags")
local mutations = require("ids.mutations")
local rage = require("policy.character.rage")

local berserk = {}

-- Check source monster flags before rolling: harmless stationary targets
-- should not let the player farm berserk triggers without real combat.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Exclude stationary no-XP targets before mutation RNG, then try rage on a valid melee attempt.
-- Example: a melee attempt at positive Berserk mutation level tests its mutation-stream trigger.
function berserk.on_melee_attempt(level, ctx, player, attack)
    local actor = ctx:get(attack.target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local firewood = has_flag(definition, flags.STATIONARY) and
        has_flag(definition, flags.NO_EXP_GAIN)

    if firewood then
        return
    end

    if ctx:random("mutation", 100) < 3 ^ level then
        rage.begin(ctx, player)
    end
end

effects.add(mutations.MUT_BERSERK, {
    [capabilities.ON_MELEE_ATTEMPT] = berserk.on_melee_attempt,
})

return berserk
