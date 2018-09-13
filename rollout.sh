#!/bin/bash
# This script updates image(s) for deployment/statefulset/daemonset and
# checks if it is successful and rolls it back if it fails

set -u

conf_dir=$HOME/.k8s-ca

k8s_addr=${PLUGIN_ADDR-$K8S_ADDR}
k8s_user=${PLUGIN_USER-$K8S_USER}
k8s_pass=${PLUGIN_TOKEN-$K8S_TOKEN}
k8s_ca=${PLUGIN_CA-$K8S_CA}

k8s_kind=${PLUGIN_KIND}
k8s_object=${PLUGIN_OBJECT}
k8s_ns=${PLUGIN_NAMESPACE}
k8s_imgs=(${PLUGIN_IMG_NAMES//,/" "})
k8s_cnts=(${PLUGIN_IMG_CNTS//,/" "})
k8s_tags=(${PLUGIN_IMG_TAGS//,/" "})

opt_debug=${PLUGIN_DEBUG}
opt_revert=${PLUGIN_REVERT_IF_FAIL}
opt_logs=${PLUGIN_LOGS_IF_FAIL}
opt_timeout=${PLUGIN_ROLLOUT_TIMEOUT}

###
# Globs
###

log_path="stdout"

E_BAD_ARGS=13
E_FAILED=20
E_AUTH=21
E_DEPLOY=22

# Log messagae prefixes
MSG_SUCCESS="Release successful!"
MSG_AUTH="Using cluster"
MSG_DEPLOY="Updating images for containers"

MSG_E_BAD_ARGS="Invalid arguments. Uneven number of containers, images and tags."
MSG_E_FAILED="Failed to release"
MSG_E_AUTH="Failed to authorize in cluster"
MSG_E_DEPLOY="Failed to deploy"

###
# Functions
###

# Logging function (KO to the rescue)
logEvent() {
    timestamp=`date -R`
    log_msg="$@"

    if [[ $log_path = "stdout" ]]
    then
        echo "[$timestamp] $log_msg"
    else
        echo "[$timestamp] $log_msg" >> $log_path
    fi
}

# Panic function
errorExit () {
    exit_code=$1
    shift
    logEvent "$@"
    exit $exit_code
}

# Authorize in k8s
clusterAuth() {
    if [[ ! -d $conf_dir ]]; then mkdir $conf_dir; fi
    echo -n $k8s_ca | base64 -d > $conf_dir/cluster.crt

    kubectl config set-credentials cluster --password=$k8s_pass --username=$k8s_user > /dev/null
    kubectl config set-cluster cluster --server="$k8s_addr" --embed-certs=false --certificate-authority=$conf_dir/cluster.crt > /dev/null
    kubectl config set-context cluster --user=cluster --cluster=cluster > /dev/null
    kubectl config use-context cluster > /dev/null

    logEvent $MSG_AUTH "'$k8s_addr'"
}

# Update image of k8s object
updateImage() {
    i=0
    update_cmd="kubectl set image $k8s_kind $k8s_object --namespace=$k8s_ns"

    until [[ $i = ${#k8s_cnts[@]} ]]
    do
        update_cmd="$update_cmd ${k8s_cnts[$i]}=${k8s_imgs[$i]}:${k8s_tags[$i]-latest}"
        # A workaround to add container and image names to log message
        MSG_DEPLOY="$MSG_DEPLOY ${k8s_cnts[$i]}=${k8s_imgs[$i]}:${k8s_tags[$i]-latest}"
        let i++
    done

    logEvent $MSG_DEPLOY
    $update_cmd
}

# Watch release status
releaseWatch() {
    kubectl rollout status $k8s_kind $k8s_object --namespace=$k8s_ns -w --request-timeout=${opt_timeout}
}

# Print logs of containers in deployment
printLogs() {
    containers=( `kubectl get $k8s_kind $k8s_object -o=jsonpath='{.spec.template.spec.containers[*].name}'` )
    pods=( `kubectl get pod -o name | grep -oE ${k8s_object}-'[a-zA-Z0-9-]+$'` )

    for pod in ${pods[@]}
    do
        for container in ${containers[@]}
        do
            log_header="###\\n# $pod / $container\\n###\\n"
            echo -e $log_header
            kubectl logs $pod --container=$container
            echo
        done
    done
}

# Rollback a release
releaseRollBack() {
    kubectl rollout undo $k8s_kind $k8s_object --namespace=$k8s_ns
}

###
# main()
###

# Enable debug?
if [[ $opt_debug = true ]]; then set -x; fi

# Checking args
if [[ ${#k8s_imgs[@]} != ${#k8s_cnts[@]} ]]; then exit $E_BAD_ARGS; fi
if [[ ${#k8s_tags[@]} != ${#k8s_imgs[@]} && ${#k8s_tags[@]} != 1 ]]; then exit $E_BAD_ARGS; fi

# Authorize and rollout
clusterAuth || errorExit $E_AUTH $MSG_E_AUTH "$k8s_addr"
updateImage || errorExit $E_DEPLOY $MSG_E_DEPLOY "$k8s_kind" "$k8s_object"
releaseWatch

release_status=$?
if [[ $release_status != 0 && $release_status != 127 ]]
then
    if [[ $opt_logs = true ]]; then printLogs; fi
    if [[ $opt_revert = true ]]; then releaseRollBack; fi
    errorExit $E_FAILED $MSG_E_FAILED
else
    logEvent $MSG_SUCCESS
    exit 0
fi

