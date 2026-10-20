-- The committed overflow family must include every source NAME as an
-- effective DES file. The ordinary extra-vault catalog excludes this family
-- until its scheduled god assignment chooses a specific map.
local catalog = require("policy.generation.altar.catalog")
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local names = require("constants.vault_feature_names")
local ordinary = require("policy.generation.vaults.catalog")
local operations = require("policy.generation.vaults.operations")
local settings = require("constants.vault_settings")
local tags = require("constants.vault_tags")

local test = {}

-- Run an actual parsed hook with a minimal record sink. This checks the DES
-- reference and production Lua together, without copying their definitions.
local function records_for(id, method)
    local definition = catalog.get(id)
    local found = false
    local records = {}
    local api = {}

    function api:record(kind, arguments)
        records[#records + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN and
            operation.argument == method then
            hooks.run(definition, method, api)
            found = true
        end
    end

    harness.truthy(found, id .. " has its source-position " .. method .. " hook")

    return records
end

-- The source's repeated renames share a Lua implementation but every map
-- must retain its own hook, so no vault silently loses its displayed name.
local function assert_feature_names()
    local gold_maps = {
        "grunt_gozag_statues",
        "grunt_gozag_breadcrumbs",
        "nicolae_gozag_conspicuous_consumption",
        "grunt_temple_overflow_opulence",
        "grunt_temple_overflow_gold_and_silver",
    }

    for _, id in ipairs(gold_maps) do
        local records = records_for(id, "features.golden_statue")

        harness.equal(#records, 1, id .. " records one golden statue name")
        harness.equal(records[1].kind, effects.FEATURE_NAME)
        harness.equal(records[1].arguments.feature, features.GRANITE_STATUE)
        harness.equal(records[1].arguments.name, names.GOLDEN_STATUE)
    end

    local cases = {
        { "grunt_temple_overflow_gold_and_silver", "features.silver_wall",
            features.METAL_WALL, names.SILVER_WALL },
        { "nemelex_diamond_rough_becter", "features.white_crystal_wall",
            features.CRYSTAL_WALL, names.WHITE_CRYSTAL_WALL },
        { "nicolae_yredelemnul_corpse_copse", "features.dead_tree",
            features.TREE, names.DEAD_TREE },
        { "gammafunk_temple_of_torment", "features.sarcophagus",
            features.GRANITE_STATUE, names.SARCOPHAGUS },
        { "worldfamousw_hep_ancestral_shrine", "features.gravestone",
            features.GRANITE_STATUE, names.GRAVESTONE },
        { "worldfamousw_hep_ancestral_shrine", "features.dead_tree",
            features.TREE, names.DEAD_TREE },
    }

    for _, entry in ipairs(cases) do
        local records = records_for(entry[1], entry[2])

        harness.equal(#records, 1, entry[1] .. " records one feature name")
        harness.equal(records[1].kind, effects.FEATURE_NAME)
        harness.equal(records[1].arguments.feature, entry[3])
        harness.equal(records[1].arguments.name, entry[4])
    end
end

-- Delayed decay must remain attached to the source D/E corpse glyphs instead
-- of replacing them with permanent scenery during map parsing.
local function assert_dancefloor_decay()
    local records = records_for(
        "nicolae_uskayaw_murder_on_the_dancefloor", "decay_dancers")

    harness.equal(#records, 1)
    harness.equal(records[1].kind, effects.DELAYED_DECAY)
    harness.equal(records[1].arguments.glyph, "DE")
    harness.equal(records[1].arguments.alternatives, "random corpse")
end

-- Run count-driven source blocks using the same local setting future floor
-- placement must provide. This also proves every DES points to its Lua file.
local function arrangement_for(id, selected)
    local definition = catalog.get(id)
    local emissions = {}
    local api = {}
    local found = false

    function api:setting(key)
        harness.equal(key, settings.OVERFLOW_ALTAR_COUNT)

        return selected
    end

    function api:emit(kind, argument)
        emissions[#emissions + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN and
            operation.argument == "arrange_altars" then
            hooks.run(definition, operation.argument, api)
            found = true
        end
    end

    harness.truthy(found, id .. " has its source count hook")

    return emissions
end

-- Each placement test starts from the actual authored MAP rows. Reusing a
-- mutated cell grid would hide substitutions left by a previous branch.
local function copy_rows(definition)
    local cells = {}

    for y, row in ipairs(definition.rows) do
        cells[y] = {}

        for x = 1, #row do
            cells[y][x] = row:sub(x, x)
        end
    end

    return cells
end

-- The layout stream is fixed here so the test isolates hook and directive
-- behavior from unrelated random choices in the same source vault.
local function fixed_random()
    local random = {}

    function random:roll()
        return 0
    end

    function random:one_in()
        return true
    end

    return random
end

-- Exercise every count-bearing map at its limits and check cases whose
-- source substitutions depend on both count and directive order.
local function assert_count_arrangements()
    local ranges = {
        { "minitemple", 2, 14 },
        { "chequers_temple_overflow_minitemple", 3, 5 },
        { "chequers_temple_overflow_statue_of_worship", 2, 4 },
        { "gammafunk_temple_overflow_arena", 1, 3 },
        { "grunt_temple_overflow_open", 1, 8 },
        { "nicolae_overflow_hallway_of_the_gods", 5, 11 },
        { "nicolae_overflow_hidden_temple", 1, 5 },
        { "nicolae_overflows_in_rows", 9, 15 },
    }

    for _, entry in ipairs(ranges) do
        for selected = entry[2], entry[3] do
            arrangement_for(entry[1], selected)
        end

        local valid = pcall(arrangement_for, entry[1], nil)

        harness.falsy(valid, entry[1] .. " rejects an absent count")
    end

    local mini = arrangement_for("minitemple", 9)

    harness.equal(mini[1].kind, directives.NSUBST)
    harness.equal(mini[1].argument, "B : 9:B / *:x")

    local statue = arrangement_for(
        "chequers_temple_overflow_statue_of_worship", 2)

    harness.equal(statue[1].argument, "C = .")
    harness.equal(statue[2].argument, "B = 2:B / *:.")

    local open = arrangement_for("grunt_temple_overflow_open", 8)

    harness.equal(#open, 1)
    harness.equal(open[1].argument, "defghijk = B")

    local hall = arrangement_for(
        "nicolae_overflow_hallway_of_the_gods", 7)

    harness.equal(hall[1].kind, directives.SHUFFLE)
    harness.equal(hall[1].argument, "EFHJK")
    harness.equal(hall[2].argument, "DEFH : B")

    local hidden = arrangement_for("nicolae_overflow_hidden_temple", 3)

    harness.equal(hidden[1].argument, "ae/bd")
    harness.equal(hidden[2].argument, "cbd = B")
    harness.equal(hidden[3].argument, "ae = G")

    local rows = arrangement_for("nicolae_overflows_in_rows", 12)

    harness.equal(rows[1].argument, "T=.")
    harness.equal(rows[#rows].argument, "Z=E")
end

-- Parsing hooks alone would miss a malformed emitted SUBST or SHUFFLE.
-- Apply each count map to a fresh copy of its real DES rows at both ends
-- of its capacity and verify that an altar glyph survives each layout.
local function assert_count_maps_apply()
    local ranges = {
        { "minitemple", 2, 14 },
        { "chequers_temple_overflow_minitemple", 3, 5 },
        { "chequers_temple_overflow_statue_of_worship", 2, 4 },
        { "gammafunk_temple_overflow_arena", 1, 3 },
        { "grunt_temple_overflow_open", 2, 8 },
        { "nicolae_overflow_hallway_of_the_gods", 5, 11 },
        { "nicolae_overflow_hidden_temple", 1, 5 },
        { "nicolae_overflows_in_rows", 9, 15 },
    }
    local random = fixed_random()

    for _, entry in ipairs(ranges) do
        local definition = catalog.get(entry[1])

        for _, selected in ipairs({ entry[2], entry[3] }) do
            local cells = copy_rows(definition)

            local player = {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 3,
                absolute_depth = 3,
                settings = {
                    [settings.OVERFLOW_ALTAR_COUNT] = selected,
                },
            }

            operations.apply(definition, cells, random, 3, player)

            local altars = 0

            for _, row in ipairs(cells) do
                for _, glyph in ipairs(row) do
                    if glyph == "B" then
                        altars = altars + 1
                    end
                end
            end

            harness.equal(altars, selected,
                entry[1] .. " keeps exactly its scheduled altar count")
        end
    end
end

-- Apply each branch's real vault operations rather than checking only the
-- hook output. This catches a forgotten active DES line from either arm.
local function monsters_for(id, branch_id, depth, absolute_depth)
    local definition = catalog.get(id)
    depth = depth or 5
    local player = {
        branch_id = branch_id,
        depth = depth,
        absolute_depth = absolute_depth or depth,
        branch_bottom = 15,
    }
    local records = operations.apply(
        definition, copy_rows(definition), fixed_random(), depth, player)
    local monsters = {}

    for _, record in ipairs(records) do
        if record.kind == effects.MONSTER then
            monsters[#monsters + 1] = record.identity
        end
    end

    return monsters
end

-- Each depth-scaled map must materialize just one source roster. Running
-- the actual operation pipeline also validates equipment and named monster
-- expressions emitted by the larger Trog and torment handlers.
local function assert_depth_monsters()
    local cases = {
        { "grunt_temple_overflow_bloody_war", 5, 8 },
        { "kennysheep_orc_sif_temple", 5, 6 },
        { "nemelex_dance_club_becter", 4, 5 },
        { "nicolae_tso_besieged_by_evil", 4, 5 },
        { "tgw_sif", 3, 5 },
        { "tgw_trog", 5, 16 },
        { "trog_antimagical", 5, 6 },
        { "trog_butcher_becter", 5, 6 },
        { "trog_ov_bears_minmay", 9, 10 },
        { "gammafunk_temple_of_torment", 4, 8 },
    }

    for _, entry in ipairs(cases) do
        local early = monsters_for(
            entry[1], branches.BRANCH_DUNGEON, entry[2], entry[2])
        local late = monsters_for(
            entry[1], branches.BRANCH_DUNGEON, entry[3], entry[3])

        harness.truthy(#early > 0, entry[1] .. " has an early roster")
        harness.truthy(#late > 0, entry[1] .. " has a late roster")
        harness.falsy(table.concat(early, "|") == table.concat(late, "|"),
            entry[1] .. " changes its roster at the source threshold")
    end

    local middle = monsters_for(
        "gammafunk_temple_of_torment", branches.BRANCH_DUNGEON, 6, 6)

    harness.truthy(#middle > 0, "torment temple has a middle roster")

    local deep_sif = monsters_for(
        "tgw_sif", branches.BRANCH_DEPTHS, 2, 18)

    harness.equal(deep_sif[1], "deep elf annihilator",
        "Depths chooses Sif Muna's late source guardian")
end

-- The blood cavern's sole source coin flip schedules either a corpse and
-- hound or a necrophage and skeleton. The two scenes must not mix.
local function assert_blood_cavern_scenes()
    local definition = catalog.get("makhleb_blood_cavern_becter")
    local player = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 5,
        absolute_depth = 5,
    }
    local corpse = operations.apply(
        definition, copy_rows(definition), fixed_random(), 5, player)
    local skeleton_random = fixed_random()

    function skeleton_random:one_in()
        return false
    end

    local skeleton = operations.apply(
        definition, copy_rows(definition), skeleton_random, 5, player)
    local corpse_decay = 0
    local skeleton_decay = 0

    for _, record in ipairs(corpse) do
        if record.kind == effects.DELAYED_DECAY then
            corpse_decay = corpse_decay + 1
        end
    end

    for _, record in ipairs(skeleton) do
        if record.kind == effects.DELAYED_DECAY then
            skeleton_decay = skeleton_decay + 1
        end
    end

    harness.equal(corpse_decay, 1, "corpse scene records delayed decay")
    harness.equal(skeleton_decay, 0, "skeleton scene has no fresh corpse")
end

-- Run one named source script using controlled local context. The helper
-- obtains its method through the actual .des operation, so a renamed hook
-- cannot leave this test calling an obsolete Lua function directly.
local function simple_script(id, method, options)
    local definition = catalog.get(id)
    local emissions = {}
    local api = {}
    local found = false

    function api:one_in()
        return options.first_choice
    end

    function api:coinflip()
        return options.first_choice
    end

    function api:depth()
        return options.depth or 5
    end

    function api:absolute_depth()
        return options.absolute_depth or self:depth()
    end

    function api:map_tag()
        return options.map_tag
    end

    function api:emit(kind, argument)
        emissions[#emissions + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN and
            operation.argument == method then
            hooks.run(definition, method, api)
            found = true
        end
    end

    harness.truthy(found, id .. " calls its source script")

    return emissions
end

-- Compare each visual or roster branch without duplicating its DES schema.
local function assert_simple_source_scripts()
    local silver = simple_script(
        "dreamdust_divine_triumvirate", "choose_theme", {
            first_choice = true,
        })
    local gold = simple_script(
        "dreamdust_divine_triumvirate", "choose_theme", {
            first_choice = false,
        })

    harness.equal(#silver, 4)
    harness.equal(#gold, 3)
    harness.equal(silver[2].argument, "c = dngn_metal_wall_white")
    harness.equal(gold[1].argument, "c = wall_church")

    local shuffled = simple_script(
        "good_gods_mini_temple", "vary_garden", {
            first_choice = true,
        })
    local opened = simple_script(
        "good_gods_mini_temple", "vary_garden", {
            first_choice = false,
        })

    harness.equal(shuffled[1].kind, directives.SHUFFLE)
    harness.equal(opened[1].kind, directives.SUBST)

    local early = simple_script("grunt_dithmenos_shadows",
        "choose_shadows", { depth = 5, absolute_depth = 5 })
    local late = simple_script("grunt_dithmenos_shadows",
        "choose_shadows", { depth = 9, absolute_depth = 9 })

    harness.equal(early[1].argument,
        "phantom w:5 / shadow imp w:4")
    harness.equal(late[1].argument, "shadow")

    local trog = simple_script("lightli_temple_of_fire",
        "choose_altar", { map_tag = tags.TEMPLE_OVERFLOW_TROG })
    local makhleb = simple_script("lightli_temple_of_fire",
        "choose_altar", { map_tag = tags.TEMPLE_OVERFLOW_MAKHLEB })
    local untargeted = simple_script("lightli_temple_of_fire",
        "choose_altar", {})

    harness.equal(trog[1].argument, "_ = altar_trog")
    harness.equal(makhleb[1].argument, "_ = altar_makhleb")
    harness.equal(untargeted[1].argument,
        "_ = altar_trog / altar_makhleb")

    local definition = catalog.get("grunt_dithmenos_shadows")
    local player = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 5,
        absolute_depth = 5,
        branch_bottom = 15,
    }
    local records = operations.apply(
        definition, copy_rows(definition), fixed_random(), 5, player)
    local monsters = 0

    for _, record in ipairs(records) do
        if record.kind == effects.MONSTER then
            monsters = monsters + 1
        end
    end

    harness.equal(monsters, 1,
        "real placement receives one selected Dithmenos monster slot")
end

-- Shared source choices appear in several maps; test every caller and both
-- branches, including Crypt's separate mausoleum population.
local function assert_branch_monsters()
    local depth_maps = {
        "slow_altar_1",
        "slow_altar_2",
        "chei_slow_surprise",
        "kennysheep_okawaru_gauntlet",
        "kennysheep_vampire_church",
        "lemuel_zombie_altar_kikubaaqudgha",
        "nemelex_lonely_heart_becter",
        "nicolae_hepliaklqana_monster_ancestors",
        "okawaru_altar_gauntlet_db",
        "yredelemnul_forgotten_temple_becter",
    }

    for _, id in ipairs(depth_maps) do
        local dungeon = monsters_for(id, branches.BRANCH_DUNGEON)
        local depths = monsters_for(id, branches.BRANCH_DEPTHS)

        harness.truthy(#dungeon > 0, id .. " has Dungeon monsters")
        harness.truthy(#depths > 0, id .. " has Depths monsters")
        harness.falsy(table.concat(dungeon, "|") == table.concat(depths, "|"),
            id .. " changes its source population by branch")
    end

    for _, id in ipairs({
        "lemuel_mausoleum_altar_kikubaaqudgha",
        "lemuel_mausoleum_altar_yredelemnul",
    }) do
        local dungeon = monsters_for(id, branches.BRANCH_DUNGEON)
        local crypt = monsters_for(id, branches.BRANCH_CRYPT)

        harness.equal(#dungeon, 5,
            id .. " keeps four Dungeon slots and its keyed altar zombie")
        harness.equal(#crypt, 5,
            id .. " keeps four Crypt slots and its keyed altar zombie")
        harness.falsy(table.concat(dungeon, "|") == table.concat(crypt, "|"),
            id .. " changes its source population in Crypt")
    end
end

-- Run the map's production hook with a controlled floor context. Keep the
-- source method name in the DES file authoritative instead of importing a
-- handler module directly into this test.
local function depth_hook(id, method, options)
    local definition = catalog.get(id)
    local emissions = {}
    local api = {}
    local found = false

    function api:depth()
        return options.depth
    end

    function api:absolute_depth()
        return options.absolute_depth
    end

    function api:branch_bottom()
        return options.branch_bottom
    end

    function api:branch_id()
        return options.branch_id
    end

    function api:emit(kind, argument)
        emissions[#emissions + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    for _, operation in ipairs(definition.operations) do
        if operation.kind == directives.HOOK_RUN and
            operation.argument == method then
            hooks.run(definition, method, api)
            found = true
        end
    end

    harness.truthy(found, id .. " retains its source-position depth hook")

    return emissions
end

-- Compare both sides of each source condition, including branch bottoms.
-- A source-only DES line left active would also be caught by the placement
-- check below because it would add a duplicate typed declaration.
local function assert_depth_rules()
    local shallow = {
        depth = 3,
        absolute_depth = 3,
        branch_bottom = 4,
        branch_id = branches.BRANCH_DUNGEON,
    }
    local bottom = {
        depth = 4,
        absolute_depth = 10,
        branch_bottom = 4,
        branch_id = branches.BRANCH_DEPTHS,
    }
    local shaft_maps = {
        { "grunt_qazlal_sundering", "depth_rules.shaft_caret" },
        { "grunt_temple_overflow_forces_of_nature",
            "depth_rules.shaft_caret" },
        { "nemelex_spade_bored_becter", "depth_rules.shaft_a" },
        { "trog_butcher_becter", "depth_rules.shaft_caret" },
    }

    for _, entry in ipairs(shaft_maps) do
        local active = depth_hook(entry[1], entry[2], shallow)
        local absent = depth_hook(entry[1], entry[2], bottom)

        harness.equal(#active, 1, entry[1] .. " has an ordinary-floor shaft")
        harness.equal(active[1].kind, directives.KFEAT)
        harness.equal(active[1].argument:match("shaft trap$"), "shaft trap")
        harness.equal(#absent, 0, entry[1] .. " omits bottom-floor shafts")
    end

    harness.equal(#depth_hook("demons_altar", "deepen_demons", shallow), 0)
    harness.equal(#depth_hook("demons_altar", "deepen_demons", bottom), 3)
    harness.equal(#depth_hook("tgw_fedhas", "open_deep_enclosure", shallow), 0)
    harness.equal(#depth_hook("tgw_fedhas", "open_deep_enclosure", bottom), 2)

    local copse = depth_hook(
        "nicolae_yredelemnul_corpse_copse", "scale_zombie_slots", bottom)

    harness.equal(copse[1].kind, directives.NSUBST)
    harness.equal(copse[1].argument, ". = 10=1 / 1=1. / .")

    local xom_before = depth_hook("tgw_xom", "choose_traps", shallow)
    local xom_bottom = depth_hook("tgw_xom", "choose_traps", bottom)

    harness.truthy(xom_before[1].argument:find("shaft trap", 1, true))
    harness.falsy(xom_bottom[1].argument:find("shaft trap", 1, true))
    harness.equal(#depth_hook("tgw_xom", "deepen_monsters", shallow), 0)
    harness.equal(#depth_hook("tgw_xom", "deepen_monsters", bottom), 1)

    local decor_before = depth_hook("xom_redecorated", "choose_traps", shallow)
    local decor_bottom = depth_hook("xom_redecorated", "choose_traps", bottom)

    harness.truthy(decor_before[1].argument:find("shaft trap", 1, true))
    harness.falsy(decor_bottom[1].argument:find("shaft trap", 1, true))
    harness.equal(#depth_hook("xom_shifter_show", "turn_bottom_stair", shallow), 0)
    harness.equal(#depth_hook("xom_shifter_show", "turn_bottom_stair", bottom), 1)

    local placed = operations.apply(
        catalog.get("grunt_qazlal_sundering"),
        copy_rows(catalog.get("grunt_qazlal_sundering")),
        fixed_random(), shallow.depth, shallow)
    local shafts = 0

    for _, record in ipairs(placed) do
        if record.kind == effects.FEATURE and
            record.identity == "shaft trap" then
            shafts = shafts + 1
        end
    end

    harness.equal(shafts, 1,
        "real placement emits one shaft feature before the branch bottom")
end

-- Parsing the full family catches broken directives and missing named hooks
-- at startup rather than only when a rare altar map is selected.
function test.run()
    local ids = catalog.ids()

    harness.equal(#ids, 232,
        "all source overflow altar definitions are committed")

    local previous = ""

    for _, id in ipairs(ids) do
        harness.truthy(id > previous,
            "overflow IDs are unique and sorted")
        harness.equal(catalog.get(id).id, id,
            "the catalog returns its parsed source definition")
        previous = id
    end

    local ashenzari = catalog.get("ashenzari_altar_1")

    harness.truthy(ashenzari.tags.temple_overflow_ashenzari,
        "specialized god tags survive the source import")
    harness.truthy(#ashenzari.rows > 0,
        "source altar geometry remains in DES MAP rows")

    local selectable = pcall(ordinary.get, ashenzari.id)

    harness.falsy(selectable,
        "unported overflow maps cannot enter ordinary vault selection")

    assert_feature_names()
    assert_dancefloor_decay()
    assert_count_arrangements()
    assert_count_maps_apply()
    assert_branch_monsters()
    assert_depth_rules()
    assert_depth_monsters()
    assert_blood_cavern_scenes()
    assert_simple_source_scripts()
end

return test
