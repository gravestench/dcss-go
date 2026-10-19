local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

-- Source: spl-summoning.cc:cast_summon_mana_viper.
local spell_effects = {}

-- Example: Summon Mana Viper scales the summoned viper's HD from cast power.
-- Convert power into viper HD while the shared spawner handles placement and degree-two expiry.
function spell_effects.resolve_summon_mana_viper(ctx, player, _, _, power)
    local creature = summons.spawn(ctx, player,
        spells.SPELL_SUMMON_MANA_VIPER, monsters.MONS_MANA_VIPER, 2, 1, {
            hd = 5 + summons.divide(ctx, power, 12),
        })

    if creature then
        ctx:emit("spell", "A mana viper appears with a sibilant hiss.")
    end
end

registry.add(spells.SPELL_SUMMON_MANA_VIPER, {
    resolve = spell_effects.resolve_summon_mana_viper,
})

-- Source: spl-summoning.cc:cast_monstrous_menagerie.
function spell_effects.resolve_monstrous_menagerie(ctx, player, _, _, power)
    local kind_id

    if summons.roll(ctx, math.max(1, power)) > 60 and
        summons.roll(ctx, 2) == 0 then
        kind_id = monsters.MONS_SPHINX
    else
        kind_id = summons.roll(ctx, 2) == 0 and
            monsters.MONS_MANTICORE or monsters.MONS_LINDWURM
    end

    local creature = summons.spawn(ctx, player,
        spells.SPELL_MONSTROUS_MENAGERIE, kind_id, 4, 2, {
            hd = catalog.get("monsters", kind_id).hd +
                summons.divide(ctx, power - 50, 25),
        })

    if creature then
        ctx:emit("spell", "A fearsome beast appears.")
    end
end

registry.add(spells.SPELL_MONSTROUS_MENAGERIE, {
    resolve = spell_effects.resolve_monstrous_menagerie,
})

-- Source: spl-summoning.cc:cast_summon_horrible_things.
function spell_effects.resolve_summon_horrible_things(ctx, player, _, _, power)
    local origin = ctx:get(player, "character.origin")

    if origin and origin.religion == "GOD_NO_GOD" and
        summons.roll(ctx, 5) == 0 then
        local attributes = ctx:get(player, component.ATTRIBUTES)
        attributes.intelligence = math.max(0, attributes.intelligence - 1)
        ctx:set(player, component.ATTRIBUTES, attributes)
        ctx:emit("spell", "Your mind reels at the horrible sight.")
    end

    local abominations = 2 + summons.roll(ctx, 3)

    if summons.roll(ctx, 200) < power then
        abominations = abominations + 1
    end

    local tentacled = 0

    if summons.roll(ctx, math.max(1, power)) > 120 then
        tentacled = 2
    elseif summons.roll(ctx, math.max(1, power)) > 50 then
        tentacled = 1
    end

    if tentacled == 0 then
        abominations = abominations + 1
    end

    local count = 0

    for _ = 1, abominations do
        if summons.spawn(ctx, player, spells.SPELL_SUMMON_HORRIBLE_THINGS,
            monsters.MONS_ABOMINATION_LARGE, 3, 8) then
            count = count + 1
        end
    end

    for _ = 1, tentacled do
        if summons.spawn(ctx, player, spells.SPELL_SUMMON_HORRIBLE_THINGS,
            monsters.MONS_TENTACLED_MONSTROSITY, 3, 8) then
            count = count + 1
        end
    end

    if count > 0 then
        ctx:emit("spell", "Horrible things crowd into view.")
    end
end

registry.add(spells.SPELL_SUMMON_HORRIBLE_THINGS, {
    resolve = spell_effects.resolve_summon_horrible_things,
})

return spell_effects
