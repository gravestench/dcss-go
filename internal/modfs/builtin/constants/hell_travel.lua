-- The Vestibule persists after every visit; entering updates the most
-- recent outside gate, while returning leaves the saved map in place.
return {
    ENTER = "enter",
    RETURN = "return",
    BRANCH_FLOOR = "branch_floor",
    BRANCH_RETURN = "branch_return",
}
