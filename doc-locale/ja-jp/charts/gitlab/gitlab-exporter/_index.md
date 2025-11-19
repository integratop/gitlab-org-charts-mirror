---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Exporterチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`gitlab-exporter`サブチャートは、GitLabアプリケーション固有のデータのPrometheusメトリクスを提供します。PostgreSQLと直接通信して、CIビルド、プルミラーなどのデータをクエリして取得します。さらに、Sidekiq APIを使用します。これは、Redisと通信して、Sidekiqキューの状態に関するさまざまなメトリクス（ジョブの数など）を収集します。

## 要件 {#requirements}

このチャートは、RedisおよびPostgreSQLサービスに依存します。これらは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされているKubernetesクラスタから到達可能な外部サービスとして提供されます。

## 設定 {#configuration}

`gitlab-exporter`チャートは、次のように設定されます: [グローバル設定](#global-settings)と[チャートの設定](#chart-settings)。

## インストールコマンドラインオプション {#installation-command-line-options}

以下の表に、`helm install`コマンドに`--set`フラグを使用して指定できる、チャートの構成オプションをすべて示します。

| パラメータ                                                | デフォルト                                                    | 説明 |
|----------------------------------------------------------|------------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                       | ポッドの割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                            |                                                            | ポッドの注釈 |
| `common.labels`                                          | `{}`                                                       | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `podLabels`                                              |                                                            | 追加のポッドラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                            | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `deployment.strategy`                                    | `{}`                                                       | デプロイで使用される更新ストラテジを構成できます |
| `enabled`                                                | `true`                                                     | GitLab Exporterが有効なフラグ |
| `extraContainers`                                        |                                                            | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                    |                                                            | 含める追加のinitコンテナのリスト |
| `extraVolumeMounts`                                      |                                                            | 実行する追加のボリュームマウントのリスト |
| `extraVolumes`                                           |                                                            | 作成する追加のボリュームのリスト |
| `extraEnv`                                               |                                                            | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                            | 公開する他のデータソースからの追加の環境変数のリスト |
| `image.pullPolicy`                                       | `IfNotPresent`                                             | GitLabイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                            | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-exporter` | GitLab Exporterイメージリポジトリ |
| `image.tag`                                              |                                                            | イメージタグ   |
| `init.image.repository`                                  |                                                            | initコンテナイメージ |
| `init.image.tag`                                         |                                                            | initコンテナイメージタグ |
| `init.containerSecurityContext`                          |                                                            | initコンテナ固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                    | initコンテナ固有: プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                     | initコンテナ固有: コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                | initコンテナ固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `metrics.enabled`                                        | `true`                                                     | メトリクスエンドポイントをスクレイプできるようにするかどうか |
| `metrics.port`                                           | `9168`                                                     | メトリクスエンドポイントのポート |
| `metrics.path`                                           | `/metrics`                                                 | メトリクスエンドポイントのパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                    | Prometheus Operatorがメトリクスのスクレイピングを管理できるようにServiceMonitorを作成するかどうか。これを有効にすると、`prometheus.io`スクレイピングアノテーションが削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                       | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                       | ServiceMonitorの追加のエンドポイント設定 |
| `metrics.annotations`                                    |                                                            | **非推奨** 明示的なメトリクス注釈を設定します。テンプレートコンテンツに置き換えられました。 |
| `priorityClassName`                                      |                                                            | ポッドに割り当てられる[Priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `resources.requests.cpu`                                 | `75m`                                                      | GitLab Exporterの最小CPU |
| `resources.requests.memory`                              | `100M`                                                     | GitLab Exporterの最小メモリ |
| `serviceLabels`                                          | `{}`                                                       | 補足サービスラベル |
| `service.externalPort`                                   | `9168`                                                     | GitLab Exporterが公開するポート |
| `service.internalPort`                                   | `9168`                                                     | GitLab Exporterの内部ポート |
| `service.name`                                           | `gitlab-exporter`                                          | GitLab Exporterサービス名 |
| `service.type`                                           | `ClusterIP`                                                | GitLab Exporterサービスタイプ |
| `serviceAccount.annotations`                             | `{}`                                                       | ServiceAccount注釈 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                    | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                    | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                    | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                            | ServiceAccountの名前。設定しない場合、チャートのフルネームが使用されます |
| `securityContext.fsGroup`                                | `1000`                                                     | ポッドを開始するグループID |
| `securityContext.runAsUser`                              | `1000`                                                     | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                            | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                           | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                            | コンテナの起動時に適用される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドする |
| `containerSecurityContext.runAsUser`                     | `1000`                                                     | コンテナを開始する特定のセキュリティコンテキストユーザーIDのオーバーライドを許可します |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                    | コンテナのプロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `false`                                                    | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `tolerations`                                            | `[]`                                                       | ポッド割り当ての容認ラベル |
| `psql.port`                                              |                                                            | PostgreSQLサーバーポートを設定します。これは、`global.psql.port`よりも優先されます。 |
| `tls.enabled`                                            | `false`                                                    | GitLab Exporter TLSが有効 |
| `tls.secretName`                                         | `{Release.Name}-gitlab-exporter-tls`                       | GitLab Exporter TLSシークレット。[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を指している必要があります。 |
| `listenAddr`                                             | `*`                                                       | GitLab Exporterのlistenアドレス。 |

## チャート構成の例 {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv`を使用すると、ポッド内のすべてのコンテナで追加の環境変数を公開できます。

`extraEnv`の使用例を以下に示します:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナの起動時に、環境変数が公開されていることを確認できます:

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで、他のデータソースからの追加の環境変数を公開できます。

`extraEnvFrom`の使用例を以下に示します:

```yaml
extraEnvFrom:
  MY_NODE_NAME:
    fieldRef:
      fieldPath: spec.nodeName
  MY_CPU_REQUEST:
    resourceFieldRef:
      containerName: test-container
      resource: requests.cpu
  SECRET_THING:
    secretKeyRef:
      name: special-secret
      key: special_token
      # optional: boolean
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに対して認証して、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)にあります。

`pullSecrets`の使用例を以下に示します:

```YAML
image:
  repository: my.image.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccount注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかは、で制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定しない場合、チャートのフルネームが使用されます。 |

### アフィニティ {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

### 注釈 {#annotations}

`annotations`を使用すると、注釈をGitLab Exporterポッドに追加できます。例: 

```YAML
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## グローバル設定 {#global-settings}

いくつかの一般的なグローバル設定は、チャート間で共有されます。GitLabやレジストリのホスト名など、一般的な構成オプションについては、[グローバルドキュメント](../../globals.md)を参照してください。

## チャートの設定 {#chart-settings}

次の値は、GitLab Exporterポッドを構成するために使用されます。

### metrics.enabled {#metricsenabled}

デフォルトでは、ポッドは`/metrics`でメトリクスエンドポイントを公開します。メトリクスが有効になっている場合、Prometheusサーバーが公開されたメトリクスを検出してスクレイプできるように、注釈が各ポッドに追加されます。
