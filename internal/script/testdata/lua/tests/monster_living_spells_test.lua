-- Walking tomes turn one shared spellbook slot into four distinct living
-- spell actors. Production schemas and spellbook policy stay in this test.
local catalog = require("policy.catalog")
local attitudes = require("constants.attitude")
local ai_spell = require("policy.ai.spell")
local attack_system = require("systems.attack_spell")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local save_summons = require("policy.save.summons")
local spellbook = require("policy.combat.monster_spellbook")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local living = require("policy.combat.monster_summons.living_spells")
local tome_effect = require("policy.combat.monster_spells.conjure_living_spells")
local summons = require("policy.magic.effects.summons.common")

local test = {}

local tome_spells = {
    {
        kind_id = monsters.MONS_EARTHEN_TOME,
        spell_id = spells.SPELL_PETRIFY,
    },

    {
        kind_id = monsters.MONS_CRYSTAL_TOME,
        spell_id = spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
    },

    {
        kind_id = monsters.MONS_DIVINE_TOME,
        spell_id = spells.SPELL_SMITING,
    },

    {
        kind_id = monsters.MONS_FROSTBOUND_TOME,
        spell_id = spells.SPELL_ICEBLAST,
    },
}

-- Every source tome species owns the resulting spell actors. The custom
-- slot is projected from saved state rather than derived from the caster.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 30, 20, 100)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})

    function game:random()
        return 0
    end

    local first_caster
    local oldest
    local sample

    for index, tome in ipairs(tome_spells) do
        local caster = fixture.actor(ctx, tome.kind_id,
            5 + index * 5, 5, 30)
        local expected_hd = catalog.get("monsters", tome.kind_id).hd
        local created = living.spawn(game, caster)

        first_caster = first_caster or caster
        oldest = oldest or created[1]
        sample = created[1]

        harness.equal(#created, 2,
            "source minimum count creates two living spells")

        for _, entity in ipairs(created) do
            local state = ctx:get(entity, component.SUMMON_LIVING_SPELL)
            local summon = ctx:get(entity, component.SUMMON)
            local stats = ctx:get(entity, component.SUMMON_STATS)
            local book = spellbook.for_actor(game, entity)

            harness.equal(state.spell_id, tome.spell_id,
                "tome species selects its source living spell")
            harness.equal(summon.owner, caster,
                "tome remains the saved summon owner")
            harness.equal(stats.hd, expected_hd,
                "living spell inherits the tome's spell HD")
            harness.equal(book.slots[1].spell_id, tome.spell_id,
                "ordinary AI reads the saved custom slot")
            harness.equal(book.slots[1].frequency, 200,
                "living spell always offers its one spell")
        end
    end

    -- The save validator checks the custom spell rather than re-reading
    -- its original tome, which may have died before this actor is restored.
    local saved_actor = ctx:get(sample, component.ACTOR)
    local saved_position = ctx:get(sample, component.POSITION)
    local saved_ai = ctx:get(sample, component.AI)
    local saved_summon = ctx:get(sample, component.SUMMON)

    -- The sparse Lua fixture omits zero-valued Go AI fields. Fill those
    -- defaults before exercising the real save validator directly.
    saved_ai.target_x = saved_ai.target_x or 0
    saved_ai.target_y = saved_ai.target_y or 0
    saved_ai.memory_until_aut = saved_ai.memory_until_aut or 0

    local okay, problem = pcall(save_summons.validate, game,
        sample, saved_actor, saved_position, saved_ai, saved_summon, 0)

    harness.truthy(okay,
        "valid living spell survives restore: " .. tostring(problem))

    local selected = ctx:get(sample,
        component.SUMMON_LIVING_SPELL)
    local original_id = selected.spell_id

    selected.spell_id = spells.SPELL_CONJURE_LIVING_SPELLS
    ctx:set(sample, component.SUMMON_LIVING_SPELL, selected)

    okay = pcall(save_summons.validate, game,
        sample, saved_actor, saved_position, saved_ai, saved_summon, 0)

    harness.falsy(okay,
        "restore rejects a living spell with a forged custom slot")

    selected.spell_id = original_id
    ctx:set(sample, component.SUMMON_LIVING_SPELL, selected)

    -- Source AI refuses another cast at six. A forced direct summon still
    -- enforces the actor cap, which protects saves and modded cast paths.
    for _ = 1, 2 do
        living.spawn(game, first_caster)
    end

    harness.truthy(living.at_cap(game, first_caster),
        "three casts fill the source six-spell cap")
    harness.falsy(tome_effect.plan(game, first_caster),
        "AI declines a full-cap walking-tome cast")

    living.spawn(game, first_caster)

    local owned = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        if ctx:get(entity, component.SUMMON).owner == first_caster then
            owned = owned + 1
        end
    end

    harness.equal(owned, 6,
        "living-spell cap evicts the owner's oldest pair")
    harness.falsy(ctx:has(oldest, component.SUMMON),
        "oldest living spell no longer occupies the saved world")

    -- A charmed tome changes side. The six old hostile spells no longer
    -- count toward its new friendly cap, matching source count_summons.
    ctx:add(first_caster, component.MONSTER_ALLEGIANCE, {
        charm_aut = 100,
    })

    harness.falsy(living.at_cap(game, first_caster),
        "unaligned old spells do not block a charmed tome")
    harness.truthy(tome_effect.plan(game, first_caster),
        "charmed tome can plan a new allied conjuration")

    local friendly = living.spawn(game, first_caster)

    harness.equal(ctx:get(friendly[1], component.SUMMON).attitude,
        attitudes.FRIENDLY,
        "new living spells inherit the tome's changed side")

    -- A shorter new lifetime cannot cause the shared cap owner to delete
    -- the just-created actor before a spell-specific component is added.
    local cap_caster = fixture.actor(ctx,
        monsters.MONS_DIVINE_TOME, 35, 5, 30)
    local old = summons.spawn(game, cap_caster,
        spells.SPELL_CONJURE_LIVING_SPELLS,
        monsters.MONS_LIVING_SPELL, 1, 1, {
            expires_aut = 100,
        })
    local fresh = summons.spawn(game, cap_caster,
        spells.SPELL_CONJURE_LIVING_SPELLS,
        monsters.MONS_LIVING_SPELL, 1, 1, {
            expires_aut = 10,
        })

    harness.falsy(ctx:has(old, component.SUMMON),
        "cap evicts a preexisting actor")
    harness.truthy(ctx:has(fresh, component.SUMMON),
        "cap preserves the new actor despite its shorter lifetime")

    local iceblast = catalog.get("monster_beams",
        spells.SPELL_ICEBLAST)

    harness.equal(iceblast.explosion_radius, 1,
        "Iceblast keeps its source radius-one blast")
    harness.equal(iceblast.power_hd_factor, 12,
        "Iceblast uses normal monster spell power")

    -- The distant player cannot be planned as an Iceblast target. No
    -- committed cast means the actor remains to try on a later turn.
    harness.falsy(ai_spell.choose(game, sample, player, false),
        "out-of-range living spell has no cast intent")

    attack_system.update(game, sample)

    harness.truthy(ctx:get(sample, component.HEALTH).current > 0,
        "living spell survives a turn without a planned cast")

    -- A blocked placement must leave the HP stream untouched. The shared
    -- summon owner checks the eight candidate cells before rolling HP.
    local blocked_caster = fixture.actor(ctx,
        monsters.MONS_EARTHEN_TOME, 45, 5, 30)

    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(45 + dx) .. ":" .. (5 + dy)] = true
            end
        end
    end

    local hp_draws = 0

    function game:random(stream)
        if stream == streams.MONSTER_HP then
            hp_draws = hp_draws + 1
        end

        return 0
    end

    harness.equal(#living.spawn(game, blocked_caster), 0,
        "blocked tome cannot place a living spell")
    harness.equal(hp_draws, 0,
        "failed placement consumes no monster HP draw")
end

return test
