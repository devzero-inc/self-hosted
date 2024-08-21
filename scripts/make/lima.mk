.PHONY: start
start:
	limactl start $(VM_NAME).yaml --tty=false

.PHONY: shell
shell:
	limactl shell $(VM_NAME)

.PHONY: stop
stop:
	limactl stop $(VM_NAME) || true

.PHONY: delete
delete:
	limactl delete $(VM_NAME)

.PHONY: commit
commit: stop
	qemu-img commit ~/.lima/$(VM_NAME)/diffdisk

.PHONY: convert
image: commit
	qemu-img convert -O qcow2 -c ~/.lima/$(VM_NAME)/basedisk $(OUTPUT_IMAGE)