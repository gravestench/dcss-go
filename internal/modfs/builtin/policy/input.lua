local aim = require("policy.input.aim")
local abilities = require("policy.input.abilities")
local door = require("policy.input.door")
local items = require("policy.input.items")
local modal = require("policy.input.modal")
local mutations = require("policy.input.mutations")
local play = require("policy.input.play")
local pregame = require("policy.input.pregame")
local session = require("policy.input.session")
local skills = require("policy.input.skills")
local spells = require("policy.input.spells")

local screens = {
    abilities = abilities.route,
    ability_confirm = abilities.confirm,
    spell_confirm = spells.confirm,
    aim = aim.route,
    background = pregame.choice,
    death = modal.death,
    door = door.route,
    drop = items.drop,
    evoke_wand = items.evoke_wand,
    help = modal.help,
    quaff = items.quaff,
    modal = modal.route,
    mutations = mutations.route,
    play = play.route,
    name = pregame.name,
    species = pregame.choice,
    skills = skills.route,
    spells = spells.route,
    startup = pregame.startup,
    take_off = items.take_off,
    throw = items.throw,
    weapon = pregame.weapon,
    wear = items.wear,
    wield = items.wield,
    confirm = session.confirm,
    equipment_delay = session.equipment_delay,
    memorisation_delay = session.memorisation_delay,
    vampire_delay = session.vampire_delay,
    stat_choice = session.stat,
}

local terminal_input = {}

function terminal_input.run(ctx, input)
    local route = screens[input.screen]

    if not route then
        error("unknown terminal input screen " .. tostring(input.screen))
    end

    return route(input, ctx)
end

register.policy({
    id = "terminal.input",
    run = terminal_input.run,
})

return terminal_input
