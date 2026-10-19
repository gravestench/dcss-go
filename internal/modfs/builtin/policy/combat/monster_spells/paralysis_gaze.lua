-- The floating eye's gaze bypasses willpower but respects paralysis
-- immunity and monster stasis before storing a lasting ECS status.
local catalog = require("policy.catalog")
local component = require("constants.component")
local channels = require("constants.message_channels")
local forms = require("policy.magic.effects.forms.player")
local gazes = require("policy.combat.monster_gazes")
local flags = require("constants.monster_flags")
local monster_paralysis = require(
    "policy.magic.effects.zaps.paralysis")
local traits = require("policy.character.species_traits")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

-- A direct sight plan preserves the selected victim through the scheduler.
function effect.plan(ctx, caster, foe)
    return gazes.plan(ctx, caster, foe,
        spells.SPELL_PARALYSIS_GAZE)
end

-- Source rolls two to four turns without a will save. A current player
-- paralysis blocks repetition; the shared timer owner ages the result.
-- Example: a floating eye still paralyses through an intervening ally.
function effect.resolve(ctx, caster, foe, _, plan)
    gazes.require(ctx, caster, foe, plan)

    if ctx:has(foe, component.PLAYER) then
        local identity = ctx:get(foe, component.PLAYER)
        local species = catalog.get("species", identity.species_id)

        if traits.stasis(species) or forms.stasis(ctx, foe) then
            ctx:emit(channels.SPELL,
                "Your stasis prevents you from being paralysed.")

            return
        end

        local current = ctx:get(foe, component.PLAYER_PARALYSIS)

        if current and current.remaining_aut > 0 then
            ctx:emit(channels.SPELL,
                "You shrug off the repeated paralysis!")

            return
        end

        local turns = 2 + ctx:random(streams.MONSTER_SPELL, 3)

        local status = {
            remaining_aut = turns * 10,
        }

        if current then
            ctx:set(foe, component.PLAYER_PARALYSIS, status)
        else
            ctx:add(foe, component.PLAYER_PARALYSIS, status)
        end
        ctx:emit(channels.SPELL,
            "You suddenly lose the ability to move!")

        return
    end

    local actor = ctx:get(foe, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STASIS then
            return
        end
    end

    -- Source monster paralysis refuses an already paralysed target before
    -- another strength roll, so a gaze cannot refresh its timer.
    local current = ctx:get(foe, component.PARALYSIS)

    if current and current.remaining_aut > 0 then
        return
    end

    local strength = 2 + ctx:random(streams.MONSTER_SPELL, 3)

    monster_paralysis.apply_unresisted(ctx, foe, definition, strength)
end

return effect
