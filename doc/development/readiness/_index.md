---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Contribute to Helm chart development
---

## Adding new charts

If a new component is about to be added, first you should evaluate if a
community or vendor chart can be used or [forked](#when-to-fork-upstream-charts).

To add a new component the order of preference should be to:

1. Reuse an existing community or vendor chart.
1. Fork an existing community or vendor chart.
1. Add a new GitLab owned chart.

### Community or vendor charts

Using or forking community or vendor charts should be the preferred approach
to add new components to GitLab chart.

### Guidelines for forking

1. A chart should only be forked if there are some cases where it is needed to extend
   the functionality of a chart in such a way that an upstream may not accept.
1. If a given chart expects that sensitive communication secrets will be presented
   from within environment, such as passwords or cryptographic keys,
   [we prefer to use `initContainers`](../architecture/decisions.md#preference-of-secrets-in-initcontainer-over-environment).

