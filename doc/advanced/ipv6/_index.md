---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure for IPv6 deployments
---

The GitLab charts can be configured for IPv6 clusters. The default configuration relies on a IPv4 network.

## Sample values

We provide an example for GitLab chart values in [`examples/values-ipv6.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-ipv6.yaml)
which can help you to deploy GitLab into a IPv6 single stack cluster.

If you configured a custom IP allowlist (`gitlab.webservice.monitoring.ipWhitelist`),
make sure to update existing IPv4 addresses to their IPv6 representation.

For example, to the IPv4 client with `10.0.0.1` should be mapped to `::10.0.0.1`.
