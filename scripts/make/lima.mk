.PHONY: start
start:
	limactl start $(VM_NAME).yaml --tty=false || limactl start $(VM_NAME) || true

.PHONY: shell
shell:
	limactl shell $(VM_NAME) $(COMMAND)

.PHONY: stop
stop:
	limactl stop $(VM_NAME) || true

.PHONY: delete
delete: stop
	limactl delete $(VM_NAME)

.PHONY: commit
commit: stop
	qemu-img commit ~/.lima/$(VM_NAME)/diffdisk

.PHONY: convert
image: commit
	qemu-img convert -O qcow2 -c ~/.lima/$(VM_NAME)/basedisk $(OUTPUT_IMAGE)

.PHONY: logs
logs:
	nc -U ~/.lima/$(VM_NAME)/serial.sock