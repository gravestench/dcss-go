-- Action sides are shared by content and selection; Xom can choose either
-- side during wrath, so callers must not infer side from an ID prefix.
local sides = {
    GOOD = "good",
    BAD = "bad",
}

return sides
