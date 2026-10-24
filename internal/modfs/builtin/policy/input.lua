local aim = require("policy.input.aim")
local abilities = require("policy.input.abilities")
local action_confirmation = require("policy.input.action_confirmation")
local door = require("policy.input.door")
local items = require("policy.input.items")
local modal = require("policy.input.modal")
local mutations = require("policy.input.mutations")
local play = require("policy.input.play")
local pregame = require("policy.input.pregame")
local session = require("policy.input.session")
local selection = require("policy.input.selection")
local skills = require("policy.input.skills")
local spells = require("policy.input.spells")

local screens = {
    abilities = abilities.route,
    ability_confirm = abilities.confirm,
    action_confirm = action_confirmation.route,
    aim = aim.route,
    background = pregame.choice,
    death = modal.death,
    door = door.route,
    drop = items.drop,
    evoke_wand = items.evoke_wand,
    evoke_item = items.evoke_item,
    help = modal.help,
    quaff = items.quaff,
    read = items.read,
    selection = selection.route,
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
    put_on = items.put_on,
    remove_jewellery = items.remove_jewellery,
    confirm = session.confirm,
    equipment_delay = session.equipment_delay,
    memorisation_delay = session.memorisation_delay,
    vampire_delay = session.vampire_delay,
    stat_choice = session.stat,
}

local terminal_input = {}

-- The screen map is the terminal input registry; unknown screens fail instead of silently falling through.
-- Example: terminal_input.run(ctx, { screen = "play", key = "h" }) routes a westward play key.
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
