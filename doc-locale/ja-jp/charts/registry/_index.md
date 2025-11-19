---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`registry`サブチャートは、完全にクラウドネイティブなGitLabのKubernetesへのデプロイに、registryコンポーネントを提供します。このサブチャートは[アップストリームチャート](https://github.com/docker/distribution-library-image)をベースにしており、GitLabの[コンテナRegistry](https://gitlab.com/gitlab-org/container-registry)が含まれています。

このチャートは、主に以下の3つの部分で構成されています:

- [サービス](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml)、
- [デプロイ](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml)、
- [ConfigMap](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/configmap.yaml)。

すべての設定は、`ConfigMap`から入力された`Deployment`に提供される`/etc/docker/registry/config.yml`変数を使用して、[レジストリの設定ドキュメント](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads)に従って処理されます。`ConfigMap`はアップストリームのデフォルトをオーバーライドしますが、[それらに基づいています](https://github.com/docker/distribution-library-image/blob/master/config-example.yml)。詳細については、以下をご覧ください:

- [`distribution/cmd/registry/config-example.yml`](https://github.com/docker/distribution/blob/master/cmd/registry/config-example.yml)
- [`distribution-library-image/config-example.yml`](https://github.com/docker/distribution-library-image/blob/master/config-example.yml)

## 設計の選択 {#design-choices}

インスタンスの簡単なスケールを可能にし、[ローリングアップデート](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)を可能にするために、`Deployment`デプロイがこのチャートのデプロイ方法として選択されました。

このチャートは、2つの必須シークレットと1つのオプションを使用します:

### 必須 {#required}

- `global.registry.certificate.secret`: 関連付けられたGitLabインスタンスによって提供される認証トークンを検証するための公開CA証明書バンドルを含むグローバルシークレット。GitLabを認証エンドポイントとして使用する方法については、[ドキュメント](https://docs.gitlab.com/administration/packages/container_registry/#use-an-external-container-registry-with-gitlab-as-an-auth-endpoint)を参照してください。
- `global.registry.httpSecret.secret`: registryポッド間の[共有シークレット](https://distribution.github.io/distribution/about/configuration/#http)を含むグローバルシークレット。

### 任意 {#optional}

- `profiling.stackdriver.credentials.secret`: Stackdriverのプロファイリングが有効になっていて、明示的なサービスアカウントの認証情報を提供する必要がある場合、このシークレット（`credentials`キー（デフォルト））の値は、GCPサービスアカウントのJSON認証情報です。GKEを使用しており、[ワークロードID](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)を使用して（またはノードサービスアカウントを使用している場合は、お勧めしません）、ワークロードにサービスアカウントを提供している場合、このシークレットは不要であり、提供しないでください。いずれの場合も、サービスアカウントには、ロール`roles/cloudprofiler.agent`または同等の[手動権限](https://cloud.google.com/profiler/docs/iam#roles)が必要です

## 設定 {#configuration}

以下に、設定の主要なセクションをすべて説明します。親チャートから設定する場合、これらの値は次のようになります:

```yaml
registry:
  enabled:
  maintenance:
    readonly:
      enabled: false
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
  image:
    tag: 'v4.15.2-gitlab'
    pullPolicy: IfNotPresent
  annotations:
  service:
    type: ClusterIP
    name: registry
  httpSecret:
    secret:
    key:
  authEndpoint:
  tokenIssuer:
  certificate:
    secret: gitlab-registry
    key: registry-auth.crt
  deployment:
    terminationGracePeriodSeconds: 30
  draintimeout: '0'
  hpa:
    minReplicas: 2
    maxReplicas: 10
    cpu:
      targetAverageUtilization: 75
    behavior:
      scaleDown:
        stabilizationWindowSeconds: 300
  storage:
    secret:
    key: storage
    extraKey:
  validation:
    disabled: true
    manifests:
      referencelimit: 0
      payloadsizelimit: 0
      urls:
        allow: []
        deny: []
  notifications: {}
  tolerations: []
  affinity: {}
  ingress:
    enabled: false
    tls:
      enabled: true
      secretName: redis
    annotations:
    configureCertmanager:
    proxyReadTimeout:
    proxyBodySize:
    proxyBuffering:
  networkpolicy:
    enabled: false
    egress:
      enabled: false
      rules: []
    ingress:
      enabled: false
      rules: []
  serviceAccount:
    create: false
    automountServiceAccountToken: false
  tls:
    enabled: false
    secretName:
    verify: true
    caSecretName:
    cipherSuites:
```

このチャートをスタンドアロンとしてデプロイすることを選択した場合は、最上位レベルで`registry`を削除します。

## インストールパラメータ {#installation-parameters}

| パラメータ                                                | デフォルト                                                              | 説明 |
|----------------------------------------------------------|----------------------------------------------------------------------|-------------|
| `annotations`                                            |                                                                      | ポッドの注釈 |
| `podLabels`                                              |                                                                      | 補足的なポッドラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                                      | このチャートによって作成されたすべてのオブジェクトに適用される補足的なラベル。 |
| `authAutoRedirect`                                       | `true`                                                               | 認証自動リダイレクト（Windowsクライアントが動作するにはtrueである必要があります） |
| `authEndpoint`                                           | `global.hosts.gitlab.name`                                           | 認証エンドポイント（ホストとポートのみ） |
| `certificate.secret`                                     | `gitlab-registry`                                                    | JWT certificate |
| `debug.addr.port`                                        | `5001`                                                               | デバッグポート  |
| `debug.tls.enabled`                                      | `false`                                                              | registryのデバッグポートに対してTLSを有効にします。有効になっている場合、メトリクスエンドポイントだけでなく、実稼働状態と準備状況のプローブにも影響します |
| `debug.tls.secretName`                                   |                                                                      | registryのデバッグエンドポイントの有効なcertificateとキーを含むKubernetes TLSシークレットの名前。設定されていない場合、`debug.tls.enabled=true` - デバッグTLS設定は、デフォルトでregistryのTLS certificateを共有します。 |
| `debug.prometheus.enabled`                               | `false`                                                              | **非推奨** `metrics.enabled`を使用 |
| `debug.prometheus.path`                                  | `""`                                                                 | **非推奨** `metrics.path`を使用 |
| `metrics.enabled`                                        | `false`                                                              | メトリクスエンドポイントをスクレイプするために使用可能にする必要がある場合 |
| `metrics.path`                                           | `/metrics`                                                           | メトリクスエンドポイントのパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                              | Prometheusオペレーターがメトリクスのスクレイプを管理できるようにサービスモニターを作成する必要がある場合は、これを有効にすると`prometheus.io`のスクレイプ注釈が削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                                 | サービスモニターに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                                 | サービスモニターの追加のエンドポイント設定 |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                                 | ポッドが正常に終了するために必要なオプションの秒単位の期間。 |
| `deployment.strategy`                                    | `{}`                                                                 | デプロイで使用される更新戦略を設定できます |
| `draintimeout`                                           | `'0'`                                                                | SIGTERMシグナルを受信した後、HTTP接続をドレインするまで待機する時間（例: `'10s'`） |
| `relativeurls`                                           | `false`                                                              | registryがLocationヘッダーに相対URLを返すようにします。 |
| `enabled`                                                | `true`                                                               | registryフラグを有効にする |
| `api.enabled`                                            | `true`                                                               | サービス、デプロイ、HPA、およびPDBリソースを有効にします。 |
| `extraContainers`                                        |                                                                      | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                    |                                                                      | 含める追加のinitコンテナのリスト |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`                    | 動作には、アップスケールとダウンスケールの仕様が含まれています（`autoscaling/v2beta2`以上が必要です） |
| `hpa.customMetrics`                                      | `[]`                                                                 | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で設定された平均CPU使用率のデフォルトの使用をオーバーライドします） |
| `hpa.cpu.targetType`                                     | `Utilization`                                                        | オートスケールCPUターゲットの種類を設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                             |                                                                      | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`                       | `75`                                                                 | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                                  |                                                                      | オートスケールメモリターゲットの種類を設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                          |                                                                      | オートスケールメモリターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`                    |                                                                      | オートスケールメモリターゲット使用率を設定します |
| `hpa.minReplicas`                                        | `2`                                                                  | レプリカの最小数 |
| `hpa.maxReplicas`                                        | `10`                                                                 | レプリカの最大数 |
| `httpSecret`                                             |                                                                      | Httpsシークレット |
| `extraEnvFrom`                                           |                                                                      | 公開する他のデータソースからの追加の環境変数のリスト |
| `image.pullPolicy`                                       |                                                                      | registryイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                                      | イメージrepositoryに使用するシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry` | registryイメージ |
| `image.tag`                                              | `v4.15.2-gitlab`                                                     | 使用するイメージのバージョン |
| `init.image.repository`                                  |                                                                      | initContainerイメージ |
| `init.image.tag`                                         |                                                                      | initContainerイメージタグ |
| `init.containerSecurityContext`                          |                                                                      | initContainer固有の[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                               | initContainer固有: コンテナを開始するユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                              | initContainer固有: プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                               | initContainer固有: コンテナを非ルートユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                          | initContainer固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `keda.enabled`                                           | `false`                                                              | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                                 | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                                | リソースを0にスケールバックする前に、アクティブとレポートされた最後のトリガーの後に待機する期間 |
| `keda.minReplicaCount`                                   | `hpa.minReplicas`                                                    | KEDAがリソースをダウンスケールするレプリカの最小数。 |
| `keda.maxReplicaCount`                                   | `hpa.maxReplicas`                                                    | KEDAがリソースをアップスケールするレプリカの最大数。 |
| `keda.fallback`                                          |                                                                      | KEDAフォールバック設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                                      | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                     |                                                                      | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          | `hpa.behavior`                                                       | アップスケールとダウンスケールの動作に関する仕様。 |
| `keda.triggers`                                          |                                                                      | ターゲットリソースのスケールをアクティブにするトリガーのリストは、`hpa.cpu`と`hpa.memory`から計算されたトリガーにデフォルト設定されます |
| `log`                                                    | `{level: info, fields: {service: registry}}`                         | ログオプションを設定する |
| `minio.bucket`                                           | `global.registry.bucket`                                             | 従来のregistryバケット名 |
| `maintenance.readonly.enabled`                           | `false`                                                              | registryの読み取り専用モードを有効にします |
| `maintenance.uploadpurging.enabled`                      | `true`                                                               | アップロードのパージを有効にする |
| `maintenance.uploadpurging.age`                          | `168h`                                                               | 指定された期間より古いアップロードをパージする |
| `maintenance.uploadpurging.interval`                     | `24h`                                                                | アップロードのパージが実行される頻度 |
| `maintenance.uploadpurging.dryrun`                       | `false`                                                              | 削除せずに、パージされるアップロードのみをリストします |
| `priorityClassName`                                      |                                                                      | ポッドに割り当てられる[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `reporting.sentry.enabled`                               | `false`                                                              | Sentryを使用したレポートを有効にします |
| `reporting.sentry.dsn`                                   |                                                                      | Sentry DSN（データソース名） |
| `reporting.sentry.environment`                           |                                                                      | [Sentry環境](https://docs.sentry.io/concepts/key-terms/environments/)を参照してください |
| `profiling.stackdriver.enabled`                          | `false`                                                              | Stackdriverを使用した継続的なプロファイリングを有効にする |
| `profiling.stackdriver.credentials.secret`               | `gitlab-registry-profiling-creds`                                    | 認証情報を含むシークレットの名前 |
| `profiling.stackdriver.credentials.key`                  | `credentials`                                                        | 認証情報が保存されているシークレットキー |
| `profiling.stackdriver.service`                          | `RELEASE-registry`（テンプレート化されたサービス名）                          | プロファイルを記録するStackdriverサービスの名前 |
| `profiling.stackdriver.projectid`                        | 実行中のGCPプロジェクト                                            | プロファイルをレポートするGCPプロジェクト |
| `database.configure`                                     | `false`                                                              | 有効にせずに、registryチャートにデータベース設定を設定します。[既存のregistryをインポートする](metadata_database.md#enable-for-and-import-existing-registries)場合に必要です。 |
| `database.enabled`                                       | `false`                                                              | メタデータデータベースを有効にします。これは試験的な機能であり、本番環境で使用しないでください。 |
| `database.host`                                          | `global.psql.host`                                                   | データベースサーバーのホスト名。 |
| `database.port`                                          | `global.psql.port`                                                   | データベースサーバーのポート。 |
| `database.user`                                          |                                                                      | データベースのユーザー名。 |
| `database.password.secret`                               | `RELEASE-registry-database-password`                                 | データベースパスワードを含むシークレットの名前。 |
| `database.password.key`                                  | `password`                                                           | データベースパスワードが保存されているシークレットキー。 |
| `database.name`                                          |                                                                      | データベース名。 |
| `database.sslmode`                                       |                                                                      | SSLモード。`disable`、`allow`、`prefer`、`require`、`verify-ca`、または`verify-full`のいずれかです。 |
| `database.ssl.secret`                                    | `global.psql.ssl.secret`                                             | クライアント証明書、キー、および認証局を含むシークレット。デフォルトは、mainのPostgreSQL SSLシークレットです。 |
| `database.ssl.clientCertificate`                         | `global.psql.ssl.clientCertificate`                                  | クライアント証明書を参照するシークレット内のキー。 |
| `database.ssl.clientKey`                                 | `global.psql.ssl.clientKey`                                          | クライアントキーを参照するシークレット内のキー。 |
| `database.ssl.serverCA`                                  | `global.psql.ssl.serverCA`                                           | 認証局（CA）を参照するシークレット内のキー。 |
| `database.connecttimeout`                                | `0`                                                                  | 接続を待機する最大時間。ゼロまたは指定されていない場合は、無期限に待機することを意味します。 |
| `database.draintimeout`                                  | `0`                                                                  | シャットダウン時にすべての接続をドレインするまで待機する最大時間。ゼロまたは指定されていない場合は、無期限に待機することを意味します。 |
| `database.preparedstatements`                            | `false`                                                              | 準備されたステートメントを有効にします。PgBouncerとの互換性のために、デフォルトでは無効になっています。 |
| `database.primary`                                       | `false`                                                              | ターゲットのプライマリデータベースサーバー。これは、registry `database.migrations`の実行時にターゲットとする専用のFQDNを指定するために使用されます。指定されていない場合、`database.migrations`の実行には`host`が使用されます。 |
| `database.pool.maxidle`                                  | `0`                                                                  | アイドル接続プール内の接続の最大数。`maxopen`が`maxidle`より小さい場合、`maxidle`は`maxopen`制限に合わせて削減されます。ゼロまたは指定されていない場合は、アイドル接続がないことを意味します。 |
| `database.pool.maxopen`                                  | `0`                                                                  | データベースへのオープン接続の最大数。`maxopen`が`maxidle`より小さい場合、`maxidle`は`maxopen`制限に合わせて削減されます。ゼロまたは指定されていない場合は、無制限のオープン接続を意味します。 |
| `database.pool.maxlifetime`                              | `0`                                                                  | 接続を再利用できる最大時間。期限切れの接続は、再利用する前に遅延して閉じられる場合があります。ゼロまたは指定されていない場合は、無制限の再利用を意味します。 |
| `database.pool.maxidletime`                              | `0`                                                                  | 接続がアイドル状態になる可能性がある最大時間。期限切れの接続は、再利用する前に遅延して閉じられる場合があります。ゼロまたは指定されていない場合は、無制限の期間を意味します。 |
| `database.loadBalancing.enabled`                         | `false`                                                              | データベースのロードバランシングを有効にします。これは試験的な機能であり、本番環境で使用しないでください。 |
| `database.loadBalancing.nameserver.host`                 | `localhost`                                                          | DNSレコードの検索に使用するネームサーバーのホスト。 |
| `database.loadBalancing.nameserver.port`                 | `8600`                                                               | DNSレコードの検索に使用するネームサーバーのポート。 |
| `database.loadBalancing.record`                          |                                                                      | 検索するSRVレコード。このオプションは、サービスディスカバリが機能するために必要です。 |
| `database.loadBalancing.replicaCheckInterval`            | `1m`                                                                 | レプリカのステータスをチェックする間隔の最小時間。 |
| `database.migrations.enabled`                            | `true`                                                               | チャートの最初のデプロイおよびアップグレード時に、移行ジョブが自動的に移行を実行するように有効にします。移行は、実行中のRegistryポッド内から手動で実行することもできます。 |
| `database.migrations.activeDeadlineSeconds`              | `3600`                                                               | 移行ジョブで[activeDeadlineSeconds](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)を設定します。 |
| `database.migrations.annotations`                        | `{}`                                                                 | 移行ジョブに追加する追加の注釈。 |
| `database.migrations.backoffLimit`                       | `6`                                                                  | 移行ジョブで[backoffLimit](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)を設定します。 |
| `database.backgroundMigrations.enabled`                  | `false`                                                              | データベースのバックグラウンド移行を有効にします。これは、Registryメタデータデータベースの試験的な機能です。本番環境では使用しないでください。動作方法の詳細な説明については、[仕様](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-background-migrations.md?ref_type=heads)を参照してください。 |
| `database.backgroundMigrations.jobInterval`              |                                                                      | 各バックグラウンド移行ジョブワーカーの実行間のスリープ間隔。指定されていない場合、[レジストリによってデフォルト値が設定されます](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations)。 |
| `database.backgroundMigrations.maxJobRetries`            |                                                                      | 失敗したバックグラウンド移行ジョブの最大再試行回数。指定されていない場合、[レジストリによってデフォルト値が設定されます](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations)。 |
| `database.metrics.enabled`                               | `false`                                                              | `true`に設定すると、データベースメトリクスの収集が有効になります。これは試験的な機能であり、本番環境で使用しないでください。分散ロックには、registry 4.27.0以降、メタデータデータベース（`database.enabled: true`）およびRedis （`redis.cache.enabled: true`）が必要です。 |
| `database.metrics.interval`                              | `10s`                                                                | データベースからメトリクスを収集する間隔。 |
| `database.metrics.leaseDuration`                         | `30s`                                                                | メトリクスコレクターによってRedisロックが保持される期間。同じインスタンスによる継続的な収集を保証するには、`interval`よりも長くする必要があります。 |
| `gc.disabled`                                            | `true`                                                               | `true`に設定すると、オンラインGCワーカーが無効になります。 |
| `gc.maxbackoff`                                          | `24h`                                                                | エラーが発生した場合にワーカーの実行間でスリープするために使用される最大指数バックオフ期間。`gc.noidlebackoff`が`true`でない限り、処理するタスクがない場合にも適用されます。これは絶対最大値ではなく、最大33％のランダム化されたジッター係数が常に追加されることに注意してください。 |
| `gc.noidlebackoff`                                       | `false`                                                              | `true`に設定すると、処理するタスクがない場合にワーカーの実行間で指数バックオフが無効になります。 |
| `gc.transactiontimeout`                                  | `10s`                                                                | 各ワーカー実行のデータベーストランザクションタイムアウト。各ワーカーは、開始時にデータベーストランザクションを開始します。このタイムアウトを超過すると、停止または長時間実行されるトランザクションを回避するために、ワーカーの実行はキャンセルされます。 |
| `gc.blobs.disabled`                                      | `false`                                                              | `true`に設定すると、blobのGCワーカーが無効になります。 |
| `gc.blobs.interval`                                      | `5s`                                                                 | 各ワーカー実行間の初期スリープ間隔。 |
| `gc.blobs.storagetimeout`                                | `5s`                                                                 | ストレージ操作のタイムアウト。ストレージバックエンドで、ぶら下がっているblobを削除するリクエストの期間を制限するために使用されます。 |
| `gc.manifests.disabled`                                  | `false`                                                              | `true`に設定すると、マニフェストのGCワーカーが無効になります。 |
| `gc.manifests.interval`                                  | `5s`                                                                 | 各ワーカー実行間の初期スリープ間隔。 |
| `gc.reviewafter`                                         | `24h`                                                                | ガベージコレクターがレビューのためにレコードをピックアップするまでの最小時間。`-1`は待機しないことを意味します。 |
| `securityContext.fsGroup`                                | `1000`                                                               | ポッドの起動に使用するグループID。 |
| `securityContext.runAsUser`                              | `1000`                                                               | ポッドの起動に使用するユーザーID。 |
| `securityContext.fsGroupChangePolicy`                    |                                                                      | ボリュームの所有権と許可を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                                     | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                                      | コンテナの起動に使用する[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします。 |
| `containerSecurityContext.runAsUser`                     | `1000`                                                               | コンテナの起動に使用する特定のセキュリティコンテキストユーザーIDを上書きできるようにします。 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                              | Gitalyコンテナのプロセスがその親プロセスよりも多くの権限を取得できるかどうかを制御します。 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                               | コンテナを非ルートユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                          | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                              | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                              | ServiceAccountを使用するかどうかを示します。 |
| `serviceLabels`                                          | `{}`                                                                 | 追加のサービスラベル。 |
| `tokenService`                                           | `container_registry`                                                 | JWTトークンサービス。 |
| `tokenIssuer`                                            | `gitlab-issuer`                                                      | JWTトークン発行者。 |
| `tolerations`                                            | `[]`                                                                 | ポッドの割り当てに使用するTolerationラベル |
| `affinity`                                               | `{}`                                                                 | ポッドの割り当てのAffinityルール。 |
| `middleware.storage`                                     |                                                                      | ミドルウェアストレージの設定レイヤー（たとえば、[S3](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#example-middleware-configuration)）。 |
| `redis.cache.enabled`                                    | `false`                                                              | `true`に設定すると、Redisキャッシュが有効になります。この機能は、[メタデータデータベース](#database)が有効になっていることが前提です。設定されたRedisインスタンスにリポジトリメタデータがキャッシュされます。 |
| `redis.cache.host`                                       | `<Redis URL>`                                                        | Redisインスタンスのホスト名。空の場合、値は`global.redis.host:global.redis.port`として入力されます。 |
| `redis.cache.port`                                       | `6379`                                                               | Redisインスタンスのポート。 |
| `redis.cache.cluster`                                    | `[]`                                                                 | ホストとポートを持つアドレスのリスト。 |
| `redis.cache.sentinels`                                  | `[]`                                                                 | ホストとポートを持つリストセンチネル。 |
| `redis.cache.mainname`                                   |                                                                      | メインサーバー名。センチネルにのみ適用されます。 |
| `redis.cache.username`                                   |                                                                      | Redisインスタンスへの接続に使用されるユーザー名。 |
| `redis.cache.password.enabled`                           | `false`                                                              | レジストリで使用されるRedisキャッシュがパスワードで保護されているかどうかを示します。 |
| `redis.cache.password.secret`                            | `gitlab-redis-secret`                                                | Redisパスワードを含むシークレットの名前。`shared-secrets`機能が有効になっている場合、これが提供されていない場合は自動的に作成されます。 |
| `redis.cache.password.key`                               | `redis-password`                                                     | Redisパスワードが格納されているシークレットキー。 |
| `redis.cache.sentinelpassword.enabled`                   | `false`                                                              | Redisセンチネルがパスワードで保護されているかどうかを示します。`redis.cache.sentinelpassword`が空の場合、`global.redis.sentinelAuth`の値が使用されます。`redis.cache.sentinels`が定義されている場合にのみ使用されます。 |
| `redis.cache.sentinelpassword.secret`                    | `gitlab-redis-secret`                                                | Redisセンチネルパスワードを含むシークレットの名前。 |
| `redis.cache.sentinelpassword.key`                       | `redis-sentinel-password`                                            | Redisセンチネルパスワードが格納されているシークレットキー。 |
| `redis.cache.db`                                         | `0`                                                                  | 各接続に使用するデータベースの名前。 |
| `redis.cache.dialtimeout`                                | `0s`                                                                 | Redisインスタンスへの接続のタイムアウト。デフォルトではタイムアウトはありません。 |
| `redis.cache.readtimeout`                                | `0s`                                                                 | Redisインスタンスからの読み取りのタイムアウト。デフォルトではタイムアウトはありません。 |
| `redis.cache.writetimeout`                               | `0s`                                                                 | Redisインスタンスへの書き込みのタイムアウト。デフォルトではタイムアウトはありません。 |
| `redis.cache.tls.enabled`                                | `false`                                                              | `true`に設定して、TLSを有効にします。 |
| `redis.cache.tls.insecure`                               | `false`                                                              | TLS経由で接続するときにサーバー名の検証を無効にするには、`true`に設定します。 |
| `redis.cache.pool.size`                                  | `10`                                                                 | ソケット接続の最大数。デフォルトは10接続です。 |
| `redis.cache.pool.maxlifetime`                           | `1h`                                                                 | クライアントが接続をリタイアする接続経過時間。デフォルトでは、古い接続は閉じません。 |
| `redis.cache.pool.idletimeout`                           | `300s`                                                               | 非アクティブな接続を閉じるまで待機する時間。 |
| `redis.rateLimiting.enabled`                             | `false`                                                              | `true`に設定すると、Redisレート制限が有効になります。この機能は開発中です。 |
| `redis.rateLimiting.host`                                | `<Redis URL>`                                                        | Redisインスタンスのホスト名。空の場合、値は`global.redis.host:global.redis.port`として入力されます。 |
| `redis.rateLimiting.port`                                | `6379`                                                               | Redisインスタンスのポート。 |
| `redis.rateLimiting.cluster`                             | `[]`                                                                 | ホストとポートを持つアドレスのリスト。 |
| `redis.rateLimiting.sentinels`                           | `[]`                                                                 | ホストとポートを持つリストセンチネル。 |
| `redis.rateLimiting.mainname`                            |                                                                      | メインサーバー名。センチネルにのみ適用されます。 |
| `redis.rateLimiting.username`                            |                                                                      | Redisインスタンスへの接続に使用されるユーザー名。 |
| `redis.rateLimiting.password.enabled`                    | `false`                                                              | Redisインスタンスがパスワードで保護されているかどうかを示します。 |
| `redis.rateLimiting.password.secret`                     | `gitlab-redis-secret`                                                | Redisパスワードを含むシークレットの名前。`shared-secrets`機能が有効になっている場合、これが提供されていない場合は自動的に作成されます。 |
| `redis.rateLimiting.password.key`                        | `redis-password`                                                     | Redisパスワードが格納されているシークレットキー。 |
| `redis.rateLimiting.sentinelpassword.enabled`                   | `false`                                                              | Redisセンチネルがパスワードで保護されているかどうかを示します。`redis.rateLimiting.sentinelpassword`が空の場合、`global.redis.sentinelAuth`の値が使用されます。`redis.rateLimiting.sentinels`が定義されている場合にのみ使用されます。 |
| `redis.rateLimiting.sentinelpassword.secret`                    | `gitlab-redis-secret`                                                | Redisセンチネルパスワードを含むシークレットの名前。 |
| `redis.rateLimiting.sentinelpassword.key`                       | `redis-sentinel-password`                                            | Redisセンチネルパスワードが格納されているシークレットキー。 |
| `redis.rateLimiting.db`                                  | `0`                                                                  | 各接続に使用するデータベースの名前。 |
| `redis.rateLimiting.dialtimeout`                         | `0s`                                                                 | Redisインスタンスへの接続のタイムアウト。デフォルトではタイムアウトはありません。 |
| `redis.rateLimiting.readtimeout`                         | `0s`                                                                 | Redisインスタンスからの読み取りのタイムアウト。デフォルトではタイムアウトはありません。 |
| `redis.rateLimiting.writetimeout`                        | `0s`                                                                 | Redisインスタンスへの書き込みのタイムアウト。デフォルトではタイムアウトはありません。 |
| `redis.rateLimiting.tls.enabled`                         | `false`                                                              | `true`に設定して、TLSを有効にします。 |
| `redis.rateLimiting.tls.insecure`                        | `false`                                                              | TLS経由で接続するときにサーバー名の検証を無効にするには、`true`に設定します。 |
| `redis.rateLimiting.pool.size`                           | `10`                                                                 | ソケット接続の最大数。 |
| `redis.rateLimiting.pool.maxlifetime`                    | `1h`                                                                 | クライアントが接続をリタイアする接続経過時間。デフォルトでは、古い接続は閉じません。 |
| `redis.rateLimiting.pool.idletimeout`                    | `300s`                                                               | 非アクティブな接続を閉じるまで待機する時間。 |
| `redis.loadBalancing.enabled`                            | `false`                                                              | `true`に設定すると、[ロードバランシング](#load-balancing)のRedis接続が有効になります。 |
| `redis.loadBalancing.host`                               | `<Redis URL>`                                                        | Redisインスタンスのホスト名。空の場合、値は`global.redis.host:global.redis.port`として入力されます。 |
| `redis.loadBalancing.port`                               | `6379`                                                               | Redisインスタンスのポート。 |
| `redis.loadBalancing.cluster`                            | `[]`                                                                 | ホストとポートを持つアドレスのリスト。 |
| `redis.loadBalancing.sentinels`                          | `[]`                                                                 | ホストとポートを持つリストセンチネル。 |
| `redis.loadBalancing.mainname`                           |                                                                      | メインサーバー名。センチネルにのみ適用されます。 |
| `redis.loadBalancing.username`                           |                                                                      | Redisインスタンスへの接続に使用されるユーザー名。 |
| `redis.loadBalancing.password.enabled`                   | `false`                                                              | Redisインスタンスがパスワードで保護されているかどうかを示します。 |
| `redis.loadBalancing.password.secret`                    | `gitlab-redis-secret`                                                | Redisパスワードを含むシークレットの名前。`shared-secrets`機能が有効になっている場合、これが提供されていない場合は自動的に作成されます。 |
| `redis.loadBalancing.password.key`                       | `redis-password`                                                     | Redisパスワードが格納されているシークレットキー。 |
| `redis.loadBalancing.db`                                 | `0`                                                                  | 各接続に使用するデータベースの名前。 |
| `redis.loadBalancing.dialtimeout`                        | `0s`                                                                 | Redisインスタンスへの接続のタイムアウト。デフォルトではタイムアウトはありません。 |
| `redis.loadBalancing.readtimeout`                        | `0s`                                                                 | Redisインスタンスからの読み取りのタイムアウト。デフォルトではタイムアウトはありません。 |
| `redis.loadBalancing.writetimeout`                       | `0s`                                                                 | Redisインスタンスへの書き込みのタイムアウト。デフォルトではタイムアウトはありません。 |
| `redis.loadBalancing.tls.enabled`                        | `false`                                                              | `true`に設定して、TLSを有効にします。 |
| `redis.loadBalancing.tls.insecure`                       | `false`                                                              | TLS経由で接続するときにサーバー名の検証を無効にするには、`true`に設定します。 |
| `redis.loadBalancing.pool.size`                          | `10`                                                                 | ソケット接続の最大数。 |
| `redis.loadBalancing.pool.maxlifetime`                   | `1h`                                                                 | クライアントが接続をリタイアする接続経過時間。デフォルトでは、古い接続は閉じません。 |
| `redis.loadBalancing.pool.idletimeout`                   | `300s`                                                               | 非アクティブな接続を閉じるまで待機する時間。 |

## チャート設定の例 {#chart-configuration-examples}

### `pullSecrets` {#pullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに対して認証を行い、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)にあります。

`pullSecrets`の使用例を以下に示します:

```yaml
image:
  repository: my.registry.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | ブール値 | `false` |  の設定は、PodにデフォルトのServiceAccountアクセストークンをマウントする必要があるかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |

### `tolerations` {#tolerations}

`tolerations`を使用すると、taintされたワーカーノードでポッドをスケジュールできます。

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

### `affinity` {#affinity}

`affinity`はオプションのパラメータで、以下の一方または両方を設定できます:

- 次の`podAntiAffinity`ルール:
  - `topology key`に対応する式に一致するポッドと同じドメインにポッドをスケジュールしません。
  - `podAntiAffinity`ルールの2つのモードを設定します。必須（`requiredDuringSchedulingIgnoredDuringExecution`）と推奨（`preferredDuringSchedulingIgnoredDuringExecution`）`antiAffinity`変数を`values.yaml`で使用して、推奨モードが適用されるように設定を`soft`に設定するか、必須モードが適用されるように`hard`に設定します。
- 次の`nodeAffinity`ルール:
  - 特定のゾーンに属するノードにポッドをスケジュールします。
  - `nodeAffinity`ルールの2つのモードを設定します。必須（`requiredDuringSchedulingIgnoredDuringExecution`）と推奨（`preferredDuringSchedulingIgnoredDuringExecution`）。`soft`に設定すると、推奨モードが適用されます。`hard`に設定すると、必須モードが適用されます。このルールは、`registry`チャート、および`gitlab`チャートとそのすべてのサブチャート（`webservice`および`sidekiq`を除く）に対してのみ実装されます。

`nodeAffinity`は、[`In`演算子](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators)のみを実装します。

詳細については、[関連するKubernetesドキュメント](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)を参照してください。

次の例では、`affinity`を設定し、`nodeAffinity`と`antiAffinity`の両方が`hard`に設定されています:

```yaml
nodeAffinity: "hard"
antiAffinity: "hard"
affinity:
  nodeAffinity:
    key: "test.com/zone"
    values:
    - us-east1-a
    - us-east1-b
  podAntiAffinity:
    topologyKey: "test.com/hostname"
```

### `annotations` {#annotations}

`annotations`を使用すると、レジストリポッドに注釈を追加できます。

以下に`annotations`の使用例を示します。

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## サブチャートを有効にする {#enable-the-sub-chart}

コンパートメント化されたサブチャートを実装するために選択した方法には、特定のデプロイで不要なコンポーネントを無効にする機能が含まれています。このため、最初に決定する必要がある設定は`enabled`です。

デフォルトでは、レジストリはすぐに使用できます。無効にする場合は、`enabled: false`を設定します。

## アプリケーションに必要なリソースを有効にする {#enable-resources-required-for-the-application}

Service、デプロイメント、HPA、およびPDBリソースは、`registry.api.enabled`値（デフォルト: `true`）によって有効になります。

この設定がGitLab.comでどのように使用されるかの詳細については、[コンテナレジストリのデプロイメント後の移行（GitLab.com上）](../../development/registry_post_deployment_migrations_on_gitlab_com.md)をご覧ください。

## `image`の設定 {#configuring-the-image}

このセクションでは、このサブチャートの[デプロイメント](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml)で使用されるコンテナイメージの設定について詳しく説明します。レジストリと`pullPolicy`に含まれるバージョンを変更できます。

デフォルト設定:

- `tag: 'v4.15.2-gitlab'`
- `pullPolicy: 'IfNotPresent'`

## `service`の設定 {#configuring-the-service}

このセクションでは、[サービス](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml)の名前と種類を制御します。これらの設定は、[`values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/values.yaml)によって入力されます。

デフォルトでは、サービスは次のように構成されています:

| 名前             |  型  | デフォルト     | 説明 |
|:-----------------|:------:|:------------|:------------|
| `name`           | 文字列 | `registry`  | サービスの名前を構成します |
| `type`           | 文字列 | `ClusterIP` | サービスの種類を構成します |
| `externalPort`   |  整数   | `5000`      | サービスによって公開されるポート。 |
| `internalPort`   |  整数   | `5000`      | サービスからのリクエストを受け入れるためにポッドによって利用されるポート。 |
| `clusterIP`      | 文字列 | `null`      | 必要に応じてカスタムCluster IPを構成できます。 |
| `loadBalancerIP` | 文字列 | `null`      | 必要に応じてカスタムロードバランサーIPアドレスを構成できます。 |

## `ingress`を設定する {#configuring-the-ingress}

このセクションでは、レジストリIngressを制御します。

| 名前                   |  型   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | 文字列  |         | `apiVersion`フィールドで使用する値。 |
| `annotations`          | 文字列  |         | このフィールドは、[Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)の標準`annotations`と完全に一致します。 |
| `configureCertmanager` | ブール値 |         | Ingress注釈`cert-manager.io/issuer`および`acme.cert-manager.io/http01-edit-in-place`を切り替えます。詳細については、[GitLab PagesのTLS要件](../../installation/tls.md)を参照してください。 |
| `enabled`              | ブール値 | `false` | サービスがサポートするIngressオブジェクトを作成するかどうかを制御する設定。`false`の場合、`global.ingress.enabled`設定が使用されます。 |
| `tls.enabled`          | ブール値 | `true`  | `false`に設定すると、レジストリサブチャートのTLSが無効になります。これは、`ingress-level`でTLS終端を使用できない場合（Ingressコントローラーの前にTLS終端プロキシーがある場合など）に主に役立ちます。 |
| `tls.secretName`       | 文字列  |         | レジストリURLの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定されていない場合、代わりに`global.ingress.tls.secretName`が使用されます。デフォルトでは設定されていません。 |
| `tls.cipherSuites`     |  配列  | `[]`    | コンテナレジストリがTLSハンドシェイク中にクライアントに提示する必要がある暗号スイートのリスト。 |

## TLSを設定する {#configuring-tls}

コンテナレジストリは、`nginx-ingress`を含む他のコンポーネントとの通信を保護するTLSをサポートします。

TLSを設定するための前提条件:

- TLS証明書には、共通名（CN）またはサブジェクト代替名（SAN）にレジストリサービスホスト名（たとえば、`RELEASE-registry.default.svc`）を含める必要があります。
- TLS証明書を生成した後:
  - [Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を作成します。
  - `ca.crt`キーを使用して、TLS証明書のCA証明書のみを含む別のシークレットを作成します。

TLSを有効にするには、次の手順に従ってください:

1. `registry.tls.enabled`を`true`に設定します。
1. `global.hosts.registry.protocol`を`https`に設定します。
1. Secret名を、それに応じて`registry.tls.secretName`と`global.certificates.customCAs`に渡します。

`registry.tls.verify`が`true`の場合、CA証明書Secret名を`registry.tls.caSecretName`に渡す必要があります。これは、自己署名証明書およびカスタムCAに必要です。このSecretは、NGINXがレジストリのTLS証明書を検証するために使用します。

例: 

```yaml
global:
  certificates:
    customCAs:
    - secret: registry-tls-ca
  hosts:
    registry:
      protocol: https

registry:
  tls:
    enabled: true
    secretName: registry-tls
    verify: true
    caSecretName: registry-tls-ca
```

### コンテナレジストリの暗号スイート {#container-registry-cipher-suites}

通常、`tls.cipherSuites`オプションは、レジストリがスタンドアロンモードでデプロイされているか、最新の暗号スイートをサポートしていないデフォルト以外のイングレスが使用されている非常に特殊な構成でのみ使用してください。標準的なGitLabのデプロイでは、NGINXイングレスは、コンテナレジストリバックエンドでサポートされている最高のTLSバージョン（現在はTLS1.3）を選択します。TLS1.3では暗号の構成は許可されておらず、デフォルトで安全です。何らかの理由でTLS1.3が利用できない場合、コンテナレジストリが使用しているデフォルトのTLS1.2暗号リストもNGINXイングレスのデフォルト設定と互換性があり、同様に安全です。

### デバッグポートのTLSの構成 {#configuring-tls-for-the-debug-port}

レジストリのデバッグポートもTLSをサポートします。デバッグポートは、Kubernetesの活性と準備状況のヘルスチェック、およびPrometheusの`/metrics`エンドポイントの公開に使用されます（有効な場合）。

TLSを有効にするには、`registry.debug.tls.enabled`を`true`に設定します。[Kubernetes TLS Secret](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)は、デバッグポートのTLS構成での使用専用として、`registry.debug.tls.secretName`で提供できます。専用のSecretが指定されていない場合、デバッグ構成は`registry.tls.secretName`をレジストリの通常のTLS構成と共有するようにフォールバックします。

Prometheusが`https`を使用して`/metrics/`エンドポイントをスクレイプするには、証明書のCommonName属性またはSubjectAlternativeNameエントリの追加構成が必要です。これらの要件については、[TLS対応エンドポイントをスクレイプするためのPrometheusの構成](../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)を参照してください。

## `networkpolicy`の構成 {#configuring-the-networkpolicy}

このセクションでは、レジストリの[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この構成はオプションであり、特定のエンドポイントへのレジストリのエグレスとイングレスを制限するために使用します。また、特定のエンドポイントへのイングレスを制限します。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定は、レジストリの`NetworkPolicy`を有効にします |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのイングレス接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | イングレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および以下の例を参照してください。 |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および以下の例を参照してください。 |

### すべての内部エンドポイントへの接続を防止するためのポリシーの例 {#example-policy-for-preventing-connections-to-all-internal-endpoints}

レジストリサービスは通常、オブジェクトストレージ、Dockerクライアントからのイングレス接続、およびDNSルックアップ用のkube-DNSへのエグレス接続を必要とします。これにより、レジストリサービスに次のネットワーク制限が追加されます:

- イングレスリクエストを許可します:
  - `sidekiq`、`webservice`、および`nginx-ingress`からのポッドからポート`5000`へ
  - `Prometheus`ポッドからポート`9235`へ
- エグレスリクエストを許可します:
  - `kube-dns`からポート`53`へ
  - S3またはSTSのAWS VPCエンドポイントなどのエンドポイントからポート`443`への`172.16.1.0/24`
  - インターネット`0.0.0.0/0`からポート`443`へ

_注: レジストリサービスには、[外部オブジェクトストレージ](../../advanced/external-object-storage)上のイメージへの送信接続が必要です（エンドポイントが使用されていない場合）_

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
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 5000
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
          - port: 9235
      - from:
          - podSelector:
              matchLabels:
                app: sidekiq
        ports:
          - port: 5000
      - from:
          - podSelector:
              matchLabels:
                app: webservice
        ports:
          - port: 5000
  egress:
    enabled: true
    rules:
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
              cidr: 172.16.1.0/24
        ports:
          - port: 443
      - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
            - 10.0.0.0/8
```

## KEDAの構成 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この構成はオプションであり、カスタムまたは外部メトリクスに基づくオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルトでフォールバックします。

以下がtrueの場合、`hpa`セクションで設定されたCPUとメモリのしきい値に基づいて、CPUおよびメモリートリガーが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定もゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | リソースを0にスケールバックする前に、最後のトリガーがアクティブであるとレポートされてから待機する期間 |
| `minReplicaCount`               | 整数 | `hpa.minReplicas`               | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `maxReplicaCount`               | 整数 | `hpa.maxReplicas`               | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `fallback`                      |   マップ   |                                 | KEDAのフォールバック構成。詳細については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください。 |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | ターゲットリソースを`ScaledObject`の削除後に元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | アップスケールとダウンスケールの動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケールをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`から算出されたトリガーがデフォルトになります |

### すべての内部エンドポイントへの接続を防止するためのポリシーの例 {#example-policy-for-preventing-connections-to-all-internal-endpoints-1}

レジストリサービスは通常、オブジェクトストレージ、Dockerクライアントからのイングレス接続、およびDNSルックアップ用のkube-DNSへのエグレス接続を必要とします。これにより、レジストリサービスに次のネットワーク制限が追加されます:

- `10.0.0.0/8`ポート53のローカルネットワークへのすべてのエグレスリクエストが許可されます（kubeDNSの場合）
- `10.0.0.0/8`上のローカルネットワークへの他のエグレスリクエストは制限されています
- `10.0.0.0/8`の外部へのエグレスリクエストは許可されます

_注: レジストリサービスには、[外部オブジェクトストレージ](../../advanced/external-object-storage)上のイメージへの送信接続が必要です_

```yaml
networkpolicy:
  enabled: true
  egress:
    enabled: true
    # The following rules enable traffic to all external
    # endpoints, except the local
    # network (except DNS requests)
    rules:
      - to:
        - ipBlock:
            cidr: 10.0.0.0/8
        ports:
        - port: 53
          protocol: UDP
      - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
            - 10.0.0.0/8
```

## レジストリ構成の定義 {#defining-the-registry-configuration}

このチャートの次のプロパティは、基盤となる[registry](https://hub.docker.com/_/registry/)コンテナの構成に関係しています。GitLabとのインテグレーションのための最も重要な値のみが公開されます。このインテグレーションでは、JWT [authentication](https://distribution.github.io/distribution/spec/auth/token/)を介してレジストリへの認証を制御する、[Docker Distribution](https://github.com/docker/distribution)の`auth.token.x`設定を利用します。

### `httpSecret` {#httpsecret}

フィールド`httpSecret`は、`secret`と`key`の2つの項目を含むマップです。

この参照がキーの内容は、[registry](https://hub.docker.com/_/registry/)の`http.secret`値に対応します。この値には、暗号で生成されたランダムな文字列が入力された必要があります。

`shared-secrets`ジョブは、提供されていない場合、このSecretを自動的に作成します。これは、安全に生成された128文字の英数字文字列で、base64でエンコードされます。

このSecretを手動で作成するには:

```shell
kubectl create secret generic gitlab-registry-httpsecret --from-literal=secret=strongrandomstring
```

### 通知Secret {#notification-secret}

通知Secretは、Geoがプライマリサイトとセカンダリサイト間でContainerレジストリデータを同期するのを支援するなど、さまざまな方法でGitLabアプリケーションにコールバックするために利用されます。

`notificationSecret` secretオブジェクトは、`shared-secrets`機能が有効になっている場合、提供されていなければ自動的に作成されます。

このSecretを手動で作成するには:

```shell
kubectl create secret generic gitlab-registry-notification --from-literal=secret=[\"strongrandomstring\"]
```

次に、以下を設定します

```yaml
global:
  # To provide your own secret
  registry:
    notificationSecret:
        secret: gitlab-registry-notification
        key: secret

  # If utilising Geo, and wishing to sync the container registry.
  # Define this in the primary site configs only.
  geo:
    registry:
      replication:
        enabled: true
        primaryApiUrl: <URL to primary registry>
```

`secret`の値が、上記で作成されたSecretの名前に設定されていることを確認します

### RedisキャッシュSecret {#redis-cache-secret}

`global.redis.auth.enabled`が`true`に設定されている場合、RedisキャッシュSecretが使用されます。

`shared-secrets`機能が有効になっている場合、`gitlab-redis-secret` Secretオブジェクトは、提供されていない場合に自動的に作成されます。

このSecretを手動で作成するには、[Redisパスワードの手順](../../installation/secrets.md#redis-password)を参照してください。

### `authEndpoint` {#authendpoint}

`authEndpoint`フィールドは文字列で、[registry](https://hub.docker.com/_/registry/)が認証するGitLabインスタンスへのURLを提供します。

値には、プロトコルとホスト名のみを含める必要があります。チャートテンプレートは、必要なリクエストパスを自動的に追加します。結果の値は、コンテナ内の`auth.token.realm`に入力されたされます。例: `authEndpoint: "https://gitlab.example.com"`。

デフォルトでは、このフィールドには、[グローバル設定](../globals.md)によって設定されたGitLabホスト名の構成が入力されたされます。

### `certificate` {#certificate}

`certificate`フィールドは、`secret`と`key`の2つの項目を含むマップです。

`secret`は、GitLabインスタンスによって作成されたトークンの検証に使用される証明書バンドルを格納する[Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)の名前を含む文字列です。

`key`は、[registry](https://hub.docker.com/_/registry/)コンテナに`auth.token.rootcertbundle`として提供される証明書バンドルを格納する`Secret`の`key`の名前です。

デフォルトの例:

```yaml
certificate:
  secret: gitlab-registry
  key: registry-auth.crt
```

### 準備状況プローブと活性プローブ {#readiness-and-liveness-probe}

デフォルトでは、デバッグポートであるポート`5001`の`/debug/health`をチェックするために構成された準備状況プローブと活性プローブがあります。

### `validation` {#validation}

`validation`フィールドは、レジストリ内のDockerイメージの検証プロセスを制御するマップです。イメージの検証が有効になっている場合、検証スタンザ内の`manifests.urls.allow`フィールドでこれらのレイヤーのURLを許可するように明示的に設定されていない限り、レジストリは外部レイヤーを持つWindowsイメージを拒否します。

検証はマニフェストのプッシュ中にのみ行われるため、レジストリにすでに存在するイメージは、このセクションの値の変更の影響を受けません。

イメージの検証はデフォルトでオフになっています。

イメージの検証を有効にするには、`registry.validation.disabled: false`を明示的に設定する必要があります。

#### `manifests` {#manifests}

`manifests`フィールドを使用すると、マニフェストに固有の検証ポリシーを構成できます。

`urls`セクションには、`allow`フィールドと`deny`フィールドの両方が含まれています。検証に合格するためのURLを含むマニフェストレイヤーの場合、そのレイヤーは`allow`フィールドの正規表現のいずれかと一致し、`deny`フィールドの正規表現とは一致してはいけません。

|        名前        | 型  | デフォルト | 説明 |
|:------------------:|:-----:|:--------|:-----------:|
|  `referencelimit`  |  整数  | `0`     | 1つのマニフェストが持つことができる、レイヤー、イメージ構成、その他のマニフェストなどの参照の最大数。`0`（デフォルト）に設定すると、この検証は無効になります。 |
| `payloadsizelimit` |  整数  | `0`     | マニフェストペイロードの最大データサイズ（バイト単位）。`0`（デフォルト）に設定すると、この検証は無効になります。 |
|    `urls.allow`    | 配列 | `[]`    | マニフェストのレイヤー内のURLを有効にする正規表現のリスト。空（デフォルト）のままにすると、URLを含むレイヤーはすべて拒否されます。 |
|    `urls.deny`     | 配列 | `[]`    | マニフェストのレイヤー内のURLを制限する正規表現のリスト。空（デフォルト）のままにすると、`urls.allow`リストに合格したURLを持つレイヤーは拒否されません |

### `notifications` {#notifications}

この`notifications`フィールドは、[レジストリ通知](https://distribution.github.io/distribution/about/notifications/#configuration)を設定するために使用されます。デフォルト値として空のハッシュがあります。

|    名前     | 型  | デフォルト | 説明 |
|:-----------:|:-----:|:--------|:-----------:|
| `endpoints` | 配列 | `[]`    | 各項目が[エンドポイント](https://distribution.github.io/distribution/about/configuration/#endpoints)に対応する項目のリスト |
|  `events`   | ハッシュ  | `{}`    | [イベント](https://distribution.github.io/distribution/about/configuration/#events)通知で提供される情報 |

設定例は次のようになります:

```yaml
notifications:
  endpoints:
    - name: FooListener
      url: https://foolistener.com/event
      timeout: 500ms
      # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
      # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
      threshold: 10
      maxretries: 10
      backoff: 1s
    - name: BarListener
      url: https://barlistener.com/event
      timeout: 100ms
      # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
      # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
      threshold: 3
      maxretries: 5
      backoff: 1s
  events:
    includereferences: true
```

<!-- vale gitlab.Spelling = NO -->

### `hpa` {#hpa}

<!-- vale gitlab.Spelling = YES -->

`hpa`フィールドは、セットの一部として作成する[registry](https://hub.docker.com/_/registry/)インスタンスの数を制御するオブジェクトです。デフォルトでは、`minReplicas`の値が`2`、`maxReplicas`の値が10、`cpu.targetAverageUtilization`が75％に設定されます。

### `storage` {#storage}

```yaml
storage:
  secret:
  key: config
  extraKey:
```

`storage`フィールドは、Kubernetes Secretと関連付けられたキーへの参照です。このSecretの内容は、[Registry Configuration: `storage`](https://distribution.github.io/distribution/about/configuration/#storage)から直接取得されます。詳細については、そのドキュメントを参照してください。

[AWS S3](https://distribution.github.io/distribution/storage-drivers/s3/)および[Google GCS](https://distribution.github.io/distribution/storage-drivers/gcs/)ドライバーの例は、[`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)にあります:

- [`registry.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.s3.yaml)
- [`registry.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.gcs.yaml)

S3の場合は、正しい[レジストリストレージの属性](https://distribution.github.io/distribution/storage-drivers/s3/#s3-permission-scopes)を与えることを確認してください。ストレージ構成の詳細については、管理ドキュメントの[Containerレジストリストレージドライバー](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-storage-driver)を参照してください。

`storage`ブロックの_コンテンツ_をSecretに配置し、次の項目を`storage`マップに提供します:

- `secret`: YAMLブロックを格納するKubernetes Secretの名前。
- `key`: 使用するSecret内のキーの名前。`config`がデフォルトです。
- `extraKey`: _（オプション）_コンテナ内の`/etc/docker/registry/storage/${extraKey}`にマウントされるSecret内の追加のキーの名前。これは、`gcs`ドライバーに`keyfile`を提供するために使用できます。

```shell
# Example using S3
kubectl create secret generic registry-storage \
    --from-file=config=registry-storage.yaml

# Example using GCS with JSON key
# - Note: `registry.storage.extraKey=gcs.json`
kubectl create secret generic registry-storage \
    --from-file=config=registry-storage.yaml \
    --from-file=gcs.json=example-project-382839-gcs-bucket.json
```

ストレージドライバーのリダイレクトを[無効](https://docs.gitlab.com/administration/packages/container_registry/#disable-redirect-for-storage-driver)にし、すべてのトラフィックが別のバックエンドにリダイレクトされる代わりにレジストリサービスを通過するようにすることができます:

```yaml
storage:
  secret: example-secret
  key: config
  redirect:
    disable: true
```

`filesystem`ドライバーを使用することを選択した場合:

- このデータには永続ボリュームを提供する必要があります。
- [`hpa.minReplicas`](#hpa)は`1`に設定する必要があります
- [`hpa.maxReplicas`](#hpa)は`1`に設定する必要があります

回復力と簡素化のために、`s3`、`gcs`、`azure`、またはその他の互換性のあるオブジェクトストレージなどの外部サービスを利用することをお勧めします。

{{< alert type="note" >}}

チャートは、ユーザーが指定していない場合、デフォルトでこの構成に`delete.enabled: true`を入力されたます。これにより、期待される動作がMinIOのデフォルトの使用法、およびLinuxパッケージと一致したままになります。ユーザーが指定した値は、このデフォルトより優先されます。

{{< /alert >}}

### `middleware.storage` {#middlewarestorage}

`middleware.storage`の設定は、[アップストリームの慣例](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#middleware)に従います:

設定は非常に一般的で、同様のパターンに従います:

```yaml
middleware:
  # See https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#middleware
  storage:
    - name: cloudfront
      options:
        baseurl: https://abcdefghijklmn.cloudfront.net/
        # `privatekey` is auto-populated with the content from the privatekey Secret.
        privatekeySecret:
          secret: cloudfront-secret-name
          # "key" value is going to be used to generate filename for PEM storage:
          #   /etc/docker/registry/middleware.storage/<index>/<key>
          key: private-key-ABC.pem
        keypairid: ABCEDFGHIJKLMNOPQRST
```

上記のコードでは、`options.privatekeySecret`は、PEMファイルの内容に対応するコンテンツを持つ`generic` Kubernetesのシークレットです:

```shell
kubectl create secret generic cloudfront-secret-name --type=kubernetes.io/ssh-auth --from-file=private-key-ABC.pem=pk-ABCEDFGHIJKLMNOPQRST.pem
```

アップストリームで使用される`privatekey`は、`privatekey`シークレットからチャートによって自動的に入力されたものであり、指定された場合、**無視**されます。

#### `keypairid`のバリアント {#keypairid-variants}

さまざまなベンダーが、同じコンストラクトに異なるフィールド名を使用しています:

|   ベンダー   | フィールド名 |
|:----------:|:----------:|
| Google CDN | `keyname`  |
| クラウドフロント | `keypairid` |

{{< alert type="note" >}}

現時点では、`middleware.storage`セクションの設定のみがサポートされています。

{{< /alert >}}

### `debug` {#debug}

デバッグポートはデフォルトで有効になっており、ヘルスチェックに使用されます。さらに、Prometheusのメトリクスは、`metrics`値を介して有効にできます。

```yaml
debug:
  addr:
    port: 5001

metrics:
  enabled: true
```

### `health` {#health}

`health`プロパティはオプションであり、ストレージドライバーのバックエンドストレージに対する定期的なヘルスチェックの優先順位が含まれています。詳細については、Dockerの[構成ドキュメント](https://distribution.github.io/distribution/about/configuration/#health)を参照してください。

```yaml
health:
  storagedriver:
    enabled: false
    interval: 10s
    threshold: 3
```

### `reporting` {#reporting}

`reporting`プロパティはオプションで、[レポート](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#reporting)を有効にします。

```yaml
reporting:
  sentry:
    enabled: true
    dsn: 'https://<key>@sentry.io/<project>'
    environment: 'production'
```

### `profiling` {#profiling}

`profiling`プロパティはオプションで、[継続的なプロファイリング](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#profiling)を有効にします。

```yaml
profiling:
  stackdriver:
    enabled: true
    credentials:
      secret: gitlab-registry-profiling-creds
      key: credentials
    service: gitlab-registry
```

### `database` {#database}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/5521)された[ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)機能です。
- GitLab 17.3で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)になりました。

{{< /history >}}

`database`プロパティはオプションで、[メタデータデータベース](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#database)を有効にします。

この機能を有効にする前に、[管理ドキュメント](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)を参照してください。

{{< alert type="note" >}}

この機能には、PostgreSQL 13以降が必要です。

{{< /alert >}}

```yaml
database:
  enabled: true
  host: registry.db.example.com
  port: 5432
  user: registry
  password:
    secret: gitlab-postgresql-password
    key: postgresql-registry-password
  dbname: registry
  sslmode: verify-full
  ssl:
    secret: gitlab-registry-postgresql-ssl
    clientKey: client-key.pem
    clientCertificate: client-cert.pem
    serverCA: server-ca.pem
  connecttimeout: 5s
  draintimeout: 2m
  preparedstatements: false
  primary: 'primary.record.fqdn'
  pool:
    maxidle: 25
    maxopen: 25
    maxlifetime: 5m
    maxidletime: 5m
  migrations:
    enabled: true
    activeDeadlineSeconds: 3600
    backoffLimit: 6
  backgroundMigrations:
    enabled: true
    maxJobRetries: 3
    jobInterval: 10s
```

#### ロードバランシング {#load-balancing}

{{< alert type="warning" >}}

これは活発に開発中の試験的な機能であり、本番環境で使用しないでください。

{{< /alert >}}

`loadBalancing`セクションでは、[データベースロードバランシング](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#loadbalancing)を設定できます。この機能を動作させるには、対応する[Redis接続](#redis-for-database-load-balancing)を有効にする必要があります。

#### データベースを管理します {#manage-the-database}

データベースの作成とメンテナンスの詳細については、[Containerレジストリメタデータデータベース](metadata_database.md)ページを参照してください。

### `gc`プロパティ {#gc-property}

`gc`プロパティは、[オンラインガベージコレクション](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc)オプションを提供します。

オンラインガベージコレクションでは、[メタデータデータベース](#database)を有効にする必要があります。データベースを使用する場合はオンラインガベージコレクションを使用する必要がありますが、メンテナンスとデバッグのために、オンラインガベージコレクションを一時的に無効にすることができます。

```yaml
gc:
  disabled: false
  maxbackoff: 24h
  noidlebackoff: false
  transactiontimeout: 10s
  reviewafter: 24h
  manifests:
    disabled: false
    interval: 5s
  blobs:
    disabled: false
    interval: 5s
    storagetimeout: 5s
```

### Redisキャッシュ {#redis-cache}

{{< alert type="note" >}}

Redisキャッシュは、バージョン16.4以降のベータ機能です。この機能を有効にする前に、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)と関連ドキュメントをレビューしてください。

{{< /alert >}}

`redis.cache`プロパティはオプションであり、[Redisキャッシュ](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#cache-1)に関連するオプションを提供します。`redis.cache`をレジストリで使用するには、[メタデータデータベース](#database)を有効にする必要があります。

例: 

```yaml
redis:
  cache:
    enabled: true
    host: localhost
    port: 16379
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

#### クラスタリング {#cluster}

`redis.cache.cluster`プロパティは、Redisクラスタリングに接続するためのホストとポートのリストです。例: 

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    cluster:
      - host: host1.example.com
        port: 6379
      - host: host2.example.com
        port: 6379
```

#### センチネル {#sentinels}

`redis.cache`は`global.redis.sentinels`構成を使用できます。ローカル値を指定すると、グローバル値よりも優先されます。例: 

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    sentinels:
      - host: sentinel1.example.com
        port: 16379
      - host: sentinel2.example.com
        port: 16379
```

#### Redis Sentinelパスワードのサポート {#sentinel-password-support}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3805)。

{{< /history >}}

`redis.cache`では、[`global.redis.sentinelAuth`構成](../globals.md#redis-sentinel-password-support)を使用して、Redis Sentinelの認証パスワードを使用することもできます。ローカル値を指定すると、グローバル値よりも優先されます。例: 

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    sentinels:
      - host: sentinel1.example.com
        port: 16379
      - host: sentinel2.example.com
        port: 16379
    sentinelpassword:
      enabled: true
      secret: registry-redis-sentinel
      key: password
```

### Redisレート制限 {#redis-rate-limiter}

{{< alert type="warning" >}}

Redisのレート制限は[開発中](https://gitlab.com/groups/gitlab-org/-/epics/13237)です。機能に関する詳細情報は、利用可能になり次第、このセクションに追加されます。

{{< /alert >}}

`redis.rateLimiting`プロパティはオプションで、[Redisレート制限](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#ratelimiter)に関連するオプションを提供します。

例: 

```yaml
redis:
  rateLimiting:
    enabled: true
    host: localhost
    port: 16379
    username: registry
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

### データベースロードバランシング用Redis {#redis-for-database-load-balancing}

{{< details >}}

ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- Charts 8.11で[導入](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4180)されました。

{{< /history >}}

{{< alert type="warning" >}}

[データベースロードバランシング](#load-balancing)は、活発に開発中の試験的な機能であり、本番環境で使用しないでください。[エピック8591](https://gitlab.com/groups/gitlab-org/-/epics/8591)を使用して進捗状況を把握し、フィードバックを共有してください。

{{< /alert >}}

`redis.loadBalancing`プロパティはオプションであり、[データベースロードバランシング用のRedis接続](https://gitlab.com/gitlab-org/container-registry/-/blob/b4d71f24a9ae31288401a3459228aa7f8d3dd8f0/docs/configuration.md#loadbalancing-1)に関連するオプションを提供します。

例: 

```yaml
redis:
  loadBalancing:
    enabled: true
    host: localhost
    port: 16379
    username: registry
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

## ガベージコレクション {#garbage-collection}

Dockerレジストリは、時間の経過とともに余分なデータを蓄積しますが、これは[ガベージコレクション](https://distribution.github.io/distribution/about/garbage-collection/)を使用して解放できます。[現在](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1586)、このチャートでガベージコレクションを完全に自動化またはスケジュールする方法はありません。

{{< alert type="warning" >}}

[オンラインガベージコレクション](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc)は、[メタデータデータベース](#database)で使用する必要があります。メタデータデータベースで手動ガベージコレクションを使用すると、データが失われる可能性があります。オンラインガベージコレクションは、手動でガベージコレクションを実行する必要性を完全に置き換えます。

{{< /alert >}}

### 手動ガベージコレクション {#manual-garbage-collection}

手動ガベージコレクションでは、最初にレジストリを読み取り専用モードにする必要があります。Helmを使用してGitLabチャートをすでにインストールし、`mygitlab`という名前を付け、ネームスペース`gitlabns`にインストールしたと仮定しましょう。実際の構成に従って、以下のコマンドでこれらの値を置き換えます。

```shell
# Because of https://github.com/helm/helm/issues/2948 we can't rely on --reuse-values, so let's get our current config.
helm get values mygitlab > mygitlab.yml
# Upgrade Helm installation and configure the registry to be read-only.
# The --wait parameter makes Helm wait until all ressources are in ready state, so we are safe to continue.
helm upgrade mygitlab gitlab/gitlab -f mygitlab.yml --set registry.maintenance.readonly.enabled=true --wait
# Our registry is in r/o mode now, so let's get the name of one of the registry Pods.
# Note down the Pod name and replace the '<registry-pod>' placeholder below with that value.
# Replace the single quotes to double quotes (' => ") if you are using this with Windows' cmd.exe.
kubectl get pods -n gitlabns -l app=registry -o jsonpath='{.items[0].metadata.name}'
# Run the actual garbage collection. Check the registry's manual if you really want the '-m' parameter.
kubectl exec -n gitlabns <registry-pod> -- /bin/registry garbage-collect -m /etc/docker/registry/config.yml
# Reset registry back to original state.
helm upgrade mygitlab gitlab/gitlab -f mygitlab.yml --wait
# All done :)
```

### Containerレジストリに対する管理コマンドの実行 {#running-administrative-commands-against-the-container-registry}

管理コマンドは、レジストリポッドからのみContainerレジストリに対して実行できます。ここでは、`registry`バイナリと必要な設定の両方を使用できます。[イシュー #2629](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2629)が開き、この機能をツールボックスポッドから提供する方法について話し合っています。

管理コマンドを実行するには:

1. レジストリポッドに接続します:

   ```shell
   kubectl exec -it <registry-pod> -- bash
   ```

1. レジストリポッド内に入ると、`registry`バイナリは`PATH`で使用できるようになり、直接使用できます。設定ファイルは`/etc/docker/registry/config.yml`で利用できます。次の例では、データベース移行のステータスを確認します:

   ```shell
   registry database migrate status /etc/docker/registry/config.yml
   ```

詳細およびその他の使用可能なコマンドについては、関連ドキュメントを参照してください:

- [一般的なレジストリドキュメント](https://docs.docker.com/registry/)
- [-specific Registry documentation](https://gitlab.com/gitlab-org/container-registry/-/tree/master/docs-gitlab)

## レジストリレート制限設定 {#registry-rate-limiter-configuration}

レジストリは、コンテナレジストリインスタンスへのトラフィックを制御するために、レート制限で構成できます。これにより、乱用、DoS攻撃、または過度の使用からレジストリを保護できます。

### 注 {#notes}

- レート制限では、`registry.redis.rateLimiting`設定を使用してRedisを適切に構成する必要があります。
- レート制限は、デフォルトでは無効になっています。`registry.rateLimiter.enabled: true`に設定して有効にします。
- レート制限は、優先順位の高い順に適用されます（値が低いものが最初）。
- `log_only`オプションは、レート制限を適用する前にテストする場合に役立ちます。

### レート制限設定 {#rate-limiter-configuration}

コンテナレジストリのレート制限を有効にして構成するには、`registry.rateLimiter`設定を使用します:

```yaml
registry:
  rateLimiter:
    enabled: true
    limiters:
      - name: global_rate_limit
        description: "Global IP rate limit"
        log_only: false
        match:
          type: IP
        precedence: 10
        limit:
          rate: 5000
          period: "minute"
          burst: 8000
        action:
          warn_threshold: 0.7
          warn_action: "log"
          hard_action: "block"
```

### 制限設定 {#limiters-configuration}

レート制限は、レート制限ルールを定義するために、リミッターのリストを使用します。各レート制限には、次のプロパティがあります:

- `name`: レート制限の識別子
- `description`: レート制限の目的を人間が読んで理解できる説明
- `log_only`: `true`に設定すると、違反は強制なしでログに記録されるだけです
- `precedence`: レート制限が評価される順序を定義します（値が低いものが最初）
- `match`: リクエストを照合するための基準
- `limit`: レート制限パラメータ
- `action`: 制限に達した場合に実行するアクション

### 制限構成 {#limit-configuration}

`limit`セクションでは、実際レート制限パラメータを定義します:

```yaml
limit:
  rate: 100       # Number of requests allowed
  period: "minute" # Time period (second, minute, hour, day)
  burst: 200      # Allowed burst capacity
```

### アクション構成 {#action-configuration}

`action`セクションでは、制限に近づいたとき、または制限に達したときに何が起こるかを定義します:

```yaml
action:
  warn_threshold: 0.7      # Percentage of limit to trigger warning
  warn_action: "log"       # Action when warning threshold is reached
  hard_action: "block"     # Action when limit is reached
```

### 例 {#examples}

#### グローバルIPレート制限 {#global-ip-rate-limit}

この例では、単一のIPアドレスからのすべてのリクエストを制限します:

```yaml
- name: global_rate_limit
  description: "Global IP rate limit"
  log_only: false
  match:
    type: IP
  precedence: 10
  limit:
    rate: 5000
    period: "minute"
    burst: 8000
  action:
    warn_threshold: 0.7
    warn_action: "log"
    hard_action: "block"
```
