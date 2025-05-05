local addonName, addon = ...
local PeaversSafeList = CreateFrame("Frame", "PeaversSafeListFrame")
_G.PeaversSafeList = PeaversSafeList

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

-- Initialize addon metadata
PeaversSafeList.name = addonName
PeaversSafeList.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-- Create configuration using PeaversCommons.ConfigManager
PeaversSafeList.Config = PeaversCommons.ConfigManager:New(
    "PeaversSafeList", 
    {  -- Default settings
        DEBUG_ENABLED = false,
        items = {}
    },
    {
        savedVariablesName = "PeaversSafeListDB"
    }
)

-- Local variables for quick access
local safeListDB = {}

-- Debug function for development (internal use)
local function Debug(msg)
    if PeaversSafeList.Config.DEBUG_ENABLED then
        Utils.Debug(PeaversSafeList, msg)
    end
end

-- Initialize saved variables
function PeaversSafeList:Initialize()
    -- Config has already been initialized by ConfigManager
    
    -- Set up local reference to items table for quicker access
    safeListDB = PeaversSafeList.Config.items or {}
    PeaversSafeList.Config.items = safeListDB

    -- Register for MERCHANT_SHOW event
    PeaversCommons.Events:RegisterEvent("MERCHANT_SHOW", function()
        -- Optional: Auto-repair if you want to add that functionality
        -- self:AutoRepair()
    end)
end

-- Create item key for database storage
function PeaversSafeList:CreateItemKey(itemLink)
    local itemID = GetItemInfoInstant(itemLink)
    if itemID then
        return tostring(itemID)
    end
    return nil
end

-- Save current inventory to safelist
function PeaversSafeList:SaveInventory()
    local count = 0

    -- Clear current safelist
    table.wipe(safeListDB)

    -- Loop through all bags
    for bag = 0, NUM_BAG_FRAMES do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)

            if itemLink then
                local itemKey = self:CreateItemKey(itemLink)
                if itemKey then
                    safeListDB[itemKey] = true
                    count = count + 1
                    Debug("Added to safelist: " .. itemLink)
                end
            end
        end
    end

    -- Save to persistent storage
    PeaversSafeList.Config:Save()
    
    Utils.Print(PeaversSafeList, "Saved " .. count .. " items to your safelist!")
end

-- Sell items not in safelist when at vendor
function PeaversSafeList:SellJunkItems()
    if not MerchantFrame:IsShown() then
        Utils.Print(PeaversSafeList, "You need to be at a vendor to sell items!")
        return
    end

    local soldCount = 0
    local earnedMoney = 0

    -- Loop through all bags
    for bag = 0, NUM_BAG_FRAMES do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)

            if itemLink then
                local itemKey = self:CreateItemKey(itemLink)

                -- If item is not in safelist, sell it
                if itemKey and not safeListDB[itemKey] then
                    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                    local itemCount = itemInfo and itemInfo.stackCount or 0
                    local vendorPrice = select(11, GetItemInfo(itemKey)) or 0

                    -- Skip items with no vendor price
                    if vendorPrice > 0 then
                        C_Container.UseContainerItem(bag, slot)
                        soldCount = soldCount + 1
                        earnedMoney = earnedMoney + (vendorPrice * itemCount)
                        Debug("Sold: " .. itemLink .. " x" .. itemCount)
                    end
                end
            end
        end
    end

    -- Format gold for output
    local gold = math.floor(earnedMoney / 10000)
    local silver = math.floor((earnedMoney % 10000) / 100)
    local copper = earnedMoney % 100

    if soldCount > 0 then
        Utils.Print(PeaversSafeList, "Sold " .. soldCount .. " items for " .. gold .. "g " .. silver .. "s " .. copper .. "c")
    else
        Utils.Print(PeaversSafeList, "No items to sell!")
    end
end

-- Show safelist count
function PeaversSafeList:ShowSafeList()
    local count = 0
    for _ in pairs(safeListDB) do
        count = count + 1
    end

    Utils.Print(PeaversSafeList, "You have " .. count .. " items in your safelist.")
end

-- Clear the safelist
function PeaversSafeList:ClearSafeList()
    table.wipe(safeListDB)
    PeaversSafeList.Config:Save()
    Utils.Print(PeaversSafeList, "Your safelist has been cleared!")
end

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "psl", {
    default = function()
        Utils.Print(PeaversSafeList, "Commands:")
        print("  /psl save - Save your current inventory as your safelist")
        print("  /psl sell - Sell all items not in your safelist")
        print("  /psl show - Show how many items are in your safelist")
        print("  /psl clear - Clear your safelist")
        print("  /psl debug - Toggle debug mode")
    end,
    save = function()
        PeaversSafeList:SaveInventory()
    end,
    snapshot = function()
        PeaversSafeList:SaveInventory()
    end,
    sell = function()
        PeaversSafeList:SellJunkItems()
    end,
    show = function()
        PeaversSafeList:ShowSafeList()
    end,
    list = function()
        PeaversSafeList:ShowSafeList()
    end,
    clear = function()
        PeaversSafeList:ClearSafeList()
    end,
    debug = function()
        PeaversSafeList.Config.DEBUG_ENABLED = not PeaversSafeList.Config.DEBUG_ENABLED
        PeaversSafeList.Config:Save()
        Utils.Print(PeaversSafeList, "Debug mode " .. (PeaversSafeList.Config.DEBUG_ENABLED and "enabled" or "disabled"))
    end,
})

-- Initialize addon using PeaversCommons Events module
PeaversCommons.Events:Init(addonName, function()
    PeaversSafeList:Initialize()
    
    -- Initialize configuration UI
    if PeaversSafeList.ConfigUI and PeaversSafeList.ConfigUI.Initialize then
        PeaversSafeList.ConfigUI:Initialize()
    end
    
    -- Use the centralized SettingsUI system from PeaversCommons
    C_Timer.After(0.5, function()
        -- Create standardized settings pages
        PeaversCommons.SettingsUI:CreateSettingsPages(
            PeaversSafeList,           -- Addon reference
            "PeaversSafeList",         -- Addon name
            "Peavers Safe List",       -- Display title
            "Create a safelist of items to prevent auto-selling.", -- Description
            {   -- Slash commands
                "/psl save - Save your current inventory as your safelist",
                "/psl sell - Sell all items not in your safelist",
                "/psl show - Show how many items are in your safelist",
                "/psl clear - Clear your safelist",
                "/psl debug - Toggle debug mode"
            }
        )
    end)
end, {
	announceMessage = "Use |cff3abdf7/psl config|r to get started"
})
