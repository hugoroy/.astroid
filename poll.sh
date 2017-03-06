#! /bin/bash

# poll script for astroid

# Exit as soon as one of the commands fail.
set -e

#mbsync -a || exit $? 
offlineimap -o -a ampoliros || exit $? 

notmuch new 

# afew --move-mails --all --verbose
afew --tag --new --verbose

# Example tags 
notmuch tag --batch <<EOF

    # Tag urgent mail
    +urgent tag:new and subject:URGENT

    # Tag all mail from GitHub as "work"
    +work tag:new and from:github

EOF

# Drafts
notmuch tag +draft -unread -- tag:new AND \(folder:ampoliros/Drafts OR folder:ampoliros/Brouillons OR folder:fsfe/INBOX.Brouillons\)
notmuch tag -draft -- tag:new AND tag:draft NOT \(folder:ampoliros/Drafts OR folder:ampoliros/Brouillons OR folder:fsfe/INBOX.Brouillons\)

# tag archived messages
notmuch tag +archives/2017 -inbox -unread -- tag:new AND folder:archives/2017
notmuch tag +archives/2017 -inbox -unread -- tag:new AND folder:ampoliros/Archive.2017

# tag all spam accordingly
notmuch tag +spam -inbox -- tag:new AND \(folder:Spam OR folder:ampoliros/Spam\)
notmuch tag +junk -inbox -- tag:new AND \(folder:Junk\)
notmuch tag -inbox -- tag:new AND tag:spam

# tag deleted messages accordingly
notmuch tag +deleted -inbox -- tag:new AND \(folder:Trash OR folder:ampoliros/Trash\)


# finally, untag all "new" messages
notmuch tag -new -- tag:new

afew --move-mails --all --verbose
