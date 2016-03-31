#!/bin/bash

perl $EBISC_CODE/tracking_code/scripts/create_cellline_xml.pl -IMS_user="$IMS_USER" -IMS_pass="$IMS_PASS" \
&& perl $EBISC_CODE/tracking_code/scripts/create_batch_csv.pl -IMS_user="$IMS_USER" -IMS_pass="$IMS_PASS"