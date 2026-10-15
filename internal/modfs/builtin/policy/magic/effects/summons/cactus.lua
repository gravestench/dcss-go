local spells = require("ids.spells")
local monsters = require("ids.monsters")
local hit_points = require("policy.population.hit_points")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

-- Source: spl-summoning.cc:cast_summon_cactus sets its HP from
-- hit_points(pow + 27, 1), then applies degree-three abjuration.
local spell_effects = {}

function spell_effects.resolve(ctx, player, _, _, power)
    local hp = hit_points.roll(ctx, (power + 27) * 10)
    local creature = summons.spawn(ctx, player,
        spells.SPELL_SUMMON_CACTUS, monsters.MONS_CACTUS_GIANT, 3, 1, {
            hp = hp,
        })

    if creature then
        ctx:emit("spell", "A cactus giant appears!")
    end
end

registry.add(spells.SPELL_SUMMON_CACTUS, {
    resolve = spell_effects.resolve,
})

return spell_effects
