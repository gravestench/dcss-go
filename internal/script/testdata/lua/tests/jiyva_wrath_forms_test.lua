-- Jiyva's five hostile shapes use the same saved form and action rules as
-- other transformations; each source choice needs a live transition.
local component = require("constants.component")
local brands = require("constants.weapon_brands")
local categories = require("constants.catalog")
local form_ids = require("constants.form_ids")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local wrath = require("policy.religion.wrath.jiyva")
local forms = require("policy.magic.effects.forms.player")
local navigation = require("policy.commands.navigation")
local fixture = require("tests.monster_ally_support_fixture")
local catalog = require("policy.catalog")
local target_brands = require("policy.combat.monster_target_brands")
local fighter = require("policy.combat.fighter")
local resistance = require("policy.combat.player_resistance")
local damage = require("policy.magic.damage")
local resistance_ids = require("constants.resistance_ids")

local test = {}

-- Use real player components so form health scaling and the saved timer are
-- checked through the production owner rather than copied into this test.
local function player_at(ctx, x)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, x, 10, 30)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Fungal test",
        starting_weapon_id = items.WPN_UNARMED,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.COMBAT, { shield_blocks = 0 })
    ctx:add(player, component.PROGRESSION, { level = 10 })
    ctx:add(player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NO_GOD,
        penance = { [gods.JIYVA] = 10 },
    })

    return player
end

-- The first two gates select the transformation branch; the next draw
-- chooses a form and the final draw chooses its source power.
local function choice(ctx, index, x)
    local player = player_at(ctx, x)
    local owner = fixture.context(ctx, player)
    local cards = { 1, 0, index, 5, 0 }
    local used = 0

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            used = used + 1
            local value = cards[used]

            harness.truthy(value ~= nil and value < bound,
                "unexpected Jiyva wrath draw")
            return value
        end

        return ctx:random(stream, bound)
    end

    harness.truthy(wrath.apply(owner, player))

    return owner, player, used
end

-- All five source slots must create a real, uncancellable player form.
local function five_shapes(ctx)
    local expected = {
        form_ids.BAT,
        form_ids.FUNGUS,
        form_ids.PIG,
        form_ids.TREE,
        form_ids.WISP,
    }

    for index, id in ipairs(expected) do
        local _, player, used = choice(ctx, index - 1, 10 + index * 3)
        local state = ctx:get(player, component.PLAYER_FORM)

        harness.equal(state.form_id, id)
        harness.truthy(state.uncancellable)
        harness.truthy(state.remaining_aut >= 150)
        harness.equal(used, 5)
    end
end

-- Fungus Form permits attacking an adjacent watcher, but forbids walking
-- away until threatening monsters can no longer see the player.
local function fungus_fear(ctx)
    local player = player_at(ctx, 42)
    local owner = fixture.context(ctx, player)
    local position = ctx:get(player, component.POSITION)

    ctx:add(player, component.PLAYER_FORM, {
        form_id = form_ids.FUNGUS,
        remaining_aut = 150,
        power = 10,
        appendage_mask = 0,
        uncancellable = true,
    })

    harness.falsy(forms.nervous(owner, player))
    local foe = fixture.actor(ctx, monsters.MONS_ORC, 43, 10)

    harness.truthy(forms.nervous(owner, player))
    harness.truthy(navigation.move(owner, position, 0, 1).message)
    harness.truthy(navigation.move(owner, position, 1, 0).attack_target == foe)
    harness.equal(forms.modifiers(owner, player).unarmed_base, 12)
    harness.equal(resistance.poison(owner, player), 1)
    harness.equal(damage.player_resistance(owner, player,
        resistance_ids.NEGATIVE_ENERGY), 3)
    harness.falsy(forms.slot_usable(owner, player, "weapon"))

    -- A landed spore checks the target's breathing physiology and HD, then
    -- writes the same confusion component as other monster enchantments.
    function owner:random(stream, bound)
        if stream == streams.MELEE and bound == 100 then
            return 99
        end

        return 0
    end

    local orc = catalog.get(categories.MONSTERS, monsters.MONS_ORC)

    local attack = fighter.attack(owner, orc)

    harness.equal(attack.weapon_brand, brands.CONFUSE)
    harness.truthy(attack.form_uses_level)
    harness.equal(attack.weapon100, 1000)

    target_brands.apply(owner, brands.CONFUSE, {
        attacker = player,
        defender = foe,
        definition = orc,
        damage_done = 1,
        health = ctx:get(foe, component.HEALTH),
    })
    harness.truthy(ctx:has(foe, component.MONSTER_CONFUSION))

    local mummy = fixture.actor(ctx, monsters.MONS_MUMMY, 44, 10)

    target_brands.apply(owner, brands.CONFUSE, {
        attacker = player,
        defender = mummy,
        definition = catalog.get(categories.MONSTERS, monsters.MONS_MUMMY),
        damage_done = 1,
        health = ctx:get(mummy, component.HEALTH),
    })
    harness.falsy(ctx:has(mummy, component.MONSTER_CONFUSION))
end

-- Run source-choice and live-body checks in one rule transaction so each
-- assertion observes the same component schemas used during gameplay.
function test.run(ctx)
    five_shapes(ctx)
    fungus_fear(ctx)
end

return test
