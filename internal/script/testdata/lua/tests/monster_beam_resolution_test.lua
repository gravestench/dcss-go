-- Beam plans and resolution preserve contact order, status ownership, terrain effects, and reflection.

local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local component = require("constants.component")
local attitudes = require("constants.attitude")
local terrain = require("content.terrain_features")
local terrain_ids = require("constants.terrain")
local cloud_ids = require("ids.clouds")
local harness = require("tests.harness")
local armour_egos = require("constants.armour_egos")
local items = require("ids.items")
local monsters = require("ids.monsters")
local monster_spells = require("policy.combat.monster_spells")
local spells = require("ids.spells")

local test = {}

local caster = 101
local foe = 202
local next_foe = 303
local shield_item = 404

-- Optional second contacts, shields, and walls make the same deterministic
-- world exercise beam, cloud, bounce, and reflection order.
local function context(with_second, with_reflection, blocked_cloud_ray,
    reflected_continuation, bounce_wall, short_range)
    local values = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_ORC_WIZARD,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 1,
                y = 1,
            },
            [component.HEALTH] = {
                current = 20,
                maximum = 20,
            },
            [component.SUMMON] = {
                attitude = attitudes.FRIENDLY,
            },
        },
        [foe] = {
            [component.ACTOR] = {
                kind_id = with_reflection and monsters.MONS_ORC_WIZARD or
                    monsters.MONS_ADDER,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = short_range and 2 or
                    with_reflection and 2 or bounce_wall and 3 or 4,
                y = 1,
            },
            [component.HEALTH] = {
                current = 20,
                maximum = 20,
            },
            [component.COMBAT] = { shield_blocks = 0 },
        },
        [999] = {
            [component.PLAYER] = {},
            [component.POSITION] = {
                level_id = 1,
                x = 6,
                y = 1,
            },
        },
    }

    if with_second then
        values[next_foe] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_ADDER,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = short_range and 3 or
                    reflected_continuation and 0 or 5,
                y = 1,
            },
            [component.HEALTH] = {
                current = 20,
                maximum = 20,
            },
            [component.COMBAT] = { shield_blocks = 0 },
        }
    end

    if with_reflection then
        values[shield_item] = {
            [component.CARRIED_BY] = { holder = foe },
            [component.EQUIPPED] = { slot = "shield" },
            [component.ITEM] = {
                kind_id = items.ARM_BUCKLER,
                quantity = 1,
                charges = 0,
                plus = 0,
                ego = armour_egos.REFLECTION,
            },
        }
    end

    local ctx = {
        values = values,
        cells = {},
        messages = {},
        random_count = 0,
        next_entity = 500,
    }

    -- Fix the player entity away from monster IDs so beam targeting can distinguish sides.
    function ctx:player()
        return 999
    end

    -- Read the fixture component store exactly as policy context reads ECS components.
    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    -- Persist hit-point and status updates for later phase assertions.
    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    -- Make newly created cloud and status components visible to subsequent resolver calls.
    function ctx:add(entity, id, value)
        self.values[entity][id] = value
    end

    -- Track dispels and temporary-state cleanup in the same fixture store.
    function ctx:remove(entity, id)
        self.values[entity][id] = nil
    end

    -- Gate branch behaviour on actual saved components rather than hardcoded flags.
    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    -- Sort entity IDs so AoE target iteration cannot depend on Lua table order.
    function ctx:query(ids)
        local result = {}

        for entity, data in pairs(self.values) do
            local present = true

            for _, id in ipairs(ids) do
                if not data[id] then
                    present = false
                    break
                end
            end

            if present then
                result[#result + 1] = entity
            end
        end

        table.sort(result)

        return result
    end

    -- Allocate distinct marker entities for clouds and temporary terrain.
    function ctx:create()
        local entity = self.next_entity

        self.next_entity = entity + 1
        self.values[entity] = {}

        return entity
    end

    -- Expose stable fixture entity IDs to ownership and target checks.
    function ctx:id(entity)
        return entity
    end

    -- Supply a wall only in bounce cases; otherwise preserve floor terrain.
    function ctx:cell(_, x, y)
        if self.cells[x .. "," .. y] then
            return self.cells[x .. "," .. y]
        end

        if bounce_wall and x == 5 and y == 1 then
            return terrain.vault_terrain.DNGN_ROCK_WALL
        end

        return terrain.vault_terrain.DNGN_FLOOR
    end

    -- Record terrain replacement so Hurl Sludge and wave assertions inspect the endpoint.
    function ctx:set_cell(_, x, y, feature)
        self.cells[x .. "," .. y] = feature
    end

    -- Use a fixed action clock so cloud and status expiry values are reproducible.
    function ctx:aut()
        return 100
    end

    -- Block one cloud ray only in the occlusion case while other traces stay clear.
    function ctx:projectile_clear(_, from_x, from_y, to_x, to_y)
        if blocked_cloud_ray and from_x == 4 and from_y == 1 and
            to_x == 5 and to_y == 1 then
            return false
        end

        return true
    end

    -- Hold sight constant so tests isolate projectile and contact rules.
    function ctx:visible()
        return true
    end

    -- Turn the configured bounce wall into nonwalkable terrain for displacement tests.
    function ctx:walkable(_, x, y)
        return not (bounce_wall and x == 5 and y == 1)
    end

    -- Persist moved positions to verify Blinkbolt and knockback outcomes.
    function ctx:move_actor(entity, level_id, x, y)
        local position = self:get(entity, component.POSITION)

        position.level_id = level_id
        position.x = x
        position.y = y
        self:set(entity, component.POSITION, position)
    end

    -- Expose the optional second contact and reflected continuation at authored cells.
    function ctx:actor_at(_, x, y)
        if y ~= 1 then
            return nil
        end

        if x == 1 then
            return caster
        end

        if short_range then
            if x == 2 then
                return foe
            end

            if x == 3 and with_second then
                return next_foe
            end

            return nil
        end

        if x == 5 and with_second and not reflected_continuation or
            x == 0 and reflected_continuation then
            return next_foe
        end

        if x == 4 and not with_reflection and not bounce_wall or
            x == 3 and bounce_wall or x == 2 and with_reflection then
            return foe
        end

        return nil
    end

    -- Script bounded draws to distinguish shield blocks, misses, and reflection branches.
    function ctx:random(_, bound)
        self.random_count = self.random_count + 1

        if reflected_continuation then
            if self.random_count == 3 or self.random_count == 4 or
                self.random_count == 8 or self.random_count == 9 then
                return 0
            end

            return bound - 1
        end

        if with_reflection and self.random_count == 3 then
            return 0
        end

        if with_second and (self.random_count == 1 or
            self.random_count == 5 or self.random_count == 6) then
            return 0
        end

        return bound - 1
    end

    -- Capture combat messages without relying on a live terminal.
    function ctx:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    return ctx
end

-- Check a simple Magic Dart plan and resolved contact before compound beam cases.
local function basic_trajectory()
    local ctx = context()
    local profile = catalog.get("monster_beams", spells.SPELL_MAGIC_DART)
    local plan = beam.plan(ctx, caster, foe, profile)
    local outcomes = beam.resolve(ctx, caster, foe, profile, plan)

    harness.equal(outcomes[1].target, foe,
        "Magic Dart contacts the selected actor")
    harness.equal(outcomes[1].kind, "hit",
        "Magic Dart automatically hits")
    harness.truthy(ctx:get(foe, component.HEALTH).current < 20,
        "Magic Dart lowers the defender's ECS health")

    local second_ctx = context(true)
    local arrow = catalog.get("monster_beams", spells.SPELL_STONE_ARROW)
    local arrow_plan = beam.plan(second_ctx, caster, foe, arrow)
    local arrow_outcomes = beam.resolve(second_ctx, caster, foe,
        arrow, arrow_plan)

    harness.equal(arrow_outcomes[1].kind, "miss",
        "Stone Arrow can miss its selected target")
    harness.equal(arrow_outcomes[2].target, next_foe,
        "a missed Stone Arrow continues to the next actor")

    local reflect_ctx = context(false, true)
    local reflected_plan = beam.plan(reflect_ctx, caster, foe, arrow)
    local reflected = beam.resolve(reflect_ctx, caster, foe,
        arrow, reflected_plan)

    harness.equal(reflected[1].kind, "reflect",
        "a reflection buckler reverses Stone Arrow")
    harness.truthy(reflect_ctx:get(caster, component.HEALTH).current < 20,
        "the returned Stone Arrow reaches its original caster")

    local continue_ctx = context(true, true, false, true)
    local continue_plan = beam.plan(continue_ctx, caster, foe, arrow)
    local continued = beam.resolve(continue_ctx, caster, foe,
        arrow, continue_plan)

    harness.equal(continued[1].kind, "reflect",
        "Stone Arrow reflects from the first shield")
    harness.equal(continued[2].kind, "miss",
        "the returned Stone Arrow can miss its caster")
    harness.equal(continued[3].target, next_foe,
        "a reflected Stone Arrow continues beyond a missed caster")

end

-- Compare contact poison with endpoint cloud placement across beam profiles.
local function poison_and_areas()
    local poison_spells = {
        spells.SPELL_VENOM_BOLT,
        spells.SPELL_SPIT_POISON,
    }

    for _, spell_id in ipairs(poison_spells) do
        local poison_ctx = context()
        local poison_health = poison_ctx:get(foe, component.HEALTH)

        poison_health.current = 100
        poison_health.maximum = 100
        poison_ctx:set(foe, component.HEALTH, poison_health)

        local effect = monster_spells.effect(spell_id)
        local plan = effect.plan(poison_ctx, caster, foe)

        effect.resolve(poison_ctx, caster, foe, nil, plan)

        harness.truthy(poison_ctx:get(foe, component.PROJECTILE_POISON),
            spell_id .. " stores poison on the hit monster")
    end

    local arrow_ctx = context()
    local arrow_health = arrow_ctx:get(foe, component.HEALTH)

    arrow_health.current = 100
    arrow_health.maximum = 100
    arrow_ctx:set(foe, component.HEALTH, arrow_health)

    local poison_arrow = monster_spells.effect(spells.SPELL_POISON_ARROW)
    local poison_plan = poison_arrow.plan(arrow_ctx, caster, foe)

    poison_arrow.resolve(arrow_ctx, caster, foe, nil, poison_plan)

    harness.equal(arrow_ctx:get(foe, component.PROJECTILE_POISON).degree, 4,
        "Poison Arrow adds four forced poison stacks")

    local cloud_ctx = context(false, false, true)
    local freezing = monster_spells.effect(spells.SPELL_FREEZING_CLOUD)
    local cloud_plan = freezing.plan(cloud_ctx, caster, foe)

    freezing.resolve(cloud_ctx, caster, foe, nil, cloud_plan)

    local clouds = cloud_ctx:query({ component.WORLD_CLOUD })

    harness.equal(#clouds, 10,
        "Freezing Cloud places its ten source cloud cells")
    harness.equal(cloud_ctx:get(clouds[1], component.WORLD_CLOUD).source_actor_id,
        caster, "the cloud retains its monster caster for saves")

    local east_cloud = false

    for _, entity in ipairs(clouds) do
        local state = cloud_ctx:get(entity, component.WORLD_CLOUD)

        if state.x == 5 and state.y == 1 then
            east_cloud = true
        end
    end

    harness.truthy(east_cloud,
        "the source cloud targeter can spread around a blocked center ray")

    local cloud_cases = {
        {
            spell_id = spells.SPELL_POISONOUS_CLOUD,
            cloud_id = cloud_ids.CLOUD_POISON,
        },
        {
            spell_id = spells.SPELL_NOXIOUS_CLOUD,
            cloud_id = cloud_ids.CLOUD_MEPHITIC,
        },
    }

    for _, case in ipairs(cloud_cases) do
        local spell_ctx = context()
        local effect = monster_spells.effect(case.spell_id)
        local plan = effect.plan(spell_ctx, caster, foe)

        effect.resolve(spell_ctx, caster, foe, nil, plan)

        local placed = spell_ctx:query({ component.WORLD_CLOUD })

        harness.equal(#placed, 12,
            case.spell_id .. " places its source maximum cloud count")

        for _, entity in ipairs(placed) do
            local state = spell_ctx:get(entity, component.WORLD_CLOUD)

            harness.equal(state.kind_id, case.cloud_id,
                case.spell_id .. " places its source cloud kind")
        end
    end

    local blast_spells = {
        spells.SPELL_FIREBALL,
        spells.SPELL_HURL_DAMNATION,
    }

    for _, spell_id in ipairs(blast_spells) do
        local blast_ctx = context(true)
        local first_health = blast_ctx:get(foe, component.HEALTH)
        local second_health = blast_ctx:get(next_foe, component.HEALTH)

        first_health.current = 100
        first_health.maximum = 100
        second_health.current = 100
        second_health.maximum = 100
        blast_ctx:set(foe, component.HEALTH, first_health)
        blast_ctx:set(next_foe, component.HEALTH, second_health)

        local effect = monster_spells.effect(spell_id)
        local plan = effect.plan(blast_ctx, caster, foe)

        effect.resolve(blast_ctx, caster, foe, nil, plan)

        harness.truthy(blast_ctx:get(foe, component.HEALTH).current < 100,
            spell_id .. " hits the actor at its explosion center")
        harness.truthy(blast_ctx:get(next_foe,
            component.HEALTH).current < 100,
            spell_id .. " hits another actor in its source radius")
    end

end

-- Draining, reflection, and bounce cases assert the contact sequence as well
-- as the final damage, because each contact can consume its own RNG draw.
local function draining_projectiles_and_bounces()
    local draining_spells = {
        spells.SPELL_BOLT_OF_DRAINING,
        spells.SPELL_GHOSTLY_FIREBALL,
    }

    for _, spell_id in ipairs(draining_spells) do
        local drain_ctx = context()
        local health = drain_ctx:get(foe, component.HEALTH)

        health.current = 100
        health.maximum = 100
        drain_ctx:set(foe, component.HEALTH, health)

        local effect = monster_spells.effect(spell_id)
        local plan = effect.plan(drain_ctx, caster, foe)

        effect.resolve(drain_ctx, caster, foe, nil, plan)

        harness.truthy(drain_ctx:get(foe, component.MONSTER_DRAINED),
            spell_id .. " stores the source drained status")
    end

    local projectile_spells = {
        spells.SPELL_BOLT_OF_COLD,
        spells.SPELL_BOLT_OF_FIRE,
        spells.SPELL_BOLT_OF_MAGMA,
        spells.SPELL_CHILLING_BREATH,
        spells.SPELL_COLD_BREATH,
        spells.SPELL_ELECTRICAL_BOLT,
        spells.SPELL_ENERGY_BOLT,
        spells.SPELL_FIRE_BREATH,
        spells.SPELL_IRON_SHOT,
        spells.SPELL_HOLY_BREATH,
        spells.SPELL_LEHUDIBS_CRYSTAL_SPEAR,
        spells.SPELL_LIGHTNING_BOLT,
        spells.SPELL_MAGIC_DART,
        spells.SPELL_METAL_SPLINTERS,
        spells.SPELL_SEARING_BREATH,
        spells.SPELL_SPIT_LAVA,
        spells.SPELL_STONE_ARROW,
        spells.SPELL_STEAM_BALL,
        spells.SPELL_SPLINTERSPRAY,
        spells.SPELL_THORN_VOLLEY,
        spells.SPELL_THROW_FLAME,
        spells.SPELL_THROW_FROST,
        spells.SPELL_THROW_ICICLE,
    }

    for _, spell_id in ipairs(projectile_spells) do
        local projectile_ctx = context()
        local effect = monster_spells.effect(spell_id)
        local plan = effect.plan(projectile_ctx, caster, foe)

        harness.truthy(plan, spell_id .. " plans a source trajectory")

        local result = effect.resolve(projectile_ctx, caster, foe,
            nil, plan)

        harness.equal(result[1].target, foe,
            spell_id .. " contacts its selected actor")
    end

    -- Each elemental breath penetrates the first target and reaches the
    -- second one; a copied one-target projectile rule would fail here.
    local breath_spells = {
        spells.SPELL_CHILLING_BREATH,
        spells.SPELL_COLD_BREATH,
        spells.SPELL_FIRE_BREATH,
        spells.SPELL_SEARING_BREATH,
    }

    for _, spell_id in ipairs(breath_spells) do
        local breath_ctx = context(true)
        local effect = monster_spells.effect(spell_id)
        local plan = effect.plan(breath_ctx, caster, foe)
        local contacts = effect.resolve(breath_ctx, caster, foe,
            nil, plan)

        harness.equal(contacts[1].target, foe,
            spell_id .. " reaches the chosen foe first")
        harness.equal(contacts[2].target, next_foe,
            spell_id .. " penetrates to the second actor")
    end

    -- Both fragment zaps are piercing rays even though triple armour can
    -- reduce each contact to zero damage.
    local fragment_spells = {
        spells.SPELL_METAL_SPLINTERS,
        spells.SPELL_SPLINTERSPRAY,
    }

    for _, spell_id in ipairs(fragment_spells) do
        local nearby = spell_id == spells.SPELL_SPLINTERSPRAY
        local fragment_ctx = context(true, false, false, false, false,
            nearby)
        local effect = monster_spells.effect(spell_id)
        local plan = effect.plan(fragment_ctx, caster, foe)
        local contacts = effect.resolve(fragment_ctx, caster, foe,
            nil, plan)

        harness.equal(contacts[1].target, foe,
            spell_id .. " reaches the selected target first")
        harness.equal(contacts[2].target, next_foe,
            spell_id .. " penetrates to a second actor")
    end

    local holy_ctx = context()
    local holy_breath = monster_spells.effect(spells.SPELL_HOLY_BREATH)
    local holy_plan = holy_breath.plan(holy_ctx, caster, foe)

    holy_breath.resolve(holy_ctx, caster, foe, nil, holy_plan)

    local holy_clouds = holy_ctx:query({ component.WORLD_CLOUD })

    harness.equal(#holy_clouds, 12,
        "Holy Breath places its source variable cloud count")

    for _, entity in ipairs(holy_clouds) do
        harness.equal(holy_ctx:get(entity,
            component.WORLD_CLOUD).kind_id, cloud_ids.CLOUD_HOLY,
            "Holy Breath places holy cloud cells")
    end

    local miasma_ctx = context()
    local miasma_health = miasma_ctx:get(foe, component.HEALTH)

    miasma_health.current = 100
    miasma_health.maximum = 100
    miasma_ctx:set(foe, component.HEALTH, miasma_health)

    local miasma = monster_spells.effect(spells.SPELL_MIASMA_BREATH)
    local miasma_plan = miasma.plan(miasma_ctx, caster, foe)

    miasma.resolve(miasma_ctx, caster, foe, nil, miasma_plan)

    harness.truthy(miasma_ctx:get(foe, component.PROJECTILE_POISON),
        "Miasma Breath poisons its living target")

    local miasma_clouds = miasma_ctx:query({ component.WORLD_CLOUD })

    harness.equal(#miasma_clouds, 10,
        "Miasma Breath places its fixed source cloud count")

    for _, entity in ipairs(miasma_clouds) do
        harness.equal(miasma_ctx:get(entity,
            component.WORLD_CLOUD).kind_id, cloud_ids.CLOUD_MIASMA,
            "Miasma Breath places miasma cloud cells")
    end

    local acid_spells = {
        spells.SPELL_CORROSIVE_BOLT,
        spells.SPELL_SPIT_ACID,
    }

    for _, spell_id in ipairs(acid_spells) do
        local acid_ctx = context()
        local health = acid_ctx:get(foe, component.HEALTH)

        health.current = 100
        health.maximum = 100
        acid_ctx:set(foe, component.HEALTH, health)

        local effect = monster_spells.effect(spell_id)
        local plan = effect.plan(acid_ctx, caster, foe)

        effect.resolve(acid_ctx, caster, foe, nil, plan)

        local state = acid_ctx:get(foe, component.MONSTER_ENCHANT)

        harness.truthy(state and state.corrosion_aut > 0,
            spell_id .. " stores corrosion on its target")
    end

    local quicksilver_ctx = context()
    local quicksilver_health = quicksilver_ctx:get(foe, component.HEALTH)

    quicksilver_health.current = 100
    quicksilver_health.maximum = 100
    quicksilver_ctx:set(foe, component.HEALTH, quicksilver_health)
    quicksilver_ctx:add(foe, component.MONSTER_ENCHANT, {
        blind_aut = 20,
        corrosion_aut = 0,
        invisible_aut = 0,
    })

    local quicksilver = monster_spells.effect(
        spells.SPELL_QUICKSILVER_BOLT)
    local quicksilver_plan = quicksilver.plan(quicksilver_ctx, caster, foe)

    quicksilver.resolve(quicksilver_ctx, caster, foe,
        nil, quicksilver_plan)

    harness.equal(quicksilver_ctx:get(foe, component.MONSTER_ENCHANT), nil,
        "Quicksilver Bolt dispels the target's saved enchantment")

    local undead_ctx = context()
    local undead_actor = undead_ctx:get(foe, component.ACTOR)
    local undead_health = undead_ctx:get(foe, component.HEALTH)

    undead_actor.kind_id = monsters.MONS_SKELETON
    undead_health.current = 100
    undead_health.maximum = 100
    undead_ctx:set(foe, component.ACTOR, undead_actor)
    undead_ctx:set(foe, component.HEALTH, undead_health)

    local dispel = monster_spells.effect(spells.SPELL_DISPEL_UNDEAD_RANGE)
    local dispel_plan = dispel.plan(undead_ctx, caster, foe)

    dispel.resolve(undead_ctx, caster, foe, nil, dispel_plan)

    harness.truthy(undead_ctx:get(foe, component.HEALTH).current < 100,
        "Dispel Undead damages a selected undead monster")

    local bouncing_spells = {
        spells.SPELL_LIGHTNING_BOLT,
        spells.SPELL_CRYSTAL_BOLT,
    }

    for _, spell_id in ipairs(bouncing_spells) do
        local bounce_ctx = context(false, false, false, false, true)
        local bounce_caster = bounce_ctx:get(caster, component.ACTOR)

        bounce_caster.kind_id = monsters.MONS_FIRE_DRAGON
        bounce_ctx:set(caster, component.ACTOR, bounce_caster)

        local effect = monster_spells.effect(spell_id)
        local bounce_plan = effect.plan(bounce_ctx, caster, foe)
        local bounced = effect.resolve(bounce_ctx, caster, foe,
            nil, bounce_plan)

        harness.equal(#bounced, 2,
            spell_id .. " contacts its target again after a wall bounce")
        harness.equal(bounced[2].target, foe,
            spell_id .. " keeps reflected contact order")
    end

end

-- Cover lasting effects that outlive direct damage, including terrain changes.
local function status_and_terrain()
    local stun_ctx = context()
    local stun_health = stun_ctx:get(foe, component.HEALTH)

    stun_health.current = 100
    stun_health.maximum = 100
    stun_ctx:set(foe, component.HEALTH, stun_health)

    local stunning = monster_spells.effect(spells.SPELL_STUNNING_BURST)
    local stun_plan = stunning.plan(stun_ctx, caster, foe)

    stunning.resolve(stun_ctx, caster, foe, nil, stun_plan)

    harness.equal(stun_ctx:get(foe, component.PARALYSIS).remaining_aut, 10,
        "Stunning Burst stores one source turn of paralysis")

    local sludge_ctx = context()
    local sludge_health = sludge_ctx:get(foe, component.HEALTH)

    sludge_health.current = 100
    sludge_health.maximum = 100
    sludge_ctx:set(foe, component.HEALTH, sludge_health)

    local sludge = monster_spells.effect(spells.SPELL_HURL_SLUDGE)
    local sludge_plan = sludge.plan(sludge_ctx, caster, foe)

    sludge.resolve(sludge_ctx, caster, foe, nil, sludge_plan)

    local bog = sludge_ctx:query({ component.TEMPORARY_TERRAIN })

    harness.equal(#bog, 1,
        "Hurl Sludge stores one temporary bog at the projectile endpoint")
    harness.equal(sludge_ctx:get(bog[1],
        component.TEMPORARY_TERRAIN).x, 4,
        "the bog sits at the hit actor's cell")
    harness.equal(sludge_ctx:cell(1, 4, 1),
        terrain_ids.DNGN_TOXIC_BOG,
        "Hurl Sludge changes the dungeon cell to toxic bog")

end

-- Movement hooks run after a landed contact; misses must leave positions and
-- lingering statuses unchanged.
local function contact_timing_and_movement()
    local profile = catalog.get("monster_beams", spells.SPELL_MAGIC_DART)
    local timing_ctx = context()
    local timing_plan = beam.plan(timing_ctx, caster, foe, profile)
    local phases = {}
    local timing = {}

    -- Assert flavour hooks see calculated damage before HP is subtracted.
    function timing.before_damage(ctx, _, defender, _, outcome)
        phases[#phases + 1] = "flavour"

        harness.equal(ctx:get(defender, component.HEALTH).current, 20,
            "flavour hooks run before the base HP subtraction")
        harness.truthy(outcome.damage > 0,
            "flavour hooks see the calculated damage")
    end

    -- Assert post-hit hooks observe the already reduced defender HP.
    function timing.after_hit(ctx, _, defender)
        phases[#phases + 1] = "contact"

        harness.truthy(ctx:get(defender, component.HEALTH).current < 20,
            "contact hooks run after the base HP subtraction")
    end

    beam.resolve(timing_ctx, caster, foe, profile, timing_plan, timing)

    harness.equal(#phases, 2,
        "source flavour and post-contact phases both execute")
    harness.equal(phases[1], "flavour",
        "flavour precedes post-contact effects")

    local blink_ctx = context(false, false, false, false, true)
    local blink_effect = monster_spells.effect(spells.SPELL_BLINKBOLT)
    local blink_plan = blink_effect.plan(blink_ctx, caster, foe)
    local blink_outcomes = blink_effect.resolve(blink_ctx, caster, foe,
        nil, blink_plan)

    harness.equal(#blink_outcomes, 1,
        "Blinkbolt does not bounce from solid walls")
    harness.equal(blink_ctx:get(caster, component.POSITION).x, 4,
        "Blinkbolt moves its caster to the last free ray cell")

    local harpoon_ctx = context()
    local harpoon_effect = monster_spells.effect(spells.SPELL_HARPOON_SHOT)
    local harpoon_plan = harpoon_effect.plan(harpoon_ctx, caster, foe)
    local harpoon_outcomes = harpoon_effect.resolve(harpoon_ctx,
        caster, foe, nil, harpoon_plan)

    harness.truthy(harpoon_outcomes[1].damage > 0,
        "Harpoon Shot deals damage before pulling")
    harness.equal(harpoon_ctx:get(foe, component.POSITION).x, 2,
        "Harpoon Shot pulls its target adjacent to the caster")

    local force_ctx = context(false, false, false, false, true)
    local force_effect = monster_spells.effect(spells.SPELL_FORCE_LANCE)
    local force_plan = force_effect.plan(force_ctx, caster, foe)
    local force_outcomes = force_effect.resolve(force_ctx,
        caster, foe, nil, force_plan)

    harness.truthy(force_outcomes[1].damage > 0,
        "Force Lance deals damage before knockback")
    harness.equal(force_ctx:get(foe, component.POSITION).x, 4,
        "Force Lance pushes its target to the wall")

    local reflected_force_ctx = context(false, true)
    local original_after_hit = force_effect.after_hit

    -- Intercept reflected Force Lance contact to verify its ray origin before knockback.
    force_effect.after_hit = function(ctx, source, defender,
        profile, outcome, incoming)
        harness.equal(incoming.x, 2,
            "a reflected contact carries the reflecting shield as ray origin")

        return original_after_hit(ctx, source, defender,
            profile, outcome, incoming)
    end

    local reflected_force_plan = force_effect.plan(reflected_force_ctx,
        caster, foe)
    local reflected_force = force_effect.resolve(reflected_force_ctx,
        caster, foe, nil, reflected_force_plan)

    force_effect.after_hit = original_after_hit

    harness.equal(reflected_force[1].kind, "reflect",
        "Force Lance can return from a reflecting shield")
    harness.equal(reflected_force[2].kind, "hit",
        "returned Force Lance hits its original caster")
    harness.truthy(reflected_force[2].damage > 0,
        "returned Force Lance deals damage before pushing")
    harness.truthy(reflected_force_ctx:get(caster,
        component.POSITION).x < 1,
        "reflected Force Lance pushes away from the reflecting shield")

    local freeze_ctx = context()
    local freeze_health = freeze_ctx:get(foe, component.HEALTH)

    freeze_health.current = 100
    freeze_health.maximum = 100
    freeze_ctx:set(foe, component.HEALTH, freeze_health)

    local flash_freeze = monster_spells.effect(spells.SPELL_FLASH_FREEZE)
    local freeze_plan = flash_freeze.plan(freeze_ctx, caster, foe)
    local first_freeze = flash_freeze.resolve(freeze_ctx,
        caster, foe, nil, freeze_plan)
    local frozen = freeze_ctx:get(foe, component.FLASH_FROZEN)

    harness.truthy(first_freeze[1].damage > 0,
        "the first Flash Freeze hit deals cold damage")
    harness.truthy(frozen and frozen.remaining_aut > 0,
        "Flash Freeze persists an ice encasement")

    local second_freeze = flash_freeze.resolve(freeze_ctx,
        caster, foe, nil, freeze_plan)

    harness.equal(second_freeze[1].damage, 0,
        "Flash Freeze deals no repeated damage while ice remains")

    local sleep_ctx = context()
    local sleep_effect = monster_spells.effect(spells.SPELL_SLEEP)
    local sleep_plan = sleep_effect.plan(sleep_ctx, caster, foe)
    local sleep_outcomes = sleep_effect.resolve(sleep_ctx,
        caster, foe, nil, sleep_plan)
    local stasis = sleep_ctx:get(foe, component.MONSTER_STASIS)

    harness.equal(sleep_outcomes[1].damage, 0,
        "Sleep has no base HP damage")
    harness.truthy(stasis and stasis.hibernating,
        "Sleep persists the monster's sleeping state")

    local dig_ctx = context(false, false, false, false, true)
    local dig_effect = monster_spells.effect(spells.SPELL_DIG)
    local dig_plan = dig_effect.plan(dig_ctx, caster, foe)

    harness.truthy(dig_plan,
        "Dig can target a destructible wall along its ray")
    dig_effect.resolve(dig_ctx, caster, foe, nil, dig_plan)

    harness.equal(dig_ctx:cell(1, 5, 1), terrain_ids.DNGN_FLOOR,
        "Dig breaks a rock wall beyond an actor without damaging them")

    local wave_ctx = context()
    local wave_effect = monster_spells.effect(spells.SPELL_PRIMAL_WAVE)
    local wave_plan = wave_effect.plan(wave_ctx, caster, foe)
    local wave_outcomes = wave_effect.resolve(wave_ctx,
        caster, foe, nil, wave_plan)

    harness.equal(wave_outcomes[1].kind, "hit",
        "Primal Wave contacts the selected actor")
    harness.equal(wave_ctx:get(foe, component.POSITION).x, 5,
        "Primal Wave knocks back its target")
    harness.equal(wave_ctx:cell(1, 4, 1),
        terrain_ids.DNGN_SHALLOW_WATER,
        "Primal Wave leaves a temporary pool at impact")
    harness.truthy(#wave_ctx:query({ component.TEMPORARY_TERRAIN }) > 0,
        "Primal Wave persists temporary water markers")

    local sticky_ctx = context()
    local sticky_effect = monster_spells.effect(
        spells.SPELL_STICKY_FLAME_RANGE)
    local sticky_plan = sticky_effect.plan(sticky_ctx, caster, foe)

    sticky_effect.resolve(sticky_ctx, caster, foe, nil, sticky_plan)

    local sticky_state = sticky_ctx:get(foe, component.STICKY_FLAME)

    harness.truthy(sticky_state and sticky_state.remaining_aut > 0,
        "Sticky Flame Range persists a burning status")
    harness.equal(sticky_state.source, caster,
        "Sticky Flame Range attributes future burns to the caster")

    local pie_ctx = context()

    -- Force the first pie filling so the status assertion is deterministic.
    function pie_ctx:random()
        return 0
    end

    local pie_effect = monster_spells.effect(spells.SPELL_THROW_PIE)
    local pie_plan = pie_effect.plan(pie_ctx, caster, foe)
    local pie_outcomes = pie_effect.resolve(pie_ctx,
        caster, foe, nil, pie_plan)

    harness.truthy(pie_outcomes[1].damage > 0,
        "Throw Pie must hurt before choosing a filling")
    harness.truthy(pie_ctx:has(foe, component.MONSTER_MUTE),
        "a blueberry pie stores the monster mute effect")
end

-- Run ray, AoE, status, and hook-order cases against isolated fixture contexts.
function test.run()
    basic_trajectory()
    poison_and_areas()
    draining_projectiles_and_bounces()
    status_and_terrain()
    contact_timing_and_movement()
end

return test
