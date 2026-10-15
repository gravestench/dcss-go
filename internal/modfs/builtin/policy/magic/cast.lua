local catalog = require("policy.catalog")
local effects = require("policy.magic.effects.registry")
local failure = require("policy.magic.failure")
local power = require("policy.magic.power")
local records = require("policy.character.spell_records")
local resources = require("policy.magic.resources")
local demonic_magic = require("policy.character.demonic_magic")

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

    return "success"
end

return cast
