---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 共有シークレットジョブの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`shared-secrets`ジョブは、特に手動で指定しない限り、インストール全体で使用されるさまざまなシークレットのプロビジョニングを行います。これには次のユーザーが含まれます:

1. 初期rootパスワード
1. すべてのパブリックサービス用の自己署名TLS証明書: GitLab、MinIO、およびレジストリ
1. レジストリ認証証明書
1. MinIO、レジストリ、GitLab Shell、およびGitalyのシークレット
1. RedisおよびPostgreSQLのパスワード
1. SSHホストキー
1. [暗号化された認証情報](https://docs.gitlab.com/administration/encrypted_configuration/)のためのGitLab Railsシークレット

## インストールのコマンドラインオプション {#installation-command-line-options}

次の表に、`helm install`フラグを使用して`--set`コマンドに指定できるすべての設定を示します:

| パラメータ                    | デフォルト                                                    | 説明 |
|------------------------------|------------------------------------------------------------|-------------|
| `enabled`                    | `true`                                                     | [下記参照](#disable-functionality) |
| `env`                        | `production`                                               | Rails環境 |
| `podLabels`                  |                                                            | 追加のポッドラベル。セレクターには使用されません。 |
| `annotations`                |                                                            | 補助ポッド注釈。 |
| `image.pullPolicy`           | `Always`                                                   | **DEPRECATED**（非推奨）: 代わりに`global.kubectl.image.pullPolicy`を使用してください。 |
| `image.pullSecrets`          |                                                            | **DEPRECATED**（非推奨）: 代わりに`global.kubectl.image.pullSecrets`を使用してください。 |
| `image.repository`           | `registry.gitlab.com/gitlab-org/build/cng/kubectl`         | **DEPRECATED**（非推奨）: 代わりに`global.kubectl.image.repository`を使用してください。 |
| `image.tag`                  | `1f8690f03f7aeef27e727396927ab3cc96ac89e7`                 | **DEPRECATED**（非推奨）: 代わりに`global.kubectl.image.tag`を使用してください。 |
| `priorityClassName`          |                                                            | [優先](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)クラスがポッドに割り当てられます |
| `rbac.create`                | `true`                                                     | RBACロールとバインディングを作成 |
| `resources`                  |                                                            | リソースリクエスト、制限 |
| `securityContext.fsGroup`    | `65534`                                                    | ファイルシステムをマウントするユーザーID |
| `securityContext.runAsUser`  | `65534`                                                    | コンテナを実行するユーザーID |
| `selfsign.caSubject`         | `GitLab Helm Chart`                                        | 自己署名CAサブジェクト |
| `selfsign.image.repository`  | `registry.gitlab.com/gitlab-org/build/cnf/cfssl-self-sign` | 自己署名イメージリポジトリ |
| `selfsign.image.pullSecrets` |                                                            | イメージリポジトリのシークレット |
| `selfsign.image.tag`         |                                                            | 自己署名イメージタグ |
| `selfsign.keyAlgorithm`      | `rsa`                                                      | 自己署名証明書キーアルゴリズム |
| `selfsign.keySize`           | `4096`                                                     | 自己署名証明書キーサイズ |
| `serviceAccount.enabled`     | `true`                                                     | ジョブでサービスアカウント名を定義 |
| `serviceAccount.create`      | `true`                                                     | サービスアカウントを作成 |
| `serviceAccount.name`        | `RELEASE_NAME-shared-secrets`                              | ジョブ（および`serviceAccount.create=true`の場合、サービスアカウント自体）で指定するサービスアカウント名 |
| `tolerations`                | `[]`                                                       | ポッドの割り当てに対するTolerationラベル |

## ジョブの設定例 {#job-configuration-examples}

### `tolerations` {#tolerations}

`tolerations`を使用すると、taintされたワーカーノードでポッドをスケジュールできます

`tolerations`の使用例を以下に示します:

```yaml
tolerations:
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
```

## 機能の無効化 {#disable-functionality}

一部のユーザーは、このジョブによって提供される機能を明示的に無効にしたい場合があります。これを行うために、`enabled`フラグをブール値として提供し、`true`をデフォルトに設定しました。

ジョブを無効にするには、`--set shared-secrets.enabled=false`を渡すか、次のYAMLを`-f`フラグを介して`helm`に渡します:

```yaml
shared-secrets:
  enabled: false
```

{{< alert type="note" >}}

このジョブを無効にする場合は、すべてのシークレットを手動で作成し、必要なすべてのシークレットコンテンツを提供**must**（する必要があります）。詳細については、[installation/secrets](../installation/secrets.md#manual-secret-creation-optional)を参照してください。

{{< /alert >}}
