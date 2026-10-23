-- A saved vault trigger may fire when its authored cell first enters the
-- player's line of sight. Movement supplies the player origin each turn.
local component = require("constants.component")
local harness = require("tests.harness")
local triggers = require("policy.world.vault_triggers")
local trigger_ids = require("constants.vault_triggers")

local test = {}

-- Reuse the production ECS store. Only line of sight and message delivery
-- are supplied by this small stand-in for a fully installed game level.
local function game_context(ctx)
    local game = setmetatable({
        messages = {},
        can_see = false,
    }, { __index = ctx })
    local player = ctx:create()

    function game:player()
        return player
    end

    function game:visible()
        return self.can_see
    end

    function game:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    return game, player
end

-- Approach while hidden, then visible, then leave and return. A one-shot
-- entity must survive the first move and disappear after the callback.
function test.run(ctx)
    local game, player = game_context(ctx)
    local record = {
        identity = trigger_ids.SPIDER_NEST_WARN,
        x = 7,
        y = 8,
        source_id = "crypt_los_fixture",
        index = 1,
        arguments = {
            event = trigger_ids.PLAYER_LOS_EVENT,
        },
    }
    local level = {
        id = 9,
        vault_records = { record },
    }
    local position = {
        level_id = level.id,
        x = 4,
        y = 8,
    }

    game:add(player, component.POSITION, position)
    triggers.materialize(game, level, record)

    triggers.player_los(game, player, position)
    harness.equal(#game.messages, 0, "an unseen source marker must stay armed")
    harness.equal(#game:query({ component.WORLD_VAULT_TRIGGER }), 1)

    game.can_see = true
    triggers.player_los(game, player, position)
    harness.equal(
        #game.messages,
        1,
        "first visible move invokes the source callback"
    )
    harness.equal(
        #game:query({ component.WORLD_VAULT_TRIGGER }),
        0,
        "successful LOS callback consumes its saved entity"
    )

    game.can_see = false
    triggers.player_los(game, player, position)
    game.can_see = true
    triggers.player_los(game, player, position)
    harness.equal(
        #game.messages,
        1,
        "returning to visibility cannot replay the event"
    )
end

return test
