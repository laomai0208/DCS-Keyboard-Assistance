--- DO NOT EDIT.
--- This file is for reference purposes only
--- All user modifications should go to $HOME\Saved Games\DCS\Scripts\Export.lua

-- Data export script for DCS, version 1.2.
-- Copyright (C) 2006-2014, Eagle Dynamics.
-- See http://www.lua.org for Lua script system info 
-- We recommend to use the LuaSocket addon (http://www.tecgraf.puc-rio.br/luasocket) 
-- to use standard network protocols in Lua scripts.
-- LuaSocket 2.0 files (*.dll and *.lua) are supplied in the Scripts/LuaSocket folder
-- and in the installation folder of the DCS. 

-- Expand the functionality of following functions for your external application needs.
-- Look into Saved Games\DCS\Logs\dcs.log for this script errors, please.

-- copyright @ DamienLIU 20200730
-- version 1.0.1

--[[    
-- Uncomment if using Vector class from the Scripts\Vector.lua file 
local lfs = require('lfs')
LUA_PATH = "?;?.lua;"..lfs.currentdir().."/Scripts/?.lua"
require 'Vector'
-- See the Scripts\Vector.lua file for Vector class details, please.
--]]

local default_output_file = nil

function LuaExportStart()
-- Works once just before mission start.
-- Make initializations of your files or connections here.
-- For example:
-- 1) File

  -- default_output_file = io.open("D:/Export.log", "w")
  -- default_output_file:write("test\n")

-- 2) Socket
  package.path  = package.path..";"..lfs.currentdir().."/LuaSocket/?.lua"
  package.cpath = package.cpath..";"..lfs.currentdir().."/LuaSocket/?.dll"
  socket = require("socket")
	host = "127.0.0.1"
	port1 = 12345
	port2 = 12344
	
    socket = require("socket")
    
	-- send
    c = socket.udp()
    c:setpeername(host, port1)
    c:settimeout(.01) -- set the timeout for reading the socket 
	
	-- receive
	d = socket.udp()
    d:setsockname('*', port2)
    d:settimeout(0) -- set the timeout for reading the socket 

end

function LuaExportBeforeNextFrame()
	ProcessInput() 
	-- LoSetCommand(3, 0.25)
	-- LoSetCommand(64,1)
-- Call Lo*() functions to set data to Lock On here
-- For example:
--    LoSetCommand(3, 0.25) -- rudder 0.25 right 
--    LoSetCommand(64) -- increase thrust


end

function LuaExportAfterNextFrame()
-- Works just after every simulation frame.

-- Call Lo*() functions to get data from Lock On here.
-- For example:

    local t = LoGetModelTime()
    local name = LoGetPilotName()
    local altBar = LoGetAltitudeAboveSeaLevel()
    local altRad = LoGetAltitudeAboveGroundLevel()
    local pitch, bank, yaw = LoGetADIPitchBankYaw()
    local engine = LoGetEngineInfo()
    local HSI    = LoGetControlPanel_HSI()
    local IAS = LoGetIndicatedAirSpeed()
	local ID = LoGetPlayerPlaneId()
	local o = LoGetObjectById(ID)
	local Lat = o.LatLongAlt.Lat
	local Long = o.LatLongAlt.Long
	local Alt =  o.LatLongAlt.Alt
	local x = o.Position.x
	local y = o.Position.y
	local z = o.Position.z
	local tas = LoGetTrueAirSpeed()
	local mssage = ""
    local obj = LoGetWorldObjects()
	
	if x==nil then
	x=0
	end
	
	if y==nil then
	y=0
	end
	if z==nil then
	z=0
	end
	
	-- for k,v in pairs(o) do
      -- p=string.format("%s",v.Country)
	-- end
	
	p = o.Type.level4
	
	if p==nil then
	p = "bug"
	end
	
	--msg = string.format("t=%.2f, IAS = %.2f, ID=%.0f, Long=%.4f, x=%.2f, y=%.2f, z=%.2f, planeName:%s",t,IAS,ID,Long,x,y,z,p)


    for k,v in pairs(obj) do
       --socket.try(c:send(string.format("t = %.2f, ID = %d, name = %s, country = %s(%s), LatLongAlt = (%f, %f, %f), heading = %f\n", t, k, v.Name, v.Country, v.Coalition, v.LatLongAlt.x, v.LatLongAlt.Long, v.LatLongAlt.Alt, v.Heading)))
	    p1 = v.Type.level4
		if p1==nil then
		p1 = "bug"
		end
		
		p2 = v.Name
		if p2 ==nil then
		p2 = "NilName"
		end
		
		p3 = v.Country
		if p3 ==nil then
		p3 = "NilCountry"
		end
		
		p4 = v.LatLongAlt
		if p4 ==nil then
		p4 = {0,0,0}
		end
		
		p5 = v.Position
		if p5 ==nil then
		p5 = {0,0,0}
		end
		
		p6 = v.Heading
		if p6 ==nil then
		p6 = 0
		end
				
		p7 = v.Pitch
		if p7 ==nil then
		p7 = 0
		end
		
		p8 = v.Bank
		if p8 ==nil then
		p8 = 0
		end
		



		--[[
		if p1 == 28
		then
		msg = string.format("TankerInfo:  planeID:%s, name = %s, country = %s, LatLongAlt = (%f, %f, %f),  Heading = %f", p1, p2, p3, p4.Lat,p4.Long,p4.Alt,p5)
		else
		msg = string.format("FighterInfo:  planeID:%s, name = %s, country = %s, LatLongAlt = (%f, %f, %f), Heading = %f", p1, p2, p3, p4.Lat,p4.Long,p4.Alt,p5)
		end	
		--]]
		
		if k == ID
		then
		msg = string.format("%f,%f,%f,%f,%f,%f,%f;",t, p5.x, p5.y, p5.z, p6, p7, p8)
		mssage = table.concat({mssage,msg})
		elseif p1 == 28
		then
		msg = string.format("%f,%f,%f,%f,%f,%f,%f",t, p5.x, p5.y, p5.z, p6, p7, p8)
		mssage = table.concat({mssage,msg})
		else
		end

		-- msg = string.format("FighterInfo:  planeID:%s, name = %s, country = %s, LatLongAlt = (%f, %f, %f), Position = (%f, %f, %f), Heading = %f, Pitch = %f, Bank = %f", ID, p2, p3, p4.Lat, p4.Long, p4.Alt, p5.x, p5.y, p5.z, p6, p7, p8)
		-- msg = table.concat({msg,"\n"})

		
    end
	
	socket.try(c:send(string.format("tm%.2f",t)))
	socket.try(c:send(string.format("va%.2f",tas)))
	socket.try(c:send(string.format("ms%s",mssage)))




-- Then send data to your file or to your receiving program:
-- 1) File
 -- if default_output_file then
      -- default_output_file:write(string.format("t = %.2f, name = %s, altBar = %.2f, altRad = %.2f, pitch = %.2f, bank = %.2f, yaw = %.2f \n", t, name, altBar, altRad, 57.3*pitch, 57.3*bank, 57.3*yaw))
	-- default_output_file:write(string.format("t = %.2f ,RPM left = %f  fuel_internal = %f \n",t,engine.RPM.left,engine.fuel_internal))
      -- default_output_file:write(string.format("ADF = %f  RMI = %f\n ",57.3*HSI.ADF,57.3*HSI.RMI))
   -- end
-- 2) Socket
	-- socket.try(c:send("you\n")))
	--socket.try(c:send(string.format(" t=%.2f, IAS = %.2f, ID=%.0f, Long=%.4f, x=%.2f, y=%.2f, z=%.2f",t,IAS,ID,Long,x,y,z)))
	-- socket.try(c:send(string.format("t = %.2f, name = %s, Long = %.2f, Lat = %.2f, Alt = %.2f\n",t,name, Long, Lat, Alt)))
    -- socket.try(c:send(string.format("t = %.2f, name = %s, altBar = %.2f, alrRad = %.2f, pitch = %.2f, bank = %.2f, yaw = %.2f, Hp = %.2f\n", t, name, altRad, altBar, pitch, bank, yaw, engine.HydraulicPressure.left)))
	-- ProcessInput()
end

function LuaExportStop()
-- Works once just after mission stop.
-- Close files and/or connections here.
-- 1) File
   -- if default_output_file then
      -- default_output_file:close()
      -- default_output_file = nil
   -- end
-- 2) Socket
    socket.try(c:send("quit")) -- to close the listener socket
    c:close()
-- local lfs = require("lfs")
-- local io = require("io")
-- f = io.open("D:/input.txt", "w")
-- if f then
	-- f:write("\n\n*** fenv:\n")
	-- for k, v in pairs(getfenv()) do
		-- f:write(tostring(k))
		-- f:write("\t")
		-- f:write(tostring(v))
		-- f:write("\n")
	-- end	
	-- f:close()
-- end

	f:close()
end

function LuaExportActivityNextEvent(t)
    local tNext = t

-- Put your event code here and increase tNext for the next event
-- so this function will be called automatically at your custom
-- model times. 
-- If tNext == t then the activity will be terminated.

-- For example:
-- 1) File
--  if default_output_file then
    --    local o = LoGetWorldObjects()
    --        for k,v in pairs(o) do
    --            default_output_file:write(string.format("t = %.2f, ID = %d, name = %s, country = %s(%s), LatLongAlt = (%f, %f, %f), heading = %f\n", t, k, v.Name, v.Country, v.Coalition, v.LatLongAlt.Lat, v.LatLongAlt.Long, v.LatLongAlt.Alt, v.Heading))
    --        end
    --    local trg = LoGetLockedTargetInformation()
    --  default_output_file:write(string.format("locked targets ,time = %.2f\n",t))
    --    for i,cur in pairs(trg) do
    --      default_output_file:write(string.format("ID = %d, position = (%f,%f,%f) , V = (%f,%f,%f),flags = 0x%x\n",cur.ID,cur.position.p.x,cur.position.p.y,cur.position.p.z,cur.velocity.x,cur.velocity.y,cur.velocity.z,cur.flags))
    --    end
    --    local route = LoGetRoute()
    --    default_output_file:write(string.format("t = %f\n",t))
    --    if route then
    --          default_output_file:write(string.format("Goto_point :\n point_num = %d ,wpt_pos = (%f, %f ,%f) ,next %d\n",route.goto_point.this_point_num,route.goto_point.world_point.x,route.goto_point.world_point.y,route.goto_point.world_point.z,route.goto_point.next_point_num))
    --          default_output_file:write(string.format("Route points:\n"))
    --        for num,wpt in pairs(route.route) do
    --          default_output_file:write(string.format("point_num = %d ,wpt_pos = (%f, %f ,%f) ,next %d\n",wpt.this_point_num,wpt.world_point.x,wpt.world_point.y,wpt.world_point.z,wpt.next_point_num))
    --        end
    --    end

    --    local stations = LoGetPayloadInfo()
    --    if stations then
    --        default_output_file:write(string.format("Current = %d \n",stations.CurrentStation))

    --        for i_st,st in pairs (stations.Stations) do
    --            local name = LoGetNameByType(st.weapon.level1,st.weapon.level2,st.weapon.level3,st.weapon.level4);
    --            if name then
    --            default_output_file:write(string.format("weapon = %s ,count = %d \n",name,st.count))
    --            else
    --            default_output_file:write(string.format("weapon = {%d,%d,%d,%d} ,count = %d \n", st.weapon.level1,st.weapon.level2,st.weapon.level3,st.weapon.level4,st.count))
    --            end
    --        end
    --    end 

    --    local Nav = LoGetNavigationInfo()
    --    if Nav then
    --        default_output_file:write(string.format("%s ,%s  ,ACS: %s\n",Nav.SystemMode.master,Nav.SystemMode.submode,Nav.ACS.mode))
    --        default_output_file:write(string.format("Requirements :\n\t  roll %d\n\t pitch %d\n\t speed %d\n",Nav.Requirements.roll,Nav.Requirements.pitch,Nav.Requirements.speed))
    --    end
--    end


    --tNext = tNext + 1.0
-- 2) Socket
   -- local o = LoGetWorldObjects()
   -- for k,v in pairs(o) do
     -- socket.try(c:send(string.format("t = %.2f, ID = %d, name = %s, country = %s(%s), LatLongAlt = (%f, %f, %f), heading = %f\n", t, k, v.Name, v.Country, v.Coalition, v.LatLongAlt.x, v.LatLongAlt.Long, v.LatLongAlt.Alt, v.Heading)))
   -- end

	-- socket.try(c:send(string.format(" t=%.2f, IAS = %.2f, ID=%.0f, Long=%.4f, x=%.2f, y=%.2f, z=%.2f",t,IAS,ID,Long,x,y,z)))
   
	--tNext = tNext + 0.1

    return tNext
end

function ProcessInput()

	data = d:receive()	
	
	dataSub0h = string.sub(data,1,1)
	dataSub0b = string.sub(data,2,5)
	dataSub1h = string.sub(data,6,6)
	dataSub1b = string.sub(data,7,10)
	dataSub2h = string.sub(data,11,11)
	dataSub2b = string.sub(data,12,15)
	dataSub3h = string.sub(data,16,16)
	dataSub3b = string.sub(data,17,20)
	dataSub4h = string.sub(data,21,21)
	dataSub4b = string.sub(data,22,25)
		
	if dataSub0h=="1" then
	pitch = -tonumber(dataSub0b)/1000
	end
	if dataSub0h=="2" then
	pitch = tonumber(dataSub0b)/1000
	end
	if dataSub0h~="0" then
	LoSetCommand(2001,pitch)
	end
	
	if dataSub1h=="1" then
	roll = -tonumber(dataSub1b)/1000
	end
	if dataSub1h=="2" then
	roll = tonumber(dataSub1b)/1000
	end
	if dataSub1h~="0" then
	LoSetCommand(2002,roll)
	end
		
	if dataSub2h=="1" then
	thrust = -tonumber(dataSub2b)/1000
	end
	if dataSub2h=="2" then
	thrust = tonumber(dataSub2b)/1000
	end
	
	
	-- local ID = LoGetPlayerPlaneId()
	-- local o = LoGetObjectById(ID)
	if dataSub2h~="0" then
	-- local pt = o.Type.level4
	mstr = string.format("%s",p)
	
	if mstr == "267" then
	LoSetCommand(2024,thrust)
	else
	LoSetCommand(2004,thrust)
	end
	end
	
	if dataSub3h=="1" then
	selecterV = -tonumber(dataSub3b)/1000
	end
	if dataSub3h=="2" then
	selecterV = tonumber(dataSub3b)/1000
	end
	if dataSub3h~="0" then
	LoSetCommand(2034,selecterV)
	end
	--JF17 2034
	--F18 ???
	
	if dataSub4h=="1" then
	selecterH = -tonumber(dataSub4b)/1000
	end
	if dataSub4h=="2" then
	selecterH = tonumber(dataSub4b)/1000
	end
	if dataSub4h~="0" then
	LoSetCommand(2033,selecterH)
	end
	--JF17 2033
	--F18 ???
end
--[[

-- Lock On supports Lua coroutines using internal LoCreateCoroutineActivity() and
-- external CoroutineResume() functions. Here is an example of using scripted coroutine.

Coroutines = {}    -- global coroutines table
CoroutineIndex = 0    -- global last created coroutine index

-- This function will be called by Lock On model timer for every coroutine to resume it
function CoroutineResume(index, tCurrent)
    -- Resume coroutine and give it current model time value
    coroutine.resume(Coroutines[index], tCurrent)
    return coroutine.status(Coroutines[index]) ~= "dead"
    -- If status == "dead" then Lock On activity for this coroutine dies too 
end

-- Coroutine function example using coroutine.yield() to suspend 
function f(t)
    local tNext = t
    local file = io.open("./Temp/Coroutine.log", "w")
    file:write(string.format("t = %f, started\n", tNext))
    tNext = coroutine.yield()
    for i = 1,10 do
        file:write(string.format("t = %f, continued\n", tNext))
        tNext = coroutine.yield()
    end
    file:write(string.format("t = %f, finished\n", tNext))
    file:close()
end

-- Create your coroutines and save them in Coriutines table, e.g.:
CoroutineIndex = CoroutineIndex + 1
Coroutines[CoroutineIndex] = coroutine.create(f) 

-- Use LoCreateCoroutineActivity(index, tStart, tPeriod) to plan your coroutines
-- activity at model times, e.g.:
LoCreateCoroutineActivity(CoroutineIndex, 1.0, 3.0) -- to start at 1.0 second with 3.0 seconds period
-- Coroutine output in the Coroutine.log file:
-- t = 1.000000, started
-- t = 4.000000, continued
-- t = 7.000000, continued
-- t = 10.000000, continued
-- t = 13.000000, continued
-- t = 16.000000, continued
-- t = 19.000000, continued
-- t = 22.000000, continued
-- t = 25.000000, continued
-- t = 28.000000, continued
-- t = 31.000000, continued
-- t = 34.000000, finished
--]]

--[[ You can use registered Lock On internal data exporting functions in this script
and in your scripts called from this script.

Note: following functions are implemented for exporting technology experiments only,
so they may be changed or removed in the future by developers.

All returned values are Lua numbers if not pointed other type.

Output:
LoIsObjectExportAllowed() -- returns true if world objects data is available
LoIsSensorExportAllowed() -- returns true if radar/targets data is available
LoIsOwnshipExportAllowed() -- true if ownship data is available

LoGetModelTime() -- returns current model time (args - 0, results - 1 (sec))
LoGetMissionStartTime() -- returns mission start time (args - 0, results - 1 (sec))
LoGetPilotName() -- (args - 0, results - 1 (text string))
LoGetPlayerPlaneId() -- (args - 0, results - 1 (number))
LoGetIndicatedAirSpeed() -- (args - 0, results - 1 (m/s))
LoGetTrueAirSpeed() -- (args - 0, results - 1 (m/s))
LoGetAltitudeAboveSeaLevel() -- (args - 0, results - 1 (meters))
LoGetAltitudeAboveGroundLevel() -- (args - 0, results - 1 (meterst))
LoGetAngleOfAttack() -- (args - 0, results - 1 (rad))
LoGetAccelerationUnits() -- (args - 0, results - table {x = Nx,y = NY,z = NZ} 1 (G))
LoGetVerticalVelocity()  -- (args - 0, results - 1(m/s))
LoGetMachNumber()        -- (args - 0, results - 1)
LoGetADIPitchBankYaw()   -- (args - 0, results - 3 (rad))
LoGetMagneticYaw()       -- (args - 0, results - 1 (rad)
LoGetGlideDeviation()    -- (args - 0,results - 1)( -1 < result < 1)
LoGetSideDeviation()     -- (args - 0,results - 1)( -1 < result < 1)
LoGetSlipBallPosition()  -- (args - 0,results - 1)( -1 < result < 1)
LoGetBasicAtmospherePressure() -- (args - 0,results - 1) (mm hg)
LoGetControlPanel_HSI()  -- (args - 0,results - table)
result = 
{
    ADF_raw, (rad)
    RMI_raw, (rad)
    Heading_raw, (rad)
    HeadingPointer, (rad)
    Course, (rad)
    BearingPointer, (rad)
    CourseDeviation, (rad)
}
LoGetEngineInfo() -- (args - 0 ,results = table)
engineinfo =
{
    RPM = {left, right},(%)
    Temperature = { left, right}, (Celcium degrees)
    HydraulicPressure = {left ,right},kg per square centimeter
    FuelConsumption   = {left ,right},kg per sec
    fuel_internal      -- fuel quantity internal tanks    kg
    fuel_external      -- fuel quantity external tanks    kg
            
}

LoGetRoute()  -- (args - 0,results = table)
get_route_result =
{
    goto_point, -- next waypoint
    route       -- all waypoints of route (or approach route if arrival or landing)
}
waypoint_table =
{
    this_point_num,        -- number of point ( >= 0)
    world_point = {x,y,z}, -- world position in meters
    speed_req,             -- speed at point m/s 
    estimated_time,        -- sec
    next_point_num,           -- if -1 that's the end of route
    point_action           -- name of action "ATTACKPOINT","TURNPOINT","LANDING","TAKEOFF"
}
LoGetNavigationInfo() (args - 0,results - 1( table )) -- information about ACS
get_navigation_info_result =
{
    SystemMode = {master,submode}, -- (string,string) current mode and submode 
--[=[
    master values (depend of plane type)
                "NAV"  -- navigation
                "BVR"  -- beyond visual range AA mode
                "CAC"  -- close air combat                
                "LNG"  -- longitudinal mode
                "A2G"  -- air to ground
                "OFF"  -- mode is absent
    submode values (depend of plane type and master mode)
    "NAV" submodes
    {
        "ROUTE"
        "ARRIVAL"
        "LANDING"
        "OFF" 
    }
    "BVR" submodes
    { 
        "GUN"   -- Gunmode
        "RWS"   -- RangeWhileSearch
        "TWS"   -- TrackWhileSearch
        "STT"   -- SingleTrackTarget (Attack submode)
        "OFF" 
    }
    "CAC" submodes
    {
        "GUN"
        "VERTICAL_SCAN"
        "BORE"
        "HELMET"  
        "STT"
        "OFF"
    }
    "LNG" submodes
    {
        "GUN"
        "OFF"
        "FLOOD"  -- F-15 only
    }
    "A2G" submodes
    {
        "GUN"
        "ETS"       -- Emitter Targeting System On
        "PINPOINT"  
        "UNGUIDED"  -- unguided weapon (free fall bombs, dispensers , rockets) 
        "OFF"
    }
--]=]
    Requirements =  -- required parameters of flight
    {
        roll,       -- required roll,pitch.. , etc.
        pitch,       
        speed,    
        vertical_speed, 
        altitude,
    }
    ACS =   -- current state of the Automatic Control System
    {
        mode = string , 
        --[=[
            mode values  are :     
                    "FOLLOW_ROUTE",
                    "BARO_HOLD",          
                    "RADIO_HOLD",       
                    "BARO_ROLL_HOLD",     
                    "HORIZON_HOLD",   
                    "PITCH_BANK_HOLD",
                    "OFF"
        --]=]
        autothrust , -- 1(true) if autothrust mode is on or 0(false) when not;  
    }
}
LoGetMCPState() -- (args - 0, results - 1 (table of key(string).value(boolean))
    returned table keys for LoGetMCPState():
        "LeftEngineFailure"
        "RightEngineFailure"
        "HydraulicsFailure"
        "ACSFailure"
        "AutopilotFailure"
        "AutopilotOn"
        "MasterWarning"
        "LeftTailPlaneFailure"
        "RightTailPlaneFailure"
        "LeftAileronFailure"
        "RightAileronFailure"
        "CanopyOpen"
        "CannonFailure"
        "StallSignalization"
        "LeftMainPumpFailure"
        "RightMainPumpFailure"
        "LeftWingPumpFailure"
        "RightWingPumpFailure"
        "RadarFailure"
        "EOSFailure"
        "MLWSFailure"
        "RWSFailure"
        "ECMFailure"
        "GearFailure"
        "MFDFailure"
        "HUDFailure"
        "HelmetFailure"
        "FuelTankDamage"
LoGetObjectById() -- (args - 1 (number), results - 1 (table))
 Returned object table structure:
 { 
    Name = 
    Type =  {level1,level2,level3,level4},  ( see Scripts/database/wsTypes.lua) Subtype is absent  now
    Country   =   number ( see Scripts/database/db_countries.lua
    Coalition = 
    CoalitionID = number ( 1 or 2 )
    LatLongAlt = { Lat = , Long = , Alt = }
    Heading =   radians
    Pitch      =   radians
    Bank      =  radians
    Position = {x,y,z} -- in internal DCS coordinate system ( see convertion routnes below)
    only for units ( Planes,Hellicopters,Tanks etc)
    UnitName    = unit name from mission (UTF8)  
    GroupName = unit name from mission (UTF8)
        Flags = {
        RadarActive = true if the unit has its radar on
        Human = true if the unit is human-controlled
        Jamming = true if the unit uses EMI jamming
        IRJamming = -- same for IR jamming
        Born = true if the unit is born (activated)
        AI_ON = true if the unit's AI is active
        Invisible = true if the unit is invisible
        Static - true if the unit is a static object
        }
 }


LoGetWorldObjects() -- (args - 0- 1, results - 1 (table of object tables))  arg can be
    "units" (default)
    "ballistic" - for different type of unguided munition ()bombs,shells,rockets)
    "airdromes" - to get airdrome objects
 Returned table index = object identificator
 Returned object table structure (see LoGetObjectById())

LoGetSelfData return the same result as LoGetObjectById but only for your aircraft and not depended on anti-cheat setting in Export/Config.lua
 
LoGetAltitude(x, z) -- (args - 2 : meters, results - 1 : altitude above terrain surface, meters)

LoGetCameraPosition() -- (args - 0, results - 1 : view camera current position table:
    {
        x = {x = ..., y = ..., z = ...},    -- orientation x-vector
        y = (x = ..., y = ..., z = ...},    -- orientation y-vector
        z = {x = ..., y = ..., z = ...},    -- orientation z-vector
        p = {x = ..., y = ..., z = ...}        -- point vector 
    }
    all coordinates are in meters. You can use Vector class for position vectors.
    
-- Weapon Control System
LoGetNameByType () -- args 4 (number : level1,level2,level3,level4), result string

LoGetTargetInformation()       -- (args - 0, results - 1 (table of current targets tables)) 
LoGetLockedTargetInformation() -- (args - 0, results - 1 (table of current locked targets tables)) 
 this functions return the table of the next target data
 target =
 {
    ID ,                                  -- world ID (may be 0 ,when ground point track)
    type = {level1,level2,level3,level4}, -- world database classification
    country = ,                           -- object country
    position = {x = {x,y,z},   -- orientation X ort  
                y = {x,y,z},   -- orientation Y ort
                z = {x,y,z},   -- orientation Z ort
                p = {x,y,z}}   -- position of the center  
    velocity =        {x,y,z}, -- world velocity vector m/s
    distance = ,               -- distance in meters
    convergence_velocity = ,   -- closing speed in m/s
    mach = ,                   -- M number
    delta_psi = ,              -- aspect angle rad
    fim = ,                    -- viewing angle horizontal (in your body axis) rad
    fin = ,                    -- viewing angle vertical   (in your body axis) rad
    flags = ,                   -- field with constants detemining  method of the tracking 
                                --    whTargetRadarView        = 0x0002;    -- Radar review (BVR) 
                                --    whTargetEOSView            = 0x0004;    -- EOS   review (BVR)
                                --    whTargetRadarLock        = 0x0008;    -- Radar lock (STT)  == whStaticObjectLock (pinpoint) (static objects,buildings lock)
                                --    whTargetEOSLock            = 0x0010;    -- EOS   lock (STT)  == whWorldObjectLock (pinpoint)  (ground units lock)
                                --    whTargetRadarTrack        = 0x0020;    -- Radar lock (TWS)
                                --    whTargetEOSTrack        = 0x0040;    -- Radar lock (TWS)  == whImpactPointTrack (pinpoint) (ground point track)
                                --    whTargetNetHumanPlane    = 0x0200;    -- net HumanPlane
                                --    whTargetAutoLockOn      = 0x0400;    -- EasyRadar  autolockon
                                --    whTargetLockOnJammer      = 0x0800;    -- HOJ   mode

    reflection = ,             -- target cross section square meters
    course = ,                 -- target course rad
    isjamming = ,              -- target ECM on or not
    start_of_lock = ,          -- time of the beginning of lock
    forces = { x,y,z},         -- vector of the acceleration units 
    updates_number = ,         -- number of the radar updates
    
    jammer_burned = true/false -- indicates that jammer are burned
 }
LoGetSightingSystemInfo() -- sight system info
{
    Manufacturer  = "RUS"/"USA"
    LaunchAuthorized  = true/false
    ScanZone =
        {
                position
                {
                    azimuth
                    elevation
                    if Manufacturer  == "RUS" then
                            distance_manual
                           exceeding_manual
                    end
                   }
                coverage_H
                {
                    min
                    max
                }
                size
                {
                    azimuth
                    elevation
                }
        }
        scale
        {
            distance                    
            azimuth
        }
        TDC 
        {
                x
                y
        }
    
        radar_on   = true/false
        optical_system_on= true/false
        ECM_on= true/false
        laser_on= true/false
        
        PRF = 
        {
            current ,    -- current PRF value ( changed in ILV mode ) , values are "MED" or "HI"
            selection ,  -- selection value can be  "MED"  "HI" or "ILV"
        }

}
LoGetTWSInfo() -- return Threat Warning System status (result  the table )
result_of_LoGetTWSInfo =
{
    Mode = , -- current mode (0 - all ,1 - lock only,2 - launch only
    Emitters = {table of emitters}
}
emitter_table =
{
    ID =, -- world ID
    Type = {level1,level2,level3,level4}, -- world database classification of emitter
    Power =, -- power of signal
    Azimuth =,
    Priority =,-- priority of emitter (int)
    SignalType =, -- string with vlues: "scan" ,"lock", "missile_radio_guided","track_while_scan";
}
LoGetPayloadInfo() -- return weapon stations
result_of_LoGetPayloadInfo 
{
    CurrentStation = , -- number of current station (0 if no station selected)
    Stations = {},-- table of stations
    Cannon =
    {
        shells -- current shells count 
    }
}
station 
{
    container = true/false , -- is station container
    weapon    = {level1,level2,level3,level4} , -- world database classification of weapon
    count = ,
}
LoGetMechInfo() -- mechanization info
result_is =
{
    gear          = {status,value,main = {left = {rod},right = {rod},nose =  {rod}}}
    flaps          = {status,value}  
    speedbrakes   = {status,value}
    refuelingboom = {status,value}
    airintake     = {status,value}
    noseflap      = {status,value}
    parachute     = {status,value}
    wheelbrakes   = {status,value}
    hook          = {status,value}
    wing          = {status,value}
    canopy        = {status,value}
    controlsurfaces = {elevator = {left,right},eleron = {left,right},rudder = {left,right}} -- relative vlues (-1,1) (min /max) (sorry:(
} 

LoGetRadioBeaconsStatus() -- beacons lock
{
    airfield_near    ,
    airfield_far,
    course_deviation_beacon_lock    ,
    glideslope_deviation_beacon_lock
}

LoGetWingInfo() -- your wingmens info result is vector of wingmens with value:
wingmen_is =
{
    wingmen_id   -- world id of wingmen
    wingmen_position -- world position {x = {x,y,z},   -- orientation X ort  
                                        y = {x,y,z},   -- orientation Y ort
                                        z = {x,y,z},   -- orientation Z ort
                                        p = {x,y,z}}   -- position of the center  
    current_target -- world id of target
    ordered_target -- world id of target 
    current_task   -- name of task
    ordered_task   -- name of task 
    --[=[
    name can be :
            "NOTHING"
            "ROUTE"
            "DEPARTURE"
            "ARRIVAL"
            "REFUELING"
            "SOS"    -- Save Soul of your Wingmen :) 
            "ROUTE"
            "INTERCEPT"
            "PATROL"
            "AIR_ATTACK"
            "REFUELING"
            "AWACS"
            "RECON"
            "ESCORT"
            "PINPOINT"
            "CAS"
            "MISSILE_EVASION"
            "ENEMY_EVASION"
            "SEAD"
            "ANTISHIP"
            "RUNWAY_ATTACK"
            "TRANSPORT"
            "LANDING"
            "TAKEOFF"
            "TAXIING"
    --]=]

}

Coordinates convertion :
{x,y,z}                  = LoGeoCoordinatesToLoCoordinates(longitude_degrees,latitude_degrees)
{latitude,longitude}  = LoLoCoordinatesToGeoCoordinates(x,z);

LoGetVectorVelocity          =  {x,y,z} -- vector of self velocity (world axis)
LoGetAngularVelocity      =  {x,y,z} -- angular velocity euler angles , rad per sec 
LoGetVectorWindVelocity   =  {x,y,z} -- vector of wind velocity (world axis)
LoGetWingTargets          =   table of {x,y,z}
LoGetSnares               =   {chaff,flare}
Input:
LoSetCameraPosition(pos) -- (args - 1: view camera current position table, results - 0)
    pos table structure: 
    {
        x = {x = ..., y = ..., z = ...},    -- orientation x-vector
        y = (x = ..., y = ..., z = ...},    -- orientation y-vector
        z = {x = ..., y = ..., z = ...},    -- orientation z-vector
        p = {x = ..., y = ..., z = ...}        -- point vector 
    }
    all coordinates are in meters. You can use Vector class for position vectors.

LoSetCommand(command, value) -- (args - 2, results - 0)
-1.0 <= value <= 1.0

Some analogous joystick/mouse input commands:
command = 2001 - joystick pitch
command = 2002 - joystick roll
command = 2003 - joystick rudder
-- Thrust values are inverted for some internal reasons, sorry.
command = 2004 - joystick thrust (both engines)
command = 2005 - joystick left engine thrust
command = 2006 - joystick right engine thrust
command = 2007 - mouse camera rotate left/right  
command = 2008 - mouse camera rotate up/down
command = 2009 - mouse camera zoom 
command = 2010 - joystick camera rotate left/right
command = 2011 - joystick camera rotate up/down
command = 2012 - joystick camera zoom 
command = 2013 - mouse pitch
command = 2014 - mouse roll
command = 2015 - mouse rudder
-- Thrust values are inverted for some internal reasons, sorry.
command = 2016 - mouse thrust (both engines)
command = 2017 - mouse left engine thrust
command = 2018 - mouse right engine thrust
command = 2019 - mouse trim pitch
command = 2020 - mouse trim roll
command = 2021 - mouse trim rudder
command = 2022 - joystick trim pitch
command = 2023 - joystick trim roll
command = 2024 - trim rudder
command = 2025 - mouse rotate radar antenna left/right
command = 2026 - mouse rotate radar antenna up/down
command = 2027 - joystick rotate radar antenna left/right
command = 2028 - joystick rotate radar antenna up/down
command = 2029 - mouse MFD zoom
command = 2030 - joystick MFD zoom
command = 2031 - mouse move selecter left/right
command = 2032 - mouse move selecter up/down
command = 2033 - joystick move selecter left/right
command = 2034 - joystick move selecter up/down

Some discrete keyboard input commands (value is absent):
command = 7    -- Cockpit view                
command = 8    -- External view                        
command = 9    -- Fly-by view                        
command = 10 -- Ground units view                
command = 11 -- Civilian transport view                         
command = 12 -- Chase view                        
command = 13 -- Navy view                        
command = 14 -- Close air combat view                        
command = 15 -- Theater view                        
command = 16 -- Airfield (free camera) view                        
command = 17 --    Instruments panel view on                
command = 18 -- Instruments panel view off                
command = 19 -- Padlock toggle                        
command = 20 --    Stop padlock (in cockpit only)                
command = 21 --    External view for my plane                             
command = 22 --    Automatic chase mode for launched weapon                        
command = 23 --    View allies only filter                     
command = 24 --    View enemies only filter                 
command = 26 -- View allies & enemies filter                     
command = 28 -- Rotate the camera left fast                         
command = 29 -- Rotate the camera right fast                         
command = 30 -- Rotate the camera up fast                     
command = 31 -- Rotate the camera down fast                         
command = 32 -- Rotate the camera left slow                     
command = 33 -- Rotate the camera right slow                     
command = 34 -- Rotate the camera up slow                        
command = 35 -- Rotate the camera down slow                    
command = 36 -- Return the camera to default position                         
command = 37 --    View zoom in fast                     
command = 38 -- View zoom out fast                         
command = 39 -- View zoom in slow                 
command = 40 -- View zoom out slow                
command = 41 -- Pan the camera left                     
command = 42 -- Pan the camera right                 
command = 43 -- Pan the camera up                     
command = 44 -- Pan the camera down                     
command = 45 -- Pan the camera left slow                 
command = 46 -- Pan the camera right slow             
command = 47 -- Pan the camera up slow                 
command = 48 -- Pan the camera down slow                 
command = 49 -- Disable panning the camera                 
command = 50 -- Allies chat                 
command = 51 -- Mission quit                             
command = 52 -- Suspend/resume model time                         
command = 53 -- Accelerate model time                         
command = 54 -- Step by step simulation when model time is suspended                         
command = 55 --    Take control in the track                     
command = 57 -- Common chat                        
command = 59 -- Altitude stabilization             
command = 62 -- Autopilot                     
command = 63 -- Auto-thrust                     
command = 64 -- Power up                 
command = 65 -- Power down             
command = 68 -- Gear                     
command = 69 -- Hook                         
command = 70 -- Pack wings                
command = 71 -- Canopy                         
command = 72 -- Flaps                         
command = 73 -- Air brake                     
command = 74 -- Wheel brakes on                 
command = 75 -- Wheel brakes off                 
command = 76 -- Release drogue chute                     
command = 77 -- Drop snar                     
command = 78 -- Wingtip smoke             
command = 79 -- Refuel on                     
command = 80 -- Refuel off                 
command = 81 -- Salvo                 
command = 82 -- Jettison weapons             
command = 83 -- Eject                         
command = 84 -- Fire on                         
command = 85 -- Fire off                     
command = 86 -- Radar                 
command = 87 -- EOS                     
command = 88 -- Rotate the radar antenna left                     
command = 89 -- Rotate the radar antenna right                 
command = 90 -- Rotate the radar antenna up                 
command = 91 -- Rotate the radar antenna down                     
command = 92 -- Center the radar antenna                 
command = 93 -- Trim left                     
command = 94 -- Trim right                     
command = 95 -- Trim up                     
command = 96 -- Trim down                     
command = 97 -- Cancel trimming                 
command = 98 -- Trim the rudder left             
command = 99 -- Trim the rudder right             
command = 100 -- Lock the target             
command = 101 -- Change weapon                 
command = 102 -- Change target                 
command = 103 -- MFD zoom in                     
command = 104 -- MFD zoom out                     
command = 105 -- Navigation mode   (value 1, 2, 3, 4 for navmode_none, navmode_route, navmode_arrival ,navmode_landing    )
command = 106 -- BVR mode                     
command = 107 -- VS    mode                     
command = 108 -- Bore mode                     
command = 109 -- Helmet mode                 
command = 110 -- FI0 mode                 
command = 111 -- A2G mode                 
command = 112 -- Grid mode                     
command = 113 -- Cannon                 
command = 114 -- Dispatch wingman - complete mission and RTB                    
command = 115 -- Dispatch wingman - complete mission and rejoin                     
command = 116 -- Dispatch wingman - toggle formation                     
command = 117 -- Dispatch wingman - join up formation                     
command = 118 -- Dispatch wingman - attack my target             
command = 119 -- Dispatch wingman - cover my six                 
command = 120 -- Take off from ship            
command = 121 -- Cobra                         
command = 122 -- Sound on/off                      
command = 123 -- Sound recording on                         
command = 124 -- Sound recording off                     
command = 125 -- View right mirror on                 
command = 126 -- View right mirror off                 
command = 127 -- View left mirror on                 
command = 128 -- View left mirror off                 
command = 129 -- Natural head movement view        
command = 131 -- LSO view            
command = 135 -- Weapon to target view         
command = 136 -- Active jamming 
command = 137 -- Increase details level             
command = 138 -- Decrease details level             
command = 139 -- Scan zone left                     
command = 140 -- Scan zone right             
command = 141 -- Scan zone up                         
command = 142 -- Scan zone down                     
command = 143 -- Unlock target                         
command = 144 -- Reset master warning 
command = 145 -- Flaps on 
command = 146 -- Flaps off 
command = 147 -- Air brake on 
command = 148 -- Air brake off 
command = 149 -- Weapons view                 
command = 150 -- Static objects view            
command = 151 -- Mission targets view                 
command = 152 -- Info bar details                 
command = 155 -- Refueling boom             
command = 156 -- HUD color selection            
command = 158 -- Jump to terrain view             
command = 159 -- Starts moving F11 camera forward                 
command = 160 -- Starts moving F11 camera backward            
command = 161 -- Power up left engine 
command = 162 -- Power down left engine 
command = 163 -- Power up right engine 
command = 164 -- Power down right engine 
command = 169 -- Immortal mode             
command = 175 -- On-board lights             
command = 176 -- Drop snar once             
command = 177 -- Default cockpit angle of view             
command = 178 -- Jettison fuel tanks         
command = 179 -- Wingmen commands panel        
command = 180 -- Reverse objects switching in views    
command = 181 -- Forward objects switching in views             
command = 182 -- Ignore current object in views             
command = 183 -- View all ignored objects in views again                 
command = 184 -- Padlock terrain point             
command = 185 -- Reverse the camera                     
command = 186 -- Plane up                     
command = 187 -- Plane down 
command = 188 -- Bank left 
command = 189 -- Bank right
command = 190 -- Local camera rotation mode             
command = 191 -- Decelerate model time                     
command = 192 -- Jump into the other plane                   
command = 193 -- Nose down 
command = 194 -- Nose down end 
command = 195 -- Nose up 
command = 196 -- Nose up end 
command = 197 -- Bank left 
command = 198 -- Bank left end 
command = 199 -- Bank right 
command = 200 -- Bank right end 
command = 201 -- Rudder left 
command = 202 -- Rudder left end 
command = 203 -- Rudder right 
command = 204 -- Rudder right end 
command = 205 -- View up right                     
command = 206 -- View down right                     
command = 207 -- View down left                     
command = 208 -- View up left                         
command = 209 -- View stop                         
command = 210 -- View up right slow             
command = 211 -- View down right slow                 
command = 212 -- View down left slow                 
command = 213 -- View up left slow                     
command = 214 -- View stop slow                     
command = 215 -- Stop trimming 
command = 226 -- Scan zone up right
command = 227 -- Scan zone down right 
command = 228 -- Scan zone down left 
command = 229 -- Scan zone up left 
command = 230 -- Scan zone stop 
command = 231 -- Radar antenna up right 
command = 232 -- Radar antenna down right
command = 233 -- Radar antenna down left 
command = 234 -- Radar antenna up left
command = 235 -- Radar antenna stop
command = 236 -- Save snap view angles                 
command = 237 -- Cockpit panel view toggle     
command = 245 -- Coordinates units toggle
command = 246 -- Disable model time acceleration             
command = 252 -- Automatic spin recovery 
command = 253 -- Speed retention 
command = 254 -- Easy landing 
command = 258 -- Threat missile padlock 
command = 259 -- All missiles padlock
command = 261 -- Marker state                 
command = 262 -- Decrease radar scan area 
command = 263 -- Increase radar scan area 
command = 264 -- Marker state plane                 
command = 265 -- Marker state rocket                 
command = 266 -- Marker state plane ship                 
command = 267 -- Ask AWACS home airbase 
command = 268 -- Ask AWACS available tanker
command = 269 -- Ask AWACS nearest target 
command = 270 -- Ask AWACS declare target 
command = 271 -- Easy radar 
command = 272 -- Auto lock on nearest aircraft 
command = 273 -- Auto lock on center aircraft 
command = 274 -- Auto lock on next aircraft 
command = 275 -- Auto lock on previous aircraft 
command = 276 -- Auto lock on nearest surface target 
command = 277 -- Auto lock on center surface target 
command = 278 -- Auto lock on next surface target 
command = 279 -- Auto lock on previous surface target 
command = 280 -- Change cannon rate of fire
command = 281 -- Change ripple quantity 
command = 282 -- Change ripple interval 
command = 283 -- Switch master arm 
command = 284 -- Change release mode 
command = 285 -- Change radar mode RWS/TWS 
command = 286 -- Change RWR/SPO mode
command = 288 -- Flight clock reset 
command = 289 -- Zoom in slow stop             
command = 290 -- Zoom out slow stop            
command = 291 -- Zoom in stop                 
command = 292 -- Zoom out stop                     
command = 295 -- View horizontal stop                     
command = 296 -- View vertical stop                 
command = 298 -- Jump to fly-by view             
command = 299 -- Camera jiggle                 
command = 300 -- Cockpit illumination 
command = 308 -- Change ripple interval down         
command = 309 -- Engines start                 
command = 310 -- Engines stop             
command = 311 -- Left engine start             
command = 312 -- Right engine start             
command = 313 -- Left engine stop                 
command = 314 -- Right engine stop             
command = 315 -- Power on/off                     
command = 316 -- Altimeter pressure increase     
command = 317 -- Altimeter pressure decrease     
command = 318 -- Altimeter pressure stop 
command = 321 -- Fast mouse in views                 
command = 322 -- Slow mouse in views                
command = 323 -- Normal mouse in views             
command = 326 -- HUD only view             
command = 327 -- Recover my plane                 
command = 328 -- Toggle gear light Near/Far/Off         
command = 331 -- Fast keyboard in views            
command = 332 -- Slow keyboard in views             
command = 333 -- Normal keyboard in views             
command = 334 -- Zoom in for external views             
command = 335 -- Stop zoom in for external views 
command = 336 -- Zoom out for external views 
command = 337 -- Stop zoom out for external views 
command = 338 -- Default zoom in external views 
command = 341 -- A2G combat view             
command = 342 -- Camera view up-left            
command = 343 -- Camera view up-right            
command = 344 -- Camera view down-left        
command = 345 -- Camera view down right    
command = 346 -- Camera pan mode toggle                
command = 347 -- Return the camera            
command = 348 -- Trains/cars toggle        
command = 349 -- Launch permission override    
command = 350 -- Release weapon        
command = 351 -- Stop release weapon
command = 352 -- Return camera base        
command = 353 -- Camera view up-left slow        
command = 354 -- Camera view up-right slow    
command = 355 -- Camera view down-left slow        
command = 356 -- Camera view down-right slow    
command = 357 -- Drop flare once            
command = 358 -- Drop chaff once            
command = 359 -- Rear view                    
command = 360 -- Scores window
command = 386 -- PlaneStabPitchBank
command = 387 -- PlaneStabHbarBank
command = 388 -- PlaneStabHorizont
command = 389 -- PlaneStabHbar
command = 390 -- PlaneStabHrad
command = 391 -- Active IR jamming on/off
command = 392 -- Laser range-finder on/off
command = 393 -- Night TV on/off(IR or LLTV) 
command = 394 -- Change radar PRF       
command = 395 -- Keep F11 camera altitude over terrain
command = 396 -- SnapView0
command = 397 -- SnapView1
command = 398 -- SnapView2
command = 399 -- SnapView3
command = 400 -- SnapView4
command = 401 -- SnapView5
command = 402 -- SnapView6
command = 403 -- SnapView7
command = 404 -- SnapView8
command = 405 -- SnapView9
command = 406 -- SnapViewStop
command = 407 -- F11 view binocular mode
command = 408 -- PlaneStabCancel
command = 409 -- ThreatWarnSoundVolumeDown
command = 410 -- ThreatWarnSoundVolumeUp
command = 411 -- F11 binocular view laser range-finder on/off
command = 412 -- PlaneIncreaseBase_Distance
command = 413 -- PlaneDecreaseBase_Distance
command = 414 -- PlaneStopBase_Distance
command = 425 -- F11 binocular view IR mode on/off
command = 426 -- F8 view player targets / all targets
command = 427 -- Plane autopilot override on
command = 428 -- Plane autopilot override off
command = 429 -- Plane route autopilot on/off
command = 430 -- Gear up
command = 431 -- Gear down

To be continued...
--]]

--    LoEnableExternalFlightModel()   call one time in start
--    LoUpdateExternalFlightModel(binary_data)   update function


--LoGetHelicopterFMData()
-- return table with fm data 
--{
--G_factor = {x,y,z }    in cockpit
--speed = {x,y,z}   center of mass ,body axis 
--acceleration= {x,y,z}   center of mass ,body axis 
--angular_speed= {x,y,z}   rad/s
--angular_acceleration= {x,y,z}   rad/s^2
--yaw    radians
--pitch    radians
--roll    radians
--}

--#ifndef  _EXTERNAL_FM_DATA_H
--#define  _EXTERNAL_FM_DATA_H

--struct external_FM_data  
--{
--    double orientation_X[3];
--    double orientation_Y[3];
--    double orientation_Z[3];
--    double pos[3];

--    //

--    double velocity[3];
--    double acceleration[3];
--    double omega[3];
--};
-- #endif  _EXTERNAL_FM_DATA_H


-- you can export render targets via shared memory interface 
-- using next functions  
--        LoSetSharedTexture(name)          -- register texture with name "name"  to export
--        LoRemoveSharedTexture(name)   -- copy texture with name "name"  to named shared memory area "name"
--        LoUpdateSharedTexture(name)    -- unregister texture
--       texture exported like Windows BMP file 
--      --------------------------------
--      |BITMAPFILEHEADER   |
--      |BITMAPINFOHEADER |
--      |bits                                  |
--      --------------------------------
--      sample textures   :  "mfd0"    -  full  SHKVAL screen
--                                      "mfd1"     -  ABRIS map screen
--                                      "mfd2"    - not used
--                                      "mfd3"    - not used
--                                      "mirrors" - mirrors