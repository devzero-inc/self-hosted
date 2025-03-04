echo "Checking pods in namespace: devzero"
PODS=$(kubectl get pods -n devzero --no-headers)

if [[ -z "$PODS" ]]; then
    echo "No pods found in namespace  devzero."
    exit 0
fi

COUNT_RUNNING=0
COUNT_PENDING=0
COUNT_SUCCEEDED=0
COUNT_FAILED=0
COUNT_CRASHLOOPBACKOFF=0
COUNT_UNKNOWN=0

while read -r POD_LINE; do
    POD_NAME=$(echo "$POD_LINE" | awk '{print $1}')
    POD_STATUS=$(echo "$POD_LINE" | awk '{print $3}')

    case "$POD_STATUS" in
        Running)
            ((COUNT_RUNNING++))
            ;;
        Pending)
            ((COUNT_PENDING++))
            ;;
        Completed)
            ((COUNT_SUCCEEDED++))
            ;;
        Failed)
            ((COUNT_FAILED++))
            ;;
        CrashLoopBackOff)
            ((COUNT_CRASHLOOPBACKOFF++))
            ;;
        *)
            ((COUNT_UNKNOWN++))
            ;;
    esac
done <<< "$PODS"

echo -e "\nPod status summary in namespace devzero:"
echo "Running: $COUNT_RUNNING"
echo "Pending: $COUNT_PENDING"
echo "Completed: $COUNT_SUCCEEDED"
echo "Failed: $COUNT_FAILED"
echo "CrashLoopBackOff: $COUNT_CRASHLOOPBACKOFF"
echo "Unknown: $COUNT_UNKNOWN"

echo -e "\nIngress in namespace  devzero:"
