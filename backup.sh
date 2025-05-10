#!/bin/bash

# 错误处理函数
handle_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> error.log
    exit 1
}

# 显示帮助信息
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <directory> <compression> <output_file>
       $(basename "$0") -h|--help

Options:
  -h, --help      Show this help message
  -c, --compress  Specify compression type (none/gzip/bzip2/xz)

Arguments:
  directory       Directory to backup
  compression    Compression algorithm (none, gzip, bzip2, xz)
  output_file    Output filename (will be encrypted)

Example:
  ./backup.sh -c gzip /path/to/dir gzip backup.tar.gz
EOF
    exit 0
}

# 压缩函数
compress() {
    local dir=$1
    local comp=$2
    local output=$3

    case $comp in
        none)
            tar -cf "$output" "$dir" 2>> error.log || handle_error "Tar failed"
            ;;
        gzip)
            tar -czf "$output" "$dir" 2>> error.log || handle_error "Tar gzip failed"
            ;;
        bzip2)
            tar -cjf "$output" "$dir" 2>> error.log || handle_error "Tar bzip2 failed"
            ;;
        xz)
            tar -cJf "$output" "$dir" 2>> error.log || handle_error "Tar xz failed"
            ;;
        *)
            handle_error "Unsupported compression type: $comp"
            ;;
    esac
}

# 加密函数
encrypt() {
    local input=$1
    local output="${input}.enc"

    openssl enc -aes-256-cbc -salt -in "$input" -out "$output" 2>> error.log || handle_error "Encryption failed"
    rm "$input" 2>> error.log || handle_error "Failed to remove temporary file"
    echo "$output"
}

# 主函数
main() {
    # 检查参数
    if [[ $# -eq 0 ]]; then
        show_help
    fi

    # 处理选项
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -c|--compress)
                shift
                compression=$1
                shift
                directory=$1
                shift
                output_file=$1
                shift
                ;;
            *)
                directory=$1
                compression=$2
                output_file=$3
                shift 3
                ;;
        esac
    done

    # 验证参数
    [[ -z "$directory" || -z "$compression" || -z "$output_file" ]] && \
        handle_error "Missing required arguments"

    [[ ! -d "$directory" ]] && \
        handle_error "Directory does not exist: $directory"

    # 执行备份
    compress "$directory" "$compression" "$output_file"
    encrypted_file=$(encrypt "$output_file")

    echo "Backup completed successfully. Encrypted file: $encrypted_file" >> error.log
}

# 执行主函数（抑制所有正常输出）
main "$@" > /dev/null