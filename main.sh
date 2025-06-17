#!/usr/bin/env bash

# Check Bash version 4+.
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "Bash version 4 or higher is required (found version ${BASH_VERSINFO[0]})."
    exit 1
fi


# Resolve script directory and source common functions
UTILITIES_DIR="$(dirname "$(realpath "$0")")"
METAGEAR_DIR="$(dirname "$UTILITIES_DIR")"
PIPELINE_DIR="$METAGEAR_DIR/latest"
LAUNCH_DIR="$PWD"

source "${UTILITIES_DIR}/lib/common.sh"
source "${UTILITIES_DIR}/lib/workflows.sh"

check_metagear_home

# Ensure a command is provided
if [ $# -eq 0 ]; then
    usage
fi

COMMAND="$1"
shift

check_command "$COMMAND"

mkdir -p $LAUNCH_DIR/.metagear

argument_config_file=$(get_config $COMMAND $@)

custom_config_files=( $PIPELINE_DIR/conf/metagear/$COMMAND.config $METAGEAR_DIR/metagear.config  $argument_config_file)
metagear_config_files=( $PIPELINE_DIR/conf/metagear/*.config )
all_config_files=( "${metagear_config_files[@]}" "${custom_config_files[@]}" )

$UTILITIES_DIR/lib/merge_configuration.sh ${all_config_files[@]} > $LAUNCH_DIR/.metagear/$COMMAND.config

nf_cmd_workflow_part=$(run_workflows $COMMAND $@)

cat $METAGEAR_DIR/metagear.env > $LAUNCH_DIR/metagear_$COMMAND.sh

echo "" >> $LAUNCH_DIR/metagear_$COMMAND.sh
echo "nextflow run $PIPELINE_DIR/main.nf \\
        $nf_cmd_workflow_part \\
        -c $LAUNCH_DIR/.metagear/$COMMAND.config \\
        \$RUN_PROFILES -w \\
        \$NF_WORK -resume" >> $LAUNCH_DIR/metagear_$COMMAND.sh
echo "" >> $LAUNCH_DIR/metagear_$COMMAND.sh

chmod +x $LAUNCH_DIR/metagear_$COMMAND.sh

$LAUNCH_DIR/metagear_$COMMAND.sh
