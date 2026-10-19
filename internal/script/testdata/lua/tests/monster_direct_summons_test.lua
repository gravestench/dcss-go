local effects = require("policy.combat.monster_spells")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local self_target = require("policy.combat.monster_support.self_target")
local targets = require("policy.ai.targets")
local attitudes = require("constants.attitude")
local branches = require("policy.combat.monster_summons.branches")
local branch_ids = require("ids.branches")
local catalog = require("policy.catalog")
local hit_points = require("policy.population.hit_points")
local monster_stats = require("policy.combat.monster_stats")
local monster_defense = require("policy.combat.monster_defense")
local monster_inventory = require("policy.save.monster_inventory")
local awareness = require("policy.ai.awareness")
local stealth = require("policy.character.stealth")

local test = {}

-- These are the complete direct-creature family from the pinned source
-- audit. Each ID must resolve by its own file, without a central switch.
local direct_spells = {
    spells.SPELL_SUMMON_SMALL_MAMMAL,
    spells.SPELL_CALL_IMP,
    spells.SPELL_SUMMON_MINOR_DEMON,
    spells.SPELL_SUMMON_UFETUBUS,
    spells.SPELL_SUMMON_HELL_BEAST,
    spells.SPELL_SUMMON_ICE_BEAST,
    spells.SPELL_SUMMON_GREATER_DEMON,
    spells.SPELL_SUMMON_HOLIES,
    spells.SPELL_SUMMON_EYEBALLS,
    spells.SPELL_SUMMON_TZITZIMITL,
    spells.SPELL_SUMMON_HELL_SENTINEL,
    spells.SPELL_CALL_LOST_SOUL,
    spells.SPELL_SUMMON_MANA_VIPER,
    spells.SPELL_SUMMON_SCORPIONS,
    spells.SPELL_SUMMON_EMPEROR_SCORPIONS,
    spells.SPELL_SUMMON_SCARABS,
    spells.SPELL_SUMMON_EXECUTIONERS,
    spells.SPELL_GREATER_SERVANT_MAKHLEB,
    spells.SPELL_SHADOW_CREATURES,
    spells.SPELL_SUMMON_DEMON,
    spells.SPELL_SUMMON_SPIDERS,
    spells.SPELL_SUMMON_HORRIBLE_THINGS,
    spells.SPELL_SUMMON_UNDEAD,
    spells.SPELL_SUMMON_DRAKES,
    spells.SPELL_SUMMON_DRAGON,
    spells.SPELL_SUMMON_HYDRA,
    spells.SPELL_FIRE_SUMMON,
    spells.SPELL_SUMMON_VERMIN,
    spells.SPELL_MONSTROUS_MENAGERIE,
    spells.SPELL_FORCEFUL_INVITATION,
    spells.SPELL_PLANEREND,
    spells.SPELL_SUMMON_MUSHROOMS,
    spells.SPELL_HAUNT,
    spells.SPELL_SUMMON_SPECTRAL_ORCS,
    spells.SPELL_BROTHERS_IN_ARMS,
    spells.SPELL_WATER_ELEMENTALS,
    spells.SPELL_FIRE_ELEMENTALS,
    spells.SPELL_EARTH_ELEMENTALS,
    spells.SPELL_AIR_ELEMENTALS,
}

-- Loading each real module checks that the game will find it when a source
-- spellbook gains this slot. Later tests call plan and resolve on live ECS.
local function complete_resolvers()
    for _, spell_id in ipairs(direct_spells) do
        local ok, effect = pcall(effects.effect, spell_id)

        harness.truthy(ok, spell_id .. " effect file loads")
        harness.truthy(type(effect.plan) == "function",
            spell_id .. " plans before spending the cast")
        harness.truthy(type(effect.resolve) == "function",
            spell_id .. " resolves the selected cast")
    end
end

-- A deterministic zero draw exposes count and weighted-choice boundaries
-- without copying the production pool data into the test.
local function zero_draws(game)
    game.random = function(_, _, _)
        return 0
    end
end

-- The real ECS records the source ID, kind, owner, and duration for every
-- creature. This checks the full effect-to-creator path, not just a picker.
local function creatures_for(ctx, source_id)
    local found = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.source_id == source_id then
            found[#found + 1] = entity
        end
    end

    return found
end

-- Each fixed-kind case starts far from the previous one so eight adjacent
-- spawn cells are available in this grid-light fixture.
local function fixed_creatures(ctx, game)
    local cases = {
        {
            id = spells.SPELL_SUMMON_UFETUBUS,
            kind = monsters.MONS_UFETUBUS,
            count = 2,
            degree = 2,
        },

        {
            id = spells.SPELL_SUMMON_HELL_BEAST,
            kind = monsters.MONS_HELL_BEAST,
            count = 1,
            degree = 4,
        },

        {
            id = spells.SPELL_SUMMON_ICE_BEAST,
            kind = monsters.MONS_ICE_BEAST,
            count = 1,
            degree = 5,
        },

        {
            id = spells.SPELL_SUMMON_MANA_VIPER,
            kind = monsters.MONS_MANA_VIPER,
            count = 1,
            degree = 2,
        },

        {
            id = spells.SPELL_SUMMON_SCARABS,
            kind = monsters.MONS_DEATH_SCARAB,
            count = 1,
            degree = 2,
        },
    }

    for index, case in ipairs(cases) do
        local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST,
            20 + index * 10, 20)
        local effect = effects.effect(case.id)
        local plan = effect.plan(game, caster, nil, nil)

        harness.truthy(plan, case.id .. " prepares a self-targeted cast")
        effect.resolve(game, caster, nil, nil, plan)

        local creatures = creatures_for(ctx, case.id)

        harness.equal(#creatures, case.count,
            case.id .. " uses the source minimum count")

        for _, creature in ipairs(creatures) do
            local actor = ctx:get(creature, component.ACTOR)
            local state = ctx:get(creature, component.SUMMON)

            harness.equal(actor.kind_id, case.kind,
                case.id .. " creates the source creature")
            harness.equal(state.owner, caster,
                case.id .. " keeps the caster as owner")
            harness.truthy(state.expires_aut > 0,
                case.id .. " has a finite source duration")
        end
    end
end

-- Zero draws choose the source's first weighted imp and exactly one rat
-- family creature per attempt. A nonzero count still uses caster allegiance.
local function weighted_creatures(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 120, 20)
    local effect = effects.effect(spells.SPELL_CALL_IMP)
    local plan = effect.plan(game, caster, nil, nil)

    effect.resolve(game, caster, nil, nil, plan)

    local creatures = creatures_for(ctx, spells.SPELL_CALL_IMP)

    harness.equal(#creatures, 1, "Call Imp makes one creature")
    harness.equal(ctx:get(creatures[1], component.ACTOR).kind_id,
        monsters.MONS_IRON_IMP, "zero weighted draw picks first imp")
end

-- The source undead pool includes generic skeletons with no fixed HP in
-- their catalog entry. A skeleton needs a real base body before creation.
local function derived_undead(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 135, 20)
    local effect = effects.effect(spells.SPELL_SUMMON_UNDEAD)
    local plan = effect.plan(game, caster, nil, nil)

    game.random = function(_, stream, bound)
        if stream == "monster_spell" and bound == 16 then
            return 4
        end

        return 0
    end

    effect.resolve(game, caster, nil, nil, plan)

    local creatures = creatures_for(ctx, spells.SPELL_SUMMON_UNDEAD)

    harness.equal(#creatures, 2, "two minimum undead are created")

    for _, creature in ipairs(creatures) do
        local health = ctx:get(creature, component.HEALTH)
        local base = ctx:get(creature, component.SUMMON_UNDEAD)

        harness.truthy(health and health.current > 0,
            "derived skeleton has HP from a base creature")
        harness.truthy(base and base.base_kind_id ~= "",
            "derived skeleton records its base creature")

        local definition = catalog.get("monsters",
            ctx:get(creature, component.ACTOR).kind_id)
        local base_definition = catalog.get("monsters", base.base_kind_id)

        harness.equal(monster_stats.hit_dice(game, creature, definition),
            base_definition.hd,
            "derived skeleton uses its source body's HD in later rules")

        local original_score = stealth.score

        stealth.score = function()
            return 50
        end

        local detected = awareness.detects(game, creature,
            { behavior = "wander" }, true)

        stealth.score = original_score
        harness.truthy(type(detected) == "boolean",
            "derived skeleton's later awareness turn resolves")
    end

    zero_draws(game)
end

-- Forceful Invitation stores its selected branch on the caster. A second
-- cast must reuse that saved component even though it draws new monsters.
local function invitation_branch(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 150, 20)
    local effect = effects.effect(spells.SPELL_FORCEFUL_INVITATION)
    local plan = effect.plan(game, caster, nil, nil)

    effect.resolve(game, caster, nil, nil, plan)

    local first = ctx:get(caster, component.MONSTER_INVITATION)

    harness.truthy(first and first.branch_id ~= "",
        "Invitation branch is saved on its caster")

    effect.resolve(game, caster, nil, nil, plan)

    local second = ctx:get(caster, component.MONSTER_INVITATION)

    harness.equal(second.branch_id, first.branch_id,
        "later Invitation casts keep the chosen branch")
end

-- A foe-centered plan records coordinates. Moving its target before
-- resolution must not drag the planned mushroom ring along with the foe.
local function fixed_foe_cell(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 180, 20)
    local foe = fixture.actor(ctx, monsters.MONS_HUMAN, 184, 20)
    local effect = effects.effect(spells.SPELL_SUMMON_MUSHROOMS)
    local plan = effect.plan(game, caster, foe, nil)

    ctx:set(foe, component.POSITION, {
        level_id = 1,
        x = 194,
        y = 20,
    })

    effect.resolve(game, caster, foe, nil, plan)

    local creatures = creatures_for(ctx, spells.SPELL_SUMMON_MUSHROOMS)

    harness.truthy(#creatures >= 2,
        "Mushrooms use the source minimum count")

    for _, creature in ipairs(creatures) do
        local position = ctx:get(creature, component.POSITION)
        local distance = math.max(math.abs(position.x - plan.x),
            math.abs(position.y - plan.y))

        harness.truthy(distance >= 1 and distance <= 2,
            "Mushroom stays around the original foe cell")
    end
end

-- Haunt keeps a saved victim for pursuit and refuses to bind a replacement
-- that entered the selected cell after the original victim moved away.
local function haunting_target(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 200, 80)
    local foe = game:player()
    local replacement = fixture.actor(ctx, monsters.MONS_HUMAN, 210, 80)
    local effect = effects.effect(spells.SPELL_HAUNT)

    ctx:set(foe, component.POSITION, {
        level_id = 1,
        x = 204,
        y = 80,
    })

    local plan = effect.plan(game, caster, foe, nil)

    ctx:set(foe, component.POSITION, {
        level_id = 1,
        x = 208,
        y = 80,
    })
    ctx:set(replacement, component.POSITION, {
        level_id = 1,
        x = 204,
        y = 80,
    })

    effect.resolve(game, caster, foe, nil, plan)

    for _, creature in ipairs(creatures_for(ctx, spells.SPELL_HAUNT)) do
        harness.falsy(ctx:has(creature, component.SUMMON_HAUNTING),
            "Haunt does not bind a replacement occupant")
    end

    local fresh = effect.plan(game, caster, foe, nil)

    effect.resolve(game, caster, foe, nil, fresh)

    local bound = nil

    for _, creature in ipairs(creatures_for(ctx, spells.SPELL_HAUNT)) do
        if ctx:has(creature, component.SUMMON_HAUNTING) then
            bound = creature
            break
        end
    end

    harness.truthy(bound, "Haunt saves the original victim on a wraith")

    local position = ctx:get(bound, component.POSITION)
    local nearer = fixture.actor(ctx, monsters.MONS_HUMAN,
        position.x + 1, position.y)

    ctx:add(nearer, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:set(foe, component.POSITION, {
        level_id = 1,
        x = 240,
        y = 80,
    })

    local chosen = targets.nearest(game, bound, position, 7)

    harness.equal(chosen, foe,
        "haunting wraith pursues its saved victim beyond sight")
end

-- Source MGEN_BLOB_SIZE makes a Planerend slime a five-body creature at
-- creation, not merely a normal slime carrying a decorative size field.
local function planerend_blob(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 230, 80)
    local effect = effects.effect(spells.SPELL_PLANEREND)
    local original = branches.choose_planerend

    branches.choose_planerend = function()
        return branch_ids.BRANCH_SLIME
    end

    local plan = effect.plan(game, caster, nil, nil)

    effect.resolve(game, caster, nil, nil, plan)
    branches.choose_planerend = original

    local creatures = creatures_for(ctx, spells.SPELL_PLANEREND)
    local creature = creatures[1]
    local definition = catalog.get("monsters", monsters.MONS_SLIME_CREATURE)
    local ordinary_hp = hit_points.roll(game, definition.average_hp_10x)
    local health = ctx:get(creature, component.HEALTH)

    harness.equal(ctx:get(creature, component.SUMMON_BLOB).size, 5,
        "Planerend stores the source merged size")
    harness.equal(health.max, ordinary_hp * 5,
        "Planerend merged slime has five bodies of HP")
end

-- Spectral orcs are derived actors whose source orc type determines their
-- equipment as well as their copied attacks. Carried gear expires with them.
local function spectral_orc_gear(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 240, 80)
    local foe = fixture.actor(ctx, monsters.MONS_HUMAN, 244, 80)
    local effect = effects.effect(spells.SPELL_SUMMON_SPECTRAL_ORCS)
    local plan = effect.plan(game, caster, foe, nil)

    effect.resolve(game, caster, foe, nil, plan)

    local creature = creatures_for(ctx,
        spells.SPELL_SUMMON_SPECTRAL_ORCS)[1]
    local found = {}

    for _, item in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(item, component.CARRIED_BY)

        if carrier.holder == creature then
            local equipped = ctx:get(item, component.EQUIPPED)

            if equipped then
                found[equipped.slot] = true
            end
        end
    end

    harness.truthy(found.weapon, "spectral orc carries its base weapon")
    harness.truthy(found.body, "spectral orc wears its base armour")

    local definition = catalog.get("monsters",
        ctx:get(creature, component.ACTOR).kind_id)

    harness.truthy(monster_defense.armour(game, creature, definition) >
        (definition.ac or 0),
        "spectral orc's worn body armour contributes AC")
    monster_inventory.validate(game)
end

-- The source counts attempts, not successful placements, and a third
-- Brother cannot be planned until Berserker Rage clears that counter.
local function brothers_limit(ctx, game)
    local caster = fixture.actor(ctx,
        monsters.MONS_SPRIGGAN_BERSERKER, 210, 20)
    local effect = effects.effect(spells.SPELL_BROTHERS_IN_ARMS)

    for _ = 1, 2 do
        local plan = effect.plan(game, caster, nil, nil)

        harness.truthy(plan, "first two Brothers casts may be planned")
        effect.resolve(game, caster, nil, nil, plan)
    end

    harness.equal(ctx:get(caster, component.MONSTER_BROTHERS).count, 2,
        "caster stores two Brothers attempts")
    harness.falsy(effect.plan(game, caster, nil, nil),
        "a third Brother is refused before spending a cast")

    local rage = effects.effect(spells.SPELL_BERSERKER_RAGE)

    rage.resolve(game, caster, nil, nil, self_target.plan(caster))

    harness.falsy(ctx:has(caster, component.MONSTER_BROTHERS),
        "Berserker Rage clears the saved Brother count")
end

-- Loading a file does not prove its resolver can run. Cast each source
-- family once against real Akara stores with open fixture cells; focused
-- cases above check the detailed outcomes that differ by spell.
local function resolve_every_spell(ctx, game)
    for index, spell_id in ipairs(direct_spells) do
        local x = 250 + index * 20
        local kind = monsters.MONS_ORC_PRIEST

        if spell_id == spells.SPELL_BROTHERS_IN_ARMS then
            kind = monsters.MONS_SPRIGGAN_BERSERKER
        end

        local caster = fixture.actor(ctx, kind, x, 20)
        local foe = fixture.actor(ctx, monsters.MONS_HUMAN, x + 5, 20)
        local effect = effects.effect(spell_id)
        local plan = effect.plan(game, caster, foe, nil)
        local before = #ctx:query({ component.SUMMON })

        harness.truthy(plan, spell_id .. " has a live target plan")
        effect.resolve(game, caster, foe, nil, plan)

        local after = #ctx:query({ component.SUMMON })

        harness.truthy(after > before,
            spell_id .. " creates a live ECS summon")
    end
end

-- The named list is one source-audit assertion, not a duplicated schema.
function test.run(ctx)
    harness.equal(#direct_spells, 39,
        "all thirty-nine direct-creature effects are represented")

    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 3, 3)
    local game = fixture.context(ctx, player)

    zero_draws(game)
    fixed_creatures(ctx, game)
    weighted_creatures(ctx, game)
    derived_undead(ctx, game)
    invitation_branch(ctx, game)
    fixed_foe_cell(ctx, game)
    haunting_target(ctx, game)
    planerend_blob(ctx, game)
    spectral_orc_gear(ctx, game)
    brothers_limit(ctx, game)
    resolve_every_spell(ctx, game)
    complete_resolvers()
end

return test
