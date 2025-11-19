---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートを使用したGKE用ワークロードアイデンティティフェデレーション
---

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3434)されました。

{{< /history >}}

チャートでの外部オブジェクトストレージのデフォルト設定では、シークレットキーを使用します。[ワークロードアイデンティティフェデレーションfor GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)を使用すると、短時間のトークンを使用して、Kubernetesクラスタにオブジェクトストレージへのアクセスを許可できます。既存のGKEクラスタがある場合は、[ワークロードアイデンティティフェデレーションを使用するためにノードプールを更新する方法については、Googleのドキュメントを参照してください](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#option_2_node_pool_modification)。

ワークロードIDを使用するには、[`object-storage.yaml`](../../charts/globals.md#connection)シークレットの`google_json_key_string`を省略します:

```yaml
provider: Google
google_project: your-project-id
google_client_email: null  # Will use workload identity
google_json_key_string: null  # Will use workload identity
```

## トラブルシューティング {#troubleshooting}

`iam.gke.io/gcp-service-account`注釈を介して、[KubernetesサービスアカウントがIAMサービスアカウントにリンクされている](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubernetes-sa-to-iam)ことを確認してください。

toolboxポッド内のメタデータエンドポイントにクエリを実行して、ワークロードIDが適切に設定されているかどうかを確認できます。クラスタに関連付けられたサービスアカウントが返されるはずです:

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email
example@your-example-project.iam.gserviceaccount.com
```

このアカウントは、次のスコープにもアクセスできる必要があります:

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/scopes
https://www.googleapis.com/auth/cloud-platform
https://www.googleapis.com/auth/userinfo.email
```
