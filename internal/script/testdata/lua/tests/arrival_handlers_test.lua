local des = require("policy.generation.vaults.des")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local vault_ids = require("ids.vaults")
local species_ids = require("ids.species")

local test = {}

local function test_api(rolls, options)
    local api = {
        rolls = rolls or {},
        options = options or {},
        emissions = {},
        records = {},
    }

    function api:roll(bound)
        local result = table.remove(self.rolls, 1) or 0

        assert(result >= 0 and result < bound)

        return result
    end

    function api:one_in(bound)
        return self:roll(bound) == 0
    end

    function api:coinflip()
        return self:roll(2) == 0
    end

    function api:random_from(values)
        return values[self:roll(#values) + 1]
    end

    function api:random_range(first, last)
        return first + self:roll(last - first + 1)
    end

    function api:emit(kind, argument)
        self.emissions[#self.emissions + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:record(kind, arguments)
        self.records[#self.records + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    function api:player_species()
        return self.options.species or species_ids.SP_HUMAN
    end

    function api:player_monster()
        return self.options.monster or "human"
    end

    function api:player_name()
        return self.options.name or "Test Hero"
    end

    function api:game_started()
        return self.options.started or false
    end

    function api:validating()
        return false
    end

    function api:marker_positions()
        return self.options.markers
    end

    function api:has_exit()
        return self.options.has_exit or false
    end

    return api
end

local function handler_for(id)
    return require("policy.generation.vaults.arrival." .. id)
end

local function assert_all_source_hooks_have_handlers()
    local owners = {}
    local veto_count = 0

    for _, path in ipairs(mod.paths("vaults/arrival", ".des")) do
        local vault = des.parse(path, mod.read(path))

        for _, operation in ipairs(vault.operations) do
            if operation.kind == directives.HOOK_RUN or
                operation.kind == directives.HOOK_VETO then
                local handler = handler_for(vault.id)
                local method = handler[operation.argument]

                assert(type(method) == "function", vault.id .. "." .. operation.argument)
                owners[vault.id] = true

                if operation.kind == directives.HOOK_VETO then
                    veto_count = veto_count + 1
                else
                    local api = test_api()

                    method(api)
                    assert(#api.emissions + #api.records > 0,
                        vault.id .. "." .. operation.argument .. " emitted nothing")

                    local alternate = test_api()

                    function alternate:roll(bound)
                        return bound - 1
                    end

                    method(alternate)
                end
            end
        end
    end

    local count = 0

    for _ in pairs(owners) do
        count = count + 1
    end

    assert(count == 36)
    assert(veto_count == 1)
end

local function assert_crop_circle_branch()
    local handler = handler_for(vault_ids.roderic_crop_circles_arrival_small)
    local rare = test_api({ 0 })
    local common = test_api({ 1 })

    handler.choose_crop_colour(rare)
    handler.choose_crop_colour(common)

    assert(#rare.emissions == 1)
    assert(rare.emissions[1].kind == directives.SUBST)
    assert(rare.emissions[1].argument == "1 = 2:100 1:20")
    assert(#common.emissions == 1)
    assert(common.emissions[1].argument == "1 = 1:100 2:10")
end

local function assert_veto_uses_marker_exit()
    local handler = handler_for(vault_ids.dpeg_arrival_water_fire)
    local absent = test_api(nil, { markers = nil })
    local blocked = test_api(nil, { markers = { { x = 4, y = 5 } } })
    local open = test_api(nil, {
        markers = { { x = 4, y = 5 } },
        has_exit = true,
    })

    assert(handler.check_exit_marker(absent) == false)
    assert(handler.check_exit_marker(blocked) == true)
    assert(handler.check_exit_marker(open) == false)
end

local function assert_source_effects()
    local naming = test_api()

    handler_for(vault_ids.roderic_dead_forest).name_dead_trees(naming)

    assert(naming.records[1].kind == "feature_name")
    assert(naming.records[1].arguments.feature == "tree")
    assert(naming.records[1].arguments.name == "dead tree")

    local remains = test_api()

    handler_for(vault_ids.beargit_arrival_diablo_church)
        .schedule_skeleton_decay(remains)

    assert(remains.records[1].kind == "delayed_decay")
    assert(remains.records[1].arguments.glyph == "H")
    assert(remains.records[1].arguments.alternatives ==
        "human skeleton / elf skeleton")

    local battle = test_api({ 0, 0 })

    handler_for(vault_ids.heliophobic_arrival_battle_scene)
        .schedule_battle_remains(battle)

    assert(#battle.records == 2)
    assert(battle.records[1].arguments.alternatives == "dwarf skeleton")
    assert(battle.records[2].arguments.alternatives == "goblin skeleton")

    local memorial = test_api(nil, { species = species_ids.SP_FORMICID })

    handler_for(vault_ids.nicolae_arrival_memento_mori)
        .schedule_named_remains(memorial)

    assert(memorial.records[1].arguments.alternatives ==
        "human name:Test_Hero corpse")
    assert(memorial.records[2].arguments.alternatives ==
        "human name:Test_Hero corpse")
end

local function assert_complex_source_choices()
    local round = test_api({ 0, 0 })

    handler_for(vault_ids.dpeg_arrival_round_a).choose_round_layout(round)

    assert(round.emissions[1].kind == directives.SUBST)
    assert(round.emissions[1].argument == "? = x")
    assert(round.emissions[4].argument == "B = .")

    local temple = test_api({ 0 })

    handler_for(vault_ids.erik_arrival_cave_to_temple)
        .choose_temple_tenant(temple)

    assert(temple.emissions[1].kind == directives.KFEAT)
    assert(temple.emissions[1].argument == "C = altar_beogh")

    local water_fire = test_api({ 0 })

    handler_for(vault_ids.dpeg_arrival_water_fire)
        .choose_water_fire_layout(water_fire)

    assert(water_fire.emissions[1].kind == directives.NSUBST)
    assert(water_fire.emissions[1].argument == "A=*:., a=1:./*:l, b=1:./*:l")

    local spiral = test_api({ 0 })

    handler_for(vault_ids.nagdon_arrival_double_spiral)
        .choose_spiral_variant(spiral)

    assert(spiral.emissions[1].kind == directives.SUBST)
    assert(spiral.emissions[1].argument ==
        "G : G:20 H:20 T:5 V:5 1:5 2:5 t:5 A:1 B:1 C:1")

    local zigzag = test_api({ 0, 0, 0 })

    handler_for(vault_ids.nagdon_arrival_zigzag_paths)
        .choose_zigzag_layout(zigzag)

    assert(zigzag.emissions[1].argument == "GHIJ = x")
    assert(zigzag.emissions[3].argument == "& = @")

    local octagon = test_api({ 0, 0 })

    handler_for(vault_ids.enne_arrival_octagon_isle)
        .shape_octagon_isle(octagon)

    assert(octagon.records[1].kind == effects.OCTA_ROOM)
    assert(octagon.records[1].arguments.oblique == 3)
    assert(octagon.records[2].kind == effects.SMEAR_MAP)
    assert(octagon.records[2].arguments.iterations == 20)
end

local function assert_complex_alternates()
    local temple_handler = handler_for(vault_ids.erik_arrival_cave_to_temple)
    local temple_first = {
        "C = altar_beogh",
        "C = altar_lugonu",
        "C = altar_jiyva",
        "D = V",
    }

    for choice, first in ipairs(temple_first) do
        local api = test_api({ choice - 1 })

        temple_handler.choose_temple_tenant(api)
        assert(api.emissions[1].argument == first)
    end

    local water_handler = handler_for(vault_ids.dpeg_arrival_water_fire)

    for choice = 0, 11 do
        local api = test_api({ choice })

        water_handler.choose_water_fire_layout(api)
        assert(#api.emissions > 0)

        if choice >= 6 then
            assert(api.emissions[1].kind == directives.SUBST)
        else
            assert(api.emissions[1].kind == directives.NSUBST)
        end
    end

    local spiral_handler = handler_for(vault_ids.nagdon_arrival_double_spiral)

    for _, draws in ipairs({
        { 0 },
        { 1, 0 },
        { 1, 1, 0 },
        { 1, 1, 1, 0 },
    }) do
        local api = test_api(draws)

        spiral_handler.choose_spiral_variant(api)
        assert(#api.emissions > 0)
    end
end

function test.run()
    assert_all_source_hooks_have_handlers()
    assert_crop_circle_branch()
    assert_veto_uses_marker_exit()
    assert_source_effects()
    assert_complex_source_choices()
    assert_complex_alternates()
end

return test
