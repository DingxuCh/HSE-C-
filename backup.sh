#!/bin/bash

# 错误处理函数
handle_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> error.log
    exit 1
}

# 显示帮助信息
show_help() {
    cat << EOF
Usage: $(basename "$0") <directory> <compression> <output_file>
       $(basename "$0") -h|--help

Arguments:
  directory       Directory to backup (must exist)
  compression    Compression algorithm (none/gzip/bzip2/xz)
  output_file    Output filename (will be encrypted)

Examples:
  ./backup.sh /path/to/dir gzip backup.tar.gz
  ./backup.sh /etc none etc-backup.tar
EOF
    exit 0
}

# 压缩函数
compress() {
    local dir=$1
    local comp=$2
    local output=$3

    case $comp in
        none)  tar -cf "$output" "$dir" 2>> error.log ;;
        gzip)  tar -czf "$output" "$dir" 2>> error.log ;;
        bzip2) tar -cjf "$output" "$dir" 2>> error.log ;;
        xz)    tar -cJf "$output" "$dir" 2>> error.log ;;
        *)     handle_error "Unsupported compression: $comp" ;;
    esac || handle_error "Compression failed"
}

# 加密函数
encrypt() {
    openssl enc -aes-256-cbc -salt -in "$1" -out "${1}.enc" 2>> error.log \
        && rm "$1" 2>> error.log \
        || handle_error "Encryption failed"
    echo "${1}.enc"
}

# 主逻辑
main() {
    [[ "$1" = "-h" || "$1" = "--help" ]] && show_help
    [[ $# -ne 3 ]] && handle_error "Usage: $0 <directory> <compression> <output_file>"
    
    local dir=$1 comp=$2 output=$3
    
    [[ ! -d "$dir" ]] && handle_error "Directory not found: $dir"
    
    compress "$dir" "$comp" "$output"
    encrypt "$output" > /dev/null
}

main "$@"
