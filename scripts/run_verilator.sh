#!/bin/bash
TEST_PATH=$1
TEST=$(basename $TEST_PATH)
riscv_torture_path=../../ci/riscv-torture
SPIKE="$SPIKE_PATH/spike"
SIGNATURE_FOLDER="signature"
WAVE_FOLDER="waves"
KONATA_FOLDER="konata"
OUTPUT_FOLDER="output"

RUN_SPIKE=false

BIN_VERILATOR="sim"
EXE="./$BIN_VERILATOR +load=${TEST_PATH} "

shift
while getopts 'wdkscha:' OPTION; do
  case "$OPTION" in
    w) #WAVE
      mkdir -p ./${OUTPUT_FOLDER}/${WAVE_FOLDER}
      EXE+=" +vcd +vcd_name=./${OUTPUT_FOLDER}/$WAVE_FOLDER/${TEST}.vcd "
      ;;
    d) #DUMP SIGNATURE
      mkdir -p ./${OUTPUT_FOLDER}/${SIGNATURE_FOLDER}
      EXE+=" +commit_log=./${OUTPUT_FOLDER}/${SIGNATURE_FOLDER}/$TEST.vsim.sig"
      ;;
    k) #KONATA
      mkdir -p ./${OUTPUT_FOLDER}/${KONATA_FOLDER}
      EXE+=" +konata_dump_ON +konata_dump=./${OUTPUT_FOLDER}/${KONATA_FOLDER}/${TEST}.vsim.out "
      ;;
    s) #SPIKE EXECUTION
      RUN_SPIKE=true
      ;;
    c) #RUN COSIMULATION
      EXE=${EXE//$BIN_VERILATOR/DefaultConfig-sim-cosim}
      ;;
    a) #ADD EXTRA ARGUMENTS
      avalue="$OPTARG"
      EXE+="$OPTARG"
      ;;
    h) #HELP
      echo "Run Verilator Script"
      echo "IMPORTANT: Include the binary to execute on ./${OUTPUT_FOLDER} folder"
      echo "Usage: ./run_verilator.sh TEST_NAME [-w] [-d] [-k] [-s] [-c] [-a \"arguments\"] "
      echo "-w : Generate a waveform"
      echo "-d : Generate a dump signature of the execution"
      echo "-k : Generate a konata dump"
      echo "-s : Add a spike run execution"
      echo "-c : Execute cosimulation (needs DefaultConfig-sim-cosim)"
      echo "-a : Add extra arguments"
      exit 1
      ;;
    ?) #USAGE
      echo "usage: ./run_verilator.sh TEST_NAME [-w] [-d] [-k] [-s] [-c] [-a \"arguments\"]" >&2
      exit 1
      ;;
  esac
done
 shift "$(($OPTIND -1))"

#Run Spike
if [ $RUN_SPIKE = true ] ; then
  set -x
  $SPIKE --isa=RV64G -l ./${OUTPUT_FOLDER}/${TEST} 2>./${OUTPUT_FOLDER}/$SIGNATURE_FOLDER/$TEST.ref.sig
fi

#Run Verilator
set -x
$EXE

#echo "$riscv_torture_path/scripts/diff.sh $TEST.diff $TEST.ref.sig $TEST.vsim.sig"
#$riscv_torture_path/scripts/diff.sh $TEST.diff $TEST.ref.sig $TEST.vsim.sig
