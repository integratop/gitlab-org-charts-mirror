#!/bin/bash

# Deploy PostgreSQL using the the CloudNativePG helm chart into the same namespace
# as the GitLab namespace.
# Should currently only be used for vcluster-based review environments to:
#   1. Avoid CRD conflicts.
#   2. Avoid resource conflicts in native review environments where mutliple review deploysments exist in the same namespace.
function deploy_external_postgresql() {
  echo "Installing external PostgreSQL"

  install_cnpg_operator
  create_cnpg_cluster
}

function install_cnpg_operator {
  VERSION_FLAG=""
  if [ -n "${CNPG_CHART_VERSION}" ]; then
    VERSION_FLAG="--version ${CNPG_CHART_VERSION}"
  fi

  helm repo add cnpg https://cloudnative-pg.github.io/charts
  helm upgrade cnpg cnpg/cloudnative-pg \
    --install \
    ${VERSION_FLAG} \
    --namespace ${NAMESPACE} \
    --set config.clusterWide=false \
    --wait \
    --hide-notes
}

function create_cnpg_cluster {
  local image="ghcr.io/cloudnative-pg/postgresql:${CNPG_POSTGRESQL_TAG}"
  local cluster_cr=$(cat <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: gitlab-cluster
  namespace: "${NAMESPACE}"
spec:
  instances: 1
  imageName: "${image}"
  storage:
    size: 3Gi
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"
  bootstrap:
    initdb:
      database: gitlabhq_production
      owner: gitlab
      postInitSQL:
        - CREATE EXTENSION IF NOT EXISTS pg_trgm;
        - CREATE EXTENSION IF NOT EXISTS btree_gist;
        - CREATE EXTENSION IF NOT EXISTS plpgsql;
        - CREATE EXTENSION IF NOT EXISTS amcheck;
        - CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
EOF
)

  # Apply cluster CR with retries because webhook may not be up: https://github.com/cloudnative-pg/charts/issues/674
  # Once applied, wait for PostgreSQL to be ready.
  for i in $(seq 1 5); do
    sleep 5
    if echo "$cluster_cr" | kubectl apply -n "${NAMESPACE}" -f -; then
      kubectl wait --timeout 180s --for=condition=Ready -n "${NAMESPACE}" "clusters/gitlab-cluster"
      return 0
    fi
  done

  return 1
}

function remove_external_postgres() {
    echo "Removing GitLab CNPG Cluster"
    kubectl delete -n "${NAMESPACE}" --wait --ignore-not-found=true cluster gitlab-cluster
    
    echo "Removing CNPG"
    helm uninstall cnpg -n "${NAMESPACE}" --wait --ignore-not-found
}