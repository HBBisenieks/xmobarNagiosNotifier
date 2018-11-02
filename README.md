# xmobarNagiosNotifier
A quick shell script to get Nagios status up in your xmobar

## Quick Setup
Clone the repo onto your machine. Edit the `server`, `user`, and `pass` fields 
to fit your environment. Run the script from your terminal; expected output for 
a server with no services problems is

`C:0 W:0 U:0`

If everything is running as expected, add to your .xmobarrc commands using

`Run Com "/path/to/nagiosStatus.sh" [] "nagios" 600`

and add `%nagios%` to your template definition.
