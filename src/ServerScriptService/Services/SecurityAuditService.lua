local SecurityAuditService = {}

function SecurityAuditService:AssertRejected(ok, before, after)
    return ok == false and before == after
end

function SecurityAuditService:ExploitResult(ok, changed)
    return { rejected = ok == false, noStateChange = changed == false, passed = ok == false and changed == false }
end

return SecurityAuditService
