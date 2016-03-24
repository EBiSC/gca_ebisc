#!/bin/bash

VERSION=`date "+%Y%m%d.%H%M%S"`
OUTGOING_FTP=/nfs/production/reseq-info/drop/ebisc-data/outgoing

perl $EBISC_CODE/tracking_code/scripts/create_LIMS_import_xml.pl -IMS_user="$IMS_USER" -IMS_pass="$IMS_PASS" > $OUTGOING_FTP/cellline_xml/LIMS_depositor_import_$VERSION.xml