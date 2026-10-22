-- The HUD projection derives names, stars, and debt from the same saved
-- worship component used by gameplay, so modded god files stay authoritative.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local religion = require("policy.presentation.religion")

local test = {}

-- Bind presentation's player lookup to this real ECS entity while leaving
-- component reads and catalog resolution in production code.
local function bound(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    function proxy.player()
        return player
    end

    return proxy
end

-- Godless, ordinary, penitent, and no-piety patrons exercise distinct HUD
-- contracts without copying source threshold math into the test.
function test.run(ctx)
    local player = ctx:create()
    local screen = bound(ctx, player)

    ctx:add(player, component.RELIGION_WORSHIP, {})

    local absent = religion.run(screen)

    harness.equal(absent.god_name, "")
    harness.equal(absent.piety_stars, "")

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    state.god_id = gods.TROG
    state.piety = 50
    ctx:set(player, component.RELIGION_WORSHIP, state)

    local devoted = religion.run(screen)

    harness.equal(devoted.god_name, "Trog")
    harness.equal(devoted.piety_stars, "**....")

    state = ctx:get(player, component.RELIGION_WORSHIP)
    state.penance[gods.TROG] = 7
    ctx:set(player, component.RELIGION_WORSHIP, state)

    harness.equal(religion.run(screen).penance, 7)

    state = ctx:get(player, component.RELIGION_WORSHIP)
    state.god_id = gods.GOZAG
    ctx:set(player, component.RELIGION_WORSHIP, state)

    local gozag = religion.run(screen)

    harness.equal(gozag.god_name, "Gozag")
    harness.equal(gozag.piety_stars, "")
end

return test
