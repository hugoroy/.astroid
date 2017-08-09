#! /bin/bash

# This is a poll script for the Astroid mail user agent. To get
# introduced about polling in Astroid, read
# <https://github.com/astroidmail/astroid/wiki/Polling>.

# This poll script is intended to run automatically every few minutes
# in order to fetch new mail via IMAP (using Offlineimap), to put new
# mail in the index database and to tag it accordingly (using notmuch
# and afew) and to move mail around in accordance with defined tags
# (using afew).

# Exit as soon as one of the commands fail.
set -e


#######################
# Fetch mail with IMAP
#######################

# Simple way

#mbsync -a || exit $? 
#offlineimap -o -q -a ampoliros || exit $? 

# Complicated way

# FIXME this needs work to be more reliable and fail-proof. Otherwise,
# just remember that offlineimap may fail, delete the lock file and
# start it again.

## do a full offlineimap sync once every two hours, otherwise only quicksync
lastfull_f=~/.cache/astroid/offlineimap-last-full # storing state
if [ -f $lastfull_f ]; then
  lastfull=$(cat $lastfull_f)
else
  lastfull=0
fi

delta=$((2 * 60 * 60)) # seconds between full sync
now=$(date +%s)
diff=$(($now - $lastfull))

if [ $diff -gt $delta ]; then
  echo "full offlineimap sync.."
  offlineimap -o || exit 1
  echo -n $now > $lastfull_f
else
  echo "quick offlineimap sync.."
  offlineimap -o -q || exit 1
fi


######################
# Index new mail
######################

notmuch new 

######################
# Tag new mail
######################

# afew --move-mails --all --verbose
afew --tag --new --verbose

# Example tags 
notmuch tag --batch <<EOF

    # Tag urgent mail
    +urgent tag:new and subject:URGENT

    # Tag all mail from GitHub as "work"
    +work tag:new and from:github

EOF

# Tag drafts as such
notmuch tag +draft -unread -- tag:new AND \(folder:ampoliros/Drafts OR folder:ampoliros/Brouillons OR folder:fsfe/INBOX.Brouillons\)
notmuch tag -draft -- tag:new AND tag:draft NOT \(folder:ampoliros/Drafts OR folder:ampoliros/Brouillons OR folder:fsfe/INBOX.Brouillons\)

# Tag mail in archive folders
notmuch tag +archives/2017 -inbox -unread -- tag:new AND folder:archives/2017
notmuch tag +archives/2017 -inbox -unread -- tag:new AND folder:ampoliros/Archive.2017

# Mute incoming mail in response to already muted threads
# THREAD_TAGS="muted"
# for tag in "$THREAD_TAGS"; do
# 	notmuch tag +$tag $(notmuch search --output=threads tag:$tag AND tag:new)
# done

# tag all spam accordingly
notmuch tag +spam -inbox -- tag:new AND \(folder:Spam OR folder:ampoliros/Spam\)
notmuch tag +junk -inbox -- tag:new AND \(folder:Junk\)
notmuch tag -inbox -- tag:new AND tag:spam

# tag deleted messages accordingly
notmuch tag +deleted -inbox -- tag:new AND \(folder:Trash OR folder:ampoliros/Trash\)


# finally, untag all "new" messages
notmuch tag -new -- tag:new


########################
# Move mail around
########################


afew --move-mails --all --verbose
