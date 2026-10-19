local catalog = require("policy.catalog")
local effects = require("policy.magic.effects.registry")
local failure = require("policy.magic.failure")
local power = require("policy.magic.power")
local records = require("policy.character.spell_records")
local resources = require("policy.magic.resources")
local demonic_magic = require("policy.character.demonic_magic")
local hex_status = require("policy.combat.monster_hexes.status")
local streams = require("constants.rng_streams")

local cast = {}

-- Source: spl-cast.cc:cast_a_spell and your_spells. Preparation already
-- resolved all no-time aborts before the scheduler began this action.
function cast.resolve(ctx, player, intent, aut)
    local spell_id = intent.spell_id
    local known = records.find(ctx, player, spell_id)
    local effect = effects.get(spell_id)

    if not known or known.state.known_slot == 0 or not effect then
        error("player spell intent has no known Lua effect " .. spell_id)
    end

    local spell = catalog.get("spells", spell_id)
    local casting = ctx:get(player, "character.spellcasting")

    casting.last_spell_id = spell_id
    ctx:set(player, "character.spellcasting", casting)
    resources.pay(ctx, player,
        resources.spell_cost(ctx, player, spell.level))

    local profile = failure.profile(ctx, player, spell)

    if failure.roll(ctx, profile.raw) then
        ctx:emit("spell", "You miscast " .. spell.name .. ".")

        return "fail"
    end

    effect.resolve(ctx, player, intent, spell,
        power.cast(ctx, player, spell), aut)
    demonic_magic.on_success(ctx, player, spell)

    -- In DCSS, Sap Magic punishes successful casting with a short period
    -- during which no further spell can be started.
    if hex_status.sapped(ctx, player) then
        local turns = 3 + ctx:random(streams.MONSTER_SPELL, 3)

        hex_status.no_cast(ctx, player, turns * 10)
        ctx:emit("spell", "Your magic is temporarily exhausted.")
    end

    return "success"
end

return cast
