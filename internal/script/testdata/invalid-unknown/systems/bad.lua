-- Querying an unregistered component named missing must fail system validation.
-- Theory of operation: register a query for an absent component schema; the
-- scheduler should reject the system before an update can run.

register.system{
    id = "test.bad",
    query = { "missing" },
    -- Leave the body empty because the invalid query itself is the test;
    -- executing this function would mean schema validation failed.
    update = function() end,
}
