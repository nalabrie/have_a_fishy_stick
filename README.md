# ><> Have a Fishy Stick <><

## Installation

Create a folder in your ESO addons directory (usually at `C:\Users\%USERNAME%\Documents\Elder Scrolls Online\live\AddOns`) called `have_a_fishy_stick` and place the files `have_a_fishy_stick.lua` and `have_a_fishy_stick.txt` inside.

## Usage

Type `/fishy` in the chat box to send a fishy stick to the default mail recipient.

Type `/fishy @username` to send a fishy stick to a username.

Type `/fishy player character name` to send a fishy stick to a player by their character name (spaces are allowed).

**Remember** to have at least one fishy stick in your backpack!

## Configuration

The addon does not have any in-game settings (yet) so they need to be modified at the beginning section of the `have_a_fishy_stick.lua` file.

* `defaultMailRecipient` = default person to mail when using `/fishy`
* `mailSubject` = default subject line of all new mails
* `mailBody` = default body of all new mails
