-- The z key returns a nonreturnable drop screen and x returns an invalid step kind.

local pregame = {}

-- Offer two deliberately invalid startup routes so navigation validates
-- both the screen return contract and step-kind type before changing state.
-- Example: pregame.startup({ key = "z" }) proposes a forbidden drop screen.
function pregame.startup(input)
    if input.key == "z" then
        return {
            action = "screen",
            screen = "drop",
            returnable = false,
        }
    elseif input.key == "x" then
        return {
            action = "step",
            kind = 5,
        }
    end

    return {
        action = "none",
    }
end

return pregame
