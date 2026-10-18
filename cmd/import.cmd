function cmd.import() {
	source ${EMPEROR_SRC_DIR}/cmd/create
	source ${EMPEROR_SRC_DIR}/cmd/destroy
	source ${EMPEROR_SRC_DIR}/cmd/info
	source ${EMPEROR_SRC_DIR}/cmd/list
	source ${EMPEROR_SRC_DIR}/cmd/root
	source ${EMPEROR_SRC_DIR}/cmd/slumber
}

cmd.import
