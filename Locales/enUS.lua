local debug = false
--@debug@
debug = true
--@end-debug@
local L = LibStub("AceLocale-3.0"):NewLocale("AltsFinder", "enUS", true, debug)

----------------------
-- Main search pattern
----------------------

L["SEARCH_QUERY_PATTERN"] = "%s %q" -- format:(zone, race)

---------------
-- Targets tab
---------------

L["TARGETS_TAB"] = "Targets"
L["TARGETS_TAB_DESCRIPTION"] = "Your list of targets and their stats."
L["TARGETS_TAB_TEXT"] = [[Add targets to spy upon and wait for them to log off several times. See |cFF00FFFFhelp|r in a dropdown below.]]

L["ADD_TARGET_INPUT"] = "Add target:"
L["ADD_TARGET_INPUT_DESCRIPTION"] = "Adds target's name to the list."
L["ADD_TARGET_INPUT_USAGE"] = "<Nickname>"

L["REMOVE_TARGET_INPUT"] = "Remove target:"
L["REMOVE_TARGET_INPUT_DESCRIPTION"] = "Removes target's name from the list."
L["REMOVE_TARGET_INPUT_USAGE"] = "<Nickname>" -- same as ADD_TARGET_INPUT_USAGE

L["TARGETS_DROPDOWN_STATS"] = "Targets list and statistics"
L["TARGETS_DROPDOWN_HELP"] = "|cFF00FFFFHelp on targets|r"

L["REMOVE_TARGET_BUTTON"] = "x"
L["REMOVE_TARGET_BUTTON_DESCRIPTION"] = "Remove current target from the list"
L["REMOVE_TARGET_BUTTON_CONFIRM"] = "Are you sure you want to remove the current target and all of its stats from DB?"

L["TARGET_ALTS_STATS_TIMES_LOGGED_IN"] = "  %s login(s) right after target: %s\n" -- format:(counter, name)

L["EXAMPLE_TARGET"] = "TargetExample"
L["EXAMPLE_TARGET_STATS"] = {
    ["VarianWrynnNephew"] = 1,
    ["Thrall"] = 2,
    ["Sylvanas"] = 1,
    ["Abathur"] = 3,
    ["Hanzo"] = 4,
    ["Mephisto"] = 1,
    ["Junkrat"] = 2,
    ["TheButcher"] = 1,
}

L["TARGETS_HELP_TEXT"] = [[===|cFF00CCFF Step 1 |r===
Add a target whose alts you wish to find. Enter player's nickname into the field above.

===|cFF00CCFF Step 2 |r===
Review (or modify) "Search" tab parameters along with the |cFF00FFFFhelp|r on that tab.

===|cFF00CCFF Step 3 |r===
Wait. For how long? Until the target logs off several times to switch alts.
Maybe a few days will be enough, but that depends entirely on the target.

===|cFF00CCFF Step 4 |r===
Return to this tab to review the obtained target's potential alts stats. Addon counts
potential alts' logins after target's logoff. Those with high numbers are first candidates
to real target's alts. Add them to friends list and check!

===|cFF00CCFF Step 5 |r===
If found alts are false positives, then return to step 2 and refer to search tab's help.
Add any real alts to targets list (as in step 1) so to find other alts of the original target.

|cFFFF6EB4How it works:|r the addon waits for the target to log off. Right after that, the addon scans
the chosen zone for currently online players (while target chooses his next alt and loads
into the world). After target's alt presumably logs in, the addon scans for online players
again (now they should include target's alt). Then two scan's (referred to as "before"
and "after" scans) results are compared and any newly logged in players are added to
the targets' stats database.

|cFFFF1A1ADisclaimer:|r the addon is not intended to pursue people! The original purpose was to
monitor a competitor who undercut me at the auction house and undercut him in turn
after he logs off completely from the game.]]


---------------
-- Search tab
---------------

L["SEARCH_TAB"] = "Search"
L["SEARCH_TAB_DESCRIPTION"] = "Here you can modify /who query parameters."
L["SEARCH_TAB_TEXT"] = [[Review and edit search parameters. See |cFF00FFFFhelp|r in a dropdown below.]]

L["ADD_QUERY_BUTTON"] = "Add query"
L["ADD_QUERY_BUTTON_DESCRIPTION"] = "Adds another query to the end of the list."

L["REMOVE_QUERY_BUTTON"] = "Remove query"
L["REMOVE_QUERY_BUTTON_DESCRIPTION"] = "Removes the last query in the list."

L["ZONE_INPUT"] = "Set zone parameter:"
L["ZONE_INPUT_DESCRIPTION"] = "You can change the default zone used for search parameters."
L["ZONE_INPUT_USAGE"] = "Stormwind City"
L["ZONE_INPUT_CONFIRM"] = "This will |cFFFF0000DELETE|r all current query strings and generate new ones."

L["NUM_QUERIES_DROPDOWN"] = "#num"
L["NUM_QUERIES_DROPDOWN_DESCRIPTION"] = "Default queries number when regenerated."
L["NUM_QUERIES_DROPDOWN_CONFIRM"] = "This will |cFFFF0000DELETE|r all current query strings and generate new ones." -- same as ZONE_INPUT_CONFIRM

L["SEARCH_DROPDOWN_QUERIES"] = "Search queries list"
L["SEARCH_DROPDOWN_HELP"] = "|cFF00FFFFHelp on search and queries|r"

L["QUERY_INPUT"] = "Query #%d" -- format:(n)
L["QUERY_INPUT_DESCRIPTION"] = [[You can edit or enter custom /who query. Search "wow /who" on the internet to check for available query options.]]
L["QUERY_INPUT_USAGE"] = "Stormwind r-Human"

L["RACE_DROPDOWN"] = "Select race"
L["RACE_DROPDOWN_DESCRIPTION"] = "Choose a race to switch to."
L["SEARCH_HELP_TEXT"] = [[|cFFFF6EB4Info:|r searching is based on two scan cycles – "before" and "after" potential alt logs in.
Each cycle sends a series of configurable /who requests. But there are limitations:
  • each /who query results are limited by 50 players by the server
  • there is a server-side cooldown (around 5 seconds) between subsequent requests
  • scan cycle takes time: around 5*(#num-1) seconds (maybe target can relog faster)
  • no way to know beforehand the duration of target's relogin (depends on hardware)

These limitations impose some assumptions and restrictions to be made:
  • target is likely to have a favorite zone (or set of zones)
  • for major cities splitting queries by race will probably suffice to cover that city
  • default set includes 6 - queries which is around 25 secs of "before" scan
  • only most playable races are included in the default set (6 out of 10 faction races)

===|cFF00CCFF Step 1:|r Choose the zone parameter
Think of which zone is the most popular to bind hearthstone to in the current expansion.
Maybe some major faction city. Your first bet is to choose the zone the target logs in to.

===|cFF00CCFF Step 2:|r Decide on the number of queries
Scan cycle duration should be less than the target's relogin time (see |cFF00FFFFsettings|r for more
info). Relogin for HDDs takes half a minute, so 6-7 queries will have time to process.
Relogin for SSDs is faster - like 10-15 secs, and that's a window for only 2-3 queries.
If you've found at least one alt of a target, you can measure the target's relogin duration
(constant for the particular target) - turn on "show timestamps" in social settings.

===|cFF00CCFF Step 3:|r Review and choose races to scan
Probably you will have to rotate races periodically, especially if you've decided on a small number of queries.

Not working? Go to step 1 and try choosing some other zone, they're to be rotated too.]]


---------------
-- Settings tab
---------------

L["SETTINGS_TAB"] = "Settings"
L["SETTINGS_TAB_DESCRIPTION"] = "Global settings and testing."


L["SETTINGS_SECTION_GLOBAL"] = "Global"

L["ALTS_ALERT_CHECKBOX"] = "Alert when potential alt is found"
L["ALTS_ALERT_CHECKBOX_DESCRIPTION"] = "This will play a sound and show an on-screen message when a potential alt is found."
L["INFO_ALTS_ALERT"] = "New potential alt: (%d) %s" -- format:(counter, name)

L["SILENT_MODE_CHECKBOX"] = "Silent mode"
L["SILENT_MODE_CHECKBOX_DESCRIPTION"] = "Disables all chat messages (except on-screen alerts)."

L["RESET_DB_BUTTON"] = "Reset DB"
L["RESET_DB_BUTTON_DESCRIPTION"] = "Drops database: clears out targets, potential alts with counters, resets queries and settings."
L["RESET_DB_BUTTON_CONFIRM"] = "Are you sure you want to |cFFFF0000purge|r the addon's database?"


L["SETTINGS_SECTION_SEARCH"] = "Search"

L["DELAY_SLIDER_TEXT"] = [[You can tune the delay between the first "before" scan finishes
and the second "after" scan starts. The delay is needed just to be
sure the second "after" scan performs any time after alt's login
and can be of high value (though increasing false positives).
]]
L["DELAY_SLIDER"] = "Second scan delay"
L["DELAY_SLIDER_DESCRIPTION"] = "Second scan cycle delay in seconds. NOTE: You can enter manual value up to 5 minutes (300 seconds)."

L["DURATION_INFO_TEXT"] = [[Ideally the time it takes to perform the first "before" scan
should be less than the time it takes the target to relogin
with an alt. Only the first number matters (last scan).
]]
L["DURATION_INFO"] = "|cFF00FF00%12.1f (last scan)|r + delay = %.1f sec" -- format:(elapsed, elapsed + delay)

L["TEST_SCAN_BUTTON_TEXT"] = [[You can start a test scan cycles to estimate how long does it take for your number of
queries to process. This also may be useful to observe what's happening during
the scan cycles.]]
L["TEST_SCAN_BUTTON"] = "Test scan"
L["TEST_SCAN_BUTTON_DESCRIPTION"] = "Starts test scan cycle as if some target goes offline."
L["TEST_SCAN_BUTTON_CONFIRM"] = "This will choose some random target from the targets list. Consider readding the target after completion to reset its stats."
L["INFO_TEST_SCAN"] = "Test scan as if target goes offline: %s" -- format:(currentTarget)
L["INFO_TEST_SCAN_NO_TARGETS"] = "No targets found! Add at least one target to proceed."

L["SETTINGS_SECTION_DEBUG"] = "Debug"

L["PRINT_STATS_BUTTON_TEXT"] = [[Prints all targets from the database along with their corresponding potential
alts' stats to the chat:]]
L["PRINT_STATS_BUTTON"] = "Print stats"
L["PRINT_STATS_BUTTON_DESCRIPTION"] = "Prints targets and potential alts statistics."
L["INFO_PRINT_STATS"] = "Printing DB stats storage:"
L["INFO_PRINT_STATS_FOR"] = "List for %s:\n%s" -- format:(target, stats)

L["SHOW_STATUSES_BUTTON_TEXT"] = [[Prints targets' online|offline statuses:]]
L["SHOW_STATUSES_BUTTON"] = "Show statuses"
L["SHOW_STATUSES_BUTTON_DESCRIPTION"] = "Test online status of targets."
L["INFO_SHOW_STATUSES"] = "Showing statuses:"
L["INFO_SHOW_STATUSES_FOR"] = "%s is %s" -- format:(target, status)

L["DEBUG_CHECKBOX_TEXT"] = [[This setting will turn ON all debug messages along with the usual info. If you
are a developer or just want to peek into what's happening - turn this on:]]
L["DEBUG_CHECKBOX"] = "Show debug messages"
L["DEBUG_CHECKBOX_DESCRIPTION"] = "Will print additional debug messages to the chat."


----------------------
-- Other chat info log
----------------------

L["INFO_ADDING_FRIEND"] = "Adding %s to friends for monitoring.." -- format:(target)
L["INFO_PLAYER_LOGS_OFF"] = "Player %s goes offline!" -- format:(target)
L["INFO_PLAYER_LOGS_ON"] = "Player %s goes online" -- format:(target)
L["INFO_START_SCAN"] = "Starting scan procedure for %s" -- format:(target)
L["INFO_SCANNING_QUERY"] = "Sending query #%d: %s..." -- format:(i, queries[i])
L["INFO_SCAN_CYCLE_COMPLETE"] = "Scan cycle complete."
L["INFO_ELAPSED"] = "Elapsed time: %.3f seconds" -- format:(timeElapsed)
L["INFO_DELAYING_SECOND_SCAN"] = "Delaying second scan cycle for %d seconds.." -- format:(delay)
L["INFO_COMPARING"] = "Comparing results..."
L["INFO_NEW_ENTRY"] = "..new entry: (%d) %s" -- format:(counter, name)
L["INFO_COMPARING_DONE"] = "Done comparing."

L["INFO_TIMEOUT_WARNING"] = "Time is out - /who request took too long to process. Server isn't responding."


----------------
-- Chat commands
----------------

L["altsfinder"] = true
L["af"] = true