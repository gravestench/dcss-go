local catalog = require("policy.catalog")
local effects = require("policy.magic.effects.registry")
local player_ids = require("data.player_spell_ids")

local invoke = {}

-- Wands, artefacts, and abilities own their own item or ability costs.
-- Source: spl-cast.cc:your_spells(actual_spell=false). Their successful
-- activation reaches the same Lua effect without memorisation or miscast.
function invoke.resolve(ctx, player, input)
    local spell_id = input.spell_id

    if not player_ids.invoked[spell_id] then
        error("invalid invoked player effect " .. tostring(spell_id))
    end

    if type(input.power) ~= "number" or input.power < 0 then
        error("invoked player effect has invalid power")
    end

    local spell = catalog.get("spells", spell_id)
    local effect = effects.get(spell_id)

    if not effect then
        error("invoked player effect has no Lua resolver " .. spell_id)
    end

    local dx = input.dx or 0
    local dy = input.dy or 0

    if effect.prepare then
        local rejected = effect.prepare(ctx, player, spell, dx, dy)

        if rejected then
            return { message = rejected }
        end
    end

    effect.resolve(ctx, player, {
        dx = dx,
        dy = dy,
        forced = true,
        spell_id = spell_id,
    }, spell, input.power)

    return { invoked = true }
end

function invoke.run_policy(ctx, input)
    return invoke.resolve(ctx, ctx:player(), input)
end

register.policy({
    id = "magic.invoke_effect",
    run = invoke.run_policy,
})

return invoke
