local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local transition = require("policy.mutations.transition")

local malmutate = {}

-- Source: player.cc:player::malmutate and mutation.cc:mutate. Quality is
-- selected before protection; heavy mutation can cause a removal instead.
-- Example: a zero quality draw uses the ANY pool; four other draws use BAD mutations.
-- Use one mutation-stream quality draw before delegating resistance and grant handling.
function malmutate.apply(ctx, owner, reason)
    local choice = ctx:random("mutation", 5) == 0 and
        choices.ANY or choices.BAD

    return transition.grant_random(ctx, owner, choice,
        classes.ACQUIRED, false)
end

return malmutate
