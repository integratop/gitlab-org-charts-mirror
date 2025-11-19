---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: FIPS準拠のイメージでGitLabチャートを設定する
---

GitLabは、[FIPS準拠](https://docs.gitlab.com/development/fips_compliance/)バージョンのイメージを提供しており、FIPS対応クラスター上でGitLabを実行できます。

これらのイメージは、[Red Hat Universal Base Images](https://access.redhat.com/articles/4238681)に基づいています。完全に準拠したFIPSモードで機能させるには、すべてのホストがFIPSモード用に設定されている必要があります。

## サンプル値 {#sample-values}

FIPS互換のGitLabデプロイをビルドするのに役立つ[`examples/fips/values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/fips/values.yaml)のGitLabチャート値の例を示します。

FIPS互換のNGINX Ingressコントローラーイメージを使用するための関連する設定を提供する`nginx-ingress.controller`キーの下のコメントに注意してください。このイメージは、[NGINX Ingressコントローラーフォーク](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-ingress-nginx)で管理されています。
