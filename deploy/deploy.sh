#!/usr/bin/env bash
# Installs the shop into $NAMESPACE: chart from deploy/chart.env, values from
# deploy/values.yaml, images from deploy/images.yaml plus deploy/images.branch.yaml
# (written by deploy/build.sh), feature flags from src/flagd/demo.flagd.json.
#
# Env: NAMESPACE. Requires helm and a kubeconfig for that namespace.
set -euo pipefail
: "${NAMESPACE:?}"
source deploy/chart.env

work=$(mktemp -d)
helm pull "$CHART_NAME" --repo "$CHART_REPO" --version "$CHART_VERSION" --untar --untardir "$work"
# The chart ships flagd's config as a file; use this repository's flags instead.
cp src/flagd/demo.flagd.json "$work/$CHART_NAME/flagd/demo.flagd.json"
flags_sha=$(sha256sum src/flagd/demo.flagd.json | cut -c1-16)

extra=()
[ -f deploy/images.branch.yaml ] && extra+=(-f deploy/images.branch.yaml)

# The repository is the source of truth: --force-conflicts takes back fields
# changed by hand (kubectl set env/edit), which server-side apply would refuse.
helm upgrade --install "$RELEASE_NAME" "$work/$CHART_NAME" \
    --namespace "$NAMESPACE" \
    -f deploy/values.yaml -f deploy/images.yaml "${extra[@]}" \
    --set-string "components.flagd.podAnnotations.sre-lab/flags-sha=$flags_sha" \
    --server-side=true --force-conflicts \
    --history-max 10 --wait --timeout 15m

kubectl get pods -n "$NAMESPACE" -o wide
