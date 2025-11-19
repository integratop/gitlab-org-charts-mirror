---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Webserviceチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`webservice`サブチャートは、GitLab Railsウェブサーバーにポッドごとに2つのWebserviceワーカーを提供します。これは、1つのポッドがGitLabであらゆるWebリクエストを処理するために必要な最小限の数です。

このチャートのポッドは、`gitlab-workhorse`と`webservice`の2つのコンテナを使用します。[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab/-/tree/master/workhorse)はポート`8181`でリッスンし、ポッドへの受信トラフィックの宛先は_常に_そうでなければなりません。`webservice`はGitLabの[Railsコードベース](https://gitlab.com/gitlab-org/gitlab)を格納し、`8080`でリッスンし、メトリクス収集の目的でアクセスできます。`webservice`は、通常のトラフィックを直接受信してはなりません。

## 要件 {#requirements}

このチャートは、Redis、PostgreSQL、Gitaly、およびRegistryサービスに依存します。これらは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされるKubernetesクラスタリングから到達可能な外部サービスとして提供されます。

## 設定 {#configuration}

`webservice`チャートは、次のように構成されています: [グローバル設定](#global-settings) 、[デプロイメント設定](#deployments-settings) 、[Ingress設定](#ingress-settings) 、[外部サービス](#external-services) 、および[チャートの設定](#chart-settings)。

## インストールコマンドラインオプション {#installation-command-line-options}

以下の表には、`helm install`コマンドに`--set`フラグを使用して指定できる、チャートの構成がすべて記載されています。

| パラメータ                                                     | デフォルト                                                         | 説明 |
|---------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `annotations`                                                 |                                                                 | ポッドの注釈 |
| `podLabels`                                                   |                                                                 | 補足的なポッドラベル。セレクターには使用されません。 |
| `common.labels`                                               |                                                                 | このチャートによって作成されたすべてのオブジェクトに適用される補足的なラベル。 |
| `deployment.terminationGracePeriodSeconds`                    | `30`                                                            | Kubernetesがポッドの終了を待機する秒数。これは`shutdown.blackoutSeconds`より長くする必要があります |
| `deployment.livenessProbe.initialDelaySeconds`                | `20`                                                            | livenessプローブが開始されるまでの遅延 |
| `deployment.livenessProbe.periodSeconds`                      | `60`                                                            | livenessプローブを実行する頻度 |
| `deployment.livenessProbe.timeoutSeconds`                     | `30`                                                            | livenessプローブがタイムアウトになるタイミング |
| `deployment.livenessProbe.successThreshold`                   | `1`                                                             | livenessプローブが失敗した後、成功したと見なされるための最小連続成功数 |
| `deployment.livenessProbe.failureThreshold`                   | `3`                                                             | livenessプローブが成功した後、失敗したと見なされるための最小連続失敗数 |
| `deployment.readinessProbe.initialDelaySeconds`               | `0`                                                             | readinessプローブが開始されるまでの遅延 |
| `deployment.readinessProbe.periodSeconds`                     | `10`                                                            | readinessプローブを実行する頻度 |
| `deployment.readinessProbe.timeoutSeconds`                    | `2`                                                             | readinessプローブがタイムアウトになるタイミング |
| `deployment.readinessProbe.successThreshold`                  | `1`                                                             | readinessプローブが失敗した後、成功したと見なされるための最小連続成功数 |
| `deployment.readinessProbe.failureThreshold`                  | `3`                                                             | readinessプローブが成功した後、失敗したと見なされるための最小連続失敗数 |
| `deployment.strategy`                                         | `{}`                                                            | デプロイメントで使用される更新戦略を構成できます。指定しない場合、クラスターのデフォルトが使用されます。 |
| `enabled`                                                     | `true`                                                          | Webserviceが有効なフラグ |
| `extraContainers`                                             |                                                                 | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                         |                                                                 | 含める追加のinitコンテナのリスト |
| `extras.google_analytics_id`                                  | `nil`                                                           | フロントエンドのGoogle Analytics ID |
| `extraVolumeMounts`                                           |                                                                 | 実行する追加のボリュームマウントのリスト |
| `extraVolumes`                                                |                                                                 | 作成する追加のボリュームのリスト |
| `extraEnv`                                                    |                                                                 | エクスポーズする追加の環境変数のリスト |
| `extraEnvFrom`                                                |                                                                 | エクスポーズする他のデータソースからの追加の環境変数のリスト |
| `gitlab.webservice.workhorse.image`                           | `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee`  | WorkhorseDockerイメージリポジトリ |
| `gitlab.webservice.workhorse.tag`                             |                                                                 | WorkhorseDockerイメージタグ |
| `hpa.behavior`                                                | `{scaleDown: {stabilizationWindowSeconds: 300 }}`               | 動作には、スケールアップおよびスケールダウン動作の仕様が含まれています（`autoscaling/v2beta2`以上が必要です） |
| `hpa.customMetrics`                                           | `[]`                                                            | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用をオーバーライドします） |
| `hpa.cpu.targetType`                                          | `AverageValue`                                                  | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                                  | `1`                                                             | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`                            |                                                                 | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                                       |                                                                 | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                               |                                                                 | オートスケールメモリターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`                         |                                                                 | オートスケールメモリターゲット使用率を設定します |
| `hpa.targetAverageValue`                                      |                                                                 | **非推奨** オートスケールCPUターゲット値を設定します |
| `sshHostKeys.mount`                                           | `false`                                                         | パブリックSSHキーを含むGitLab Shellシークレットをマウントするかどうか。 |
| `sshHostKeys.mountName`                                       | `ssh-host-keys`                                                 | マウントされたボリュームの名前。 |
| `sshHostKeys.types`                                           | `[dsa,rsa,ecdsa,ed25519]`                                       | マウントするSSHキータイプのリスト。 |
| `image.pullPolicy`                                            | `Always`                                                        | WebserviceDockerイメージプルポリシー |
| `image.pullSecrets`                                           |                                                                 | イメージリポジトリのシークレット |
| `image.repository`                                            | `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee` | WebserviceDockerイメージリポジトリ |
| `image.tag`                                                   |                                                                 | WebserviceDockerイメージタグ |
| `init.image.repository`                                       |                                                                 | initContainerイメージ |
| `init.image.tag`                                              |                                                                 | initContainerイメージタグ |
| `init.containerSecurityContext.runAsUser`                     | `1000`                                                          | initContainer固有: コンテナを起動するユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                         | initContainer固有: プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`                  | `true`                                                          | initContainer固有: コンテナを非ルートユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                     | initContainer固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `keda.enabled`                                                | `false`                                                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                        | `30`                                                            | 各トリガーで確認する間隔 |
| `keda.cooldownPeriod`                                         | `300`                                                           | リソースを0にスケールバックする前に、最後のアクティブを報告されたトリガーの後に待機する期間 |
| `keda.minReplicaCount`                                        | `minReplicas`                                                   | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `keda.maxReplicaCount`                                        | `maxReplicas`                                                   | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `keda.fallback`                                               |                                                                 | KEDAフォールバック構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                                | `keda-hpa-{scaled-object-name}`                                 | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                          |                                                                 | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                               | `hpa.behavior`                                                  | スケールアップおよびスケールダウン動作の仕様。 |
| `keda.triggers`                                               |                                                                 | ターゲットリソースのスケールをアクティブ化するトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーにデフォルト設定されます |
| `metrics.enabled`                                             | `true`                                                          | メトリクスエンドポイントをスクレイピングに利用できるようにする必要がある場合 |
| `metrics.port`                                                | `8083`                                                          | メトリクスエンドポイントポート |
| `metrics.listenAddr`                                          | `0.0.0.0`                                                       | メトリクスリスナーアドレス。 |
| `metrics.path`                                                | `/metrics`                                                      | メトリクスエンドポイントのパス |
| `metrics.serviceMonitor.enabled`                              | `false`                                                         | メトリクスのスクレイプを管理するためにPrometheus Operatorを有効にするServiceMonitorを作成する必要がある場合、これを有効にすると、`prometheus.io`スクレイプ注釈が削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                     | `{}`                                                            | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                       | `{}`                                                            | ServiceMonitorの追加のエンドポイント構成 |
| `metrics.annotations`                                         |                                                                 | **非推奨** 明示的なメトリクス注釈を設定します。テンプレートコンテンツに置き換えられました。 |
| `metrics.tls.enabled`                                         |                                                                 | メトリクス/web_exporterエンドポイントに対してTLSが有効。`tls.enabled`がデフォルトです。 |
| `metrics.tls.secretName`                                      |                                                                 | メトリクス/web_exporterエンドポイントTLS証明書とキーのシークレット。`tls.secretName`がデフォルトです。 |
| `minio.bucket`                                                | `git-lfs`                                                       | MinIOを使用する場合のストレージバケットの名前 |
| `minio.port`                                                  | `9000`                                                          | MinIOサービスのポート |
| `minio.serviceName`                                           | `minio-svc`                                                     | MinIOサービスの名前 |
| `monitoring.ipWhitelist`                                      | `[0.0.0.0/0, ::/0]`                                             | モニタリングエンドポイントのホワイトリストに登録するIPのリスト |
| `monitoring.exporter.listenAddr`                              | `0.0.0.0`                                                       | メトリクスリスナーアドレス。 |
| `monitoring.exporter.enabled`                                 | `false`                                                         | PrometheusメトリクスをエクスポーズするためにWebサーバーを有効にします。これは、メトリクスポートがモニタリングエクスポーターポートに設定されている場合、`metrics.enabled`によってオーバーライドされます |
| `monitoring.exporter.port`                                    | `8083`                                                          | メトリクスエクスポーターに使用するポート番号 |
| `psql.password.key`                                           | `psql-password`                                                 | psqlシークレット内のpsqlパスワードへのキー |
| `psql.password.secret`                                        | `gitlab-postgres`                                               | psqlシークレット名 |
| `psql.port`                                                   |                                                                 | PostgreSQLサーバーのポートを設定します。これは、`global.psql.port`よりも優先されます。 |
| `puma.disableWorkerKiller`                                    | `true`                                                          | Pumaワーカーメモリキラーを無効にします |
| `puma.workerMaxMemory`                                        |                                                                 | Pumaワーカーキラーの最大メモリ(ギガバイト単位) |
| `puma.threads.min`                                            | `4`                                                             | Pumaスレッドの最小量 |
| `puma.threads.max`                                            | `4`                                                             | Pumaスレッドの最大量 |
| `puma.bindIp6`                                                | `false`                                                         | Pumaを使用してIPv6アドレスをバインドします。現在、レート制限に関連する[既知の問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6084)のため、デフォルトではfalseになっています。 |
| `rack_attack.git_basic_auth`                                  | `{}`                                                            | 詳細については、[GitLabドキュメント](https://docs.gitlab.com/administration/settings/protected_paths/)を参照してください |
| `redis.serviceName`                                           | `redis`                                                         | Redisサービス名 |
| `global.registry.api.port`                                    | `5000`                                                          | Registryポート |
| `global.registry.api.protocol`                                | `http`                                                          | Registryプロトコル |
| `global.registry.api.serviceName`                             | `registry`                                                      | Registryサービス名 |
| `global.registry.enabled`                                     | `true`                                                          | すべてのプロジェクトメニューでregistryリンクを追加/削除します |
| `global.registry.tokenIssuer`                                 | `gitlab-issuer`                                                 | Registryトークン発行者 |
| `replicaCount`                                                | `1`                                                             | Webserviceレプリカ数 |
| `resources.requests.cpu`                                      | `300m`                                                          | Webserviceの最小CPU |
| `resources.requests.memory`                                   | `1.5G`                                                          | Webserviceの最小メモリ |
| `service.externalPort`                                        | `8080`                                                          | Webserviceエクスポーズされたポート |
| `securityContext.fsGroup`                                     | `1000`                                                          | ポッドの起動に使用するグループID |
| `securityContext.runAsUser`                                   | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `securityContext.fsGroupChangePolicy`                         |                                                                 | ボリュームの所有権と許可を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                         | `RuntimeDefault`                                                | 使用するSeccompプロファイル |
| `containerSecurityContext`                                    |                                                                 | コンテナが起動される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                          | `1000`                                                          | コンテナが起動される特定のセキュリティコンテキストユーザーIDを上書きできます |
| `containerSecurityContext.allowPrivilegeEscalation`           | `false`                                                         | Gitalyコンテナのプロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                       | `true`                                                          | Gitalyコンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`                  | `[ "ALL" ]`                                                     | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.automountServiceAccountToken`                 | `false`                                                         | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                       | `false`                                                         | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                      | `false`                                                         | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                         |                                                                 | ServiceAccountの名前。設定しない場合、チャートの完全な名前が使用されます |
| `serviceLabels`                                               | `{}`                                                            | 補足サービスラベル |
| `service.internalPort`                                        | `8080`                                                          | Webservice内部ポート |
| `service.type`                                                | `ClusterIP`                                                     | Webserviceサービスタイプ |
| `service.workhorseExternalPort`                               | `8181`                                                          | Workhorseエクスポーズされたポート |
| `service.workhorseInternalPort`                               | `8181`                                                          | Workhorse内部ポート |
| `service.loadBalancerIP`                                      |                                                                 | ロードバランサーに割り当てるIPアドレス（クラウドプロバイダーでサポートされている場合） |
| `service.loadBalancerSourceRanges`                            |                                                                 | ロードバランサーへのアクセスを許可されているIP CIDRのリスト（サポートされている場合）。service.type = ロードバランサーに必要 |
| `shell.authToken.key`                                         | `secret`                                                        | Shellシークレット内のShellトークンへのキー |
| `shell.authToken.secret`                                      | `{Release.Name}-gitlab-shell-secret`                            | Shellトークンシークレット |
| `shell.port`                                                  | `nil`                                                           | UIで生成されたSSH URIで使用するポート番号 |
| `shutdown.blackoutSeconds`                                    | `10`                                                            | シャットダウンを受信した後、Webserviceを実行し続ける秒数。これは`deployment.terminationGracePeriodSeconds`より短くする必要があります |
| `tls.enabled`                                                 | `false`                                                         | Webservice TLSが有効 |
| `tls.secretName`                                              | `{Release.Name}-webservice-tls`                                 | Webservice TLSシークレット。`secretName`は、[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を指している必要があります。 |
| `tolerations`                                                 | `[]`                                                            | ポッドの割り当てに使用するTolerationラベル |
| `trusted_proxies`                                             | `[]`                                                            | 詳細については、[GitLabドキュメント](https://docs.gitlab.com/install/installation/#adding-your-trusted-proxies)を参照してください |
| `workhorse.logFormat`                                         | `json`                                                          | ログ形式。有効な形式: `json`、`structured`、`text` |
| `workerProcesses`                                             | `2`                                                             | Webserviceワーカー数 |
| `workhorse.keywatcher`                                        | `true`                                                          | RedisにWorkhorseをサブスクライブします。これは、`/api/*`へのリクエストを処理するすべてのデプロイメントで**必須**ですが、他のデプロイメントでは安全に無効にできます |
| `workhorse.shutdownTimeout`                                   | `global.webservice.workerTimeout + 1`（秒）                 | すべてのWebリクエストがWorkhorseからクリアされるまで待機する時間。例: `1min`、`65s`。 |
| `workhorse.adoptCfRayHeader`                                  | `false`                                                         | 着信`Cf-Ray`ヘッダーが存在する場合、相関IDとして採用します。詳細については、[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#propagate-correlation-ids)を参照してください。 |
| `workhorse.trustedCIDRsForPropagation`                        |                                                                 | 相関IDの伝播を信頼できるCIDRブロックのリスト。これが機能するには、`-propagateCorrelationID`オプションも`workhorse.extraArgs`で使用する必要があります。詳細については、[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#propagate-correlation-ids)を参照してください。 |
| `workhorse.trustedCIDRsForXForwardedFor`                      |                                                                 | `X-Forwarded-For` HTTPヘッダーを介して実際のクライアントIPを解決するために使用できるCIDRブロックのリスト。これは、`workhorse.trustedCIDRsForPropagation`と共に使用されます。詳細については、[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#trusted-proxies)を参照してください。 |
| `workhorse.metadata.zipReaderLimitBytes`                      |                                                                 | zipリーダーを制限するオプションのバイト数。GitLab 16.9で導入されました。詳細については、[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#metadata-options)を参照してください。 |
| `workhorse.containerSecurityContext`                          |                                                                 | コンテナが起動される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `workhorse.containerSecurityContext.runAsUser`                | `1000`                                                          | コンテナを起動するユーザーID |
| `workhorse.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                         | コンテナのプロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `workhorse.containerSecurityContext.runAsNonRoot`             | `true`                                                          | コンテナを非ルートユーザーで実行するかどうかを制御します |
| `workhorse.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                     | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `workhorse.livenessProbe.initialDelaySeconds`                 | `20`                                                            | livenessプローブが開始されるまでの遅延 |
| `workhorse.livenessProbe.periodSeconds`                       | `60`                                                            | livenessプローブを実行する頻度 |
| `workhorse.livenessProbe.timeoutSeconds`                      | `30`                                                            | livenessプローブがタイムアウトになるタイミング |
| `workhorse.livenessProbe.successThreshold`                    | `1`                                                             | livenessプローブが失敗した後、成功したと見なされるための最小連続成功数 |
| `workhorse.livenessProbe.failureThreshold`                    | `3`                                                             | livenessプローブが成功した後、失敗したと見なされるための最小連続失敗数 |
| `workhorse.monitoring.exporter.enabled`                       | `false`                                                         | PrometheusメトリクスをエクスポーズするためにWorkhorseを有効にします。これは、`workhorse.metrics.enabled`によってオーバーライドされます |
| `workhorse.monitoring.exporter.port`                          | `9229`                                                          | Workhorse Prometheusメトリクスに使用するポート番号 |
| `workhorse.monitoring.exporter.tls.enabled`                   | `false`                                                         | `true`に設定すると、メトリクスエンドポイントでTLSが有効になります。Workhorseで[TLSを有効にする](#gitlab-workhorse)必要があります。 |
| `workhorse.metrics.enabled`                                   | `true`                                                          | Workhorseメトリクスエンドポイントをスクレイプに利用できるようにする必要がある場合 |
| `workhorse.metrics.port`                                      | `8083`                                                          | Workhorseメトリクスエンドポイントポート |
| `workhorse.metrics.path`                                      | `/metrics`                                                      | Workhorseメトリクスエンドポイントのパス |
| `workhorse.metrics.serviceMonitor.enabled`                    | `false`                                                         | Prometheus OperatorがWorkhorseメトリクスのスクレイプを管理できるようにするためにServiceMonitorを作成する必要がある場合 |
| `workhorse.metrics.serviceMonitor.additionalLabels`           | `{}`                                                            | Workhorse ServiceMonitorに追加する追加のラベル |
| `workhorse.metrics.serviceMonitor.endpointConfig`             | `{}`                                                            | Workhorse ServiceMonitorの追加のエンドポイント構成 |
| `workhorse.readinessProbe.initialDelaySeconds`                | `0`                                                             | readinessプローブが開始されるまでの遅延 |
| `workhorse.readinessProbe.periodSeconds`                      | `10`                                                            | readinessプローブを実行する頻度 |
| `workhorse.readinessProbe.timeoutSeconds`                     | `2`                                                             | readinessプローブがタイムアウトになるタイミング |
| `workhorse.readinessProbe.successThreshold`                   | `1`                                                             | readinessプローブが失敗した後、成功したと見なされるための最小連続成功数 |
| `workhorse.readinessProbe.failureThreshold`                   | `3`                                                             | 成功後に、readiness probeが失敗したと見なされるまでの最小連続失敗回数 |
| `workhorse.imageScaler.maxProcs`                              | `2`                                                             | 同時に実行できるイメージスケールプロセスの最大数 |
| `workhorse.imageScaler.maxFileSizeBytes`                      | `250000`                                                        | スケーラによって処理されるイメージのバイト単位の最大ファイルサイズ |
| `workhorse.tls.verify`                                        | `true`                                                          | `true`に設定すると、NGINX IngressはWorkhorseのTLS証明書を強制的に検証します。カスタムCAの場合は、`workhorse.tls.caSecretName`も設定する必要があります。自己署名証明書の場合は、`false`に設定する必要があります。 |
| `workhorse.tls.secretName`                                    | `{Release.Name}-workhorse-tls`                                  | TLSキーと証明書のペアを含む[TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)の名前。これは、Workhorse TLSが有効になっている場合に必要です。 |
| `workhorse.tls.caSecretName`                                  |                                                                 | CA証明書を含むシークレットの名前。これは**等しくない**[TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)ではありません。`ca.crt`キーのみが必要です。これは、NGINXによるTLS検証に使用されます。 |
| `workhorse.circuitBreaker.enabled`                            | `false`                                                         | サーキットブレーカーを有効にするかどうか |
| `workhorse.circuitBreaker.timeout`                            | `60`                                                            | オープン時にサーキットブレーカーをハーフオープンに移行するまでの時間（秒） |
| `workhorse.circuitBreaker.interval`                           | `180`。                                                          | クローズ時にサーキットブレーカーが連続エラーをクリアするまでの時間（秒） |
| `workhorse.circuitBreaker.maxRequests`                        | `1`。                                                            | ハーフオープン時にサーキットブレーカーを開くための失敗したリクエスト数 |
| `workhorse.circuitBreaker.consecutiveFailures`                | `5`。                                                            | クローズ時にサーキットブレーカーを開くための連続して失敗したリクエストの数 |
| `webServer`                                                   | `puma`                                                          | リクエスト処理に使用するWebサーバー（Webservice/Puma）を選択します |
| `priorityClassName`                                           | `""`                                                            | `priorityClassName`ポッドを構成できます。これは、エビクションが発生した場合のポッドの優先度を制御するために使用されます |

## チャート設定の例 {#chart-configuration-examples}

### `extraEnv` {#extraenv}

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

### `extraEnvFrom` {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで、他のデータソースからの追加の環境変数を公開できます。後続の変数は、[デプロイ](#deployments-settings)ごとにオーバーライドできます。

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
deployments:
  default:
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

### `image.pullSecrets` {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに対して認証を行い、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法の詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)を参照してください。

`pullSecrets`の使用例を以下に示します:

```yaml
image:
  repository: my.webservice.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

このセクションでは、サービスアカウントを作成するかどうか、およびポッドにデフォルトのアクセストークンをマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | サービスアカウント注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | サービスアカウントを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | サービスアカウントを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | サービスアカウントの名前。設定されていない場合は、チャート名がフルで使用されます。 |

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

### `annotations` {#annotations}

`annotations`を使用すると、Webserviceポッドに注釈を追加できます。例: 

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### `strategy` {#strategy}

`deployment.strategy`を使用すると、デプロイの更新仕様を変更できます。更新時にデプロイのポッドがどのように再作成されるかを定義します。指定されていない場合は、クラスタリングのデフォルトが使用されます。たとえば、ローリング更新の開始時に追加のポッドを作成せず、使用できないポッドの最大数を50%に変更する場合は、次のようにします:

```yaml
deployment:
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 50%
```

更新仕様のタイプを`Recreate`に変更することもできますが、新しいポッドのスケジュール前にすべてのポッドが強制終了され、新しいポッドが起動するまでWeb UIが使用できなくなるため、注意してください。この場合、`rollingUpdate`を定義する必要はなく、`type`のみを定義する必要があります:

```yaml
deployment:
  strategy:
    type: Recreate
```

詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)を参照してください。

### TLS {#tls}

Webserviceポッドは2つのコンテナを実行します:

- `gitlab-workhorse`
- `webservice`

#### `gitlab-workhorse` {#gitlab-workhorse}

Workhorseは、WebおよびメトリクスのエンドポイントでTLSをサポートしています。これにより、Workhorseと他のコンポーネント（特に`nginx-ingress`、`gitlab-shell`、および`gitaly`）間の通信が保護されます。TLS証明書には、共通名（CN）またはサブジェクト代替名（SAN）にWorkhorseサービスホスト名（例: `RELEASE-webservice-default.default.svc`）が含まれている必要があります。

[Webserviceの複数のデプロイ](#deployments-settings)が存在する可能性があることに注意してください。そのため、異なるサービス名に対してTLS証明書を準備する必要があります。これは、複数のSANまたはワイルドカード証明書のいずれかによって実現できます。

TLS証明書が生成されたら、その証明書の[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を作成します。`ca.crt`キーを持つTLS証明書のCA証明書のみを含む別のシークレットも作成する必要があります。

`global.workhorse.tls.enabled`を`true`に設定することで、`gitlab-workhorse`コンテナのTLSを有効にできます。カスタムシークレット名を`gitlab.webservice.workhorse.tls.secretName`および`global.certificates.customCAs`にそれぞれ渡すことができます。

`gitlab.webservice.workhorse.tls.verify`が`true`（デフォルト）の場合、CA証明書シークレット名も`gitlab.webservice.workhorse.tls.caSecretName`に渡す必要があります。これは、自己署名証明書とカスタムCAに必要です。このシークレットは、NGINXがWorkhorseのTLS証明書を検証するために使用します。

```yaml
global:
  workhorse:
    tls:
      enabled: true
  certificates:
    customCAs:
      - secret: gitlab-workhorse-ca
gitlab:
  webservice:
    workhorse:
      tls:
        verify: true
        # secretName: gitlab-workhorse-tls
        caSecretName: gitlab-workhorse-ca
      monitoring:
        exporter:
          enabled: true
          tls:
            enabled: true
```

`gitlab-workhorse`コンテナのメトリクスエンドポイントのTLSは、`global.workhorse.tls.enabled`から継承されます。メトリクスエンドポイントのTLSは、WorkhorseでTLSが有効になっている場合にのみ使用できます。メトリクスリスナーは、`gitlab.webservice.workhorse.tls.secretName`で指定されたものと同じTLS証明書を使用します。

メトリクスエンドポイントに使用されるTLS証明書では、特に含まれているPrometheus Helmチャートを使用している場合は、含まれているサブジェクトの代替名（SAN）について追加の考慮事項が必要になる場合があります。詳細については、[TLS対応エンドポイントをスクレイプするようにPrometheusを構成する](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)を参照してください。

#### `webservice` {#webservice}

TLSを有効にする主なユースケースは、[Prometheusメトリクスのスクレイプ](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)のためにHTTPS経由で暗号化を提供することです。

PrometheusがHTTPSを使用して`/metrics/`エンドポイントをスクレイプするには、証明書の`CommonName`属性または`SubjectAlternativeName`エントリの追加構成が必要です。これらの要件については、[TLS対応エンドポイントをスクレイプするようにPrometheusを構成する](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)を参照してください。

設定`gitlab.webservice.tls.enabled`により、`webservice`コンテナでTLSを有効にできます:

```yaml
gitlab:
  webservice:
    tls:
      enabled: true
      # secretName: gitlab-webservice-tls
```

`secretName`は、[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を指している必要があります。たとえば、ローカル証明書とキーを使用してTLSシークレットを作成するには、次のようにします:

```shell
kubectl create secret tls <secret name> --cert=path/to/puma.crt --key=path/to/puma.key
```

## このチャートのCommunity Editionを使用する {#using-the-community-edition-of-this-chart}

デフォルトの場合、HelmチャートではGitLabのEnterprise Editionを使用します。必要に応じて、Community Editionを代わりに使用できます。[2つのエディションの違い](https://about.gitlab.com/install/ce-or-ee/)について詳しくは、こちらをご覧ください。

Community Editionを使用するには、`image.repository`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ce`に、`workhorse.image`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce`に設定します。

## グローバル設定 {#global-settings}

いくつかの一般的なグローバル設定をチャート間で共有します。GitLabやレジストリホスト名など、一般的な構成オプションについては、[グローバルドキュメント](../../globals.md)を参照してください。

## デプロイ設定 {#deployments-settings}

このチャートには、複数のデプロイオブジェクトとそれらに関連するリソースを作成する機能があります。この機能を使用すると、パスベースのルーティングを使用して、GitLabアプリケーションへのリクエストをポッドの複数のセット間で分散させることができます。

このマップのキー（この例では`default`）は、それぞれの「名前」です。`default`には、`RELEASE-webservice-default`で作成された、デプロイ、サービス、HorizontalPodAutoscaler、PodDisruptionBudget、およびオプションのIngressがあります。

指定されていないプロパティは、`gitlab-webservice`チャートのデフォルトから継承されます。

```yaml
deployments:
  default:
    ingress:
      path: # Does not inherit or default. Leave blank to disable Ingress.
      pathType: Prefix
      provider: nginx
      annotations:
        # inherits `ingress.anntoations`
      proxyConnectTimeout: # inherits `ingress.proxyConnectTimeout`
      proxyReadTimeout:    # inherits `ingress.proxyReadTimeout`
      proxyBodySize:       # inherits `ingress.proxyBodySize`
    deployment:
      annotations: # map
      labels: # map
      # inherits `deployment`
    pod:
      labels: # additional labels to .podLabels
      annotations: # map
        # inherit from .Values.annotations
    service:
      labels: # additional labels to .serviceLabels
      annotations: # additional annotations to .service.annotations
        # inherits `service.annotations`
    hpa:
      minReplicas: # defaults to .minReplicas
      maxReplicas: # defaults to .maxReplicas
      metrics: # optional replacement of HPA metrics definition
      # inherits `hpa`
    pdb:
      maxUnavailable: # inherits `maxUnavailable`
    resources: # `resources` for `webservice` container
      # inherits `resources`
    workhorse: # map
      # inherits `workhorse`
    extraEnv: #
      # inherits `extraEnv`
    extraEnvFrom: #
      # inherits `extraEnvFrom`
    puma: # map
      # inherits `puma`
    workerProcesses: # inherits `workerProcesses`
    shutdown:
      # inherits `shutdown`
    nodeSelector: # map
      # inherits `nodeSelector`
    tolerations: # array
      # inherits `tolerations`
    priorityClassName: # inherits `priorityClassName`
```

### デプロイIngress {#deployments-ingress}

各`deployments`エントリは、チャート全体の[Ingress設定](#ingress-settings)から継承されます。ここに表示される値は、そこで提供される値をオーバーライドします。`path`を除き、すべての設定はこれらと同一です。

```yaml
webservice:
  deployments:
    default:
      ingress:
        path: /
   api:
     ingress:
       path: /api
```

`path`プロパティは、Ingressの`path`プロパティに直接入力され、各サービスに送信されるURIパスを制御できます。上記の例では、`default`はキャッチオールパスとして機能し、`api`は`/api`ですべてのトラフィックを受信しました

`path`を空に設定すると、特定のデプロイが関連付けられたIngressリソースの作成を無効にできます。以下を参照してください。 `internal-api`は外部トラフィックを受信しません。

```yaml
webservice:
  deployments:
    default:
      ingress:
        path: /
   api:
     ingress:
       path: /api
   internal-api:
     ingress:
       path:
```

## Ingress設定 {#ingress-settings}

| 名前                              |  型   | デフォルト                   | 説明 |
|:----------------------------------|:-------:|:--------------------------|:------------|
| `ingress.apiVersion`              | 文字列  |                           | `apiVersion`フィールドで使用する値。 |
| `ingress.annotations`             |   マップ   | [下記](#annotations)をご覧ください。 | これらの注釈は、すべてのIngressに使用されます。例: `ingress.annotations."nginx\.ingress\.kubernetes\.io/enable-access-log"=true`。 |
| `ingress.configureCertmanager`    | ブール値 |                           | Ingress注釈`cert-manager.io/issuer`および`acme.cert-manager.io/http01-edit-in-place`を切り替えます。詳細については、[GitLab PagesのTLS要件](../../../installation/tls.md)を参照してください。 |
| `ingress.enabled`                 | ブール値 | `false`                   | サービスがサポートするIngressオブジェクトを作成するかどうかを制御する設定。`false`の場合、`global.ingress.enabled`設定値が使用されます。 |
| `ingress.proxyBodySize`           | 文字列  | `512m`                    | [下記を参照](#proxybodysize)。 |
| `ingress.serviceUpstream`         | ブール値 | `true`                    | [下記を参照](#serviceupstream)。 |
| `ingress.tls.enabled`             | ブール値 | `true`                    | `false`に設定すると、GitLab WebserviceのTLSが無効になります。これは、IngressレベルでTLSターミネーションを使用できない場合（TLSターミネーションプロキシがIngressコントローラーの前にある場合など）に役立ちます。 |
| `ingress.tls.secretName`          | 文字列  | （空）                   | GitLab URIの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定しない場合は、代わりに`global.ingress.tls.secretName`値が使用されます。 |
| `ingress.tls.smardcardSecretName` | 文字列  | （空）                   | 有効になっている場合、GitLabスマートカードURIの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定しない場合は、代わりに`global.ingress.tls.secretName`値が使用されます。 |
| `ingress.tls.useGeoClass`         | ブール値 | `false`                   | IngressClassをGeo Ingressクラス（`global.geo.ingressClass`）でオーバーライドします。プライマリGeoサイトに必須。 |

### 注釈 {#annotations-1}

`annotations`は、Webservice Ingressに注釈を設定するために使用されます。

### `serviceUpstream` {#serviceupstream}

これにより、NGINXにアップストリームとしてサービス自体に直接連絡するように指示することで、Webserviceポッドへのトラフィックのバランスがより均等になります。詳細については、[NGINXドキュメント](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#service-upstream)を参照してください。

これをオーバーライドするには、次のように設定します:

```yaml
gitlab:
  webservice:
    ingress:
      serviceUpstream: "false"
```

### `proxyBodySize` {#proxybodysize}

`proxyBodySize`は、NGINXプロキシの最大ブロックサイズを設定するために使用されます。これは通常、デフォルトよりも大きいDockerイメージを許可するために必要です。これは、[Linuxパッケージインストール](https://docs.gitlab.com/omnibus/settings/nginx/#use-an-existing-passenger-and-nginx-installation)の`nginx['client_max_body_size']`構成と同等です。代替オプションとして、次の2つのパラメータのいずれかを使用してブロックサイズを設定することもできます:

- `gitlab.webservice.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`
- `global.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`

### 追加のIngress {#extra-ingress}

`extraIngress.enabled=true`を設定すると、追加のIngressをデプロイできます。Ingressには、`-extra`サフィックスが付いたデフォルトIngressという名前が付けられ、デフォルトIngressと同じ設定がサポートされます。

## リソース {#resources}

### メモリリクエスト/制限 {#memory-requestslimits}

各ポッドは、`workerProcesses`と等しい数のワーカーを起動します。各ワーカーは、ベースライン量のメモリをいくらか使用します。推奨事項:

- ワーカーあたり最小1.25GB（`requests.memory`）
- ワーカーあたり最大1.5GB、さらにプライマリに1GB（`limits.memory`）

必要なリソースはユーザーが生成したワークロードに依存し、GitLabアプリケーションの変更またはアップグレードに基づいて将来変更される可能性があることに注意してください。

デフォルトは、:

```yaml
workerProcesses: 2
resources:
  requests:
    memory: 2.5G # = 2 * 1.25G
# limits:
#   memory: 4G   # = (2 * 1.5G) + 950M
```

4つのワーカーが構成されている場合:

```yaml
workerProcesses: 4
resources:
  requests:
    memory: 5G   # = 4 * 1.25G
# limits:
#   memory: 7G   # = (4 * 1.5G) + 950M
```

## 外部サービス {#external-services}

### Redis {#redis}

Redisドキュメントは、[グローバル](../../globals.md#configure-redis-settings)ページに統合されました。最新のRedis構成オプションについては、このページを参照してください。

### PostgreSQL {#postgresql}

PostgreSQLドキュメントは、[グローバル](../../globals.md#configure-postgresql-settings)ページに統合されました。最新のPostgreSQL構成オプションについては、このページを参照してください。

Webserviceデプロイの`dependencies` `initContainer`は、次のことを確認するスクリプトを実行します:

- GitLabの依存関係が利用可能かどうか。
- PostgreSQLのデータベース移行が実行されたかどうか。

これらのスクリプトの動作を制御するには、Webserviceチャートの`extraEnv`構成キーを使用できます。2つの環境変数がサポートされています:

- `BYPASS_POST_DEPLOYMENT=true`: すべての通常の移行が実行され、デプロイ後の移行のみが保留されている場合、依存関係チェックは合格します
- `BYPASS_SCHEMA_VERSION=true`（推奨されません）: 通常の移行が実行されていない場合でも、依存関係チェックは合格します。この環境変数を使用すると、データベーススキーマがアプリケーションコードの期待値と一致しないため、起動後にRailsデプロイがエラーになる可能性があります。

### Gitaly {#gitaly}

Gitalyは、[グローバル設定](../../globals.md)によって構成されます。[Gitaly構成ドキュメント](../../globals.md#configure-gitaly-settings)を参照してください。

### MinIO {#minio}

```yaml
minio:
  serviceName: 'minio-svc'
  port: 9000
```

| 名前          |  型   | デフォルト     | 説明 |
|:--------------|:-------:|:------------|:------------|
| `port`        | 整数 | `9000`      | MinIO `Service`に到達するためのポート番号。 |
| `serviceName` | 文字列  | `minio-svc` | MinIOポッドによって公開される`Service`の名前。 |

### レジストリ {#registry}

```yaml
registry:
  host: registry.example.com
  port: 443
  api:
    protocol: http
    host: registry.example.com
    serviceName: registry
    port: 5000
  tokenIssuer: gitlab-issuer
  certificate:
    secret: gitlab-registry
    key: registry-auth.key
```

| 名前                 |  型   | デフォルト         | 説明 |
|:---------------------|:-------:|:----------------|:------------|
| `api.host`           | 文字列  |                 | 使用するレジストリサーバーのホスト名。`api.serviceName`の代わりとして省略できます。 |
| `api.port`           | 整数 | `5000`          | レジストリAPIへの接続に使用するポート。 |
| `api.protocol`       | 文字列  |                 | WebserviceがレジストリAPIに到達するために使用する必要があるプロトコル。 |
| `api.serviceName`    | 文字列  | `registry`      | レジストリサーバーを操作している`service`の名前。これが存在し、`api.host`が存在しない場合、チャートは`api.host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、レジストリをGitLabチャート全体の一部として使用する場合に便利です。 |
| `certificate.key`    | 文字列  |                 | [レジストリ](https://hub.docker.com/_/registry/)コンテナに`auth.token.rootcertbundle`として提供される証明書バンドルを格納する`Secret`キー内の`key`の名前。 |
| `certificate.secret` | 文字列  |                 | GitLabインスタンスによって作成されたトークンを検証するために使用される証明書バンドルを格納する[Kubernetesシークレット](https://kubernetes.io/docs/concepts/configuration/secret/)の名前。 |
| `host`               | 文字列  |                 | GitLab UIでDockerコマンドをユーザーに提供するために使用する外部ホスト名。`registry.hostname`仕様で設定された値にフォールバックします。これにより、`global.hosts`で設定された値に基づいてレジストリホスト名が決定されます。詳細については、[Globals Documentation](../../globals.md)のドキュメントを参照してください。 |
| `port`               | 整数 |                 | ホスト名で使用される外部ポート。`80`または`443`ポートを使用すると、URIが`http`/`https`で形成されます。他のポートはすべて`http`を使用し、ホスト名の最後にポートを追加します（たとえば、`http://registry.example.com:8443`）。 |
| `tokenIssuer`        | 文字列  | `gitlab-issuer` | 認証トークン発行者の名前。これは、送信時にトークンに組み込まれるため、レジストリの構成で使用されている名前と一致している必要があります。`gitlab-issuer`のデフォルトは、レジストリチャートで使用するのと同じデフォルトです。 |

## チャート設定 {#chart-settings}

次の値は、Webserviceポッドの構成に使用されます。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `workerProcesses` | 整数 | `2`     | ポッドごとに実行するWebserviceワーカーの数。GitLabが適切に機能するためには、クラスタリングで少なくとも`2`つのワーカーを使用できる必要があります。`workerProcesses`を増やすと、ワーカーごとに約`400MB`だけ必要なメモリが増加するため、それに応じてポッドの`resources`を更新する必要があります。 |
| `minReplicas`     | 整数 | `2`     | レプリカの最小数 |
| `maxReplicas`     | 整数 | `10`    | レプリカの最大数 |
| `maxUnavailable`  | 整数 | `1`     | 利用できないポッドの最大数の制限 |

### メトリクス {#metrics}

`metrics.enabled`の値でメトリクスを有効にし、GitLabモニタリングエクスポーターを使用してメトリクスポートを公開できます。ポッドにはPrometheus注釈が付与されるか、`metrics.serviceMonitor.enabled`が`true`の場合、Prometheus Operator ServiceMonitorが作成されます。メトリクスは`/-/metrics`エンドポイントからスクレイプできますが、これには[GitLab Prometheusメトリクス](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)が管理者エリアで有効になっている必要があります。また、GitLab Workhorseのメトリクスは`workhorse.metrics.enabled`を介して公開することもできますが、Prometheusの注釈を使用して収集することはできないため、`workhorse.metrics.serviceMonitor.enabled`が`true`であるか、外部のPrometheus設定が必要です。

### GitLab Shell {#gitlab-shell}

GitLab Shellは、Webserviceとの通信で認証トークンを使用します。共有シークレットを使用して、トークンをGitLab ShellおよびWebserviceと共有します。

```yaml
shell:
  authToken:
    secret: gitlab-shell-secret
    key: secret
  port:
```

| 名前               |  型   | デフォルト | 説明 |
|:-------------------|:-------:|:--------|:------------|
| `authToken.key`    | 文字列  |         | は、上記のシークレットのうちトークンを含むキーの名前を定義します。 |
| `authToken.secret` | 文字列  |         | `Secret`は、プル元のシークレットの名前を定義します。 |
| `port`             | 整数 | `22`    | GitLab UI内でSSH URLの生成に使用するポート番号。`global.shell.port`によって制御されます。 |

### WebServerオプション {#webserver-options}

現在のチャートのバージョンは、Puma Webサーバーをサポートしています。

Puma固有のオプション:

| 名前                   |  型   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `puma.workerMaxMemory` | 整数 |         | Pumaワーカーキラーの最大メモリ（メガバイト単位） |
| `puma.threads.min`     | 整数 | `4`     | Pumaスレッドの最小量 |
| `puma.threads.max`     | 整数 | `4`     | Pumaスレッドの最大量 |

## `networkpolicy`の設定 {#configuring-the-networkpolicy}

このセクションでは、[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この設定はオプションであり、特定のエンドポイントへのポッドのエグレスおよびイングレスを制限するために使用されます。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定により、`NetworkPolicy`が有効になります。 |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークポリシーがアクティブになります。ルールが指定されていない限り、これにより、すべてのイングレス接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | イングレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |

### ネットワークポリシーの例 {#example-network-policy}

webserviceサービスには、Prometheusエクスポーターが有効になっている場合、イングレス接続、NGINXイングレスからのトラフィック、およびいくつかのGitLabポッドが必要です。通常、さまざまな場所へのエグレス接続が必要です。この例では、次のネットワークポリシーを追加します:

- イングレスリクエストを許可:
  - ポッド`gitaly`、`gitlab-pages`、`gitlab-shell`、`kas`、`mailroom`、および`nginx-ingress`からポート`8181`へ
  - `Prometheus`ポッドからポート`8080`、`8083`、および`9229`へ
- エグレスリクエストを許可:
  - `gitaly`ポッドからポート`8075`へ
  - `kas`ポッドからポート`8153`へ
  - `kube-dns`からポート`53`へ
  - `registry`ポッドからポート`5000`へ
  - 外部データベース`172.16.0.10/32`からポート`5432`へ
  - 外部Redis `172.16.0.11/32`からポート`6379`へ
  - インターネット`0.0.0.0/0`からポート`443`へ
  - S3またはSTSのAWS VPCエンドポイントのようなエンドポイントからポート`443` `172.16.1.0/24`へ

_提供されている例は単なる例であり、完全ではない可能性があります_

_ウェブサービスには、[オブジェクトストレージ](../../../advanced/external-object-storage)上のイメージへの送信接続が必要であることに注意してください_

この例は、`kube-dns`がネームスペース`kube-system`に、`prometheus`がネームスペース`monitoring`に、`nginx-ingress`がネームスペース`nginx-ingress`にデプロイされたという前提に基づいています。

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - podSelector:
              matchLabels:
                app: gitaly
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: gitlab-pages
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: gitlab-shell
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: kas
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: mailroom
        ports:
          - port: 8181
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 8181
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
          - port: 9229
          - port: 8080
          - port: 8083
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
          - ipBlock:
              cidr: 0.0.0.0/0
              except:
                - 10.0.0.0/8
        ports:
          - port: 443
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
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: kube-system
            podSelector:
              matchLabels:
                k8s-app: kube-dns
        ports:
          - port: 53
            protocol: UDP
```

### `LoadBalancer`LoadBalancerサービス {#loadbalancer-service}

`service.type`が`LoadBalancer`に設定されている場合、オプションで`service.loadBalancerIP`を指定して、ユーザー指定のIPで`LoadBalancer`を作成できます（クラウドプロバイダーがサポートしている場合）。

`service.type`が`LoadBalancer`に設定されている場合は、`service.loadBalancerSourceRanges`を設定して、`LoadBalancer`にアクセスできるCIDR範囲を制限する必要があります（クラウドプロバイダーがサポートしている場合）。現在、[メトリクスポートが公開されている](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2500)問題により、これは必須です。

`LoadBalancer`サービスタイプの詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)を参照してください

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges:
  - 10.0.0.0/8
```

## KEDAの設定 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`ではなく、[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムまたは外部メトリクスに基づいてオートスケーリングが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルト設定されます。

以下が当てはまる場合、`hpa`セクションで設定されたCPUとメモリのしきい値に基づいて、CPUとメモリのトリガーが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定も、ゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | リソースを0にスケールバックする前に、最後トリガーがアクティブとレポートされてから待機する期間 |
| `minReplicaCount`               | 整数 | `minReplicas`                   | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `maxReplicaCount`               | 整数 | `maxReplicas`                   | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `fallback`                      |   マップ   |                                 | KEDAのフォールバック設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | ターゲットリソースを、`ScaledObject`の削除後に元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | アップスケールとダウンスケールの動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケールをアクティブにするトリガーのリスト。`hpa.cpu`と`hpa.memory`から計算されたトリガーにデフォルト設定されています |
