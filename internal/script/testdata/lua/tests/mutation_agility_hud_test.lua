local component = require("constants.component")
local restrictions = require("constants.safety_restrictions")
local hud = require("policy.presentation.hud")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local curl = require("policy.character.curl")
local species = require("ids.species")

local test = {}

local function player_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    function proxy.player()
        return player
    end

    return proxy
end

local function has_write(rows, expected)
    for _, write in ipairs(rows.writes) do
        if write.text == expected then
            return true
        end
    end

    return false
end

function test.run(ctx)
    local player = ctx:create()
    local screen = player_context(ctx, player)
    local view = {
        player_name = "Adventurer",
        species_name = "Human",
        player_hp = 10,
        player_max_hp = 10,
        player_mp = 0,
        player_max_mp = 0,
        defense_known = false,
        attributes = {
            strength = 10,
            intelligence = 10,
            dexterity = 10,
        },
        experience_level = 1,
        next_level_percent = 0,
        level_id = 1,
        current_aut = 0,
        inventory = {},
        might_aut = 0,
        poison_amount_scaled = 0,
        haste_aut = 0,
        constricted = false,
    }

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "HUD test",
    })

    ctx:add(player, component.AGILITY, {
        remaining_aut = 350,
    })

    harness.truthy(has_write(hud.run(screen, { view = view }), "Agi"),
        "Agility appears in the HUD from its Lua ECS component")

    local agility = ctx:get(player, component.AGILITY)
    agility.remaining_aut = 0
    ctx:set(player, component.AGILITY, agility)

    harness.falsy(has_write(hud.run(screen, { view = view }), "Agi"),
        "Agility disappears from the HUD when the duration ends")

    ctx:add(player, component.DAMAGE_SAFETY, {
        [restrictions.POTIONS] = 10,
        [restrictions.SCROLLS] = 20,
    })

    local restricted = hud.run(screen, { view = view })

    harness.truthy(has_write(restricted, "-Potion"),
        "Drink Safety appears in the HUD")
    harness.truthy(has_write(restricted, "-Scroll"),
        "Read Safety appears in the HUD")

    ctx:add(player, component.POWERED_BY_DEATH, {
        strength = 2,
        remaining_aut = 30,
    })

    harness.truthy(has_write(hud.run(screen, { view = view }), "Regen (2)"),
        "Powered by Death appears in the HUD")

    local powered = ctx:get(player, component.POWERED_BY_DEATH)
    powered.strength = 0
    powered.remaining_aut = 0
    ctx:set(player, component.POWERED_BY_DEATH, powered)

    harness.falsy(has_write(hud.run(screen, { view = view }), "Regen (2)"),
        "expired Powered by Death disappears from the HUD")

    records.grant_acquired(ctx, player,
        mutations.MUT_TENGU_FLIGHT, 1)

    harness.truthy(has_write(hud.run(screen, { view = view }), "Fly"),
        "permanent mutation flight appears in the HUD")

    records.grant_acquired(ctx, player, mutations.MUT_CURL, 1)
    ctx:add(player, component.CURL, { active = true })

    harness.truthy(has_write(hud.run(screen, { view = view }), "Curl"),
        "active Curl appears in the HUD")

    curl.reset(ctx, player)

    harness.falsy(has_write(hud.run(screen, { view = view }), "Curl"),
        "uncurling clears the HUD status")

    ctx:add(player, component.PLAYER_PETRIFICATION, {
        petrifying_aut = 20,
        petrified_aut = 0,
    })

    harness.truthy(has_write(hud.run(screen, { view = view }), "Petr"),
        "petrifying stage appears in the HUD")

    ctx:set(player, component.PLAYER_PETRIFICATION, {
        petrifying_aut = 0,
        petrified_aut = 60,
    })

    harness.truthy(has_write(hud.run(screen, { view = view }), "Stone"),
        "fully petrified stage appears in the HUD")
    harness.falsy(has_write(hud.run(screen, { view = view }), "Petr"),
        "completed petrification replaces the warning status")

    ctx:add(player, component.HORROR, { penalty = 5 })

    harness.truthy(has_write(hud.run(screen, { view = view }), "Horr(-5)"),
        "Cowardice horror displays its current slaying penalty")

    ctx:add(player, component.RAGE, {
        remaining_aut = 90,
        cooldown_aut = 0,
    })

    harness.truthy(has_write(hud.run(screen, { view = view }), "Berserk"),
        "active rage uses the source status light")

    ctx:set(player, component.RAGE, {
        remaining_aut = 0,
        cooldown_aut = 180,
    })

    harness.truthy(has_write(hud.run(screen, { view = view }), "-Berserk"),
        "rage exhaustion uses the source cooldown light")
    harness.falsy(has_write(hud.run(screen, { view = view }), "Berserk"),
        "expired rage does not keep its active light")
end

return test
