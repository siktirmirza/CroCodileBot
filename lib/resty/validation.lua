local setmetatable = setmetatable
local getmetatable = getmetatable
local rawget = rawget
local select = select
local tostring = tostring
local tonumber = tonumber
local type = type
local ipairs = ipairs
local error = error
local match = string.match
local lower = string.lower
local upper = string.upper
local find = string.find
local gsub = string.gsub
local sub = string.sub
local len = utf8 and utf8.len or function(s) return select(2, gsub(s, '[^\x80-\xC1]', '')) end
local iotype = io.type
local mathtype = math.type
local tointeger = math.tointeger
local abs = math.abs
local unpack = unpack or table.unpack
local nothing = {}
local inf = 1 / 0
local sreverse = string.reverse
local function reverse(s)
    return sreverse(gsub(s, "[%z-\x7F\xC2-\xF4][\x80-\xBF]*", function(c) return #c > 1 and sreverse(c) end))
end
if not mathtype then
    mathtype = function(value)
        if type(value) ~= "number" then
            return nil
        end
        return value % 1 == 0 and "integer" or "float"
    end
end
if not tointeger then
    tointeger = function(value)
        local v = tonumber(value)
        return mathtype(value) == "integer" and v or nil
    end
end
local function istype(t)
    if t == "integer" or t == "float" then
        return function(value)
            return t == mathtype(value)
        end
    elseif t == "file" then
        return function(value)
            return t == iotype(value)
        end
    else
        return function(value)
            return t == type(value)
        end
    end
end
local factory = {}
function factory.type(t)
    return istype(t)
end
function factory.iftype(t, truthy, falsy)
    local check = istype(t)
    return function(value)
        if check(value) then
            return true, truthy
        end
        return true, falsy
    end
end
function factory.null()
    return factory.type("nil")
end
factory["nil"] = factory.null
function factory.boolean()
    return factory.type("boolean")
end
function factory.number()
    return factory.type("number")
end
function factory.string()
    return factory.type("string")
end
function factory.table()
    return factory.type("table")
end
function factory.userdata()
    return factory.type("userdata")
end
function factory.func()
    return factory.type("function")
end
factory["function"] = factory.func
function factory.thread()
    return factory.type("thread")
end
function factory.integer()
    return factory.type("integer")
end
function factory.float()
    return factory.type("float")
end
function factory.file()
    return factory.type("file")
end
function factory.inf()
    return function(value)
        return value == inf or value == -inf
    end
end
function factory.nan()
    return function(value)
        return value ~= value
    end
end
function factory.finite()
    return function(value)
        if value ~= value then
            return false
        end
        return value ~= inf and value ~= -inf
    end
end
function factory.abs()
    return function(value)
        return true, abs(value)
    end
end
function factory.positive()
    return function(value)
        return value > 0
    end
end
function factory.negative()
    return function(value)
        return value < 0
    end
end
function factory.min(min)
    return function(value)
        return value >= min
    end
end
function factory.max(max)
    return function(value)
        return value <= max
    end
end
function factory.between(min, max)
    if not max then max = min end
    if max < min then min, max = max, min end
    return function(value)
        return value >= min and value <= max
    end
end
function factory.outside(min, max)
    if not max then max = min end
    if max < min then min, max = max, min end
    return function(value)
        return value < min and value > max
    end
end
function factory.divisible(number)
    return function(value)
        if type(value) == "number" then
            return value % number == 0
        else
            return false
        end
    end
end
function factory.indivisible(number)
    return function(value)
        if type(value) == "number" then
            return value % number ~= 0
        else
            return false
        end
    end
end
function factory.len(min, max)
    if max then
        if max < min then min, max = max, min end
    end
    return function(value)
        local l
        if type(value) == "string" then l = len(value) else l = #value end
        if type(l)     ~= "number" then return false end
        return l >= min and l <= max
    end
end
function factory.minlen(min)
    return function(value)
        local l
        if type(value) == "string" then l = len(value) else l = #value end
        if type(l)     ~= "number" then return false end
        return l >= min
    end
end
function factory.maxlen(max)
    return function(value)
        local l
        if type(value) == "string" then l = len(value) else l = #value end
        if type(l)     ~= "number" then return false end
        return l <= max
    end
end
function factory.equals(equal)
    return function(value)
        return value == equal
    end
end
factory.equal = factory.equals
function factory.unequals(unequal)
    return function(value)
        return value ~= unequal
    end
end
factory.unequal = factory.unequals
function factory.oneof(...)
    local args = { ... }
    return function(value)
        for _, v in ipairs(args) do
            if v == value then
                return true
            end
        end
        return false
    end
end
function factory.noneof(...)
    local args = { ... }
    return function(value)
        for _, v in ipairs(args) do
            if v == value then
                return false
            end
        end
        return true
    end
end
function factory.match(pattern, init)
    return function(value)
        return match(value, pattern, init) ~= nil
    end
end
function factory.unmatch(pattern, init)
    return function(value)
        return match(value, pattern, init) == nil
    end
end
function factory.tostring()
    return function(value)
        return true, tostring(value)
    end
end
function factory.tonumber(base)
    return function(value)
        local nbr = tonumber(value, base)
        return nbr ~= nil, nbr
    end
end
function factory.tointeger()
    return function(value)
        local nbr = tointeger(value)
        return nbr ~= nil, nbr
    end
end
function factory.toboolean()
    return function(value)
        return true, not not value
    end
end
function factory.tonil()
    return function()
        return true, nothing
    end
end
factory.tonull = factory.tonil
function factory.lower()
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, lower(value)
        end
        return false
    end
end
function factory.upper()
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, upper(value)
        end
        return false
    end
end
function factory.trim(pattern)
    pattern = pattern or "%s+"
    local l = "^" .. pattern
    local r = pattern .. "$"
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, (gsub(value, r, ""):gsub(l, ""))
        end
        return false
    end
end
function factory.ltrim(pattern)
    pattern = "^" .. (pattern or "%s+")
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, (gsub(value, pattern, ""))
        end
        return false
    end
end
function factory.rtrim(pattern)
    pattern = (pattern or "%s+") .. "$"
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, (gsub(value, pattern, ""))
        end
        return false
    end
end
function factory.starts(starts)
    return function(value)
        return sub(value, 1, len(starts)) == starts
    end
end
function factory.ends(ends)
    return function(value)
        return ends == '' or sub(value, -len(ends)) == ends
    end
end
function factory.reverse()
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, reverse(value)
        end
        return false
    end
end
function factory.coalesce(...)
    local args = { ... }
    return function(value)
        if value ~= nil then return true, value end
        for _, v in ipairs(args) do
            if v ~= nil then return true, v end
        end
        return true
    end
end
function factory.email()
    return function(value)
        if value == nil or type(value) ~= "string" then return false end
        local i, at = find(value, "@", 1, true), nil
        while i do
            at = i
            i = find(value, "@", i + 1)
        end
        if not at or at > 65 then return false end
        local lp = sub(value, 1, at - 1)
        if not lp then return false end
        local dp = sub(value, at + 1)
        if not dp or #dp > 254 then return false end
        local qp = find(lp, '"', 1, true)
        if qp and qp > 1 then return false end
        local q, p
        for i = 1, #lp do
            local c = sub(lp, i, i)
            if c == "@" then
                if not q then return false end
            elseif c == '"' then
                if p ~= [[\]] then
                    q = not q
                end
            elseif c == " " or c == '"' or c == [[\]] then
                if not q then
                    return false
                end
            end
            p = c
        end
        if q or find(lp, "..", 1, true) or find(dp, "..", 1, true) then return false end
        if match(lp, "^%s+") or match(dp, "%s+$") then return false end
        return match(value, "%w*%p*@+%w*%.?%w*") ~= nil
    end
end
factory.__index = factory
local validators = setmetatable({
    ["nil"]      = factory.null(),
    null         = factory.null(),
    boolean      = factory.boolean(),
    number       = factory.number(),
    string       = factory.string(),
    table        = factory.table(),
    userdata     = factory.userdata(),
    ["function"] = factory.func(),
    func         = factory.func(),
    thread       = factory.thread(),
    integer      = factory.integer(),
    float        = factory.float(),
    file         = factory.file(),
    tostring     = factory.tostring(),
    tonumber     = factory.tonumber(),
    tointeger    = factory.tointeger(),
    toboolean    = factory.toboolean(),
    tonil        = factory.tonil(),
    tonull       = factory.tonull(),
    abs          = factory.abs(),
    inf          = factory.inf(),
    nan          = factory.nan(),
    finite       = factory.finite(),
    positive     = factory.positive(),
    negative     = factory.negative(),
    lower        = factory.lower(),
    upper        = factory.upper(),
    trim         = factory.trim(),
    ltrim        = factory.ltrim(),
    rtrim        = factory.rtrim(),
    reverse      = factory.reverse(),
    email        = factory.email()
}, factory)
local data = {}
function data:__call(...)
    local argc = select("#", ...)
    local data = setmetatable({}, data)
    if argc == 0 then
        return self
    else
        for _, index in ipairs{ ... } do
            if self[index] then
                data[index] = self[index]
            end
        end
    end
    return data
end
local fields = {}
function fields:__call(...)
    local valid, invalid, validatad, unvalidated
    local argc = select("#", ...)
    if argc == 0 then
        valid = true
    else
        for _, v in ipairs({ ... }) do
            if v == "valid" then
                valid = true
            elseif v == "invalid" then
                invalid = true
            elseif v == "validated" then
                validated = true
            elseif v == "unvalidated" then
                unvalidated = true
            elseif v == "all" then
                valid = true
                invalid = true
                validated = true
                unvalidated = true
            end
        end
    end
    local data = setmetatable({}, data)
    for index, field in pairs(self) do
        if valid and field.valid then
            data[index] = field.value
        elseif invalid and field.invalid then
            data[index] = field.value
        elseif validated and field.validated then
            data[index] = field.value
        elseif unvalidated and field.unvalidated then
            data[index] = field.value
        end
    end
    return data
end
local field = {}
field.__index = field
function field.new(opts)
    local self = setmetatable({
        valid = true,
        invalid = false,
        validated = true,
        unvalidated = false
    }, field)
    if type(opts) == "table" then
        self.name = opts.name
        self.value = opts.value or opts.input
        self.input = opts.input or opts.value
        if opts.valid == false or opts.invalid then
            self:invalidate(opts.error or "unknown")
        elseif opts.validated == false or opts.unvalidated then
            self.validated = false
            self.unvalidated = true
        end
    end
    return self
end
function field:__tostring()
    if type(self.value) == "string" then return self.value end
    return tostring(self.value)
end
function field:invalidate(error)
    self.error = error
    self.valid = false
    self.invalid = true
    self.validated = true
    self.unvalidated = false
end
local irules = {}
local grules = {}
local operators = { "<=", ">=", "==", "~=", "<", ">" }
local group = {}
group.__index = group
function group:add(func)
    local gr = self[grules]
    gr[#gr+1] = func
end
function group:compare(comparison)
    local s, e, o
    for _, operator in ipairs(operators) do
        s, e = find(comparison, operator, 2, true)
        if s then
            o = operator
            break
        end
    end
    local f1 = (gsub(sub(comparison, 1, s - 1), "%s+$", ""):gsub("^%s+", ""))
    local f2 = (gsub(sub(comparison,    e + 1), "%s+$", ""):gsub("^%s+", ""))
    self:add(function(fields)
        if not fields[f1] then
            fields[f1] = field.new{ name = f1 }
        end
        if not fields[f2] then
            fields[f2] = field.new{ name = f2 }
        end
        local v1 = fields[f1]
        local v2 = fields[f2]
        if v1.valid and v2.valid then
            local valid, x, y = true, v1.value, v2.value
            if o == "<=" then
                valid = x <= y
            elseif o == ">=" then
                valid = x >= y
            elseif o == "==" then
                valid = x == y
            elseif o == "~=" then
                valid = x ~= y
            elseif o == "<" then
                valid = x < y
            elseif o == ">" then
                valid = x > y
            end
            if not valid then
                v1:invalidate("compare")
                v2:invalidate("compare")
            end
        end
    end)
end
function group:__call(t)
    local ir, results = self[irules], setmetatable({}, fields)
    for _, v in ipairs(ir) do
        local name, func = v.name, v.func
        if not results[name] then
            results[name] = field.new{ name = name, value = t[name] }
        end
        local fld = results[name]
        if fld.valid then
            local ok, value = func(fld.value)
            if ok then
                fld.value = value
            else
                fld:invalidate(value)
            end
        end
    end
    for name, input in pairs(t) do
        if not results[name] then
            results[name] = field.new{ name = name, value = input, validated = false }
        end
    end
    local gr = self[grules]
    for _, func in ipairs(gr) do
        func(results)
    end
    local errors
    for name, field in pairs(results) do
        if field.invalid then
            if not errors then
                errors = {}
            end
            errors[name] = field.error or "unknown"
        end
    end
    return errors == nil, results, errors
end
function new(rules)
    local self = setmetatable({ [irules] = {}, [grules] = {} }, group)
    if rules then
        local ir = self[irules]
        for index, func in pairs(rules) do
            if type(index) == "table" then
                for _, name in ipairs(index) do
                    ir[#ir+1] = { name = name, func = func }
                end
            else
                ir[#ir+1] = { name = index, func = func }
            end
        end
    end
    return self
end
local function validation(func, parent_f, parent, method)
    return setmetatable({ new = new, group = group, nothing = nothing, validators = validators }, {
        __index = function(self, index)
            return validation(function(...)
                local valid, value = func(...)
                if not valid then error(index, 0) end
                local validator = rawget(validators, index)
                if not validator then
                    error(index, 0)
                end
                local valid, v = validator(value)
                if not valid then error(index, 0) end
                if v == nothing then
                    v = nil
                elseif v == nil then
                    v = value
                end
                return true, v
            end, func, self, index)
        end,
        __call = function(_, self, ...)
            if parent ~= nil and self == parent then
                local n = select("#", ...)
                local args = { ... }
                return validation(function(...)
                    local v
                    local valid, value = parent_f(...)
                    if not valid then error(method, 0) end
                    if sub(method, 1, 2) == "if" then
                        local validator = rawget(getmetatable(validators), sub(method, 3))
                        if not validator then error(method, 0) end
                        if n > 2 then
                            valid, v = validator(unpack(args, 1, n - 2))(value)
                        else
                            valid, v = validator()(value)
                        end
                        valid, v = true, valid and args[n - 1] or args[n]
                    else
                        local validator = rawget(getmetatable(validators), method)
                        if not validator then error(method, 0) end
                        valid, v = validator(unpack(args, 1, n))(value)
                        if v == nothing then
                            v = nil
                        elseif v == nil then
                            v = value
                        end
                    end
                    if not valid then error(method, 0) end
                    return true, v
                end)
            end
            local ok, error, value = pcall(func, self, ...)
            if ok then
                return true, value
            end
            return false, error
        end
    })
end
return validation(function(...)
    return true, ...
end)
