#!/usr/bin/env bash

# ============================================================
# run.sh
# ============================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" || exit 1

TOP_MODULE="tb_top"
TEST_NAME="${TEST_NAME:-fifo_base_test}"
RUN_F="run.f"
SIMV="./simv"

LOG_DIR="./logs"
COV_DIR="./cov_report"
CM_DIR="./simv.vdb"
FSDB_FILE="sync_fifo_uvm.fsdb"
REGRESS_DIR="./regress_results"

DEFAULT_DATA_WIDTH="${FIFO_DATA_WIDTH:-8}"
DEFAULT_DEPTH="${FIFO_DEPTH:-10}"
RUN_SEED="${2:-1}"

REGRESSION_WIDTHS=(1 8 16)
REGRESSION_DEPTHS=(1 2 3 5 10 16 17)
REGRESSION_SEEDS=(1 101 2026)

mkdir -p "${LOG_DIR}"

VCS_COMMON_OPTS=(
    -sverilog
    -full64
    -ntb_opts uvm
    -debug_access+all
    -kdb
    -timescale=1ns/1ps
    +vcs+lic+wait
    -f "${RUN_F}"
    -top "${TOP_MODULE}"
)

CM_OPTIONS=(
    -cm line+cond+fsm+branch+tgl
    -cm_dir "${CM_DIR}"
)

make_cfg_define_opts() {
    local data_width="$1"
    local depth="$2"
    CFG_DEFINE_OPTS=(
        "+define+FIFO_CFG_DATA_WIDTH=${data_width}"
        "+define+FIFO_CFG_DEPTH=${depth}"
    )
}

validate_positive_int() {
    local value="$1"
    local name="$2"
    if [[ ! "${value}" =~ ^[1-9][0-9]*$ ]]; then
        echo "[RUN.SH] ERROR: ${name} must be a positive integer, got '${value}'."
        return 1
    fi
}

clean_build_artifacts() {
    rm -rf "${SIMV}" simv.daidir csrc "${CM_DIR}"
}

# Arguments: data_width depth compile_log coverage_enable sva_enable
compile_with_config() {
    local data_width="$1"
    local depth="$2"
    local compile_log="$3"
    local with_coverage="$4"
    local with_sva="$5"
    local coverage_opts=()
    local sva_opts=()
    local vcs_status

    validate_positive_int "${data_width}" "DATA_WIDTH" || return 1
    validate_positive_int "${depth}" "DEPTH" || return 1
    make_cfg_define_opts "${data_width}" "${depth}"
    mkdir -p "$(dirname "${compile_log}")"
    clean_build_artifacts

    if [[ "${with_coverage}" == "1" ]]; then
        rm -rf "${COV_DIR}"
        coverage_opts=("${CM_OPTIONS[@]}")
    fi
    if [[ "${with_sva}" == "1" ]]; then
        sva_opts=("+define+FIFO_ENABLE_SVA")
    fi

    echo "============================================================"
    echo "[RUN.SH] Compile started"
    echo "[RUN.SH] DATA_WIDTH=${data_width}, DEPTH=${depth}, COVERAGE=${with_coverage}, SVA=${with_sva}"
    echo "============================================================"

    vcs "${VCS_COMMON_OPTS[@]}" "${CFG_DEFINE_OPTS[@]}" "${sva_opts[@]}" "${coverage_opts[@]}" -o "${SIMV}" 2>&1 | tee "${compile_log}"
    vcs_status=${PIPESTATUS[0]}

    if [[ ${vcs_status} -ne 0 ]]; then
        echo "[RUN.SH] Compile failed. Check: ${compile_log}"
        return ${vcs_status}
    fi
}

# Arguments: seed sim_log coverage_enable no_fsdb verbosity test_name
run_sim_to_log() {
    local seed="$1"
    local sim_log="$2"
    local with_coverage="$3"
    local disable_fsdb="$4"
    local verbosity="$5"
    local test_name="$6"
    local sim_opts=()
    local sim_status

    mkdir -p "$(dirname "${sim_log}")"
    sim_opts=(
        "+UVM_TESTNAME=${test_name}"
        "+UVM_VERBOSITY=${verbosity}"
        "+ntb_random_seed=${seed}"
    )

    if [[ "${with_coverage}" == "1" ]]; then
        sim_opts+=("${CM_OPTIONS[@]}")
    fi
    if [[ "${disable_fsdb}" == "1" ]]; then
        sim_opts+=("+NO_FSDB")
    fi

    echo "============================================================"
    echo "[RUN.SH] Simulation started"
    echo "[RUN.SH] TEST=${test_name}, SEED=${seed}, COVERAGE=${with_coverage}, NO_FSDB=${disable_fsdb}"
    echo "============================================================"

    "${SIMV}" "${sim_opts[@]}" 2>&1 | tee "${sim_log}"
    sim_status=${PIPESTATUS[0]}

    if [[ ${sim_status} -ne 0 ]]; then
        echo "[RUN.SH] Simulation failed. Check: ${sim_log}"
        return ${sim_status}
    fi
}

verify_sim_log() {
    local sim_log="$1"

    if ! grep -Eq "Scoreboard errors[[:space:]]*:[[:space:]]*0" "${sim_log}"; then
        echo "[RUN.SH] FAIL: scoreboard did not report zero errors: ${sim_log}"
        return 1
    fi
    if ! grep -Eq "UVM_ERROR[[:space:]]*:[[:space:]]*0" "${sim_log}"; then
        echo "[RUN.SH] FAIL: UVM_ERROR summary is not zero: ${sim_log}"
        return 1
    fi
    if ! grep -Eq "UVM_FATAL[[:space:]]*:[[:space:]]*0" "${sim_log}"; then
        echo "[RUN.SH] FAIL: UVM_FATAL summary is not zero: ${sim_log}"
        return 1
    fi
    # $error from SVA/top-level assertions is outside UVM report counting.
    if grep -qE "FIFO_SVA:|FIFO protocol error:|FIFO reset error:" "${sim_log}"; then
        echo "[RUN.SH] FAIL: FIFO assertion failure found: ${sim_log}"
        return 1
    fi
}

compile() {
    compile_with_config "${DEFAULT_DATA_WIDTH}" "${DEFAULT_DEPTH}" "${LOG_DIR}/comp.log" 0 0
}

compile_cov() {
    compile_with_config "${DEFAULT_DATA_WIDTH}" "${DEFAULT_DEPTH}" "${LOG_DIR}/comp_cov.log" 1 0
}

run_sim() {
    run_sim_to_log "${RUN_SEED}" "${LOG_DIR}/sim.log" 0 0 UVM_MEDIUM "${TEST_NAME}"
}

run_sim_cov() {
    run_sim_to_log "${RUN_SEED}" "${LOG_DIR}/sim_cov.log" 1 0 UVM_MEDIUM "${TEST_NAME}"
}

# Bound-SVA smoke test. It does not change the 63-run base regression.
sva_smoke() {
    compile_with_config "${DEFAULT_DATA_WIDTH}" "${DEFAULT_DEPTH}" "${LOG_DIR}/comp_sva.log" 0 1 || return $?
    run_sim_to_log "${RUN_SEED}" "${LOG_DIR}/sim_sva.log" 0 0 UVM_MEDIUM "${TEST_NAME}" || return $?
    verify_sim_log "${LOG_DIR}/sim_sva.log"
}

# Directed test that applies reset after FIFO traffic has occurred.
runtime_reset() {
    local reset_test_name="fifo_runtime_reset_test"
    compile_with_config "${DEFAULT_DATA_WIDTH}" "${DEFAULT_DEPTH}" "${LOG_DIR}/comp_reset.log" 0 0 || return $?
    run_sim_to_log "${RUN_SEED}" "${LOG_DIR}/sim_reset.log" 0 0 UVM_MEDIUM "${reset_test_name}" || return $?
    verify_sim_log "${LOG_DIR}/sim_reset.log"
}

gen_urg() {
    local urg_status
    : > "${LOG_DIR}/urg.log"

    if ! command -v urg >/dev/null 2>&1; then
        echo "[RUN.SH] ERROR: urg command was not found in PATH." | tee -a "${LOG_DIR}/urg.log"
        return 1
    fi
    if [[ ! -d "${CM_DIR}" ]]; then
        echo "[RUN.SH] ERROR: coverage database ${CM_DIR} does not exist." | tee -a "${LOG_DIR}/urg.log"
        return 1
    fi

    urg -dir "${CM_DIR}" -format both -report "${COV_DIR}" 2>&1 | tee -a "${LOG_DIR}/urg.log"
    urg_status=${PIPESTATUS[0]}
    if [[ ${urg_status} -ne 0 ]]; then
        echo "[RUN.SH] URG failed. Check: ${LOG_DIR}/urg.log"
        return ${urg_status}
    fi
    echo "[RUN.SH] Coverage report generated: ${COV_DIR}/dashboard.html"
}

append_regression_result() {
    local summary_file="$1"
    local data_width="$2"
    local depth="$3"
    local seed="$4"
    local status="$5"
    local log_path="$6"
    printf "DATA_WIDTH=%-3s DEPTH=%-3s SEED=%-6s STATUS=%-14s LOG=%s\n" "${data_width}" "${depth}" "${seed}" "${status}" "${log_path}" >> "${summary_file}"
}

# 21 compiles + 63 simulations. SVA/reset are exercised separately.
regress() {
    local data_width depth seed case_dir compile_log sim_log summary_file
    local total_count=0 pass_count=0 fail_count=0

    rm -rf "${REGRESS_DIR}"
    mkdir -p "${REGRESS_DIR}"
    summary_file="${REGRESS_DIR}/summary.txt"

    {
        echo "FIFO Parameter Regression Summary"
        echo "Test: ${TEST_NAME}"
        echo "Widths: ${REGRESSION_WIDTHS[*]}"
        echo "Depths: ${REGRESSION_DEPTHS[*]}"
        echo "Seeds: ${REGRESSION_SEEDS[*]}"
        echo "============================================================"
    } > "${summary_file}"

    for data_width in "${REGRESSION_WIDTHS[@]}"; do
        for depth in "${REGRESSION_DEPTHS[@]}"; do
            case_dir="${REGRESS_DIR}/dw${data_width}_depth${depth}"
            compile_log="${case_dir}/compile.log"

            if ! compile_with_config "${data_width}" "${depth}" "${compile_log}" 0 0; then
                for seed in "${REGRESSION_SEEDS[@]}"; do
                    total_count=$((total_count + 1))
                    fail_count=$((fail_count + 1))
                    append_regression_result "${summary_file}" "${data_width}" "${depth}" "${seed}" COMPILE_FAIL "${compile_log}"
                done
                continue
            fi

            for seed in "${REGRESSION_SEEDS[@]}"; do
                sim_log="${case_dir}/seed_${seed}.log"
                total_count=$((total_count + 1))
                if run_sim_to_log "${seed}" "${sim_log}" 0 1 UVM_LOW "${TEST_NAME}" && verify_sim_log "${sim_log}"; then
                    pass_count=$((pass_count + 1))
                    append_regression_result "${summary_file}" "${data_width}" "${depth}" "${seed}" PASS "${sim_log}"
                else
                    fail_count=$((fail_count + 1))
                    append_regression_result "${summary_file}" "${data_width}" "${depth}" "${seed}" FAIL "${sim_log}"
                fi
            done
        done
    done

    {
        echo "============================================================"
        echo "TOTAL : ${total_count}"
        echo "PASS  : ${pass_count}"
        echo "FAIL  : ${fail_count}"
        echo "============================================================"
    } | tee -a "${summary_file}"

    echo "[RUN.SH] Regression summary: ${summary_file}"
    [[ ${fail_count} -eq 0 ]]
}

open_verdi() {
    if [[ ! -f "${FSDB_FILE}" ]]; then
        echo "[RUN.SH] ERROR: FSDB file not found: ${FSDB_FILE}"
        return 1
    fi
    verdi -sv -f "${RUN_F}" -top "${TOP_MODULE}" -ssf "${FSDB_FILE}" &
}

clean() {
    clean_build_artifacts
    rm -rf "${COV_DIR}" "${LOG_DIR}" "${REGRESS_DIR}"
    rm -rf DVEfiles verdiLog novas.* novas_dump.log ucli.key *.fsdb *.vpd *.key
}

show_help() {
    cat <<'HELP'
Usage:
  ./run.sh all [seed]     : compile and run default random test
  ./run.sh cov [seed]     : compile, run, and generate code coverage
  ./run.sh sva [seed]     : compile and run bound-SVA smoke test
  ./run.sh reset [seed]   : compile and run runtime-reset test
  ./run.sh regress        : 63-run base parameter regression
  ./run.sh urg            : generate URG report from simv.vdb
  ./run.sh verdi          : open latest FSDB
  ./run.sh clean          : remove generated files
HELP
}

case "$1" in
    all)     compile && run_sim ;;
    comp)    compile ;;
    run)     run_sim ;;
    cov)     compile_cov && run_sim_cov && gen_urg ;;
    sva)     sva_smoke ;;
    reset)   runtime_reset ;;
    urg)     gen_urg ;;
    regress) regress ;;
    verdi)   open_verdi ;;
    clean)   clean ;;
    help|"") show_help ;;
    *) echo "[RUN.SH] Unknown command: $1"; show_help; exit 1 ;;
esac
