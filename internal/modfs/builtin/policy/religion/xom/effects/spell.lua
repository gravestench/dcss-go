-- Xom casts one normal player spell as a divine effect. The source list is
-- ordered by required severity: a larger act exposes a longer prefix, not
-- a weighted set whose order depends on Lua file loading.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local events = require("ids.xom_events")
local registry = require("policy.magic.effects.registry")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

local source_order = {
    spells.SPELL_SUMMON_SMALL_MAMMAL,
    spells.SPELL_CALL_CANINE_FAMILIAR,
    spells.SPELL_OLGREBS_TOXIC_RADIANCE,
    spells.SPELL_SUMMON_ICE_BEAST,
    spells.SPELL_LEDAS_LIQUEFACTION,
    spells.SPELL_CAUSE_FEAR,
    spells.SPELL_INTOXICATE,
    spells.SPELL_SUMMON_MANA_VIPER,
    spells.SPELL_STATUE_FORM,
    spells.SPELL_SUMMON_CACTUS,
    spells.SPELL_DISPERSAL,
    spells.SPELL_ENGLACIATION,
    spells.SPELL_DEATH_CHANNEL,
    spells.SPELL_SUMMON_HYDRA,
    spells.SPELL_MONSTROUS_MENAGERIE,
    spells.SPELL_DISCORD,
    spells.SPELL_DISJUNCTION,
    spells.SPELL_SUMMON_HORRIBLE_THINGS,
    spells.SPELL_SUMMON_DRAGON,
    spells.SPELL_NECROMUTATION,
    spells.SPELL_CHAIN_OF_CHAOS,
}

-- Source spell_is_useless and transformation dry runs both happen before
-- the choice. A spell whose ordinary Lua resolver is not ported cannot be
-- forced safely, so leave it out until that spell is implemented.
local function usable(ctx, player, spell_id)
    local resolver = registry.get(spell_id)

    if not resolver then
        return false
    end

    local definition = catalog.get(categories.SPELLS, spell_id)

    if resolver.prepare and resolver.prepare(ctx, player,
        definition, 0, 0, { forced = true }) then
        return false
    end

    if resolver.can_target and
        not resolver.can_target(ctx, player, definition) then
        return false
    end

    return true
end

-- Selection and effect application each choose from the live usable list,
-- as the source probes once in its gate and once again when it casts.
function effect.choose(ctx, player, severity, stream)
    stream = stream or streams.RELIGION
    local available = {}
    local count = math.min(math.max(1, severity), #source_order)

    for index = 1, count do
        local spell_id = source_order[index]

        if usable(ctx, player, spell_id) then
            available[#available + 1] = spell_id
        end
    end

    if #available == 0 then
        return nil
    end

    local index = #available == 1 and 1 or
        ctx:random(stream, #available) + 1

    return available[index]
end

-- Invoke the same resolver as a player cast, but Xom supplies power equal
-- to event severity and pays neither a spell slot, MP, nor a miscast roll.
function effect.apply(ctx, player, event_id, severity, request)
    if event_id ~= events.GOOD_SPELL then
        error("spell effect received another Xom event")
    end

    local stream = request and request.stream or streams.RELIGION
    local spell_id = effect.choose(ctx, player, severity, stream)

    if not spell_id then
        return nil
    end

    local definition = catalog.get(categories.SPELLS, spell_id)
    local resolver = registry.get(spell_id)

    ctx:emit(channels.RELIGION,
        "Xom makes you cast " .. definition.name .. "!")

    resolver.resolve(ctx, player, {
        dx = 0,
        dy = 0,
        forced = true,
        spell_id = spell_id,
    }, definition, severity)

    return spell_id
end

return effect
