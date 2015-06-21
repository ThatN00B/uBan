print("[uBan] Loading")

uBan = {}
uBan.Bans = {
	sID1 = "EXAMPLE",
}

if !file.Exists("uBans.txt", "DATA") then
	file.Write("uBans.txt", util.TableToJSON(uBan.Bans))
else
	uBan.Bans = util.JSONToTable(file.Read("uBans.txt", "DATA"))
end

function uBan.Unban(sID)
	if !util.SteamIDTo64(sID) then return end
	if !uBan.Bans["sID" .. util.SteamIDTo64(sID)] then return end
	
	print("[uBan] Unbanned SteamID " .. sID .. " (" .. uBan.Bans["sID" .. util.SteamIDTo64(sID)] .. ")")
	uBan.Bans["sID" .. util.SteamIDTo64(sID)] = nil
	file.Write("uBans.txt", util.TableToJSON(uBan.Bans))
end

function uBan.Ban(ply, reason)
	if !IsValid(ply) or !ply or !reason then return end
	
	print("[uBan] Banned player " .. ply:Nick() .. " for " .. reason)
	uBan.Bans["sID" .. ply:SteamID64()] = reason
	file.Write("uBans.txt", util.TableToJSON(uBan.Bans))
	ply:Kick("[uBan] You have been banned from this server for: " .. reason)
end

function uBan.BanID(sID, reason)
	if !string.find(sID, "STEAM") then return end
	
	print("[uBan] Banned SteamID " .. sID .. " for " .. reason)
	uBan.Bans["sID" .. util.SteamIDTo64(sID)] = reason
	file.Write("uBans.txt", util.TableToJSON(uBan.Bans))
	
	for k,v in next, player.GetAll() do
		if ply:SteamID() == sID then
			ply:Kick("[uBan] You have been banned from this server for: " .. reason)
		end
	end
end

function uBan.CheckBanned(sID64, ip, svpass, clpass, name)
	if uBan.Bans["sID" .. sID64] then
		return false, "[uBan] You have been banned from this server for: " .. uBan.Bans["sID" .. sID64]
	end
end

hook.Add("CheckPassword", "uBan.CheckBanned", uBan.CheckBanned)

local _R = debug.getregistry()

function _R.Player:uBan(reason)
	uBan.Ban(self, reason)
end

print("[uBan] Loaded!")
