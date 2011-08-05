Dealing with spam in OTRS
=========================

This script was written to ease the handling of spam on [OTRS](http://www.otrs.org/) systems.

How to use it
-------------

Just place the files on the otrs directory as indicated by the path used by each file.

OTRS automatically will place spamassasin tagged emails on the Junk queue. Manual deletion can be cumbersome when receiving too many spam mails.
This script will be executed as a cron job and will do the following set of actions:

* Change to user id of the ticket to an specific one (uid 8 is hardcoded, spamuser's user id on the test system) so a search on this tickets can be quickly done via this user id.
* Put a copy of the email on a directory to be used as feedback to the antispam system.
* Close the ticket.

