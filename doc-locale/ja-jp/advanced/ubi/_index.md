---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: UBIベースのイメージでGitLabチャートを設定する
---

GitLabは、イメージの[Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)バージョンを提供しており、標準イメージをUBIベースのイメージに置き換えることができます。これらのイメージは、`-ubi`拡張子を持つ標準イメージと同じタグを使用します。

{{< alert type="note" >}}

GitLab 17.3より前のUBIベースのイメージは、`-ubi8`拡張子を使用します。

{{< /alert >}}

GitLabチャートは、UBIに基づいていないサードパーティのイメージを使用します。これらのイメージは主に、Redis、PostgreSQLなどの外部サービスをGitLabに提供します。UBIのみに基づくGitLabインスタンスをデプロイする場合は、内部サービスを無効にし、外部デプロイまたはサービスを使用する必要があります。

無効にして外部から提供する必要があるサービスは次のとおりです:

- PostgreSQL
- MinIO（オブジェクトストア）
- Redis

無効にする必要のあるサービスは次のとおりです:

- CertManager (Let's Encryptインテグレーション)
- Prometheus
- GitLab Runner

## サンプル値 {#sample-values}

純粋なUBI GitLabデプロイをビルドするのに役立つ[`examples/ubi/values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/ubi/values.yaml)のGitLabチャート値の例を提供します。
