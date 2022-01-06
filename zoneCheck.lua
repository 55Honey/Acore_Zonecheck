--
--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 16/06/2021
-- Time: 20:38
-- To change this template use File | Settings | File Templates.
-- Originally created by Honey for Azerothcore
-- requires ElunaLua module


-- This module kicks players when they enter or login a zone specified in Config_Zones
------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with ElunaLua module
--               -  adjust config in this file
--               -  add this script to ../lua_scripts/
------------------------------------------------------------------------------------------------
-- GM GUIDE:     -  summon the pitiful cheaters back to a legal map when they complain about kicks. Or don't
------------------------------------------------------------------------------------------------

local Config_Teleport = true            -- Teleports players to home when entering forbidden zone
local Config_Kick     = true            -- Kicks players when entering forbidden zone

local Config_Zones = {}                 -- forbidden zones

table.insert(Config_Zones, 4080) -- Quel'Danas
table.insert(Config_Zones, 3483) -- Hellfire Peninsula
table.insert(Config_Zones, 3518) -- Nagrand
table.insert(Config_Zones, 3519) -- Terokkar Forest
table.insert(Config_Zones, 3520) -- Shadowmoon Valley
table.insert(Config_Zones, 3521) -- Zangarmarsh
table.insert(Config_Zones, 3522) -- Blade's Edge Mountain
table.insert(Config_Zones, 3523) -- Netherstorm
table.insert(Config_Zones, 3703) -- Shattrath
table.insert(Config_Zones, 3537) -- Borean Tundra
table.insert(Config_Zones, 3711) -- Sholazar Basin
table.insert(Config_Zones, 4197) -- Wintergrasp
table.insert(Config_Zones, 210) -- Icecrown
table.insert(Config_Zones, 2817) -- Crystalsong Forest
table.insert(Config_Zones, 4395) -- Dalaran
table.insert(Config_Zones, 65) -- Dragonblight
table.insert(Config_Zones, 66) -- Zul'Drak
table.insert(Config_Zones, 67) -- Storm Peaks
table.insert(Config_Zones, 394) -- Grizzly Hills
table.insert(Config_Zones, 495) -- Howling Fjord
table.insert(Config_Zones, 4742) -- Hrothgar's Landing
table.insert(Config_Zones, 876) -- GM Island

------------------------------------------------------------------------------------------------
-- CONFIG END
------------------------------------------------------------------------------------------------

local FILE_NAME = string.match(debug.getinfo(1,'S').source, "[^/\\]*.lua$")

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function shouldKick(player)
    if player:GetGMRank() >= 1 then
        return false
    end
    if player:GetData("_kicked") then -- do not fire multiple times
        return false
    end
    local zone = player:GetZoneId()
    if has_value(Config_Zones, zone) then
        return true
    end

    return false
end

local function performKick(player)
    PrintError("["..FILE_NAME.."] Kicking player " .. player:GetName())
    player:SetData("_kicked", true)
    player:KickPlayer()
end

-- SQL: azerothcore-wotlk/src/server/database/Database/Implementation/CharacterDatabase.cpp - CHAR_SEL_CHARACTER_HOMEBIND
local function getPlayerHomeLocationDB(pGUID)
    local mapId, zoneId, posX, posY, posZ
    local Q = CharDBQuery(string.format("SELECT mapId, zoneId, posX, posY, posZ FROM character_homebind WHERE guid=%u", pGUID))
    if Q then
        mapId, zoneId, posX, posY, posZ = Q:GetUInt16(0), Q:GetUInt16(1), Q:GetFloat(2), Q:GetFloat(3), Q:GetFloat(4) 
    end
    if mapId and zoneId and posX and posY and posZ then
        return mapId, zoneId, posX, posY, posZ
    else
        PrintError("["..FILE_NAME.."] ERROR! Could not get home location in database for character id: " .. pGUID)
        return nil
    end
end

local function performTeleport(player)
    local mapId, zoneId, posX, posY, posZ = getPlayerHomeLocationDB(player:GetGUIDLow())
    if mapId and zoneId and posX and posY and posZ then
        PrintError(string.format("[%s] Teleporting player %s to home (%u, %f, %f, %f)", FILE_NAME, player:GetName(), mapId, posX, posY, posZ))
        player:Teleport(mapId, posX, posY, posZ, player:GetO())
    end
end

-- This function is another option instead of teleporting 
--
--local function setPlayerLocationDB(pGUID, mapId, zoneId, posX, posY, posZ)
--    -- SQL: azerothcore-wotlk/src/server/database/Database/Implementation/CharacterDatabase.cpp - CHAR_UPD_CHARACTER_POSITION
--    local Q = CharDBQuery(string.format("UPDATE characters SET position_x=%f, position_y=%f, position_z=%f, map=%u, zone=%u, trans_x=0, trans_y=0, trans_z=0, transguid=0, taxi_path='', cinematic=1 WHERE guid=%u", posX, posY, posZ, mapId, zoneId, pGUID))
--    PrintError(string.format("[%s] Set character id: %u location in database to (%u, %u, %f, %f, %f)", FILE_NAME, pGUID, mapId, zoneId, posX, posY, posZ))
--end

local function checkPlayerZone(player)
    if shouldKick(player) then
        local zone = player:GetZoneId()
        PrintError("["..FILE_NAME.."] Player " .. player:GetName() .. " entered restricted zone " .. zone .. " (characterId: " .. player:GetGUIDLow() .. ", accountName: " .. player:GetAccountName() .. ", accountId: " .. player:GetAccountId() .. ")")
        if Config_Teleport then
            performTeleport(player)
        end
        if Config_Kick then
            performKick(player)
        end
    end
end

local function checkZoneLogin(event, player)
    checkPlayerZone(player)
end

local function checkZoneUpdate(event, player, newZone, newArea)
    checkPlayerZone(player)
end

local PLAYER_EVENT_ON_LOGIN = 3               -- (event, player)
local PLAYER_EVENT_ON_UPDATE_ZONE = 27        -- (event, player, newZone, newArea)

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, checkZoneLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_UPDATE_ZONE, checkZoneUpdate)
