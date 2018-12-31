AltsFinder = LibStub("AceAddon-3.0"):NewAddon("AltsFinder", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
-- other dependencies: AceDB-3.0, AceConfig-3.0, AceConfigDialog-3.0, AceConfigCmd-3.0, AceConfigRegistry-3.0
local L = LibStub("AceLocale-3.0"):GetLocale("AltsFinder") -- load locale

-------------
--- Variables
-------------

local queriesToScan                     -- a bool flags array
local entriesBefore                     -- a list of players online before (right after the target logs off but before his alt logs in)
local entriesAfter                      -- a list of players online after (after target's alt logs in)
local currentEntries                    -- a list holding current online players in a zone
local currentQuery = ""                 -- a string for current query to scan
local whoRequestReceived = false        -- a flag to monitor /who request result
local whoRequestsTimer                  -- a timer object, repeats /who requests
local whoRequestsDelay = 0.5            -- a delay before repeating /who request (in seconds)
local elapsedTimer                      -- a timer object for timing scan cycles
local targetsStatuses = {}              -- a table with targets online|offline|unknown statuses
local currentTarget = ""                -- current target character nickname
local isScanning = false                -- a flag to monitor scanning procedure
local isScanBefore = true               -- a flag to indicate scan cycles before and after alt's logging in
local defaultQueries = {}               -- a list of default query strings
local races = {}                        -- a list of races for UI's dropdown
local targetsGroup                      -- a ref to UI's targets group in options tree
local queriesGroup                      -- a ref to UI's queries group in options tree


-- FIXME: in future patches new race IDs should be added here (also modify UI's races dropdown)
local raceIDsHorde = {10, 2, 5, 6, 8, 9, 24, 27, 28, 36}        -- Horde's race IDs by popularity descending
local raceIDsAlliance = {1, 4, 11, 22, 3, 7, 24, 29, 30, 34}    -- Alliance's race IDs by popularity descending

-- constants for the log() function
local LOG_DEBUG = 1     -- 0b001        -- debug log level (only when showDebug option is on)
local LOG_INFO = 3      -- 0b011        -- normal log level (these messages are printed to the chat normally)
local LOG_ALERT = 4     -- 0b100        -- shows message at the center of the screen (when showAlert option is on)


--------------
--- Options UI
--------------

local options = {
    name = "AltsFinder",
    handler = AltsFinder,
    type = 'group',
    childGroups = "tab",
    args = {
        targetsTab = { -- tab for targets and their potential alts stats
            type = "group",
            name = L["TARGETS_TAB"],
            desc = L["TARGETS_TAB_DESCRIPTION"],
            childGroups = "select",
            order = 10,
            args = {
                descriptionTargets = { -- text intro for the tab
                    type = "description",
                    name = L["TARGETS_TAB_TEXT"],
                    order = 10,
                },
                addTarget = { -- text input to add target's name to the list
                    type = "input",
                    name = L["ADD_TARGET_INPUT"],
                    desc = L["ADD_TARGET_INPUT_DESCRIPTION"],
                    usage = L["ADD_TARGET_INPUT_USAGE"],
                    set = "AddTarget",
                    order = 11,
                },
                removeTarget = { -- text input to remove target's name from the list
                    type = "input",
                    name = L["REMOVE_TARGET_INPUT"],
                    desc = L["REMOVE_TARGET_INPUT_DESCRIPTION"],
                    usage = L["REMOVE_TARGET_INPUT_USAGE"],
                    set = "RemoveTarget",
                    order = 12,
                },
                targets = { -- tab's subgroup (dropdown item)
                    type = "group",
                    name = L["TARGETS_DROPDOWN_STATS"],
                    order = 13,
                    args = {
                        -- is filled with targets array when user adds them
                    },
                },
                helpTargets = { -- tab's subgroup (dropdown item)
                    type = "group",
                    name = L["TARGETS_DROPDOWN_HELP"],
                    cmdHidden = true,
                    order = 14,
                    args = {
                        descriptionHelpTargets = { -- text with help
                            type = "description",
                            name = L["TARGETS_HELP_TEXT"],
                            fontSize = "medium",
                            order = 10,
                        },
                    },
                },
            },
        },
        searchTab = { -- tab for search queries editing
            type = "group",
            name = L["SEARCH_TAB"],
            desc = L["SEARCH_TAB_DESCRIPTION"],
            childGroups = "select",
            disabled = false,
            order = 11,
            args = {
                descriptionSearch = { -- text intro for the tab
                    type = "description",
                    name = L["SEARCH_TAB_TEXT"],
                    order = 10,
                },
                addQuery = { -- button to add query
                    type = "execute",
                    name = L["ADD_QUERY_BUTTON"],
                    desc = L["ADD_QUERY_BUTTON_DESCRIPTION"],
                    func = "AddQuery",
                    order = 11,
                },
                removeQuery = { -- button to remove query
                    type = "execute",
                    name = L["REMOVE_QUERY_BUTTON"],
                    desc = L["REMOVE_QUERY_BUTTON_DESCRIPTION"],
                    func = "RemoveQuery",
                    order = 12,
                },
                defaultZone = { -- text input for zone parameter of queries
                    type = "input",
                    name = L["ZONE_INPUT"],
                    desc = L["ZONE_INPUT_DESCRIPTION"],
                    usage = L["ZONE_INPUT_USAGE"],
                    confirm = true,
                    confirmText = L["ZONE_INPUT_CONFIRM"],
                    set = "SetDefaultZone",
                    get = "GetDefaultZone",
                    order = 13,
                },
                defaultQueriesNum = { -- dropdown with default queries number
                    type = "select",
                    name = L["NUM_QUERIES_DROPDOWN"],
                    desc = L["NUM_QUERIES_DROPDOWN_DESCRIPTION"],
                    confirm = true,
                    confirmText = L["NUM_QUERIES_DROPDOWN_CONFIRM"],
                    get = "GetDefaultQueriesNum",
                    set = "SetDefaultQueriesNum",
                    values = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
                    width = 0.4,
                    order = 14,
                },
                queries= { -- tab's subgroup (dropdown item)
                    type = "group",
                    name = L["SEARCH_DROPDOWN_QUERIES"],
                    order = 15,
                    args = {
                        -- is filled with queries array from DB
                    },
                },
                helpQueries = { -- tab's subgroup (dropdown item)
                    type = "group",
                    name = L["SEARCH_DROPDOWN_HELP"],
                    cmdHidden = true,
                    order = 16,
                    args = {
                        descriptionHelpQueries = { -- text with help
                            type = "description",
                            name = L["SEARCH_HELP_TEXT"],
                            fontSize = "medium",
                            order = 10,
                        },
                    },
                },
            },
        },
        settingsTab = { -- tab with settings
            type = "group",
            name = L["SETTINGS_TAB"],
            desc = L["SETTINGS_TAB_DESCRIPTION"],
            order = 12,
            args = {
                headerGlobal = { -- section header
                    type = "header",
                    name = L["SETTINGS_SECTION_GLOBAL"],
                    order = 11,
                },
                showAlert = { -- checkbox for on-screen alert and sound
                    type = "toggle",
                    name = L["ALTS_ALERT_CHECKBOX"],
                    desc = L["ALTS_ALERT_CHECKBOX_DESCRIPTION"],
                    get = "GetShowAlert",
                    set = "SetShowAlert",
                    width = 1.5,
                    order = 12,
                },
                silentMode = { -- checkbox to turn off chat messages
                    type = "toggle",
                    name = L["SILENT_MODE_CHECKBOX"],
                    desc = L["SILENT_MODE_CHECKBOX_DESCRIPTION"],
                    get = "GetSilentMode",
                    set = "SetSilentMode",
                    width = 1.1,
                    order = 13,
                },
                resetDB = { -- button to drop database
                    type = "execute",
                    name = L["RESET_DB_BUTTON"],
                    desc = L["RESET_DB_BUTTON_DESCRIPTION"],
                    confirm = true,
                    confirmText = L["RESET_DB_BUTTON_CONFIRM"],
                    func = "OnResetDB",
                    width = 0.8,
                    order = 14,
                },
                spacerGlobal = { -- formatting: adds space
                    type = "description",
                    name = " ",
                    fontSize = "medium",
                    order = 15,
                },

                headerSearch = { -- section header
                    type = "header",
                    name = L["SETTINGS_SECTION_SEARCH"],
                    order = 20,
                },
                descriptionSecondScanDelay = { -- text for secondScanDelay
                    type = "description",
                    name = L["DELAY_SLIDER_TEXT"],
                    width = "double",
                    order = 21,
                },
                secondScanDelay = { -- a delay before second scan cycle (in seconds)
                    type = "range",
                    name = L["DELAY_SLIDER"],
                    desc = L["DELAY_SLIDER_DESCRIPTION"],
                    get = "GetSecondScanDelay",
                    set = "SetSecondScanDelay",
                    softMin = 0, softMax = 30, bigStep = 1,
                    min = 0, max = 300, step = 1,
                    width = 1.4,
                    order = 22,
                },
                descriptionDurationInfo = { -- text for durationInfo
                    type = "description",
                    name = L["DURATION_INFO_TEXT"],
                    width = 1.8,
                    order = 23,
                },
                durationInfo = { -- disabled text input with duration equation
                    type = "input",
                    name = "",
                    get = "GetDurationInfo",
                    set = "SetDurationInfo",
                    cmdHidden = true,
                    disabled = true,
                    width = 1.6,
                    order = 24,
                },
                descriptionTestScan = { -- text for testScan
                    type = "description",
                    name = L["TEST_SCAN_BUTTON_TEXT"],
                    width = 2.7,
                    order = 25,
                },
                testScan = { -- button to initiate test scan cycle
                    type = "execute",
                    name = L["TEST_SCAN_BUTTON"],
                    desc = L["TEST_SCAN_BUTTON_DESCRIPTION"],
                    confirm = true,
                    confirmText = L["TEST_SCAN_BUTTON_CONFIRM"],
                    func = "TestScan",
                    width = 0.7,
                    order = 26,
                },
                spacerSearch = { -- formatting: adds large space
                    type = "description",
                    name = "\n\n\n\n\n\n",
                    fontSize = "large",
                    order = 27,
                },

                headerDebug = { -- section header
                    type = "header",
                    name = L["SETTINGS_SECTION_DEBUG"],
                    order = 30,
                },
                descriptionPrintStats = { -- text for printStats
                    type = "description",
                    name = L["PRINT_STATS_BUTTON_TEXT"],
                    width = 2.4,
                    order = 31,
                },
                printStats = { -- button to print top occurrences (potential alts)
                    type = "execute",
                    name = L["PRINT_STATS_BUTTON"],
                    desc = L["PRINT_STATS_BUTTON_DESCRIPTION"],
                    func = "OnPrintStats",
                    order = 32,
                },
                descriptionShowStatuses = { -- text for showStatuses
                    type = "description",
                    name = L["SHOW_STATUSES_BUTTON_TEXT"],
                    width = 2.4,
                    order = 33,
                },
                showStatuses = { -- test button to show target's online/offline statuses
                    type = "execute",
                    name = L["SHOW_STATUSES_BUTTON"],
                    desc = L["SHOW_STATUSES_BUTTON_DESCRIPTION"],
                    func = "OnShowStatuses",
                    order = 34,
                },
                descriptionShowDebug = { -- text for showDebug
                    type = "description",
                    name = L["DEBUG_CHECKBOX_TEXT"],
                    width = 2.4,
                    order = 35,
                },
                showDebug = { -- checkbox to enable debug log
                    type = "toggle",
                    name = L["DEBUG_CHECKBOX"],
                    desc = L["DEBUG_CHECKBOX_DESCRIPTION"],
                    get = "GetShowDebug",
                    set = "SetShowDebug",
                    order = 36,
                },
            },
        },
    },
}


---------------
--- DB defaults
---------------

local defaults = {
    global = {  -- global wide parameters
        showAlert = true,
        silentMode = false,
        showDebug = false,
        secondScanDelay = 10,
        elapsedLastScan = 27,
    },
    faction = { -- search parameters are faction wide
        defaultQueriesNum = 6,
        defaultZone = nil,
        queries = {},
        raceSelects = {1,2,3,4,5,6,7,8,9,10},
    },
    factionrealm = { -- targets are per faction per realm
        targets = {},
        targetsCounter = 0,
  }
}


---------------------
--- Getters & Setters
---------------------

-- showAlert option, checkbox
function AltsFinder:GetShowAlert(info)
    return self.db.global.showAlert
end

function AltsFinder:SetShowAlert(info, value)
    self.db.global.showAlert = value
end

-- silentMode option, checkbox
function AltsFinder:GetSilentMode(info)
    local isSilent = self.db.global.silentMode
    local settings = options.args.settingsTab.args
    settings.showDebug.disabled = isSilent
    settings.printStats.disabled = isSilent
    settings.showStatuses.disabled = isSilent
    return isSilent
end

function AltsFinder:SetSilentMode(info, value)
    self.db.global.silentMode = value
end

-- duration info option, disabled text input
function AltsFinder:GetDurationInfo(info)
    local elapsed = self.db.global.elapsedLastScan
    local delay = self.db.global.secondScanDelay
    return string.format(L["DURATION_INFO"], elapsed, elapsed + delay)
end

function AltsFinder:SetDurationInfo(info, value)
    self.db.global.elapsedLastScan = value
end

-- secondScanDelay option, slider (in seconds)
function AltsFinder:GetSecondScanDelay(info)
    return self.db.global.secondScanDelay
end

function AltsFinder:SetSecondScanDelay(info, value)
    self.db.global.secondScanDelay = value
end

-- showDebug option, checkbox
function AltsFinder:GetShowDebug(info)
    return self.db.global.showDebug
end

function AltsFinder:SetShowDebug(info, value)
    self.db.global.showDebug = value
end

-- defaultZone option, text input
function AltsFinder:GetDefaultZone(info)
    return self.db.faction.defaultZone
end

function AltsFinder:SetDefaultZone(info, str)
    self.db.faction.defaultZone = str
    -- reset UI's queries tab and DB queries
    self:resetSearchQueries()
end

-- defaultQueriesNum option, dropdown
function AltsFinder:GetDefaultQueriesNum(info)
    return self.db.faction.defaultQueriesNum
end

function AltsFinder:SetDefaultQueriesNum(info, value)
    self.db.faction.defaultQueriesNum = value
    -- reset UI's queries tab and DB queries
    self:resetSearchQueries()
end

-- queries array of options, text inputs
function AltsFinder:GetQuery(info)
    local queryNum = tonumber(info[#info]:match("%d+"))
    return self.db.faction.queries[queryNum]
end

function AltsFinder:SetQuery(info, str)
    local queryNum = tonumber(info[#info]:match("%d+"))
    self.db.faction.queries[queryNum] = str
    self.db.faction.raceSelects[queryNum] = -1
end

-- race selects array of options, dropdowns
function AltsFinder:GetRace(info)
    local selectNum = tonumber(info[#info]:match("%d+"))
    return self.db.faction.raceSelects[selectNum]
end

function AltsFinder:SetRace(info, key)
    local selectNum = tonumber(info[#info]:match("%d+"))
    self.db.faction.raceSelects[selectNum] = key
    self.db.faction.queries[selectNum] = defaultQueries[key]
end


----------------
--- UI functions
----------------

-- Adds new target's nickname to DB and updates UI (targets tab's text input)
function AltsFinder:AddTarget(info, name)
    if name and name:trim() ~= "" then
        self:log(string.format(L["INFO_ADDING_FRIEND"], name), LOG_INFO)
        AddFriend(name)
        -- create entry in DB
        self.db.factionrealm.targets[name] = {}
        self.db.factionrealm.targetsCounter = self.db.factionrealm.targetsCounter + 1
        self:UpdateTargetsTab()
        -- retrieve target's online status
        targetsStatuses[name] = "UNKNOWN"
        self:OnFriendListUpdate()
    end
end

-- Removes a target's nickname from DB and updates UI (targets tab's text input)
function AltsFinder:RemoveTarget(info, name)
    local targetsNum = self.db.factionrealm.targetsCounter

    -- handle per-target button without arguments
    if info[#info] == "removeTargetLeaf" then
        local targetLeaf = info[#info-1]
        name = targetsGroup.args[targetLeaf].name
        -- delete target's leaf
        targetsGroup.args[targetLeaf] = nil
    end

    -- else handle with name argument
    if info[#info] == "removeTarget" then
        for i = 1,targetsNum do
            if targetsGroup.args["target" .. i].name == name then
                targetsGroup.args["target" .. i] = nil
            end
        end
    end

    -- delete from db in both cases
    local targets = self.db.factionrealm.targets
    if targets[name] then
        targets[name] = nil
        self.db.factionrealm.targetsCounter = targetsNum - 1
        targetsStatuses[name] = nil
        self:UpdateTargetsTab()
    end
end

-- Refreshes UI targets tab's list with targets
function AltsFinder:UpdateTargetsTab()
    self:log("AltsFinder:UpdateTargetsTab()", LOG_DEBUG)

    -- reset UI's targets tree
    targetsGroup.args = {}
    -- rebuild the tree from DB
    local i = 0
    for target in pairs(self.db.factionrealm.targets) do
        i = i + 1
        targetsGroup.args["target" .. i] = {
            type = "group",
            name = target,
            -- cmdHidden = true,
            order = i,
            args = {
                removeTargetLeaf = {
                    type = "execute",
                    name = L["REMOVE_TARGET_BUTTON"],
                    desc = L["REMOVE_TARGET_BUTTON_DESCRIPTION"],
                    confirm = true,
                    confirmText = L["REMOVE_TARGET_BUTTON_CONFIRM"],
                    func = "RemoveTarget",
                    width = 0.25,
                    order = 0,
                },
                altsList = {
                    type = "description",
                    name = AltsFinder:getStatsForTarget(target, true),
                    fontSize = "medium",
                },
            },
        }
    end
end

-- Constructs UI friendly colored and sorted multiline string from DB table entries
-- Each line is a potential alt entry (with a counter) for the target
function AltsFinder:getStatsForTarget(target, isSortDescending)
    -- read entries from DB
    local stats = {}
    for name,counter in pairs(self.db.factionrealm.targets[target]) do
        -- if counter >= 1 then -- cuts off random players if uncommented
        local neutral = counter == 1 and "|cFF888888" or "|r"
        local green = counter <= 2 and neutral or counter == 3 and "|cFF80FF80" or counter >= 4 and "|cFF00FF00"
        local line = string.format(L["TARGET_ALTS_STATS_TIMES_LOGGED_IN"], green .. counter .. neutral, green .. name .. neutral)
        table.insert(stats, {line, counter})
    end

    -- sort occurrences by counter
    if isSortDescending then
        table.sort(stats, function(a, b) return a[2] > b[2] end)
    else
        table.sort(stats, function(a, b) return a[2] < b[2] end)
    end

    -- merge sorted strings
    local statsStr = ""
    for _,entry in ipairs(stats) do
        statsStr = statsStr .. entry[1]
    end
    return statsStr
end

-- Adds new query string to the end of the list of /who requests (search tab's button)
function AltsFinder:AddQuery(info)
    local queries = self.db.faction.queries

    -- if with number arg - read the existent entry, else add new one to DB
    local n = type(info) == "number" and info or #queries + 1
    queries[n] = queries[n] or defaultQueries[n] or defaultQueries[1]

    -- update UI's queries tab
    queriesGroup.args["query" .. n] = {
        type = "input",

        name = string.format(L["QUERY_INPUT"], n),
        desc = L["QUERY_INPUT_DESCRIPTION"],
        usage = L["QUERY_INPUT_USAGE"],
        get = "GetQuery",
        set = "SetQuery",
        width = "double",
        order = 2*n - 1,
    }
    queriesGroup.args["select" .. n] = {
        type = "select",
        name = L["RACE_DROPDOWN"],
        desc = L["RACE_DROPDOWN_DESCRIPTION"],
        get = "GetRace",
        set = "SetRace",
        values = races,
        order = 2*n,
    }
end

-- Removes the last query string from the list of /who requests (search tab's button)
function AltsFinder:RemoveQuery(info)
    local queries = self.db.faction.queries
    queriesGroup.args["query" .. #queries] = nil
    queriesGroup.args["select" .. #queries] = nil
    queries[#queries] = nil
end

-- Regenerates search queries (for search tab's zone and #num controls)
function AltsFinder:resetSearchQueries()
    queriesGroup.args = {}
    self.db.faction.queries = {}
    self:initializeDefaultQueries()
    for i = 1,self.db.faction.defaultQueriesNum do
        self.db.faction.raceSelects[i] = i
        AltsFinder:AddQuery(i)
    end
end

-- Drops DB (settings tab's button)
function AltsFinder:OnResetDB()
    self.db:ResetDB()

    -- clear UI's targets tree
    targetsGroup.args = {}
    targetsStatuses = {}

    -- reset UI's queries tab
    self:resetSearchQueries()
end


---------------------
--- Addon's lifecycle
---------------------

-- Called when the addon is first loaded
function AltsFinder:OnInitialize()
    -- load DB or populate with defaults
    self.db = LibStub("AceDB-3.0"):New("AltsFinderDB", defaults)
    self:log("AltsFinder:OnInitialize()", LOG_DEBUG)

    -- configure options UI
    LibStub("AceConfig-3.0"):RegisterOptionsTable("AltsFinder", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AltsFinder")
    -- two chat shortcuts to call ChatCommand() function
    self:RegisterChatCommand(L["af"], "ChatCommand")
    self:RegisterChatCommand(L["altsfinder"], "ChatCommand")

    -- initialize UI refs (must be readonly)
    targetsGroup = options.args.targetsTab.args.targets
    queriesGroup = options.args.searchTab.args.queries

    -- load default queries (or from DB)
    self:initializeDefaultQueries()
    local numQueries = #self.db.faction.queries
    numQueries = numQueries == 0 and self.db.faction.defaultQueriesNum or numQueries
    for i=1,numQueries do
        AltsFinder:AddQuery(i)
    end
end

-- Initializes default query strings based on faction and zone
function AltsFinder:initializeDefaultQueries()
    local mapID, raceIDs
    -- check faction
    if UnitFactionGroup("player") == "Alliance" then
        mapID, raceIDs = 84, raceIDsAlliance -- 84 for Stormwind, 1161 for Boralus
    else
        mapID, raceIDs = 85, raceIDsHorde -- 85 for Orgrimmar, 1165 for Zuldazar
    end

    -- user's choice or localized faction capital
    local zone = self.db.faction.defaultZone or C_Map.GetMapInfo(mapID).name
    self.db.faction.defaultZone = zone

    -- construct query strings
    for i,raceID in ipairs(raceIDs) do
        local race = C_CreatureInfo.GetRaceInfo(raceID).raceName -- localized race name
        defaultQueries[i] = string.format(L["SEARCH_QUERY_PATTERN"], zone, race)
        races[i] = race
    end
end

-- Called when the addon is enabled
function AltsFinder:OnEnable()
    self:log("AltsFinder:OnEnable()", LOG_DEBUG)

    local targets = self.db.factionrealm.targets

    -- add all targets to friends on other chars on the same realm (each char has separate friends list)
    local friendsList = {}
    for i = 1,GetNumFriends() do
        local name = GetFriendInfo(i)
        if name then
            friendsList[name] = true
        end
    end
    for target in pairs(targets) do
        if not friendsList[target] then
            self:log(string.format(L["INFO_ADDING_FRIEND"], target), LOG_INFO)
            AddFriend(target)
        end
    end

    -- add target example if there are no targets
    local targetsNum = self.db.factionrealm.targetsCounter
    if targetsNum == 0 then
        self.db.factionrealm.targetsCounter = targetsNum + 1
        targetsStatuses[L["EXAMPLE_TARGET"]] = "UNKNOWN"
        targets[L["EXAMPLE_TARGET"]] = L["EXAMPLE_TARGET_STATS"]
    end

    -- populate UI with targets from DB
    self:UpdateTargetsTab()

    -- reset initial statuses
    for name in pairs(targets) do
        targetsStatuses[name] = "UNKNOWN"
    end

    -- main event to monitor targets
    self:RegisterEvent("FRIENDLIST_UPDATE", "OnFriendListUpdate")
    -- simulate firing to populate initial online statuses
    self:OnFriendListUpdate()
end

-- Called when the addon is disabled
function AltsFinder:OnDisable()
    self:log("AltsFinder:OnDisable()", LOG_DEBUG)
    self:UnregisterEvent("FRIENDLIST_UPDATE")
end

-- Callback for /af and /altsfinder
function AltsFinder:ChatCommand(input)
    -- if without arguments
    if not input or input:trim() == "" then
        -- then open addon's UI options frame
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) -- "first opening" bug workaround
        -- and print command help
        LibStub("AceConfigCmd-3.0"):HandleCommand(L["af"], "AltsFinder", input)
    else
    -- if there are arguments, then process them
        LibStub("AceConfigCmd-3.0"):HandleCommand(L["af"], "AltsFinder", input)
    end
end


------------------
--- Scan lifecycle
------------------

--[[
    The sequence of events is as follows:
    1. OnFriendListUpdate() is triggered when FRIENDLIST_UPDATE event fires by Blizzard UI.
        It repopulates new offline|online statuses and checks if any target logs off;
    3. ScanOnlinePlayers() if so - first "before" scanning procedure is initiated.
        Presumably this first "before" scan will be able to finish before target's alt logs in;
    4. After a short timer the second "after" scanning procedure is initiated with ScanOnlinePlayers() call.
        Presumably this second "after" scan will start after target's alt logs in.
    Each scan traverses a list with /who parameters and sends requests for each /who string.
    Requests lifecycle consists of following stages:
        1.) prepareWhoRequest() is called which chooses current /who parameter or finishes scan procedure;
        2.) repeatWhoRequest() is called multiple times until server returns a result (due to server-side cooldown and silent throttling);
        3.) receiveWhoRequest() on a successful return then prepare next request;
        4.) finishScanning() when all requests are processed and either delay the second scan or compare the results.
    5. CompareScanResults() when both scans are finished.
        Comparing procedure looks for players who are online at the second "after" scan and compares them to those
        who were online at the first "before" scan. New online players are added to the DB with a counter.
        The counter is a number of occurrences of a particular new online player after target logs off.
    After the target logs off several times and all the 1-5 cycle repeats itself for each of those events, we can
    now sort new online players list by the counter. Top occurrences are potential alts of the target.

    Some hints:
        - just two events of target's logging off could be sufficient: one of those with counter=2 is a potential alt.
        - /who results are limited by 50. Parameters are such constructed so to narrow down /who search results:
          good chances are alts starting zone is a big town and in that town searching by race is enough.
]]

-- Fired when friendlist is updated and targets' online status may change.
-- Repopulates new offline|online statuses and checks if any target logs off so to start the scan cycle.
function AltsFinder:OnFriendListUpdate()
    self:log("AltsFinder:OnFriendListUpdate()", LOG_DEBUG)

    -- first, need to get all friends' current online status
    local friendsList = {}
    for i = 1,GetNumFriends() do
        local name, _, _, _, online = GetFriendInfo(i)
        if online and name then
            friendsList[name] = "ONLINE"
        elseif name then
            friendsList[name] = "OFFLINE"
        end
    end

    -- then filter only targets from the list
    for target,status in pairs(targetsStatuses) do
        if friendsList[target] then
            if status == "UNKNOWN" then
                targetsStatuses[target] = friendsList[target]
            else
                if status ~= friendsList[target] then
                    if status == "ONLINE" then
                        -- main conditions to initiate scan - target was online and goes offline
                        self:log(string.format(L["INFO_PLAYER_LOGS_OFF"], target), LOG_INFO)
                        if not isScanning then
                            self:log(string.format(L["INFO_START_SCAN"], target), LOG_INFO)
                            currentTarget = target
                            isScanning = true
                            options.args.searchTab.disabled = true
                            isScanBefore = true
                            self:ScanOnlinePlayers()
                        end
                    elseif status == "OFFLINE" then
                        self:log(string.format(L["INFO_PLAYER_LOGS_ON"], target), LOG_INFO)
                    end
                    targetsStatuses[target] = friendsList[target]
                end
            end
        end
    end
end

-- Initiates "before" and "after" scans
function AltsFinder:ScanOnlinePlayers()
    self:log("AltsFinder:ScanOnlinePlayers()", LOG_DEBUG)

    -- for timing scan duration in seconds (if all's ok, timeOut should not be called)
    elapsedTimer = self:ScheduleTimer("timeOut", 1000)

    -- redirecting /who results from Blizzard UI to receiveWhoRequest function
    FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
    self:RegisterEvent("WHO_LIST_UPDATE", "receiveWhoRequest")
    SetWhoToUI(1)

    -- nullify /who parameters scan list flags
    queriesToScan = {}
    for i = 1,#self.db.faction.queries do
        queriesToScan[i] = true
    end

    -- choose between either it is a first "before" scan or a second "after" scan
    if isScanBefore then
        entriesBefore = {}
        currentEntries = entriesBefore
    else
        entriesAfter = {}
        currentEntries = entriesAfter
    end
    -- enter scan cycle
    self:prepareWhoRequest()
end

-- Constructs next /who request or finishes current scan procedure.
-- Traverses a list with /who parameters and sends requests for each /who string.
function AltsFinder:prepareWhoRequest()
    self:log("AltsFinder:prepareWhoRequest()", LOG_DEBUG)

    whoRequestReceived = false
    -- choose next /who parameter to scan
    local isAllQueriesScanned = true
    local queries = self.db.faction.queries
    for i = 1,#queries do
        if queriesToScan[i] then
            self:log(string.format(L["INFO_SCANNING_QUERY"], i, queries[i]), LOG_INFO)
            isAllQueriesScanned = false
            queriesToScan[i] = false
            currentQuery = queries[i]
            -- repeats /who query until results are received
            whoRequestsTimer = self:ScheduleRepeatingTimer("repeatWhoRequest", whoRequestsDelay)
            break
        end
    end

    -- finish current scan if all requests are processed
    if isAllQueriesScanned then
        self:finishScanning()
    end
end

-- Called multiple times by whoRequestsTimer until server returns a result (due to server-side cooldown and silent throttling)
function AltsFinder:repeatWhoRequest()
    self:log("AltsFinder:repeatWhoRequest()", LOG_DEBUG)

    if not whoRequestReceived then
        -- repeat /who query
        SendWho(currentQuery)
    end
end

-- Process successful /who return and then prepare next request
function AltsFinder:receiveWhoRequest()
    self:log("AltsFinder:receiveWhoRequest()", LOG_DEBUG)

    -- collect /who data
    for i = 1,GetNumWhoResults() do
        currentEntries[GetWhoInfo(i)] = true
    end

    -- stop query repeating timer and prepare next query
    whoRequestReceived = true
    self:CancelTimer(whoRequestsTimer)
    self:prepareWhoRequest()
end

-- Finish scanning when all requests are processed and either delay the second scan or compare the results.
function AltsFinder:finishScanning()
    self:log("AltsFinder:finishScanning()", LOG_DEBUG)

    self:log(L["INFO_SCAN_CYCLE_COMPLETE"], LOG_INFO)

    -- timing
    local timeElapsed = 1000 - self:TimeLeft(elapsedTimer)
    self:CancelTimer(elapsedTimer)
    self:log(string.format(L["INFO_ELAPSED"], timeElapsed), LOG_INFO)
    self:SetDurationInfo(nil, timeElapsed)

    -- release UI event
    self:UnregisterEvent("WHO_LIST_UPDATE")
    FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")

    if isScanBefore then
        -- delay second "after" scan
        local delay = self.db.global.secondScanDelay
        self:log(string.format(L["INFO_DELAYING_SECOND_SCAN"], delay), LOG_INFO)
        isScanBefore = false
        self:ScheduleTimer("ScanOnlinePlayers", delay)
    else
        -- both scans are finished so process the results
        self:CompareScanResults()
        isScanning = false
        options.args.searchTab.disabled = false
    end
end

-- Comparing procedure looks for new online players between two scans and adds them to the DB with a counter.
-- The counter is a number of occurrences of a particular new online player after target logs off.
function AltsFinder:CompareScanResults()
    self:log(L["INFO_COMPARING"], LOG_INFO)

    -- process scan results and write to DB
    local targetAltsList = self.db.factionrealm.targets[currentTarget]
    for name in pairs(entriesAfter) do
        if entriesAfter[name] ~= entriesBefore[name] then
            local counter = targetAltsList[name]
            counter = counter and counter + 1 or 1
            targetAltsList[name] = counter
            self:log(string.format(L["INFO_NEW_ENTRY"], counter, name), LOG_INFO)
            -- remind user of addon's existence if new potential alt is found
            if counter >= 2 then
                self:log(string.format(L["INFO_ALTS_ALERT"], counter, name), LOG_ALERT)
            end
        end
    end
    self:log(L["INFO_COMPARING_DONE"], LOG_INFO)

    -- update UI
    self:UpdateTargetsTab()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("AltsFinder")
end

-- Normally scan should've been finished before timeOut (limit: 1000 seconds)
-- Called only when something's wrong.
function AltsFinder:timeOut()
    self:log(L["INFO_TIMEOUT_WARNING"], LOG_INFO)
end


----------------
--- Misc and log
----------------

-- Initiates test scan for random target
function AltsFinder:TestScan(info)
    isScanning = true
    options.args.searchTab.disabled = true
    isScanBefore = true
    currentTarget = next(targetsStatuses)
    if currentTarget then
        self:log(string.format(L["INFO_TEST_SCAN"], currentTarget), LOG_INFO)
        self:ScanOnlinePlayers()
    else
        self:log(L["INFO_TEST_SCAN_NO_TARGETS"], LOG_INFO)
    end
end

-- Prints out DB statistics on potential target's alts with counters of occurrences.
-- The higher the counter - more likely that's the target's alt.
function AltsFinder:OnPrintStats()
    self:log(L["INFO_PRINT_STATS"], LOG_INFO)
    -- for every target
    for target in pairs(self.db.factionrealm.targets) do
        self:log(string.format(L["INFO_PRINT_STATS_FOR"], target, AltsFinder:getStatsForTarget(target)), LOG_INFO)
    end
end

-- Test function to show online|offline status for each target
function AltsFinder:OnShowStatuses()
    self:log(L["INFO_SHOW_STATUSES"], LOG_INFO)
    for target,status in pairs(targetsStatuses) do
        self:log(string.format(L["INFO_SHOW_STATUSES_FOR"], target, status), LOG_INFO)
    end
end

-- Logs addon messages to chat or on-screen
function AltsFinder:log(msg, flag)
    -- info log and debug log
    if flag == LOG_INFO or flag == LOG_DEBUG and self.db.global.showDebug then
        if not self.db.global.silentMode then
            self:Print(msg)
        end
    elseif flag == LOG_ALERT and self.db.global.showAlert then
    -- on-screen alert with a sound
        PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_2, "Master");
        UIErrorsFrame:AddMessage(msg, 1.0, 1.0, 1.0)
    end
end