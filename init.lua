local Replicated = game:GetService("ReplicatedStorage")
local StoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local MessagingService = game:GetService("MessagingService")
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")

local banStore = StoreService:GetDataStore("playerbans-v1")

local lib = {
	bans = {}
}

local function makeRequest(func, ...)
	return pcall(func, banStore, ...)
end

local function loadBans()
	local success, bans = makeRequest(banStore.GetAsync, "list")
	if (success) then
		if bans then
			lib.bans = Http:JSONDecode(bans)
		end
	else
		warn("Bans datastore could not be loaded.")
	end
end

local function getBan(userId: number)
	if #lib.bans > 0 then
		for i,v in lib.bans do
			if v.userId == userId then
				return true, v, i
			end
		end
	end
	return false, nil, nil
end

local function publishBans()
    local success, err = makeRequest(banStore.SetAsync, "list", Http:JSONEncode(lib.bans))
    loadBans()
    return success, err
end

local function banUser(moderatorId: number, userId: number, duration: number, reason: string)
	if not getBan(userId) then
		assert(typeof(moderatorId) == "number", "moderatorId (argument #1) must be a number")
		assert(typeof(userId) == "number", "userId (argument #2) must be a number (preferably a user ID)")
		assert(typeof(duration) == "number", "duration (argument #3) must be a number")
		assert(typeof(reason) == "string", "reason (argument #4) must be a string")
		local data = {}
		local expirationDate = os.time() + duration
		data.userId = userId
		data.expirationDate = expirationDate
		data.reason = reason
		data.moderatorId = moderatorId
		table.insert(lib.bans, data)
		local success, err = publishBans()
		if (success) then
			return true, data
		else
			return false, nil
		end
	else
		return false, "could not ban user"
	end
end

local function unbanUser(userId: number)
	local isBanned, data, dataIndex = getBan(userId)
	if isBanned then
		table.remove(lib.bans, dataIndex)
		local success, err = publishBans()
		if (success) then
			return true
		else
			return false
		end
	end
	return false
end

local function editBan(userId: number, prop: {[any]: any})
    local isBanned, data, dataIndex = getBan(userId)
    local forbiddenKeyNames = {"userId", "moderatorId"}
    if isBanned and data ~= nil then
        for k,v in prop do
            if table.find(forbiddenKeyNames, k) == nil then
                data[k] = v
            end
        end
        local success, err = publishBans()
        if (success) then
            return true, data
        end
    end
    return false, nil
end

loadBans()

lib.banUser = banUser
lib.unbanUser = unbanUser
lib.getBan = getBan
lib.editBan = editBan

return lib