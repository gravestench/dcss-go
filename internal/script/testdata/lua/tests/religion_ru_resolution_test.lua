-- Rejecting Ru's three saved offers clears every choice and lengthens the
-- next interval. Cancellation is handled before this paid resolution path.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local ids = require("ids.ru_sacrifices")
local mutations = require("ids.mutations")
local species = require("ids.species")
local jobs = require("ids.jobs")
local levels = require("policy.mutations.levels")
local abilities = require("policy.abilities.registry")
local ability_ids = require("ids.abilities")
local hand = require("policy.religion.ru.consequences.hand")
local slots = require("constants.jewellery_slots")
local transition = require("policy.mutations.transition")
local classes = require("constants.mutation_classes")
local commands = require("policy.commands.abilities")
local resolution = require("policy.religion.ru.resolution")
local ru_god = require("policy.religion.gods.ru")
local experience_limit = require("policy.character.experience_limit")

local test = {}

-- Source normal rejection uses the faith-penalty reset branch even when
-- the player is not wearing Faith: 90 + 33 + twice 33 = 189 progress.
function test.run(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = 10,
    })
    ctx:add(player, component.RELIGION_RU, {
        sacrifice_progress = 50,
        sacrifice_delay = 50,
        sacrifice_penalty = 0,
        available = { ids.HEALTH },
        health = { mutations.MUT_FRAIL },
        essence = {},
        purity = {},
        arcana = {},
        quoted_piety = {
            [ids.HEALTH] = 32,
        },
    })

    function game:random()
        error("exact rejection delay should spend no RNG")
    end

    resolution.reject(game, player)

    local state = ctx:get(player, component.RELIGION_RU)

    harness.equal(state.sacrifice_progress, 0)
    harness.equal(state.sacrifice_delay, 189)
    harness.equal(state.sacrifice_penalty, 33)
    harness.equal(state.sacrifice_mutations, 0)
    harness.equal(#state.available, 0)
    harness.equal(#state.health, 0)
    harness.truthy(next(state.quoted_piety) == nil)

    -- Acceptance reads the saved quote, grants a permanent rank, and
    -- closes the full choice set. The catalog and registry are production.
    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Ru resolution test",
    })

    state.available = { ids.HEALTH }
    state.health = { mutations.MUT_FRAIL }
    state.quoted_piety = {
        [ids.HEALTH] = 32,
    }
    ctx:set(player, component.RELIGION_RU, state)

    local option = abilities.get(ids.HEALTH)

    harness.truthy(option ~= nil)
    harness.truthy(abilities.usable_now(ctx, player, option))
    harness.truthy(abilities.usable_now(ctx, player,
        abilities.get(ability_ids.RU_REJECT_SACRIFICES)))
    local bargain = option.prepare(game, player, {
        forced = false,
    })

    harness.equal(bargain.confirmation_id, ids.HEALTH)
    harness.truthy(bargain.confirmation:find(
        "Piety after sacrifice: *.....", 1, true) ~= nil)

    resolution.accept(game, player, ids.HEALTH)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    state = ctx:get(player, component.RELIGION_RU)
    harness.equal(worship.piety, 42)
    harness.equal(levels.base(ctx, player, mutations.MUT_FRAIL), 1)
    harness.equal(state.sacrifice_progress, 0)
    harness.equal(state.sacrifice_delay, 90)
    harness.equal(state.sacrifice_penalty, 0)
    harness.equal(state.sacrifice_mutations, 1)
    harness.equal(#state.available, 0)
    harness.truthy(not abilities.usable_now(ctx, player, option))

    -- A safety sacrifice grants all catalog ranks in one choice;
    -- the source does not ask the player to accept it repeatedly.
    state.available = { ids.WORDS }
    state.quoted_piety = {
        [ids.WORDS] = 30,
    }
    ctx:set(player, component.RELIGION_RU, state)
    resolution.accept(game, player, ids.WORDS)
    harness.equal(levels.base(ctx, player,
        mutations.MUT_READ_SAFETY), 2)
    harness.equal(ctx:get(player,
        component.RELIGION_WORSHIP).piety, 72)
    harness.equal(ctx:get(player,
        component.RELIGION_RU).sacrifice_mutations, 2)

    local rejected = pcall(resolution.accept,
        game, player, ids.WORDS)

    harness.truthy(not rejected,
        "a stale Ru command cannot repeat a sacrifice")

    -- Arcana counts its three school mutations, not one menu choice.
    state = ctx:get(player, component.RELIGION_RU)
    state.available = { ids.ARCANA }
    state.arcana = {
        mutations.MUT_NO_AIR_MAGIC,
        mutations.MUT_NO_HEXES_MAGIC,
        mutations.MUT_NO_CONJURATION_MAGIC,
    }
    state.quoted_piety = {
        [ids.ARCANA] = 30,
    }
    ctx:set(player, component.RELIGION_RU, state)
    resolution.accept(game, player, ids.ARCANA)
    harness.equal(ctx:get(player,
        component.RELIGION_RU).sacrifice_mutations, 5)

    -- The source resets offers and waiting time on rejoining Ru, but
    -- lifetime mutation history remains part of the player's record.
    ru_god.prepare(game, player)
    harness.equal(ctx:get(player,
        component.RELIGION_RU).sacrifice_mutations, 5)

    -- Both a terminal confirmation and a direct command use the ordinary
    -- ability path. Cancel is free; a confirmed rejection owns one intent.
    state = ctx:get(player, component.RELIGION_RU)
    state.available = { ids.HEALTH }
    state.health = { mutations.MUT_FRAIL }
    state.quoted_piety = {
        [ids.HEALTH] = 32,
    }
    ctx:set(player, component.RELIGION_RU, state)

    local reject_id = ability_ids.RU_REJECT_SACRIFICES
    local waiting = commands.prepare(game, player, {
        ability_id = reject_id,
    })

    harness.equal(waiting.confirmation_id, reject_id)
    harness.equal(commands.prepare(game, player, {
        ability_id = reject_id,
        cancelled = true,
    }).message, "Okay.")
    harness.equal(#ctx:get(player,
        component.RELIGION_RU).available, 1)

    local confirmed = commands.prepare(game, player, {
        ability_id = reject_id,
        forced = true,
    })

    harness.equal(confirmed.cost, 10)
    abilities.resolve(game, player, confirmed.intent, 10)
    harness.equal(#ctx:get(player,
        component.RELIGION_RU).available, 0)
    harness.equal(ctx:get(player,
        component.RELIGION_RU).sacrifice_mutations, 5)

    -- A missing hand cannot leave a shield or a ring in the lost slot.
    -- With the other ring slot filled, the removed ring stays carried.
    local shield = ctx:create()
    local lost_ring = ctx:create()
    local kept_ring = ctx:create()

    for _, item in ipairs({ shield, lost_ring, kept_ring }) do
        ctx:add(item, component.CARRIED_BY, { holder = player })
    end

    ctx:add(shield, component.EQUIPPED, { slot = "shield" })
    ctx:add(lost_ring, component.EQUIPPED, {
        slot = slots.LEFT,
    })
    ctx:add(kept_ring, component.EQUIPPED, {
        slot = slots.RIGHT,
    })
    transition.grant(game, player, mutations.MUT_MISSING_HAND,
        classes.INNATE, true)
    hand.apply(game, player)
    harness.truthy(not ctx:has(shield, component.EQUIPPED))
    harness.truthy(not ctx:has(lost_ring, component.EQUIPPED))
    harness.equal(ctx:get(kept_ring,
        component.EQUIPPED).slot, slots.RIGHT)

    -- A saved Experience choice can outlive a separate level drain.
    -- Source disables that one bargain at XL1 but still allows rejection.
    local drained = ctx:create()

    ctx:add(drained, component.PROGRESSION, {
        level = 1,
        total_xp = 0,
        pending_stat_level = 0,
    })
    ctx:add(drained, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = 10,
    })
    ctx:add(drained, component.RELIGION_RU, {
        available = { ids.EXPERIENCE },
        quoted_piety = {
            [ids.EXPERIENCE] = 35,
        },
    })

    harness.truthy(not resolution.acceptable(game, drained,
        ids.EXPERIENCE))
    harness.truthy(abilities.usable_now(ctx, drained,
        abilities.get(ability_ids.RU_REJECT_SACRIFICES)))

    -- Inexperienced shifts the XP threshold immediately: 30 XP reaches
    -- Human XL3 before the bargain and only XL2 afterward.
    local experienced = ctx:create()

    ctx:add(experienced, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Experience bargain test",
    })
    ctx:add(experienced, component.PROGRESSION, {
        level = 3,
        total_xp = 30,
        pending_stat_level = 0,
    })
    ctx:add(experienced, component.SKILLS, {
        entries = {},
    })
    ctx:add(experienced, component.HEALTH, {
        current = 25,
        max = 25,
    })
    ctx:add(experienced, component.REGENERATION, {
        hp_progress = 0,
    })
    ctx:add(experienced, component.MAGIC, {
        current = 3,
        max = 3,
    })
    ctx:add(experienced, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = 10,
    })
    ctx:add(experienced, component.RELIGION_RU, {
        sacrifice_progress = 50,
        sacrifice_delay = 50,
        sacrifice_penalty = 0,
        available = { ids.EXPERIENCE },
        quoted_piety = {
            [ids.EXPERIENCE] = 35,
        },
    })

    resolution.accept(game, experienced, ids.EXPERIENCE)
    harness.equal(ctx:get(experienced,
        component.PROGRESSION).level, 2)
    -- The source threshold calculation subtracts one from its table value.
    harness.equal(experience_limit.needed(game, experienced, 3), 69)
    harness.equal(experience_limit.earned_level(game, experienced,
        30), 2)
    harness.equal(experience_limit.progress(game, experienced,
        30, 2), 2)
    harness.truthy(ctx:get(experienced,
        component.HEALTH).max < 25)
    harness.equal(ctx:get(experienced,
        component.RELIGION_WORSHIP).piety, 45)
end

return test
