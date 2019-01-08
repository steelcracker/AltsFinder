# AltsFinder

AltsFinder is an addon for WoW that helps find other player's alts (alternate characters).  
Internally it utilizes `/who` queries for searching when target character that you wish to spy upon goes offline.  
The addon doesn't guarantee to find any alts with the default settings - some user involvement might be needed.

**Disclaimer**: the addon is not intended to pursue people! The original purpose was to monitor a competitor who undercut me at the auction house and undercut him in turn after he logs off completely from the game.

### Download
You can download and install the addon from:

- [Curse](https://www.wowace.com/projects/altsfinder)

Install the addon with your favorite addon manager or manually download and unpack it to the WoW `Interface` folder.

### Usage
While in-game simply open interface settings for the addon or type `/af` or `/altsfinder` to the chat and press enter.  
Then follow on-screen instructions and refer to an embedded detailed help:
- add a target character whose alts you wish to find to the list
- decide on search and other parameters (read further in-game instructions in tabs' drop-down menus)
- just wait for the target to log off several times
- open the addon options again to see the results and statistics on potential alts

Though searching is automated, you will still need to decide on zones and perhaps some other parameters  
(it is more of an instrument than a fully automatic solution).

**How it works:**
The addon waits for the target to log off. Right after that, the addon scans the chosen zone for currently online players (while target chooses his next alt and loads into the world). After some fixed time interval (after target's alt presumably logs in), the addon scans for online players again (now they should include target's alt). Then two scan's (referred to as "before" and "after" scans) results are compared and any newly logged in players are added to the targets' stats database with a counter. Characters with a high counter are candidates to potential alts of the target.


### Help
There is an embedded help at the addon options screen (look for tabs' drop-down menus).  
You can also refer to the [Wiki pages](https://github.com/steelcracker/AltsFinder/wiki).

### Translation
Please use the [localization app](https://www.wowace.com/projects/altsfinder/localization) on WoWAce to translate.

### Feedback
If you have an issue or a feature suggestion, please use the [issue tracker](https://github.com/steelcracker/AltsFinder/issues).
You can also use project's [forum thread](https://authors.curseforge.com/forums/world-of-warcraft/official-addon-threads/general-addons/237326-altsfinder) or contact me directly.
