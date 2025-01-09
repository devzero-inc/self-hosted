#!/bin/bash

NAMESPACE="devzero"

fetch_pod_details() {
    local pod_name="$1"
    local namespace="$2"

    echo -e "\nFetching logs for pod: $pod_name"
    kubectl logs "$pod_name" -n "$namespace"

    echo -e "\nFetching description for pod: $pod_name"
    kubectl describe pod "$pod_name" -n "$namespace"
}

check_service_reachability() {
    local service_name="$1"
    local namespace="$2"
    local service_port="$3"

    echo "Forwarding port for service: $service_name..."
    kubectl port-forward svc/"$service_name" "$service_port:$service_port" -n "$namespace" &> /tmp/port-forward.log &
    local port_forward_pid=$!

    sleep 5

    curl -s --connect-timeout 5 "http://localhost:$service_port" &> /dev/null
    if [[ $? -eq 0 ]]; then
        ((reachable_count++))
    else
        ((not_reachable_count++))
    fi

    kill $port_forward_pid &> /dev/null
    wait $port_forward_pid 2>/dev/null
}

check_ingresses() {
    echo -e "\nChecking ingresses in namespace: $NAMESPACE"
    INGRESS=$(kubectl get ingress -n "$NAMESPACE" --no-headers)

    if [[ -z "$INGRESS" ]]; then
        echo "No ingresses found in namespace $NAMESPACE."
        return
    fi

    while read -r INGRESS_LINE; do
        INGRESS_NAME=$(echo "$INGRESS_LINE" | awk '{print $1}')
        HOSTS=$(echo "$INGRESS_LINE" | awk '{print $3}')

        echo "Ingress: $INGRESS_NAME, Host(s): $HOSTS"
        echo "Checking connectivity to $HOSTS..."
        curl -s -o /dev/null -w "%{http_code}" "http://$HOSTS"
        if [[ $? -eq 0 ]]; then
            echo " - Accessible"
        else
            echo " - Unreachable"
        fi
    done <<< "$INGRESS"
}

echo "Checking pods in namespace: $NAMESPACE"
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers)

if [[ -z "$PODS" ]]; then
    echo "No pods found in namespace $NAMESPACE."
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
            fetch_pod_details "$POD_NAME" "$NAMESPACE"
            ((COUNT_FAILED++))
            ;;
        CrashLoopBackOff)
            ((COUNT_CRASHLOOPBACKOFF++))
            ;;
        *)
            echo "Pod $POD_NAME has an unknown status: $POD_STATUS."
            ((COUNT_UNKNOWN++))
            ;;
    esac
done <<< "$PODS"

echo -e "\nPod status summary in namespace $NAMESPACE:"
echo "Running: $COUNT_RUNNING"
echo "Pending: $COUNT_PENDING"
echo "Completed: $COUNT_SUCCEEDED"
echo "Failed: $COUNT_FAILED"
echo "CrashLoopBackOff: $COUNT_CRASHLOOPBACKOFF"
echo "Unknown: $COUNT_UNKNOWN"

echo

check_ingresses

echo

reachable_count=0
not_reachable_count=0

echo "Checking services in namespace: $NAMESPACE"
SERVICES=$(kubectl get svc -n "$NAMESPACE" --no-headers)

if [[ -z "$SERVICES" ]]; then
    echo "No services found in namespace $NAMESPACE."
    exit 0
fi

while read -r SVC_LINE; do
    SVC_NAME=$(echo "$SVC_LINE" | awk '{print $1}')
    SVC_PORTS=$(echo "$SVC_LINE" | awk '{print $5}')

    SVC_PORT=$(echo "$SVC_PORTS" | sed 's|/.*||' | awk -F, '{print $1}')

    if [[ -n "$SVC_PORT" ]]; then
        check_service_reachability "$SVC_NAME" "$NAMESPACE" "$SVC_PORT"
    else
        echo "No valid ports found for service $SVC_NAME. Skipping."
    fi
done <<< "$SERVICES"

echo "Summary of services:"
echo "Reachable services: $reachable_count"
echo "Not reachable services: $not_reachable_count"