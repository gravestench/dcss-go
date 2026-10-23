-- God descriptions must read the same resolved Lua rule module that
-- handles gameplay, and must sort by stable event ID rather than load order.
local gods = require("constants.gods")
local harness = require("tests.harness")
local kinds = require("constants.religion_conduct")
local descriptions = require("policy.religion.conduct.description")

local test = {}

-- Zin's unclean reward and evil offense are source responses in the
-- production module. An empty-rule god produces empty lists.
function test.run()
    local zin = descriptions.for_god(gods.ZIN)
    local found_like = false
    local found_dislike = false

    for index, entry in ipairs(zin.likes) do
        if index > 1 then
            harness.truthy(zin.likes[index - 1].event_id < entry.event_id)
        end

        if entry.event_id == kinds.KILL_UNCLEAN then
            found_like = true
        end
    end

    for index, entry in ipairs(zin.dislikes) do
        if index > 1 then
            harness.truthy(zin.dislikes[index - 1].event_id < entry.event_id)
        end

        if entry.event_id == kinds.EVIL then
            found_dislike = true
        end
    end

    harness.truthy(found_like)
    harness.truthy(found_dislike)
    harness.equal(#descriptions.for_god(gods.XOM).likes, 0)
end

return test
