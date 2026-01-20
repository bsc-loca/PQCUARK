#!/bin/bash

rm -rf spyglass_reports
# Run spyglass
echo "Running spyglass. This will take a while..."
sg_shell -enable_pass_exit_codes < ./scripts/lint_spyglass.tcl

DESIGN_TOP=bfu_top
SPYGLASS_RETURN_CODE=$?

# Show reports
cat spyglass_reports/${DESIGN_TOP}/lint/lint_rtl/spyglass_reports/moresimple.rpt

# Show summary
echo "*** Spyglass Lint Summary ***"
cat spyglass_reports/Run_Summary/*.txt

exit $SPYGLASS_RETURN_CODE
