print("[uBan] Loading")

uBan = {}
uBan.Bans = {
	sID1 = "EXAMPLE",
}

uBan.TempBans = {
	sID1 = "EXAMPLE|0"
}

if !file.Exists("uBans.txt", "DATA") then
	file.Write("uBans.txt", util.TableToJSON(uBan.Bans))
else
	uBan.Bans = util.JSONToTable(file.Read("uBans.txt", "DATA"))
end

if !file.Exists("uBans_Temp.txt", "DATA") then
	file.Write("uBans_Temp.txt", util.TableToJSON(uBan.TempBans))
else
	uBan.TempBans = util.JSONToTable(file.Read("uBans_Temp.txt", "DATA"))
end

function uBan.Unban(sID)
	if !string.find(sID, "STEAM") then return end
	if !uBan.Bans["sID" .. util.SteamIDTo64(sID)] and !uBan.TempBans["sID" .. util.SteamIDTo64(sID)] then return end
	
	local reason = " "
	if uBan.Bans["sID" .. util.SteamIDTo64(sID)] then
		reason = uBan.Bans["sID" .. util.SteamIDTo64(sID)]
	else
		reason = string.Explode("|", uBan.TempBans["sID" .. util.SteamIDTo64(sID)])[1]
	end
	
	print("[uBan] Unbanned SteamID " .. sID .. "(" .. reason .. ")")
	if uBan.Bans["sID" .. util.SteamIDTo64(sID)] then
		uBan.Bans["sID" .. util.SteamIDTo64(sID)] = nil
		file.Write("uBans.txt", util.TableToJSON(uBan.Bans))
	else
		uBan.TempBans["sID" .. util.SteamIDTo64(sID)] = nil
		file.Write("uBans_Temp.txt", util.TableToJSON(uBan.TempBans))
	end
end

function uBan.Ban(ply, reason, time)
	if !IsValid(ply) or !ply or !reason or 0 > time then return end
	
	if !time or time == 0 then
		print("[uBan] Permanently banned player " .. ply:Nick() .. " for " .. reason)
		uBan.Bans["sID" .. ply:SteamID64()] = reason
		file.Write("uBans.txt", util.TableToJSON(uBan.Bans))
		ply:Kick("\n[uBan] You have been permanently banned from this server for:\n" .. reason)
	else
		print("[uBan] Banned player " .. ply:Nick() .. " for " .. reason .. " (" .. string.NiceTime(time) .. ")")
		uBan.TempBans["sID" .. ply:SteamID64()] = reason .. "|" .. tostring(time)
		file.Write("uBans_Temp.txt", util.TableToJSON(uBan.TempBans))
		ply:Kick("\n[uBan] You have been temporarily banned from this server for:\n" .. reason .. "\nTime remaining:\n" .. string.NiceTime(time))
	end
end

function uBan.BanID(sID, reason, time)
	if !string.find(sID, "STEAM") then return end
	
	if !time or time == 0 then
		print("[uBan] Permanently banned SteamID " .. sID .. " for " .. reason)
		uBan.Bans["sID" .. util.SteamIDTo64(sID)] = reason
		file.Write("uBans.txt", util.TableToJSON(uBan.Bans))
	else
		print("[uBan] Banned SteamID " .. sID .. " for " .. reason .. " (" .. string.NiceTime(time) .. ")")
		uBan.TempBans["sID" .. util.SteamIDTo64(sID)] = reason .. "|" .. tostring(time)
		file.Write("uBans_Temp.txt", util.TableToJSON(uBan.TempBans))
	end
	
	for k,v in next, player.GetAll() do
		if v:SteamID() == sID then
			if !time or time == 0 then
				v:Kick("\n[uBan] You have been permanently banned from this server for:\n" .. reason)
			else
				v:Kick("\n[uBan] You have been temporarily banned from this server for:\n" .. reason .. "\nTime remaining:\n" .. string.NiceTime(time))
			end
		end
	end
end

function uBan.CheckBanned(sID64, ip, svpass, clpass, name)
	if uBan.Bans["sID" .. sID64] then
		return false, "\n[uBan] You have been permanently banned from this server for: " .. uBan.Bans["sID" .. sID64]
	end
	
	if uBans.TempBans["sID" .. sID64] then
		return false, "\n[uBan] You have been temporarily banned from this server for:\n" .. string.Explode("|", uBan.TempBans["sID" .. sID64])[1] .. "\nTime remaining:\n" .. string.Explode("|", uBan.TempBans["sID" .. sID64])[2]
	end
end

hook.Add("CheckPassword", "uBan.CheckBanned", uBan.CheckBanned)

local _R = debug.getregistry()

function _R.Player:uBan(reason, time)
	uBan.Ban(self, reason, time or 0)
end

function uBan.RemoveTime()
	for k,v in next, uBan.TempBans do
		local tbl = string.Explode("|", uBan.TempBans[k])
		
		if 0 >= tonumber(tbl[2]) then
			local sID = string.Explode("D", k)[2]
			uBan.TempBans[k] = nil
			file.Write("uBans_Temp.txt", util.TableToJSON(uBan.TempBans))
		end
		
		local time = tonumber(tbl[2])
		time = time - 1
		uBan.TempBans[k] = tbl[1] .. "|" .. tostring(time)
	end
end

timer.Create("uBan.RemoveTime", 1, 0, uBan.RemoveTime)

print("[uBan] Loaded!")
