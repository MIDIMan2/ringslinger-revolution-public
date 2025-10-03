--bHooks (Bastardized Hooks), a takis hook clone for accessibility.

--this file is completely reusable
--used in 'epic! murder mystery', 'spice runners' and 'soap/takis'
--coders: Unmatched Bracket, Luigi Budd, Jisk

RSR.events = {}
RSR.internal_hook_name = "RSR"

/*
	return value: Boolean (override default behavior?)
	true = override, otherwise hook is ran then the default function after
*/
local handler_snaptrue = {
	func = function(current, ...)
		local arg = {...}
		return (#arg and true or false) or current
	end,
	initial = false
}

/*
	if true, then the default func will run
	if false, then the default func will be forced to not run
	if nil, use the default behavior
	...generally
*/
local handler_snapany = {
	func = function(current, ...)
		local arg = {...}
		if #arg then
			return unpack(arg)
		else
			return current ~= nil and unpack(current) or nil
		end
	end,
	initial = nil
}

local handler_default = handler_snaptrue -- If no handler is given.

local typefor_mobj = function(this_mobj, ...)
	local arg = {...}
	local type = (#arg and arg[1] or nil)
	if (type == nil) then
		return true
	end
	return this_mobj.type == type
end

local events = {}

events["PlayerKnockback"] = {
    handler = handler_snapany; 
    --typefor = typefor_mobj
}

events["PlayerDamage"] = {
    handler = handler_snapany; 
    --typefor = typefor_mobj
}

events["DeathFling"] = {
    handler = handler_snapany; 
    --typefor = typefor_mobj
}

events["HealthTake"] = {
    handler = handler_snapany; 
    --typefor = typefor_mobj
}

events["ArmorTake"] = {
    handler = handler_snapany; 
    --typefor = typefor_mobj
}

local deprecated = {
    /* EXAMPLE
    ["MyHook"] = {
        correct = "MyNewHook";
        seen = false; -- Always define as false.
    }
    */
}

--check for new events...
for event_name, event_t in pairs(events)
	if (RSR.events[event_name] == nil) then
		RSR.events[event_name] = event_t
		print("\x83"..RSR.internal_hook_name..":\x80 Adding new hookevent... (\""..event_name..'")')
	else
		print("\x83"..RSR.internal_hook_name..":\x80 Hooklib found an existing hookevent, not adding. (\""..event_name..'")')
	end
end

RSR.addHook = function(hooktype, func, typefor)
	local hook_okay = RSR.events[hooktype] ~= nil
	local dep_t = nil
	if not hook_okay then
		hook_okay = deprecated[hooktype] ~= nil
		dep_t = deprecated[hooktype]
	end
	
	if hook_okay then
		if dep_t ~= nil then
			if not dep_t.seen then
                RSR.hook_warn("Hook type \""..hooktype.."\" has been deprecated and will be removed. Use \""..dep_t.correct.."\" instead.", sfx_skid)
			end
			hooktype = dep_t.correct
		end
		
		table.insert(RSR.events[hooktype], {
			func = func,
			typedef = typefor,
			errored = false,
			id = #RSR.events[hooktype]
		})
	else
        RSR.hook_error("Hook type \""..hooktype.."\" does not exist.")
	end
end

RSR.tryRunHook = function(hooktype, v, ...)
	local handler = RSR.events[hooktype].handler or handler_default
	local override = handler.initial

	local results = {pcall(v.func, ...)}
	local status = results[1] or nil
	table.remove(results,1)
	
	if status then
		override = {handler.func(
			override,
			unpack(results)
		)}
	elseif (not v.errored) then
		v.errored = true

        RSR.hook_error("Hook " .. hooktype .. " handler #" .. i .. " error:", sfx_lose)
		print(unpack(results))
	end
	
	if override == nil then return nil; end
	if type(override) == "table" then return unpack(override)
	else return override; end
end

local notvalid = {}
RSR.findEvent = function(hooktype)
	local name = hooktype
	local events = RSR.events[name]
	
	if events == nil
	and deprecated[hooktype] ~= nil then
		name = deprecated[hooktype].correct
		events = BHook[name]
	end
	
	if events == nil
	and not (notvalid[name]) then
	notvalid[name] = true
        RSR.hook_warn("could not find hookevent \""..hooktype.."\"")
	end
	
	--can still return nil!
	return events, name
end

RSR.hook_warn = function(text, sound)
    if sound and sound > 0 then
        S_StartSound(nil, sound)
    end
    
    print("\x83"..RSR.internal_hook_name..":\x82 WARNING:\x80 "..text)
end

RSR.hook_error = function(text, sound)
    if sound and sound > 0 then
        S_StartSound(nil, sound)
    elseif sound ~= nil then
        S_StartSound(nil, sfx_skid)
    end
    
    error("\x83"..RSR.internal_hook_name..":\x85 ERROR:\x80 "..text, 2)
end