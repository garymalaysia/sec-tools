#!/bin/bash
set -o errexit

case $1 in
    trivy)
        case "$2" in
        image|i|filesystem|fs|repo|repository)
        echo ""
        echo "########################"
        echo " Scanning .........   "
        echo "########################"
        echo ""
        "$@"
        ;;
        esac
    ;;
    semgrep)
        case "$2" in
        --config|-f|-c)
        echo ""
        echo "##############################################################################################################"
        echo "#  Append --config=/home/sec-tool/semgrep-rules/ci --config=/home/sec-tool/semgrep-rules/secrets             #" 
        echo "#  to skip external audit download  Air-gapped area                                                          #"
        echo "##############################################################################################################"
        echo ""
        "$@"
        ;;
        esac
    ;;
    "")
        echo "Available Commands:"
        echo "       [*] trivy"
        echo "       [*] semgrep"
    ;;
esac 
exec "$@"