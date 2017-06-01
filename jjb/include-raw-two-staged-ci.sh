#!/bin/bash

#git fetch ssh://rameshthoomu@gerrit.hyperledger.org:29418/fabric refs/changes/11/9811/13 && git checkout FETCH_HEAD

# Retrieve the patch review and verdicts for a given patch set
REVIEWS=`curl https://gerrit.hyperledger.org/r/changes/$GERRIT_CHANGE_ID/reviewers | grep '"Code-Review": "+2"' | wc -l`

# No need to have these comment outputed, unless you want to see what is getting
# processed. These lines tell you how many +2 Code-Reviews is able to find per
# ChangeId
#echo "has $REVIEWS +2 Code-Reviews"

# Store in a variable the currently processed ChangeId if it has at least 2 +2
if [ "$REVIEWS" -ge "2" ];
then
   export JOB_TYPE="FULL"
else
   export JOB_TYPE="VERIFY"
fi
