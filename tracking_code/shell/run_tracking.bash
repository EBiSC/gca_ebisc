#!/bin/bash

VERSION=`date "+%Y%m%d.%H%M%S"`
TRACK_HOME=/nfs/production/reseq-info/work/ebiscdcc/tracking_json
mkdir $TRACK_HOME/$VERSION

perl $EBISC_CODE/tracking_code/scripts/create_tracking_json.pl -hESCreg_user="$HESCREG_USER" -hESCreg_pass="$HESCREG_PASS" -IMS_user="$IMS_USER" -IMS_pass="$IMS_PASS" >$TRACK_HOME/$VERSION/api_compares.$VERSION.json \
&& perl $EBISC_CODE/tracking_code/scripts/create_error_json.pl -api_compares_json $TRACK_HOME/$VERSION/api_compares.$VERSION.json > $TRACK_HOME/$VERSION/api_errors.$VERSION.json \
&& perl $EBISC_CODE/tracking_code/scripts/create_tests_json.pl -api_compares_json $TRACK_HOME/$VERSION/api_compares.$VERSION.json > $TRACK_HOME/$VERSION/api_tests.$VERSION.json \
&& cp $TRACK_HOME/$VERSION/api_compares.$VERSION.json /homes/ebiscdcc/public_html/track/json/api_compares.json \
&& cp $TRACK_HOME/$VERSION/api_errors.$VERSION.json /homes/ebiscdcc/public_html/track/json/errors.json \
&& cp $TRACK_HOME/$VERSION/api_tests.$VERSION.json /homes/ebiscdcc/public_html/track/json/tests.json \
&& ln -sT $TRACK_HOME/$VERSION/api_compares.$VERSION.json $TRACK_HOME/api_compares.current.json \
&& ln -sT $TRACK_HOME/$VERSION/api_errors.$VERSION.json $TRACK_HOME/api_errors.current.json \
&& ln -sT $TRACK_HOME/$VERSION/api_tests.$VERSION.json $TRACK_HOME/api_tests.current.json
