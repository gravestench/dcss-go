local spells = require("ids.spells")
local monsters = require("ids.monsters")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

-- A blocked summon space is silent; report arrival only after spawn places the creature.
local function appeared(ctx, creature, message)
    if creature then
        ctx:emit("spell", message)
    end
end

-- Source: spl-summoning.cc:cast_summon_small_mammal.
local spell_effects = {}

-- Power shifts the species roll from bat or rat toward quokka; the shared spawner enforces the two-summon cap.
function spell_effects.resolve_summon_small_mammal(ctx, player, _, _, power)
    local kind_id = monsters.MONS_QUOKKA

    if summons.roll(ctx, math.max(10, power + 1)) < 10 then
        kind_id = summons.roll(ctx, 2) == 0 and monsters.MONS_BAT or monsters.MONS_RAT
    end

    local creature = summons.spawn(ctx, player,
        spells.SPELL_SUMMON_SMALL_MAMMAL, kind_id, 3, 2)
    appeared(ctx, creature, "A small mammal appears.")
end

registry.add(spells.SPELL_SUMMON_SMALL_MAMMAL, {
    resolve = spell_effects.resolve_summon_small_mammal,
})

-- Source: spl-summoning.cc:cast_call_canine_familiar.
function spell_effects.resolve_call_canine_familiar(ctx, player, _, _, power)
    local chance = power + summons.roll(ctx, 21) - 10
    local kind_id = monsters.MONS_HOUND

    if chance > 59 then
        kind_id = monsters.MONS_WARG
    elseif chance > 39 then
        kind_id = monsters.MONS_WOLF
    end

    local duration = math.min(2 + math.floor(summons.roll(ctx,
        math.max(1, power)) / 4), 6)
    local creature = summons.spawn(ctx, player,
        spells.SPELL_CALL_CANINE_FAMILIAR, kind_id, duration, 1)
    appeared(ctx, creature, "A canine familiar appears.")
end

registry.add(spells.SPELL_CALL_CANINE_FAMILIAR, {
    resolve = spell_effects.resolve_call_canine_familiar,
})

-- Example: Call Imp rolls an imp kind and a power-scaled duration before spawning it.
-- Source: spl-summoning.cc:_get_imp_type and cast_call_imp.
function spell_effects.resolve_call_imp(ctx, player, _, _, power)
    local kind_id = monsters.MONS_CRIMSON_IMP

    if summons.roll(ctx, 18) < 5 then
        kind_id = monsters.MONS_WHITE_IMP
    elseif summons.roll(ctx, 13) < 3 then
        kind_id = summons.roll(ctx, 3) == 0 and
            monsters.MONS_IRON_IMP or monsters.MONS_SHADOW_IMP
    end

    local duration = math.min(2 + math.floor(summons.roll(ctx,
        math.max(1, power)) / 4), 6)
    local creature = summons.spawn(ctx, player,
        spells.SPELL_CALL_IMP, kind_id, duration, 1)
    appeared(ctx, creature, "A little devil appears.")
end

registry.add(spells.SPELL_CALL_IMP, {
    resolve = spell_effects.resolve_call_imp,
})

-- Source: spl-summoning.cc:cast_summon_ice_beast.
function spell_effects.resolve_summon_ice_beast(ctx, player, _, _, power)
    local duration = math.min(2 + math.floor(summons.roll(ctx,
        math.max(1, power)) / 4), 4)
    local creature = summons.spawn(ctx, player,
        spells.SPELL_SUMMON_ICE_BEAST, monsters.MONS_ICE_BEAST, duration, 1, {
            hd = 3 + summons.divide(ctx, power, 13),
        })
    appeared(ctx, creature, "A chill wind blows around you.")
end

registry.add(spells.SPELL_SUMMON_ICE_BEAST, {
    resolve = spell_effects.resolve_summon_ice_beast,
})

-- Source: spl-summoning.cc:cast_summon_hydra.
function spell_effects.resolve_summon_hydra(ctx, player, _, _, power)
    local max_heads = summons.roll(ctx, 6) == 0 and 12 or 8
    local heads = math.max(4, math.min(math.floor(summons.roll(ctx,
        math.max(1, power)) / 6), max_heads))
    local creature = summons.spawn(ctx, player,
        spells.SPELL_SUMMON_HYDRA, monsters.MONS_HYDRA, 1, 2, {
            heads = heads,
        })
    appeared(ctx, creature, "A hydra appears.")
end

registry.add(spells.SPELL_SUMMON_HYDRA, {
    resolve = spell_effects.resolve_summon_hydra,
})

return spell_effects
