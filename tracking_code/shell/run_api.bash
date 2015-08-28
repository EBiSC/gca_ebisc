#/bin/bash
   perl $EBISC_CODE/tracking_code/scripts/batch_qc/create_manifest.pl \
&& perl $EBISC_CODE/tracking_code/scripts/batch_qc/cell_line_json.pl \
&& perl $EBISC_CODE/tracking_code/scripts/batch_qc/create_endpoints.pl \
&& rsync --delete-during --recursive --copy-links --times --chmod=Do+x,o+r /nfs/production/reseq-info/drop/ebisc-data/export/current/* ~/public_html/api/
