#!/bin/bash

set -euo pipefail

DIR=$(mktemp -d)
LOGFILE="/var/log/kata_install.log"
trap 'cleanup' EXIT

cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        printf "Error encountered. Check logs at %s\n" "$LOGFILE" >&2
    fi
    rm -rf "$DIR"
}

log_error() {
    printf "ERROR: %s\n" "$1" >&2 | tee -a "$LOGFILE"
}

log_info() {
    printf "INFO: %s\n" "$1" | tee -a "$LOGFILE"
}

download_file() {
    local url=$1
    local output=$2
    if ! curl -fsSL -o "$output" "$url"; then
        log_error "Failed to download $url"
        return 1
    fi
}

extract_tar() {
    local file=$1
    local dest=$2
    if ! tar -C "$dest" -xvf "$file" >>"$LOGFILE" 2>&1; then
        log_error "Failed to extract $file"
        return 1
    fi
}

create_symlink() {
    local target=$1
    local link=$2
    if ! ln -s "$target" "$link" 2>>"$LOGFILE"; then
        log_error "Failed to create symlink from $target to $link"
        return 1
    fi
}

copy_file() {
    local src=$1
    local dest=$2
    if ! cp "$src" "$dest" 2>>"$LOGFILE"; then
        log_error "Failed to copy $src to $dest"
        return 1
    fi
}

write_file() {
    local filepath=$1
    shift
    if ! printf "%s\n" "$@" >"$filepath"; then
        log_error "Failed to write to $filepath"
        return 1
    fi
    chmod +x "$filepath"
}

main() {
    pushd "$DIR" >/dev/null || { log_error "Failed to enter temp directory"; return 1; }

    log_info "Downloading Kata Containers..."
    download_file "https://github.com/kata-containers/kata-containers/releases/download/3.2.0/kata-static-3.2.0-amd64.tar.xz" "kata-static.tar.xz" || return 1

    log_info "Extracting Kata Containers..."
    extract_tar "kata-static.tar.xz" "/" || return 1

    log_info "Creating symlinks..."
    create_symlink "/opt/kata/bin/kata-collect-data.sh" "/usr/local/bin/kata-collect-data.sh"
    create_symlink "/opt/kata/bin/kata-runtime" "/usr/local/bin/kata-runtime"

    log_info "Downloading PVM Kata Stuff..."
    download_file "https://github.com/virt-pvm/misc/releases/download/test/pvm-kata-vm-img.tar.gz" "pvm-kata-stuff.tar.gz" || return 1

    log_info "Extracting PVM Kata Stuff..."
    extract_tar "pvm-kata-stuff.tar.gz" "." || return 1

    if [[ -d "pvm_img" ]]; then
        pushd "pvm_img" >/dev/null || { log_error "Failed to enter pvm_img directory"; return 1; }
        mv containerd-shim-kata-v2 /opt/kata/bin/containerd-shim-kata-clh-v2 || log_error "Failed to move containerd-shim-kata-v2"
        mv qemu-system-x86_64 /opt/kata/bin || log_error "Failed to move qemu-system-x86_64"
        popd >/dev/null
    else
        log_error "pvm_img directory not found"
        return 1
    fi

    log_info "Creating containerd-shim scripts..."
    write_file "/usr/local/bin/containerd-shim-kata-v2" "#!/bin/bash" "# Cloud Hypervisor shim" "KATA_CONF_FILE=/etc/kata-containers/configuration-clh.toml /opt/kata/bin/containerd-shim-kata-clh-v2 \"\$@\""

    write_file "/usr/local/bin/containerd-shim-kata-qemu-v2" "#!/bin/bash" "# QEMU shim" "KATA_CONF_FILE=/etc/kata-containers/configuration-qemu.toml /opt/kata/bin/containerd-shim-kata-v2 \"\$@\""

    log_info "Downloading Cloud Hypervisor..."
    download_file "https://github.com/cloud-hypervisor/cloud-hypervisor/releases/download/v37.0/cloud-hypervisor-static" "/opt/kata/bin/cloud-hypervisor" || return 1
    chmod +x /opt/kata/bin/cloud-hypervisor

    log_info "Setting up Kata Containers config..."
    mkdir -p /etc/kata-containers
    copy_file "/tmp/configuration-clh.toml" "/etc/kata-containers/configuration-clh.toml"
    copy_file "/tmp/configuration-qemu.toml" "/etc/kata-containers/configuration-qemu.toml"
    mkdir -p /opt/kata/share/kata-containers
    copy_file "/tmp/guest-vmlinux" "/opt/kata/share/kata-containers/vmlinux-6.7-pvm"

    log_info "Configuring Containerd..."
    mkdir -p /etc/containerd
    copy_file "/tmp/containerd.toml" "/etc/containerd/config.toml"

    log_info "Enabling PVM kernel module..."
    write_file "/etc/modules-load.d/pvm.conf" "kvm_pvm"

    popd >/dev/null
    log_info "Installation completed successfully."
}

main
