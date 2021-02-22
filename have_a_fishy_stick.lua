-- table to use as the addon's namespace
HAFS = {
    -- the name of the addon (mainly used for registering events)
    name = "Have a Fishy Stick",

    -- prints debug messages to the chat box when 'true'
    debug = false,

    -- in game 'fishy stick' item ID
    fishyStickId = 33526,

    defaultMailRecipient = "@Anumaril21",
    mailRecipient = "",
    mailSubject = "HAVE A FISHY STICK",
    mailBody = "<>< <>< <>< <>< <>< <>< <>< <>< <>< <><",

    -- this is 'true' when a stack is still being split and ready to attach once finished
    -- 'false' once attached
    readyToAttach = false,

    -- the slot ID in the player's backpack where the fishy stick can be found
    -- initializes at -1 to indicate that a fishy stick hasn't been found yet
    fishyStickSlotId = -1
}

-- initializes the addon
function HAFS:Initialize()
    -- unregister the 'OnAddOnLoaded' event since the addon has now loaded
    EVENT_MANAGER:UnregisterForEvent(HAFS.name, EVENT_ADD_ON_LOADED)
end

-- event handler function that runs when the addon is first loaded
function HAFS.OnAddOnLoaded(event, addonName)
    -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
    if addonName == HAFS.name then HAFS:Initialize() end
end

-- register 'OnAddOnLoaded' event handler function to be called when ESO loads this addon
EVENT_MANAGER:RegisterForEvent(HAFS.name, EVENT_ADD_ON_LOADED, HAFS.OnAddOnLoaded)

-- fills out the recipient, subject, body of the mail and attaches the fishy stick
-- note: only run this function after ensuring the 'mailSend' window is opened and ready for input
function HAFS.GenerateMailFormAndAttachFishyStick()
    ZO_MailSendToField:SetText(HAFS.mailRecipient)
    ZO_MailSendSubjectField:SetText(HAFS.mailSubject)
    ZO_MailSendBodyField:SetText(HAFS.mailBody)

    -- attempt to find a SINGLE fishy stick in inventory
    HAFS.fishyStickSlotId = HAFS.FindTargetSlotId(HAFS.fishyStickId, BAG_BACKPACK, 1)
    if HAFS.fishyStickSlotId ~= -1 then
        -- found, attach to mail now
        QueueItemAttachment(BAG_BACKPACK, HAFS.fishyStickSlotId, 1)
        return
    end

    if HAFS.fishyStickSlotId == -1 then
        -- single fishy stick cannot be found, try finding ANY amount
        HAFS.fishyStickSlotId = HAFS.FindTargetSlotId(HAFS.fishyStickId, BAG_BACKPACK, 0)
        if HAFS.fishyStickSlotId == -1 then
            -- no amount of fishy sticks could be found in inventory, attach nothing
            if HAFS.debug then
                d("could not find a single Fishy Stick in inventory to attach to mail")
            end
            return
        else
            -- a stack of fishy sticks > 1 was found
            -- split stack to get a stack of 1
            HAFS.fishyStickSlotId = HAFS.SplitStack(HAFS.fishyStickSlotId, BAG_BACKPACK, 1)
            if HAFS.fishyStickSlotId == -1 then
                -- stack could not be split, attach nothing
                if HAFS.debug then
                    d("error splitting stack of fishy sticks, cannot attach to mail")
                end
                return
            else
                -- stack is still being split (not instant), cannot attach to mail right now
                -- mark as 'ready to attach' so it can be attached after the split finishes
                HAFS.readyToAttach = true
            end
        end
    end
end

-- sends a fishy stick to the player by the username 'playerName'
-- when no name is given then the fishy stick goes to the default mail recipient
function HAFS.SendFishyStick(playerName)
    -- trim all whitespace around 'playerName'
    playerName = playerName:gsub("^%s+", "", 1)
    playerName = playerName:gsub("%s+$", "", 1)

    if playerName == "" then
        -- when no arguments are given then send mail to the default recipient
        HAFS.mailRecipient = HAFS.defaultMailRecipient
    else
        -- set recipient to user-provided name
        HAFS.mailRecipient = playerName
    end

    if HAFS.debug then d("sending fishy stick to " .. HAFS.mailRecipient) end

    -- open 'mailSend' window and wait some time to generate the form contents
    SCENE_MANAGER:Show('mailSend')
    zo_callLater(HAFS.GenerateMailFormAndAttachFishyStick, 200)
end

-- register new slash command for sending the fishy stick
SLASH_COMMANDS["/fishy"] = HAFS.SendFishyStick

-- finds an item in a bag with a specified stack size (0 = any) and returns its slot ID
-- returns -1 on failure
function HAFS.FindTargetSlotId(targetItemId, bagId, stackSize)
    for slotId = 0, GetBagSize(bagId) do
        local itemId = GetItemId(bagId, slotId)
        if stackSize == 0 then
            if itemId == targetItemId then return slotId end
        elseif itemId == targetItemId and GetSlotStackSize(bagId, slotId) == stackSize then
            return slotId
        end
    end

    -- if execution gets here then the item was not found
    if HAFS.debug then
        d("item with ID '" .. targetItemId .. "' not found in bag ID '" .. bagId ..
              "' with a stack size of '" .. stackSize .. "'")
    end
    return -1
end

-- splits a stack of items in the same bag they are currently in
-- returns the slot ID of the new stack on success, -1 on failure
function HAFS.SplitStack(targetSlotId, bagId, newStackSize)
    local newSlotId = FindFirstEmptySlotInBag(bagId)
    if newSlotId then
        CallSecureProtected("RequestMoveItem", bagId, targetSlotId, bagId, newSlotId, newStackSize)
        return newSlotId
    else
        -- no empty slot in the bag can be found, cannot split stack
        if HAFS.debug then
            d("cannot split stack at slot ID '" .. targetSlotId ..
                  "', no room left in bag with ID '" .. bagId .. "'")
        end
        return -1
    end
end

function HAFS.OnInventoryChanged(event, bagId, slotIndex, isNewItem, itemSoundCategory,
                                 updateReason, stackCountChange)
    if HAFS.readyToAttach then
        QueueItemAttachment(BAG_BACKPACK, HAFS.fishyStickSlotId, 1)
        HAFS.readyToAttach = false
    end
end

-- register the 'OnInventoryChanged' event and its associated filters
EVENT_MANAGER:RegisterForEvent(HAFS.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
                               HAFS.OnInventoryChanged)
EVENT_MANAGER:AddFilterForEvent(HAFS.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
                                REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
EVENT_MANAGER:AddFilterForEvent(HAFS.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
                                REGISTER_FILTER_IS_NEW_ITEM, false)
