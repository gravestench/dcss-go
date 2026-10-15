local aim = require("policy.input.aim")
local door = require("policy.input.door")
local items = require("policy.input.items")
local modal = require("policy.input.modal")
local play = require("policy.input.play")
local pregame = require("policy.input.pregame")
local session = require("policy.input.session")
local skills = require("policy.input.skills")

local screens = {
    aim = aim.route,
    background = pregame.choice,
    death = modal.death,
    door = door.route,
    drop = items.drop,
    help = modal.help,
    quaff = items.quaff,
    modal = modal.route,
    play = play.route,
    name = pregame.name,
    species = pregame.choice,
    skills = skills.route,
    startup = pregame.startup,
    take_off = items.take_off,
    throw = items.throw,
    weapon = pregame.weapon,
    wear = items.wear,
    wield = items.wield,
    confirm = session.confirm,
    equipment_delay = session.equipment_delay,
    stat_choice = session.stat,
}

register.policy({
    id = "terminal.input",

    run = function(ctx, input)
        local route = screens[input.screen]

        if not route then
            error("unknown terminal input screen " .. tostring(input.screen))
        end

        return route(input, ctx)
    end,
})
