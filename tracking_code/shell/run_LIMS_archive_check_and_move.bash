#!/bin/bash

perl $EBISC_CODE/tracking_code/scripts/move_LIMS_archived_xmls.pl -cellline_xml_folder /nfs/production/reseq-info/drop/ebisc-data/outgoing/cellline_xml/ -cellline_xml_archive /nfs/production/reseq-info/drop/ebisc-data/outgoing/cellline_xml_archive/ -celline_ARK_fromLIMS /nfs/production/reseq-info/drop/ebisc-data/incoming/rc_lims_cellline_xml/