--====================================================================================
-- All work by jojos38 & Titch2000.
-- You have no permission to edit, redistribute or upload. Contact us for more info!
--====================================================================================



local M = {}
print("positionGE Initialising...")



local function tick()
	local ownMap = vehicleGE.getOwnMap() -- Get map of own vehicles
	for i,v in pairs(ownMap) do -- For each own vehicle
		local veh = be:getObjectByID(i) -- Get vehicle
		if veh then
			veh:queueLuaCommand("positionVE.getVehicleRotation()")
			--veh:queueLuaCommand("positionVE.getVehicleVelocity()")
			--veh:queueLuaCommand("positionVE.getVehicleAngularVelocity()")
		end
	end
end

local function distance( x1, y1, z1, x2, y2, z2 )
	local dx = x1 - x2
	local dy = y1 - y2
	local dz = z1 - z2
	return math.sqrt ( dx*dx + dy*dy + dz*dz)
end

local function sendVehiclePosRot(data, gameVehicleID)
	if GameNetwork.connectionStatus() == 1 then -- If TCP connected
		local serverVehicleID = vehicleGE.getServerVehicleID(gameVehicleID) -- Get serverVehicleID
		if serverVehicleID and vehicleGE.isOwn(gameVehicleID) then -- If serverVehicleID not null and player own vehicle
			GameNetwork.send('Zp:'..serverVehicleID..":"..data)--Network.buildPacket(0, 2134, serverVehicleID, data))
		end
	end
end


local function applyPos(data, serverVehicleID)

	-- 1 = pos.x
	-- 2 = pos.y
	-- 3 = pos.z

	-- 4 = vel.x
	-- 5 = vel.y
	-- 6 = vel.z

	-- 7 = rot.x
	-- 8 = rot.y
	-- 9 = rot.z

	local gameVehicleID = vehicleGE.getGameVehicleID(serverVehicleID) or -1 -- get gameID
	local veh = be:getObjectByID(gameVehicleID)
	if veh then
		local pr = jsonDecode(data) -- Decoded data
		local pos = veh:getPosition()
		local diff = distance(pos.x, pos.y, pos.z, pr[1], pr[2], pr[3])
		print("Diff: "..diff)
		if diff > 0.5 then
			veh:setPosition(Point3F(pr[1], pr[2], pr[3]))
		else
			vel = vec3(pr[4], pr[5], pr[6])
			rot = vec3(pr[7], pr[8], pr[9])
			--veh:queueLuaCommand("positionVE.setVehiclePosRot(" .. tostring(pos) .. "," .. tostring(rot) .. "," .. timestamp .. ")")

			-- Apply velocities
			veh:queueLuaCommand("velocityVE.setVelocity(\'"..vel.."\')")
			-- TODO: shorten this line
			veh:queueLuaCommand("velocityVE.setAngularVelocity(\'"..rot.."\')")
		end
		veh:queueLuaCommand("electricsVE.applyLatestElectrics()") -- Redefine electrics values
	end
end

local function handle(rawData)
	--print("positionGE.handle: "..rawData)
	rawData = string.sub(rawData,3)
	local serverVehicleID = string.match(rawData,"(%w+)%:")
	local data = string.match(rawData,":(.*)")
	--print(serverVehicleID)
	--print(data)
	applyPos(data, serverVehicleID)
end


M.applyPos          = applyPos
M.tick              = tick
M.handle            = handle
M.sendVehiclePosRot = sendVehiclePosRot



print("positionGE Loaded.")
return M
