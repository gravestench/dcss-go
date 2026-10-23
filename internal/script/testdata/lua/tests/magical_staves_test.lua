-- A mod-added staff without rules is rejected at catalog validation.

local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local harness = require("tests.harness")
local items = require("ids.items")
local schools = require("constants.spell_schools")
local skills = require("ids.skills")
local staves = require("policy.inventory.staves")
local equipment = require("policy.inventory.equipment")
local fighter = require("policy.combat.fighter")
local enhancement = require("policy.magic.enhancement")
local save_equipment = require("policy.save.equipment")
local species = require("ids.species")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local player_staves = require("policy.combat.player_staves")
local player_brands = require("policy.combat.monster_target_brands")
local mutation_records = require("policy.mutations.records")
local mutations = require("ids.mutations")
local elemental_damage = require("policy.magic.damage")
local player_resistance = require("policy.combat.player_resistance")
local resistances = require("constants.resistance_ids")
local input_items = require("policy.input.items")
local modals = require("policy.presentation.modals")
local object_classes = require("ids.object_classes")
local input_commands = require("policy.input.commands")
local gods = require("constants.gods")
local component = require("constants.component")

local test = {}

local expected = {
    {
        id = items.STAFF_FIRE,
        school = schools.FIRE,
        skill = skills.SK_FIRE_MAGIC,
    },

    {
        id = items.STAFF_COLD,
        school = schools.ICE,
        skill = skills.SK_ICE_MAGIC,
    },

    {
        id = items.STAFF_POISON,
        school = schools.POISON,
        skill = skills.SK_POISON_MAGIC,
    },

    {
        id = items.STAFF_DEATH,
        school = schools.NECROMANCY,
        skill = skills.SK_NECROMANCY,
    },

    {
        id = items.STAFF_CONJURATION,
        school = schools.CONJURATION,
        skill = skills.SK_CONJURATIONS,
    },

    {
        id = items.STAFF_AIR,
        school = schools.AIR,
        skill = skills.SK_AIR_MAGIC,
    },

    {
        id = items.STAFF_EARTH,
        school = schools.EARTH,
        skill = skills.SK_EARTH_MAGIC,
    },
}

-- Drive the activation roll low and later damage rolls high, making staff
-- probability and damage assertions repeatable without a seeded world.
local function deterministic_random()
    local draws = 0

    -- Use a different edge after the first draw to distinguish activation
    -- from subsequent damage scaling in the staff rule.
    return function(_, _, bound)
        draws = draws + 1

        if draws == 1 then
            return 0
        end

        return bound - 1
    end
end

-- Overlay just the player lookup on a real ECS context so combat consumers
-- use the fixture actor without copying the host API.
local function player_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    -- Return the created actor even when the underlying context has a
    -- different current player for another test.
    function proxy.player()
        return player
    end

    return proxy
end

-- Create a real carried staff entity; later tests attach EQUIPPED only when
-- they need wielded bonuses to apply.
local function equip(ctx, player, id)
    local entity = ctx:create()

    ctx:add(entity, "core.item", {
        kind_id = id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(entity, "core.carried_by", {
        holder = player,
    })

    return entity
end

-- Maximize Evocations and each relevant school to make staff procs observable
-- while leaving their base weapon-skill path separate.
local function trained_skills()
    local entries = {
        {
            id = skills.SK_EVOCATIONS,
            level = 27,
            points = 0,
        },
    }

    for _, entry in ipairs(expected) do
        entries[#entries + 1] = {
            id = entry.skill,
            level = 27,
            points = 0,
        }
    end

    return entries
end

-- Give the rat enough HP to survive every proc so damage amounts can be
-- compared across staff types on the same defender profile.
local function target(ctx)
    local entity = ctx:create()
    local rat = catalog.get(categories.MONSTERS, monsters.MONS_RAT)

    ctx:add(entity, "core.actor", {
        kind_id = rat.id,
        speed = rat.speed,
    })
    ctx:add(entity, "core.health", {
        current = 1000,
        max = 1000,
    })

    return entity, rat
end

-- Recreate the deterministic activation/damage draw sequence for each staff
-- so earlier staff tests cannot shift later outcomes.
local function staff_random()
    local draws = 0

    -- Force activation on the first call, then maximum legal later rolls to
    -- expose each staff's damage and resistance formula.
    return function(_, _, bound)
        draws = draws + 1

        if draws == 1 then
            return 0
        end

        return bound - 1
    end
end

-- Search rendered modal rows by visible text rather than internal row IDs,
-- proving the player can actually find staves in the terminal menu.
local function contains_text(rows, wanted)
    for _, row in ipairs(rows.writes) do
        if row.text and row.text:find(wanted, 1, true) then
            return true
        end
    end

    return false
end

-- Exercise input and presentation with one staff candidate, verifying the
-- existing wield command and inventory group display include this class.
local function check_terminal()
    local candidate = {
        id = 7,
        class = object_classes.OBJ_STAVES,
        name = "staff of fire",
        slot = "",
        quantity = 1,
    }

    harness.truthy(input_items.weapon(candidate),
        "wield input accepts the magical staff class")

    local selection = input_items.wield({
        key = "a",
        inventory = { candidate },
    })

    harness.equal(selection.kind, input_commands.wield,
        "the terminal dispatches the existing wield command")
    harness.equal(selection.item_id, candidate.id,
        "the terminal selects the staff entity")
    harness.truthy(contains_text(modals.rows({
        mode = "wield",
        inventory = { candidate },
        height = 24,
    }), "staff of fire"), "wield modal lists a staff")
    harness.truthy(contains_text(modals.rows({
        mode = "inventory",
        inventory = { candidate },
        height = 24,
    }), "Magical Staves"), "inventory groups magical staves")
end

-- The catalog probe rejects a staff with no effect rule before combat can
-- dispatch it as an ordinary weapon.
local function check_catalog()
    for _, entry in ipairs(expected) do
        local definition = catalog.get(categories.ITEMS, entry.id)
        local profile = staves.weapon(definition)

        harness.equal(profile.damage, 5, entry.id .. " base damage")
        harness.equal(profile.hit, 5, entry.id .. " base hit")
        harness.equal(profile.speed, 12, entry.id .. " base delay")
        harness.equal(profile.skill_id, skills.SK_STAVES,
            entry.id .. " melee skill")
        harness.equal(definition.staff.school, entry.school,
            entry.id .. " spell school")
        harness.equal(definition.staff.skill_id, entry.skill,
            entry.id .. " proc skill")
        harness.equal(staves.enhances(definition, {
            schools = { entry.school },
        }), 1, entry.id .. " enhances its school")
        harness.equal(staves.enhances(definition, {
            schools = { schools.HEXES },
        }), 0, entry.id .. " does not enhance another school")
    end

    harness.equal(staves.resistance({
        class = object_classes.OBJ_STAVES,
        staff = {
            resistance_id = resistances.FIRE,
        },
    }, resistances.FIRE), 1,
        "a mod-added staff's metadata grants its resistance")

    local valid = pcall(staves.weapon, {
        id = "MOD_BROKEN_STAFF",
        class = object_classes.OBJ_STAVES,
        slot = "weapon",
    })

    harness.falsy(valid,
        "a mod-added staff without rules is rejected at catalog validation")

    local roll_ctx = {
        random = deterministic_random(),
    }

    harness.equal(staves.roll_damage(roll_ctx, 1000, 2000, 500), 17,
        "source activation and damage rolls use magic and Evocations")
end

-- Install only the character components staff rules need, so missing state
-- dependencies become visible in this focused fixture.
local function create_player(ctx)
    local player = ctx:create()
    local battle = player_context(ctx, player)

    ctx:add(player, "core.player", {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Staff test",
        starting_weapon_id = items.WPN_UNARMED,
    })
    ctx:add(player, "core.attributes", {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, "core.skills", {
        entries = {},
    })
    ctx:add(player, "core.combat", {
        shield_blocks = 0,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.ZIN,
        piety = 50,
    })

    return battle, player
end

-- Wield every committed staff and compare melee profile, spell enhancement,
-- resistance, meld suppression, and save validity through shared consumers.
local function check_wielding(ctx, battle, player)
    for _, entry in ipairs(expected) do
        local entity = equip(ctx, player, entry.id)
        local result = equipment.prepare_wield(battle, player,
            ctx:id(entity))

        harness.equal(result.cost, 5, entry.id .. " uses wield timing")
        harness.equal(result.intent.kind, 11,
            entry.id .. " uses the existing wield intent")

        ctx:add(entity, "core.equipped", {
            slot = "weapon",
        })

        local attack = fighter.attack(battle, { ev = 0, ac = 0 })

        harness.equal(attack.weapon_damage, 5,
            entry.id .. " uses the shared melee profile")
        harness.equal(attack.weapon_skill, skills.SK_STAVES,
            entry.id .. " trains Staves for base melee")
        harness.equal(enhancement.apply(battle, player, {
            schools = { entry.school },
        }, 100), 150, entry.id .. " enhances its spells")

        local staff = catalog.get(categories.ITEMS, entry.id).staff

        if staff.resistance_id == resistances.POISON then
            harness.equal(player_resistance.poison(battle, player), 1,
                "staff of poison grants rPois")
        elseif staff.resistance_id then
            harness.equal(elemental_damage.player_resistance(battle,
                player, staff.resistance_id), 1,
                entry.id .. " grants its elemental resistance")
        end

        ctx:add(player, "magic.player_form", {
            form_id = "ice_beast",
            remaining_aut = 30,
            power = 40,
        })
        harness.equal(enhancement.apply(battle, player, {
            schools = { entry.school },
        }, 100), 100, entry.id .. " stops enhancing when melded")
        ctx:remove(player, "magic.player_form")

        harness.truthy(pcall(save_equipment.run, battle),
            entry.id .. " passes equipped save validation")
        ctx:remove(entity, "core.equipped")
    end
end

-- Staff activation rolls use Magic and Evocations after the physical melee
-- contact, so both damage paths are asserted separately.
local function check_melee(ctx, battle, player)
    ctx:set(player, "core.skills", {
        entries = trained_skills(),
    })

    local defender, rat = target(ctx)

    for _, entry in ipairs(expected) do
        local definition = catalog.get(categories.ITEMS, entry.id)
        local health = ctx:get(defender, "core.health")

        health.current = 1000
        ctx:set(defender, "core.health", health)
        battle.random = staff_random()

        local hit = {
            attacker = player,
            defender = defender,
            definition = rat,
            damage_done = 1,
            health = health,
        }

        player_staves.apply(battle, hit, player_brands,
            definition, 10)

        if entry.id == items.STAFF_DEATH then
            local worship = ctx:get(player, component.RELIGION_WORSHIP)

            harness.equal(worship.penance[gods.ZIN], 4,
                "a damaging staff of death proc reports evil conduct")
        end

        harness.truthy(hit.health.current < 1000,
            entry.id .. " activates its source-backed melee proc")

        if entry.id == items.STAFF_CONJURATION then
            harness.equal(hit.health.current, 961,
                "conjuration rolls normal AC against the magical proc")
        elseif entry.id == items.STAFF_EARTH then
            harness.equal(hit.health.current, 965,
                "earth rolls AC three times after its 4/3 multiplier")
        end
    end

    harness.truthy(ctx:has(defender, "projectile.poison"),
        "staff of poison leaves its saved poison effect")

    mutation_records.grant_acquired(ctx, player,
        mutations.MUT_NO_ARTIFICE, 1)

    local health = ctx:get(defender, "core.health")
    health.current = 1000
    ctx:set(defender, "core.health", health)
    battle.random = staff_random()

    player_staves.apply(battle, {
        attacker = player,
        defender = defender,
        definition = rat,
        damage_done = 1,
        health = health,
    }, player_brands, catalog.get(categories.ITEMS, items.STAFF_FIRE), 0)

    harness.equal(ctx:get(defender, "core.health").current, 1000,
        "No Artifice prevents only the staff's magical damage")
end

-- Cover terminal selection, catalog rules, wielding, and magical melee procs
-- together because a usable staff needs all four paths to agree.
function test.run(ctx)
    check_terminal()
    check_catalog()

    local battle, player = create_player(ctx)

    check_wielding(ctx, battle, player)
    check_melee(ctx, battle, player)
end

return test
