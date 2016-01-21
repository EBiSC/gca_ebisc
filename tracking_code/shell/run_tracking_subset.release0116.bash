#!/bin/bash

perl $EBISC_CODE/tracking_code/scripts/subset_for_release.pl -api_compares_json /homes/ebiscdcc/public_html/track/json/api_compares.json \
      -allowed_line BIONi010-A \
      -allowed_line BIONi010-B \
      -allowed_line BIONi010-C \
      -allowed_line RBi001-A \
      -allowed_line RCi001-A \
      -allowed_line RCi001-B \
      -allowed_line RCI002-A \
      -allowed_line RCI002-B \
      -allowed_line RCi003-A \
      -allowed_line RCi003-B \
      -allowed_line RCi004-A \
      -allowed_line RCi004-B \
      -allowed_line UCLi001-A \
      -allowed_line UCLi002-A \
      -allowed_line UCLi003-A \
      -allowed_line UKBi002-A \
      -allowed_line UKBi003-A \
      -allowed_line UKBi005-A \
      -allowed_line UKBi006-A \
      -allowed_line UKBi008-A \
      -allowed_line UKKi007-A \
      -allowed_line UKKi007-B \
      -allowed_line UKKi008-A \
      -allowed_line UKKi009-A \
      -allowed_line UKKi009-B \
      -allowed_line UKKi011-A \
      -allowed_line UKKi012-A \
      -allowed_line UNEWi001-A \
      -allowed_line UNEWi002-A \
      -allowed_line UNEWi004-A \
      -allowed_line UNEWi005-A \
      -allowed_line WTSIi001-A \
      -allowed_line WTSIi002-A \
      -allowed_line WTSIi003-A \
      -allowed_line WTSIi004-A \
      -allowed_line WTSIi005-A \
      -allowed_line WTSIi006-A \
      -allowed_line WTSIi007-A \
      -allowed_line WTSIi008-A \
      -allowed_line WTSIi009-A \
      -allowed_line WTSIi010-A \
      -allowed_line WTSIi011-A \
      -allowed_line WTSIi012-A \
      -allowed_line WTSIi013-A \
      -allowed_line WTSIi014-A \
      -allowed_line WTSIi015-A \
      -allowed_line WTSIi016-A \
      -allowed_line WTSIi017-A \
      -allowed_line WTSIi018-A \
      -allowed_line WTSIi019-A \
      -allowed_line WTSIi020-A \
      -allowed_line WTSIi021-A \
      -allowed_line WTSIi022-A \
      -allowed_line WTSIi023-A \
      -allowed_line WTSIi024-A \
      -allowed_line WTSIi025-A \
      -allowed_line WTSIi026-A \
      -allowed_line WTSIi027-A \
      -allowed_line WTSIi028-A \
      -allowed_line WTSIi029-A \
      -allowed_line WTSIi030-A \
      -allowed_line WTSIi031-A \
      -allowed_line WTSIi032-A \
      > $HOME/api_compares.subset.json \
&& perl $EBISC_CODE/tracking_code/scripts/create_error_json.pl -api_compares_json $HOME/api_compares.subset.json > $HOME/api_errors.subset.json \
&& perl $EBISC_CODE/tracking_code/scripts/create_tests_json.pl -api_compares_json $HOME/api_compares.subset.json > $HOME/api_tests.subset.json \
&& mv -f $HOME/api_compares.subset.json /homes/ebiscdcc/public_html/release0116/json/api_compares.json \
&& mv -f $HOME/api_errors.subset.json /homes/ebiscdcc/public_html/release0116/json/errors.json \
&& mv -f $HOME/api_tests.subset.json /homes/ebiscdcc/public_html/release0116/json/tests.json \
&& cp /homes/ebiscdcc/public_html/track/json/error_history.json /homes/ebiscdcc/public_html/release0116/json/error_history.json
