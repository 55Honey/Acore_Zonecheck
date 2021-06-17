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
local Config_Zones = {}                 --forbidden zones

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

    local zone = player:GetZoneId()
    if has_value(Config_Zones, zone) then
        return true
    end

    return false
end

local function performKick(player)
    local zone = player:GetZoneId()
    PrintError("Kicking player " .. player:GetName() .. " (account " .. player:GetAccountName() .. ") for entering restricted zone " .. zone)
    player:KickPlayer()
end

local function checkPlayerZone(player)
    if shouldKick(player) then
        performKick(player)
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
