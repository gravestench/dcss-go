-- These tests exercise the source spells against real ECS components. The
-- sparse grid fixture only supplies position, occupancy, and deterministic RNG.
local component = require("constants.component")
local chaos_effects = require("policy.combat.player_brands.chaos_effects")
local chaos_ids = require("constants.chaos_effects")
local catalog = require("policy.catalog")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local save_summons = require("policy.save.summons")
local spells = require("ids.spells")

local test = {}

-- A carried weapon must become a second item entity, not a second holder
-- reference to the original weapon's mutable instance.
local function give_weapon(ctx, holder)
    local weapon = ctx:create()

    ctx:add(weapon, component.ITEM, {
        kind_id = items.WPN_DAGGER,
        quantity = 1,
        plus = 2,
        charges = 0,
        ego = "",
    })
    ctx:add(weapon, component.CARRIED_BY, { holder = holder })
    ctx:add(weapon, component.EQUIPPED, { slot = "weapon" })

    return weapon
end

-- Find the actor with the requested source spell while leaving all other
-- summons in the same ECS world available for cap and allegiance tests.
local function copies(ctx, source_id)
    local found = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local summon = ctx:get(entity, component.SUMMON)

        if summon.source_id == source_id then
            found[#found + 1] = entity
        end
    end

    return found
end

-- The copy must have its own item record and ownership link, while both
-- items retain the source weapon's identity and enchantment.
local function copied_weapon(ctx, source, clone, original)
    local twin

    for _, item in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
    })) do
        if ctx:get(item, component.CARRIED_BY).holder == clone then
            twin = item
        end
    end

    harness.truthy(twin, "mirror copy carries its own weapon entity")
    harness.falsy(twin == original,
        "copy cannot share the source item entity")
    harness.equal(ctx:get(twin, component.ITEM).plus,
        ctx:get(original, component.ITEM).plus,
        "mirror copies current equipment properties")
    harness.equal(ctx:get(twin, component.EQUIPPED).slot, "weapon",
        "copied weapon remains equipped")
    harness.equal(ctx:get(original, component.CARRIED_BY).holder, source,
        "source keeps its own weapon")
end

-- Mara fills exactly two active fake slots, with half its current and
-- maximum life. A fake cannot itself invoke either mirror spell.
local function mara_copies(ctx, game)
    local mara = fixture.actor(ctx, monsters.MONS_MARA, 20, 20, 50)
    local source_weapon = give_weapon(ctx, mara)
    local effect = effects.effect(spells.SPELL_FAKE_MARA_SUMMON)
    local plan = effect.plan(game, mara)

    ctx:add(mara, component.MONSTER_CONFUSION, {
        remaining_aut = 40,
    })

    harness.truthy(plan, "real Mara can plan fake summoning")
    effect.resolve(game, mara, nil, nil, plan)

    local created = copies(ctx, spells.SPELL_FAKE_MARA_SUMMON)

    harness.equal(#created, 2,
        "one cast fills the source two-fake limit")

    for _, copy in ipairs(created) do
        local health = ctx:get(copy, component.HEALTH)
        local summon = ctx:get(copy, component.SUMMON)

        harness.equal(ctx:get(copy, component.ACTOR).kind_id,
            monsters.MONS_MARA, "fake retains Mara's species")
        harness.equal(health.current, 25,
            "fake has half current life")
        harness.equal(health.max, 50,
            "fake has half maximum life")
        harness.equal(summon.owner, mara,
            "fake retains Mara as summon owner")
        harness.truthy(ctx:has(copy, component.SUMMON_MIRROR),
            "fake keeps its nonrecursive mirror marker")
        harness.equal(ctx:get(copy, component.MONSTER_CONFUSION).remaining_aut,
            40, "fake retains an internal timed body condition")
        harness.falsy(effect.plan(game, copy),
            "a fake cannot make more fake Maras")
        copied_weapon(ctx, mara, copy, source_weapon)
    end

    harness.falsy(effect.plan(game, mara),
        "real Mara declines a cast at two fakes")

    local position = ctx:get(mara, component.POSITION)
    local ai = ctx:get(created[1], component.AI)
    local actor = ctx:get(created[1], component.ACTOR)
    local copy_position = ctx:get(created[1], component.POSITION)
    local summon = ctx:get(created[1], component.SUMMON)

    ai.target_x = ai.target_x or 0
    ai.target_y = ai.target_y or 0
    ai.memory_until_aut = ai.memory_until_aut or 0

    local ok, err = pcall(save_summons.validate, game,
        created[1], actor, copy_position, ai, summon, 0)

    harness.truthy(ok, "fake validates after save: " .. tostring(err))

    local marker = ctx:get(created[1], component.SUMMON_MIRROR)

    marker.hp_percent = 100
    ctx:set(created[1], component.SUMMON_MIRROR, marker)

    ok = pcall(save_summons.validate, game,
        created[1], actor, copy_position, ai, summon, 0)

    harness.falsy(ok, "restore rejects forged fake Mara life scale")
    harness.truthy(position, "source remains placed after clone swap")

    -- Polymorph changes the current species without changing the original
    -- mirror identity recorded at creation. That state must remain savable.
    marker.hp_percent = 50
    ctx:set(created[1], component.SUMMON_MIRROR, marker)
    actor.kind_id = monsters.MONS_RAT
    ctx:set(created[1], component.ACTOR, actor)
    ctx:add(created[1], component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_MARA,
    })

    ok, err = pcall(save_summons.validate, game,
        created[1], actor, copy_position, ai, summon, 0)

    harness.truthy(ok, "polymorphed mirror validates: " .. tostring(err))
end

-- Rakshasa mirror chooses a live aligned ordinary monster, not the caster,
-- a unique, a summoned ally, or a foe.
local function phantom_copies(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_RAKSHASA, 50, 20)
    local ally = fixture.actor(ctx, monsters.MONS_ORC, 52, 20, 37)
    local unique = fixture.actor(ctx, monsters.MONS_MARA, 53, 20)
    local summoned = fixture.actor(ctx, monsters.MONS_ORC, 54, 20)
    local weapon = give_weapon(ctx, ally)
    local effect = effects.effect(spells.SPELL_PHANTOM_MIRROR)

    ctx:add(ally, component.PLAYER_CONSTRICTION, {
        by = game:player(),
        escape_attempts = 0,
    })
    ctx:add(ally, component.MONSTER_BOONS, {
        haste_aut = 30,
        might_aut = 20,
    })
    ctx:add(ally, component.PROJECTILE_POISON, {
        degree = 2,
        remaining_aut = 15,
        max_aut = 30,
        source = game:player(),
    })

    ctx:add(summoned, component.SUMMON, {
        owner = caster,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        expires_aut = 100,
    })

    local plan = effect.plan(game, caster)

    harness.truthy(plan, "one ordinary ally permits Phantom Mirror")
    effect.resolve(game, caster, nil, nil, plan)

    local created = copies(ctx, spells.SPELL_PHANTOM_MIRROR)

    harness.equal(#created, 1,
        "Phantom Mirror creates one selected ally copy")
    harness.equal(ctx:get(created[1], component.ACTOR).kind_id,
        monsters.MONS_ORC, "unique and summoned actors are excluded")
    harness.equal(ctx:get(created[1], component.HEALTH).current, 37,
        "Phantom Mirror keeps current life")
    harness.equal(ctx:get(created[1], component.HEALTH).max, 100,
        "Phantom Mirror keeps maximum life")
    harness.truthy(ctx:has(created[1], component.SUMMON_MIRROR),
        "Phantom Mirror has its saved nonrecursive marker")
    harness.equal(ctx:get(created[1], component.MONSTER_BOONS).haste_aut,
        30, "mirror retains active Haste")
    harness.equal(ctx:get(created[1], component.PROJECTILE_POISON).degree,
        2, "mirror retains monster poison")
    harness.falsy(ctx:has(ally, component.PLAYER_CONSTRICTION),
        "a successful mirror frees the original from direct constriction")
    harness.falsy(ctx:has(created[1], component.PLAYER_CONSTRICTION),
        "the duplicate does not inherit an outside constrictor")
    harness.equal(ctx:get(created[1], component.POSITION).x, 52,
        "source coin flip swaps the copy into the original cell")
    copied_weapon(ctx, ally, created[1], weapon)
    harness.falsy(effect.plan(game, created[1]),
        "a mirrored copy cannot mirror again")

    -- The original can be mirrored again, but the summoned copy cannot
    -- become the seed of exponential duplication.
    harness.truthy(effect.plan(game, caster),
        "original ordinary ally remains mirrorable")
    harness.truthy(ctx:get(unique, component.HEALTH),
        "ineligible unique remains untouched")

    -- Chaos can split an ordinary mirror copy. The extra summon must keep
    -- its mirror marker so it cannot recurse and can pass save validation.
    local before = #ctx:query({ component.CHAOS_CLONE })

    chaos_effects.apply_named(game, chaos_ids.CLONE, {
        attacker = game:player(),
        defender = created[1],
        definition = catalog.get("monsters", monsters.MONS_ORC),
        damage_done = 1,
        health = ctx:get(created[1], component.HEALTH),
    })

    local chaos_clones = ctx:query({ component.CHAOS_CLONE })

    harness.equal(#chaos_clones, before + 1,
        "chaos splits an ordinary mirror summon")

    local chaos_twin = chaos_clones[#chaos_clones]
    local chaos_actor = ctx:get(chaos_twin, component.ACTOR)
    local chaos_position = ctx:get(chaos_twin, component.POSITION)
    local chaos_ai = ctx:get(chaos_twin, component.AI)
    local chaos_summon = ctx:get(chaos_twin, component.SUMMON)

    chaos_ai.target_x = chaos_ai.target_x or 0
    chaos_ai.target_y = chaos_ai.target_y or 0
    chaos_ai.memory_until_aut = chaos_ai.memory_until_aut or 0

    local ok, err = pcall(save_summons.validate, game,
        chaos_twin, chaos_actor, chaos_position, chaos_ai,
        chaos_summon, 0)

    harness.truthy(ctx:has(chaos_twin, component.SUMMON_MIRROR),
        "chaos copy retains the mirror restriction")
    harness.truthy(ok, "chaos mirror validates: " .. tostring(err))
end

-- A blocked Mara attempt spends its cast without leaving a partial actor
-- or a copied item, because placement is the first mutating clone step.
local function blocked_mara(ctx, game)
    local mara = fixture.actor(ctx, monsters.MONS_MARA, 90, 20, 30)
    local effect = effects.effect(spells.SPELL_FAKE_MARA_SUMMON)
    local plan = effect.plan(game, mara)
    local before = #copies(ctx, spells.SPELL_FAKE_MARA_SUMMON)

    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(90 + dx) .. ":" .. (20 + dy)] = true
            end
        end
    end

    effect.resolve(game, mara, nil, nil, plan)

    harness.equal(#copies(ctx, spells.SPELL_FAKE_MARA_SUMMON),
        before, "blocked mirror has no partial summon")
end

-- Each subcase has separate map space so the source's adjacent placement
-- and cap checks run through the ordinary shared summon owner.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 3, 3)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})

    function game:random()
        return 0
    end

    mara_copies(ctx, game)
    phantom_copies(ctx, game)
    blocked_mara(ctx, game)

end

return test
