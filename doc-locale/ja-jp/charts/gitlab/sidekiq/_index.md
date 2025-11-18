---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-Sidekiqチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`sidekiq`サブチャートは、Sidekiqワーカーの設定可能なデプロイを提供し、個々のスケーラビリティと設定を備えた複数の`Deployment`間のキューの分離を提供するように明示的に設計されています。

このチャートは`pods:`のデフォルトの宣言を提供しますが、空の定義を提供すると、*no*ワーカーが表示されます。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされるKubernetesクラスタから到達可能な外部サービスとして提供されるRedis、PostgreSQL、およびGitalyサービスへのアクセスに依存します。

## 設計上の選択 {#design-choices}

このチャートは、複数の`Deployment`とそれに関連付けられた`ConfigMap`を作成します。コマンド長に関する懸念を回避するために、`environment`属性またはコンテナの`command`への追加の引数を使用する代わりに、`ConfigMap`の動作を利用する方が明確であると判断されました。この選択により、多数の`ConfigMap`が生成されますが、各ポッドが何をする必要があるかという非常に明確な定義が提供されます。

## 設定 {#configuration}

`sidekiq`チャートは、チャート全体の[外部サービス](#external-services) 、[チャート全体のデフォルト](#chart-wide-defaults) 、および[ポッドごとの定義](#per-pod-settings)の3つの部分で構成されています。

## インストールのコマンドラインオプション {#installation-command-line-options}

下の表には、`--set`フラグを使用して`helm install`コマンドに指定できる、チャートのすべての構成が記載されています:

| パラメータ                                                | デフォルト                                                      | 説明 |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `annotations`                                            |                                                              | ポッドの注釈 |
| `podLabels`                                              |                                                              | 補足的なポッドのラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                              | このチャートによって作成されたすべてのオブジェクトに適用される補足的なラベル。 |
| `concurrency`                                            | `20`                                                         | Sidekiqのデフォルトの並行処理 |
| `deployment.strategy`                                    | `{}`                                                         | デプロイで使用される更新戦略を構成できます |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                         | ポッドが正常に終了するために必要な、秒単位のオプションの期間。 |
| `enabled`                                                | `true`                                                       | Sidekiqが有効なフラグ |
| `extraContainers`                                        |                                                              | 含めるコンテナのリストを含む複数行のリテラルスタイルの文字列 |
| `extraInitContainers`                                    |                                                              | 含める追加のinitコンテナのリスト |
| `extraVolumeMounts`                                      |                                                              | 構成する追加のボリュームマウントの文字列テンプレート |
| `extraVolumes`                                           |                                                              | 構成する追加のボリュームの文字列テンプレート |
| `extraEnv`                                               |                                                              | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                              | 公開する他のデータソースからの追加の環境変数のリスト |
| `gitaly.serviceName`                                     | `gitaly`                                                     | Gitalyサービス名 |
| `health_checks.port`                                     | `3808`                                                       | ヘルスチェックサーバーのポート |
| `health_checks.listenAddr`                               | `*`                                                          | ヘルスチェックリッスンアドレス。 |
| `hpa.behaviour`                                          | `{scaleDown: {stabilizationWindowSeconds: 300 }}`            | 動作には、アップスケールとダウンスケールの動作の仕様が含まれています（`autoscaling/v2beta2`以上が必要です） |
| `hpa.customMetrics`                                      | `[]`                                                         | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用をオーバーライドします） |
| `hpa.cpu.targetType`                                     | `AverageValue`                                               | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                             | `350m`                                                       | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`                       |                                                              | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                                  |                                                              | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                          |                                                              | オートスケールメモリターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`                    |                                                              | オートスケールメモリターゲット使用率を設定します |
| `hpa.targetAverageValue`                                 |                                                              | **非推奨** オートスケールCPUターゲット値を設定します |
| `keda.enabled`                                           | `false`                                                      | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                         | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                        | リソースを0にスケールバックする前に、最後トリガーがアクティブとレポートされてから待機する期間 |
| `keda.minReplicaCount`                                   |                                                              | KEDAがリソースをスケールダウンするレプリカの最小数。`minReplicas`がデフォルトです |
| `keda.maxReplicaCount`                                   |                                                              | KEDAがリソースをスケールアップするレプリカの最大数。`maxReplicas`がデフォルトです |
| `keda.fallback`                                          |                                                              | KEDAフォールバック構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           |                                                              | KEDAが作成するHPAリソースの名前。`keda-hpa-{scaled-object-name}`がデフォルトです |
| `keda.restoreToOriginalReplicaCount`                     |                                                              | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          |                                                              | アップスケールおよびダウンスケール動作の仕様。`hpa.behavior`がデフォルトです |
| `keda.triggers`                                          |                                                              | ターゲットリソースのスケーリングをアクティブ化するトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーがデフォルトです |
| `minReplicas`                                            | `2`                                                          | レプリカの最小数 |
| `maxReplicas`                                            | `10`                                                         | レプリカの最大数 |
| `maxUnavailable`                                         | `1`                                                          | 使用できなくなるポッドの最大数の制限 |
| `image.pullPolicy`                                       | `Always`                                                     | Sidekiqイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                              | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ee` | Sidekiqイメージリポジトリ |
| `image.tag`                                              |                                                              | Sidekiqイメージタグ付け |
| `init.image.repository`                                  |                                                              | initコンテナイメージ |
| `init.image.tag`                                         |                                                              | initコンテナイメージタグ付け |
| `init.containerSecurityContext`                          |                                                              | initコンテナ固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                       | initコンテナ固有: コンテナを開始するユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initコンテナ固有: プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | initコンテナ固有: コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | initコンテナ固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `logging.format`                                         | `json`                                                       | JSON以外のログの場合は、`text`に設定します |
| `metrics.enabled`                                        | `true`                                                       | メトリクスのエンドポイントをスクレイピングに使用できるようにするかどうか |
| `metrics.port`                                           | `3807`                                                       | メトリクスエンドポイントポート |
| `metrics.listenAddr`                                     | `*`                                                          | メトリクスエンドポイントのリッスンアドレス。 |
| `metrics.path`                                           | `/metrics`                                                   | メトリクスエンドポイントパス |
| `metrics.log_enabled`                                    | `false`                                                      | `sidekiq_exporter.log`に書き込まれるメトリクスサーバーログを有効または無効にします |
| `metrics.podMonitor.enabled`                             | `false`                                                      | メトリクスのスクレイピングを管理するために、ポッドモニターを作成してPrometheus Operatorを有効にする必要があるかどうか |
| `metrics.podMonitor.additionalLabels`                    | `{}`                                                         | ポッドモニターに追加する追加のラベル |
| `metrics.podMonitor.endpointConfig`                      | `{}`                                                         | ポッドモニターの追加のエンドポイント構成 |
| `metrics.annotations`                                    |                                                              | **非推奨** 明示的なメトリクス注釈を設定します。テンプレートコンテンツに置き換えられました。 |
| `metrics.tls.enabled`                                    | `false`                                                      | `metrics/sidekiq_exporter`エンドポイントに対してTLSが有効 |
| `metrics.tls.secretName`                                 | `{Release.Name}-sidekiq-metrics-tls`                         | `metrics/sidekiq_exporter`エンドポイントTLS証明書とキーのシークレット |
| `psql.password.key`                                      | `psql-password`                                              | psqlシークレット内のpsqlパスワードへのキー |
| `psql.password.secret`                                   | `gitlab-postgres`                                            | psqlパスワードシークレット |
| `psql.port`                                              |                                                              | PostgreSQLサーバーのポートを設定します。これは、`global.psql.port`より優先されます。 |
| `redis.serviceName`                                      | `redis`                                                      | Redisサービス名 |
| `resources.requests.cpu`                                 | `900m`                                                       | Sidekiqに必要な最小CPU |
| `resources.requests.memory`                              | `2G`                                                         | Sidekiqに必要な最小メモリ |
| `resources.limits.memory`                                |                                                              | Sidekiqで許可される最大メモリ |
| `timeout`                                                | `25`                                                         | Sidekiqジョブのタイムアウト |
| `tolerations`                                            | `[]`                                                         | ポッド割り当てのTolerationラベル |
| `memoryKiller.daemonMode`                                | `true`                                                       | `false`の場合、従来のメモリキラーモードを使用します |
| `memoryKiller.maxRss`                                    | `2000000`                                                    | 遅延シャットダウンがトリガーされる前の最大RSS（キロバイト単位） |
| `memoryKiller.graceTime`                                 | `900`                                                        | トリガーされたシャットダウンの前に待機する時間（秒単位） |
| `memoryKiller.shutdownWait`                              | `30`                                                         | 既存のジョブが完了するためにトリガーされたシャットダウン後の時間（秒単位） |
| `memoryKiller.hardLimitRss`                              |                                                              | デーモンモードで、即時シャットダウンがトリガーされる前の最大RSS（キロバイト単位） |
| `memoryKiller.checkInterval`                             | `3`                                                          | メモリチェックの間隔時間 |
| `livenessProbe.initialDelaySeconds`                      | `20`                                                         | Livenessプローブを開始するまでの遅延 |
| `livenessProbe.periodSeconds`                            | `60`                                                         | Livenessプローブの実行頻度 |
| `livenessProbe.timeoutSeconds`                           | `30`                                                         | Livenessプローブがタイムアウトしたとき |
| `livenessProbe.successThreshold`                         | `1`                                                          | Livenessプローブが失敗した後、成功したと見なされるための最小連続成功回数 |
| `livenessProbe.failureThreshold`                         | `3`                                                          | Livenessプローブが成功した後、失敗したと見なされるための最小連続失敗回数 |
| `readinessProbe.initialDelaySeconds`                     | `0`                                                          | Readinessプローブを開始するまでの遅延 |
| `readinessProbe.periodSeconds`                           | `10`                                                         | Readinessプローブの実行頻度 |
| `readinessProbe.timeoutSeconds`                          | `2`                                                          | Readinessプローブがタイムアウトしたとき |
| `readinessProbe.successThreshold`                        | `1`                                                          | Readinessプローブが失敗した後、成功したと見なされるための最小連続成功回数 |
| `readinessProbe.failureThreshold`                        | `3`                                                          | Readinessプローブが成功した後、失敗したと見なされるための最小連続失敗回数 |
| `securityContext.fsGroup`                                | `1000`                                                       | ポッドを開始するグループID |
| `securityContext.runAsUser`                              | `1000`                                                       | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                              | ボリュームの所有権とアクセス許可を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                              | コンテナを開始するオーバーライドコンテナの[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | コンテナを開始する特定のセキュリティコンテキストを上書きすることを許可します |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.annotations`                             | `{}`                                                         | ServiceAccountの注釈 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                      | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                      | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                              | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます |
| `priorityClassName`                                      | `""`                                                         | ポッドの`priorityClassName`を構成できるようにします。これは、削除の場合にポッドの優先度を制御するために使用されます |

## チャート構成の例 {#chart-configuration-examples}

### リソース {#resources}

`resources`を使用すると、Sidekiqポッドが消費できるリソース（メモリとCPU）の最小量と最大量を構成できます。

Sidekiqポッドのワークロードは、デプロイによって大きく異なります。一般的に言って、各Sidekiqプロセスは約1つのvCPUと2 GBのメモリを消費すると理解されています。垂直方向のスケーリングは、通常、`vCPU:Memory`のこの`1:2`の比率に合わせる必要があります。

`resources`の使用例を以下に示します:

```yaml
resources:
  limits:
    memory: 5G
  requests:
    memory: 2G
    cpu: 900m
```

### extraEnv {#extraenv}

`extraEnv`を使用して、依存関係コンテナで追加の環境変数を公開します。

たとえば、`SOME_KEY`および`SOME_OTHER_KEY`の環境変数を公開するには、次のようにします:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナが起動したら、`env`コマンドを実行し、変数の名前をgrepして、環境変数が公開されていることを確認します。例: 

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

特定のポッドに対して`extraEnv`を設定することもできます。例: 

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
pods:
  - name: mailers
    queues: mailers
    extraEnv:
      SOME_POD_KEY: some_pod_value
  - name: catchall
```

これにより、`mailers`ポッドのアプリケーションコンテナに対してのみ`SOME_POD_KEY`が設定されます。ポッドレベルの`extraEnv`設定は、[initコンテナ](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)に追加されません。

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで、他のデータソースからの追加の環境変数を公開できます。後続の変数は、Sidekiqポッドごとにオーバーライドできます。

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
pods:
  - name: immediate
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

### extraVolumes {#extravolumes}

`extraVolumes`を使用すると、チャート全体の追加ボリュームを構成できます。

`extraVolumes`の使用例を以下に示します:

```yaml
extraVolumes: |
  - name: example-volume
    persistentVolumeClaim:
      claimName: example-pvc
```

### extraVolumeMounts {#extravolumemounts}

`extraVolumeMounts`を使用すると、チャート全体のすべてのコンテナで追加のvolumeMountsを構成できます。

`extraVolumeMounts`の使用例を以下に示します:

```yaml
extraVolumeMounts: |
  - name: example-volume-mount
    mountPath: /etc/example
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリを認証して、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)にあります。

`pullSecrets`の使用例を以下に示します:

```yaml
image:
  repository: my.sidekiq.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountの注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかは、の設定で制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます。 |

### tolerations {#tolerations}

`tolerations`を使用すると、Taintedワーカーノードでポッドをスケジュールできます

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

### annotations {#annotations}

`annotations`を使用すると、Sidekiqポッドに注釈を追加できます。

`annotations`の使用例を以下に示します:

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## このチャートのCommunity Editionの使用 {#using-the-community-edition-of-this-chart}

デフォルトの場合、HelmチャートではGitLabのEnterprise Editionを使用します。必要に応じて、Community Editionを代わりに使用できます。[2つのエディションの違い](https://about.gitlab.com/install/ce-or-ee/)の詳細については、こちらをご覧ください。

Community Editionを使用するには、`image.repository`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce`に設定します。

## 外部サービス {#external-services}

このチャートは、Webserviceチャートと同じRedis、PostgreSQL、およびGitalyインスタンスにアタッチする必要があります。外部サービスの値は、すべてのSidekiqポッド間で共有される`ConfigMap`に入力されたます。

### Redis {#redis}

```yaml
redis:
  host: rank-racoon-redis
  port: 6379
  sentinels:
    - host: sentinel1.example.com
      port: 26379
  password:
    secret: gitlab-redis
    key: redis-password
```

| 名前                |  型   | デフォルト | 説明 |
|:--------------------|:-------:|:--------|:------------|
| `host`              | 文字列  |         | 使用するデータベースが格納されているRedisサーバーのホスト名。`serviceName`の代わりとして省略できます。Redis Sentinelを使用している場合、`host`属性は、`sentinel.conf`で指定されているクラスタ名に設定する必要があります。 |
| `password.key`      | 文字列  |         | Redisの`password.key`属性は、パスワードを含むシークレット（下記）内のキーの名前を定義します。 |
| `password.secret`   | 文字列  |         | Redisの`password.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。 |
| `port`              | 整数 | `6379`  | Redisサーバーへの接続に使用するポート。 |
| `serviceName`       | 文字列  | `redis` | Redisデータベースを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、RedisをGitLabチャート全体の一部として使用する場合に便利です。 |
| `sentinels.[].host` | 文字列  |         | Redis HA設定用のRedis Sentinelサーバーのホスト名。 |
| `sentinels.[].port` | 整数 | `26379` | Redis Sentinelサーバーへの接続に使用するポート。 |

{{< alert type="note" >}}

現在のRedis Sentinelサポートは、GitLabチャートとは別にデプロイされたSentinelのみをサポートしています。そのため、`redis.install=false`に設定して、GitLabチャートによるRedisのデプロイを無効にする必要があります。また、Redisのパスワードを含むKubernetesシークレットを、GitLabチャートをデプロイする前に手動で作成しておく必要があります。

{{< /alert >}}

### PostgreSQL {#postgresql}

```yaml
psql:
  host: rank-racoon-psql
  serviceName: pgbouncer
  port: 5432
  database: gitlabhq_production
  username: gitlab
  preparedStatements: false
  password:
    secret: gitlab-postgres
    key: psql-password
```

| 名前                 |  型   | デフォルト               | 説明 |
|:---------------------|:-------:|:----------------------|:------------|
| `host`               | 文字列  |                       | 使用するデータベースを持つPostgreSQLサーバーのホスト名。これは、`postgresql.install=true`の場合に省略できます（デフォルトは非本番環境）。 |
| `serviceName`        | 文字列  |                       | PostgreSQLデータベースを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名をテンプレート処理します。 |
| `database`           | 文字列  | `gitlabhq_production` | PostgreSQLサーバーで使用するデータベースの名前。 |
| `password.key`       | 文字列  |                       | PostgreSQLの`password.key`属性は、パスワードを含むシークレット（下記）内のキーの名前を定義します。 |
| `password.secret`    | 文字列  |                       | PostgreSQLの`password.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。 |
| `port`               | 整数 | `5432`                | PostgreSQLサーバーへの接続に使用するポート。 |
| `username`           | 文字列  | `gitlab`              | データベースへの認証に使用するユーザー名。 |
| `preparedStatements` | ブール値 | `false`               | PostgreSQLサーバーとの通信時にプリペアドステートメントを使用するかどうか。 |

Sidekiqデプロイの`dependencies` `initContainer`は、次のことを確認するスクリプトを実行します:

- GitLabの依存関係が使用可能かどうか。
- PostgreSQLのデータベース移行が実行されたかどうか。

これらのスクリプトの動作を制御するには、Sidekiqチャートの`extraEnv`構成キーを使用できます。2つの環境変数がサポートされています:

- `BYPASS_POST_DEPLOYMENT=true`: すべての通常の移行が実行され、デプロイ後の移行のみが保留されている場合、依存関係チェックはパスします
- `BYPASS_SCHEMA_VERSION=true`（推奨されません）: 通常の移行が実行されていない場合でも、依存関係チェックはパスします。この環境変数を使用すると、データベーススキーマがアプリケーションコードの期待値と一致しないため、Railsデプロイが起動後にエラーになる可能性があります。

### Gitaly {#gitaly}

```YAML
gitaly:
  internal:
    names:
      - default
      - default2
  external:
    - name: node1
      hostname: node1.example.com
      port: 8079
  authToken:
    secret: gitaly-secret
    key: token
```

| 名前               |  型   | デフォルト  | 説明 |
|:-------------------|:-------:|:---------|:------------|
| `host`             | 文字列  |          | 使用するGitalyサーバーのホスト名。`serviceName`の代わりとして省略できます。 |
| `serviceName`      | 文字列  | `gitaly` | Gitalyサーバーを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、GitalyをGitLabチャート全体の一部として使用する場合に便利です。 |
| `port`             | 整数 | `8075`   | Gitalyサーバーへの接続に使用するポート。 |
| `authToken.key`    | 文字列  |          | authTokenを含む下のシークレット内のキーの名前。 |
| `authToken.secret` | 文字列  |          | `Secret`は、プル元のKubernetesシークレットの名前を定義します。 |

## メトリクス {#metrics}

デフォルトでは、ポッドごとにPrometheusメトリクスエクスポーターが有効になっています。メトリクスは、[GitLab Prometheusメトリクス](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)が管理者エリアで有効になっている場合にのみ使用できます。エクスポーターは、ポート`3807`の`/metrics`エンドポイントを公開します。メトリクスが有効になっている場合、Prometheusサーバーが公開されたメトリクスを検出してスクレイプできるように、各ポッドに注釈が追加されます。

## チャート全体のデフォルト {#chart-wide-defaults}

ポッドごとに値が表示されない場合、次の値がチャート全体で使用されます。

| 名前                         |  型   | デフォルト   | 説明 |
|:-----------------------------|:-------:|:----------|:------------|
| `concurrency`                | 整数 | `25`      | 同時に処理するタスクの数。 |
| `timeout`                    | 整数 | `4`       | Sidekiqシャットダウンタイムアウト。SidekiqがTERMシグナルを受信してから、プロセスを強制的にシャットダウンするまでの秒数。 |
| `memoryKiller.checkInterval` | 整数 | `3`       | メモリチェックの間隔時間（秒単位） |
| `memoryKiller.maxRss`        | 整数 | `2000000` | 遅延シャットダウンがトリガーされる前の最大RSS（キロバイト単位） |
| `memoryKiller.graceTime`     | 整数 | `900`     | トリガーされたシャットダウンの前に待機する時間（秒単位） |
| `memoryKiller.shutdownWait`  | 整数 | `30`      | 既存のジョブを完了するために、トリガーされたシャットダウン後の時間を秒単位で表します |
| `minReplicas`                | 整数 | `2`       | 最小レプリカ数 |
| `maxReplicas`                | 整数 | `10`      | 最大レプリカ数 |
| `maxUnavailable`             | 整数 | `1`       | 使用不能にするポッドの最大数の制限 |

{{< alert type="note" >}}

[Sidekiqメモリーキラーの詳細なドキュメントを利用できます](https://docs.gitlab.com/administration/sidekiq/sidekiq_memory_killer/) Linuxパッケージのドキュメントに記載されています。

{{< /alert >}}

## ポッドごとの設定 {#per-pod-settings}

`pods`宣言は、ワーカーポッドのすべての属性の宣言を提供します。これらは`Deployment`にテンプレート化され、Sidekiq Redisインスタンスの個々の`ConfigMap`が設定されます。

{{< alert type="note" >}}

この設定は、すべてのキューを監視するように設定された単一のポッドを含めるようにデフォルト設定されています。ポッドセクションを変更すると、*デフォルトのポッドを上書き*して、別のポッドの構成に置き換えられます。デフォルトに加えて、新しいポッドが追加されることはありません。

{{< /alert >}}

| 名前                                  |  型   | デフォルト        | 説明 |
|:--------------------------------------|:-------:|:---------------|:------------|
| `concurrency`                         | 整数 |                | 同時に処理するタスクの数。指定されていない場合は、チャート全体のデフォルトからプルされます。 |
| `name`                                | 文字列  |                | このポッドの`Deployment`と`ConfigMap`の名前を指定するために使用されます。短く保ち、2つのエントリ間で複製しないでください。 |
| `queues`                              | 文字列  |                | [下記を参照](#queues)。 |
| `timeout`                             | 整数 |                | Sidekiqシャットダウンタイムアウト。SidekiqがTERMシグナルを受信してから、プロセスを強制的にシャットダウンするまでの秒数。指定されていない場合は、チャート全体のデフォルトからプルされます。この値は、`terminationGracePeriodSeconds`より小さくする**必要があります**。 |
| `resources`                           |         |                | 各ポッドは独自の`resources`要件を示すことができ、存在する場合は、それに対して作成された`Deployment`に追加されます。これらはKubernetesドキュメントと一致します。 |
| `nodeSelector`                        |         |                | 各ポッドは`nodeSelector`属性で構成でき、存在する場合は、それに対して作成された`Deployment`に追加されます。これらの定義はKubernetesドキュメントと一致します。 |
| `memoryKiller.checkInterval`          | 整数 | `3`            | メモリーチェックの間隔時間 |
| `memoryKiller.maxRss`                 | 整数 | `2000000`      | 指定されたポッドの最大RSSをオーバーライドします。 |
| `memoryKiller.graceTime`              | 整数 | `900`          | 指定されたポッドのトリガーされたシャットダウンまでの待機時間をオーバーライドします |
| `memoryKiller.shutdownWait`           | 整数 | `30`           | 指定されたポッドの既存のジョブを完了するために、トリガーされたシャットダウン後の時間をオーバーライドします |
| `minReplicas`                         | 整数 | `2`            | 最小レプリカ数 |
| `maxReplicas`                         | 整数 | `10`           | 最大レプリカ数 |
| `maxUnavailable`                      | 整数 | `1`            | 使用不能にするポッドの最大数の制限 |
| `podLabels`                           |   マップ   | `{}`           | 補足ポッドラベル。セレクターには使用されません。 |
| `strategy`                            |         | `{}`           | デプロイで使用される更新ストラテジーを構成できます |
| `extraVolumes`                        | 文字列  |                | 指定されたポッドの追加のボリュームを構成します。 |
| `extraVolumeMounts`                   | 文字列  |                | 指定されたポッドの追加のボリュームマウントを構成します。 |
| `priorityClassName`                   | 文字列  | `""`           | ポッド`priorityClassName`を構成できるようにします。これは、削除の場合にポッドの優先度を制御するために使用されます |
| `hpa.customMetrics`                   |  配列  | `[]`           | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用をオーバーライドします） |
| `hpa.cpu.targetType`                  | 文字列  | `AverageValue` | オートスケールCPUターゲットタイプをオーバーライドします。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`          | 文字列  | `350m`         | オートスケールCPUターゲット値をオーバーライドします |
| `hpa.cpu.targetAverageUtilization`    | 整数 |                | オートスケールCPUターゲット使用率をオーバーライドします |
| `hpa.memory.targetType`               | 文字列  |                | オートスケールメモリーターゲットタイプをオーバーライドします。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`       | 文字列  |                | オートスケールメモリーターゲット値をオーバーライドします |
| `hpa.memory.targetAverageUtilization` | 整数 |                | オートスケールメモリーターゲット使用率をオーバーライドします |
| `hpa.targetAverageValue`              | 文字列  |                | **非推奨** オートスケールCPUターゲット値をオーバーライドします |
| `keda.enabled`                        | ブール値 | `false`        | KEDAの有効化をオーバーライドします |
| `keda.pollingInterval`                | 整数 | `30`           | KEDAポーリングの間隔をオーバーライドします |
| `keda.cooldownPeriod`                 | 整数 | `300`          | KEDAクールダウン期間をオーバーライドします |
| `keda.minReplicaCount`                | 整数 |                | KEDAの最小レプリカ数をオーバーライドします |
| `keda.maxReplicaCount`                | 整数 |                | KEDAの最大レプリカ数をオーバーライドします |
| `keda.fallback`                       |   マップ   |                | KEDAフォールバック構成。ドキュメントを参照してください |
| `keda.hpaName`                        | 文字列  |                | KEDA HPA名をオーバーライドします |
| `keda.restoreToOriginalReplicaCount`  | ブール値 |                | 元のレプリカ数を復元できるようにするかどうかを指定しますが削除された後にカウントします |
| `keda.behavior`                       |   マップ   |                | アップスケールとダウンスケールの仕様。デフォルトはです |
| `keda.triggers`                       |  配列  |                | KEDAトリガーをオーバーライドします |
| `extraEnv`                            |   マップ   |                | 公開する追加の環境変数のリスト。チャート全体の値をこれにマージし、ポッドの値が優先されます |
| `extraEnvFrom`                        |   マップ   |                | 公開する他のデータソースからの追加の環境変数のリスト |
| `terminationGracePeriodSeconds`       | 整数 | `30`           | ポッドが正常に終了するために必要なオプションの期間（秒単位）。 |

### キュー {#queues}

`queues`値は、処理されるキューのコンマ区切りのリストを含む文字列です。デフォルトでは、これは設定されておらず、すべてのキューが処理されることを意味します。

文字列にスペースを含めることはできません。`merge,post_receive,process_commit`は機能しますが、`merge, post_receive, process_commit`は機能しません。

ジョブが追加されたが、少なくとも1つのポッドアイテムの一部として表されていないキューは、*処理されません*。すべてのキューの完全なリストについては、GitLabソースのこれらのファイルを参照してください:

1. [`app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml)
1. [`ee/app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml)

`gitlab.sidekiq.pods[].queues`を構成することに加えて、`global.appConfig.sidekiq.routingRules`も構成する必要があります。詳細については、[Sidekiqルーティングルール設定](../../globals.md#sidekiq-routing-rules-settings)を参照してください。

### 例`pod`エントリ {#example-pod-entry}

```YAML
pods:
  - name: immediate
    concurrency: 10
    minReplicas: 2  # defaults to inherited value
    maxReplicas: 10 # defaults to inherited value
    maxUnavailable: 5 # defaults to inherited value
    queues: merge,post_receive,process_commit
    extraVolumeMounts: |
      - name: example-volume-mount
        mountPath: /etc/example
    extraVolumes: |
      - name: example-volume
        persistentVolumeClaim:
          claimName: example-pvc
    resources:
      limits:
        cpu: 800m
        memory: 2Gi
    hpa:
      cpu:
        targetType: Value
        targetAverageValue: 350m
```

### Sidekiq構成の完全な例 {#full-example-of-sidekiq-configuration}

次に示すのは、インポート関連のジョブに個別のSidekiqポッド、エクスポート関連のジョブに個別のRedisインスタンスを使用したSidekiqポッド、およびその他すべてのポッドを使用するSidekiq構成の完全な例です。

```yaml
...
global:
  appConfig:
    sidekiq:
      routingRules:
      - ["feature_category=importers", "import"]
      - ["feature_category=exporters", "export", "queues_shard_extra_shard"]
      - ["*", "default"]
  redis:
    redisYmlOverride:
      queues_shard_extra_shard: ...
...
gitlab:
  sidekiq:
    pods:
    - name: import
      queues: import
    - name: export
      queues: export
      extraEnv:
        SIDEKIQ_SHARD_NAME: queues_shard_extra_shard # to match key in global.redis.redisYmlOverride
    - name: default
...
```

## `networkpolicy`の構成 {#configuring-the-networkpolicy}

このセクションでは、[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この構成はオプションであり、特定のエンドポイントへのポッドのエグレスとイングレスを制限するために使用されます。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定は、ネットワークポリシーを有効にします |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのイングレス接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | イングレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および以下の例を参照してください |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および以下の例を参照してください |

### ネットワークポリシーの例 {#example-network-policy}

Sidekiqサービスは、有効になっている場合はPrometheus exporterに対してのみイングレス接続を必要とし、通常はさまざまな場所へのエグレス接続を必要とします。この例では、次のネットワークポリシーを追加します:

- イングレスリクエストを許可します:
  - `Prometheus`ポッドからポート`3807`へ
- エグレスリクエストを許可します:
  - `kube-dns`からポート`53`へ
  - `gitaly`ポッドからポート`8075`へ
  - `registry`ポッドからポート`5000`へ
  - `kas`ポッドからポート`8153`へ
  - 外部データベース`172.16.0.10/32`からポート`5432`へ
  - 外部Redis `172.16.0.11/32`からポート`6379`へ
  - 外部Elasticsearch `172.16.0.12/32`からポート`443`へ
  - メールゲートウェイ`172.16.0.13/32`からポート`587`へ
  - S3またはSTSのAWS VPCエンドポイントなどのエンドポイントからポート`443`へ`172.16.1.0/24`へ
  - 内部サブネット`172.16.2.0/24`からポート`443`へWebhookを送信します

*提供されている例は単なる例であり、完全ではない可能性があることに注意してください*

{{< alert type="note" >}}

Sidekiqサービスは、ローカルエンドポイントが利用できない場合に、[外部オブジェクトストレージ](../../../advanced/external-object-storage)上のイメージに対してパブリックインターネットへの送信接続を必要とします。

{{< /alert >}}

この例は、`kube-dns`がネームスペース`kube-system`にデプロイされ、`prometheus`がネームスペース`monitoring`にデプロイされ、`nginx-ingress`がネームスペース`nginx-ingress`にデプロイされたという前提に基づいています。

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: monitoring
            podSelector:
              matchLabels:
                app: prometheus
                component: server
                release: gitlab
        ports:
          - port: 3807
  egress:
    enabled: true
    rules:
      - to:
          - podSelector:
              matchLabels:
                app: gitaly
        ports:
          - port: 8075
      - to:
          - podSelector:
              matchLabels:
                app: kas
        ports:
          - port: 8153
      - to:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: kube-system
            podSelector:
              matchLabels:
                k8s-app: kube-dns
        ports:
          - port: 53
            protocol: UDP
      - to:
          - ipBlock:
              cidr: 172.16.0.10/32
        ports:
          - port: 5432
      - to:
          - ipBlock:
              cidr: 172.16.0.11/32
        ports:
          - port: 6379
      - to:
          - ipBlock:
              cidr: 172.16.0.12/32
        ports:
          - port: 25
      - to:
          - ipBlock:
              cidr: 172.16.0.13/32
        ports:
          - port: 443
      - to:
          - ipBlock:
              cidr: 172.16.1.0/24
        ports:
          - port: 443
      - to:
          - ipBlock:
              cidr: 172.16.2.0/24
        ports:
          - port: 443
```

## KEDAの構成 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この構成はオプションであり、カスタムメトリクスまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルト設定されます。

次が当てはまる場合、CPUおよびメモリートリガーは、`hpa`セクションで設定されたCPUおよびメモリーのしきい値に基づいて自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定もゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト | 説明 |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | ブール値 | `false` | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`    | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`   | 最後のアクティブとレポートされたトリガーの後に、リソースを0にスケールバックするまで待機する期間 |
| `minReplicaCount`               | 整数 |         | KEDAがリソースをスケールダウンする最小レプリカ数。デフォルトは`minReplicas`です |
| `maxReplicaCount`               | 整数 |         | KEDAがリソースをスケールアップする最大レプリカ数。デフォルトは`maxReplicas`です |
| `fallback`                      |   マップ   |         | KEDAフォールバック構成。[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  |         | KEDAが作成するHPAリソースの名前。デフォルトは`keda-hpa-{scaled-object-name}`です |
| `restoreToOriginalReplicaCount` | ブール値 |         | ターゲットリソースを、`ScaledObject`が削除された後、元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   |         | アップスケールとダウンスケールの仕様。デフォルトは`hpa.behavior`です |
| `triggers`                      |  配列  |         | ターゲットリソースのスケールをアクティブにするトリガーのリスト。デフォルトは`hpa.cpu`と`hpa.memory`から計算されるトリガーです |
