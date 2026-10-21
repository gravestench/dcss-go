-- Player movement can activate a saved vault marker before the next
-- combat phase. Individual vaults supply callback policy by mod path.
local component = require("constants.component")
local intents = require("constants.intent")
local triggers = require("policy.world.vault_triggers")

local system = {}

-- Only a committed player move can enter a source marker cell.
local function update(ctx, actor)
    if actor ~= ctx:player() then
        return
    end

    local intent = ctx:get(actor, component.INTENT)

    if not intent or intent.kind ~= intents.MOVE then
        return
    end

    local position = ctx:get(actor, component.POSITION)

    if position then
        triggers.enter(ctx, actor, position)
    end
end

system.update = update

register.system({
    id = "world.vault_triggers",
    scope = "active",
    query = {},
    after = { "world.movement" },
    before = { "world.traps", "attack.combat" },
    update = system.update,
})

return system
