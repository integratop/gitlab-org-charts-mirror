---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pagesチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`gitlab-pages`サブチャートは、GitLabプロジェクトから静的ウェブサイトを提供するためのデーモンを提供します。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされるKubernetesクラスタから到達可能な外部サービスとして提供される、Workhorseサービスへのアクセスに依存します。

## 設定 {#configuration}

`gitlab-pages`チャートは、次のように設定されます: [グローバル設定](#global-settings)と[チャートの設定](#chart-settings)。

## グローバル設定 {#global-settings}

いくつかの一般的なグローバル設定は、チャート間で共有されます。詳細については、[グローバルドキュメント](../../globals.md#configure-gitlab-pages)を参照してください。

## チャートの設定 {#chart-settings}

以下の2つのセクションの表には、`helm install`フラグを使用して`--set`コマンドに指定できる、チャートのすべての可能な設定が含まれています。

### 一般設定 {#general-settings}

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                    | ポッドの割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                            |                                                         | ポッドの注釈 |
| `common.labels`                                          | `{}`                                                    | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `deployment.strategy`                                    | `{}`                                                    | デプロイメントで使用される更新戦略を設定できます。指定されていない場合、クラスタのデフォルトが使用されます。 |
| `extraEnv`                                               |                                                         | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                         | 公開する他のデータソースからの追加の環境変数のリスト |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`       | 動作には、アップスケールとダウンスケール動作の仕様が含まれています（`autoscaling/v2beta2`以上が必要です）。 |
| `hpa.customMetrics`                                      | `[]`                                                    | カスタムメトリクスには、必要なレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で設定された平均CPU使用率のデフォルトの使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                                     | `AverageValue`                                          | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                  | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`                       |                                                         | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                                  |                                                         | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                          |                                                         | オートスケールメモリターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`                    |                                                         | オートスケールメモリターゲット使用率を設定します |
| `hpa.minReplicas`                                        | `1`                                                     | レプリカの最小数 |
| `hpa.maxReplicas`                                        | `10`                                                    | レプリカの最大数 |
| `hpa.targetAverageValue`                                 |                                                         | **非推奨** オートスケールCPUターゲット値を設定します |
| `image.pullPolicy`                                       | `IfNotPresent`                                          | GitLabイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                         | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-pages` | GitLab Pagesイメージリポジトリ |
| `image.tag`                                              |                                                         | イメージタグ   |
| `init.image.repository`                                  |                                                         | initコンテナイメージ |
| `init.image.tag`                                         |                                                         | initコンテナイメージタグ |
| `init.containerSecurityContext`                          |                                                         | initコンテナ固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | initコンテナ固有: プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | initコンテナ固有: コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | initコンテナ固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `keda.enabled`                                           | `false`                                                 | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                    | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                   | リソースを0にスケールバックする前に、最後トリガーがアクティブと報告されてから待機する期間 |
| `keda.minReplicaCount`                                   | `hpa.minReplicas`                                       | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `keda.maxReplicaCount`                                   | `hpa.maxReplicas`                                       | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `keda.fallback`                                          |                                                         | KEDAfallback設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                         | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                     |                                                         | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          | `hpa.behavior`                                          | アップスケールとダウンスケール動作の仕様。 |
| `keda.triggers`                                          |                                                         | ターゲットリソースのスケールをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーがデフォルトです |
| `metrics.enabled`                                        | `true`                                                  | メトリクスエンドポイントをスクレイプできるようにするかどうか |
| `metrics.port`                                           | `9235`                                                  | メトリクスエンドポイントのポート |
| `metrics.path`                                           | `/metrics`                                              | メトリクスエンドポイントのパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Prometheus Operatorがメトリクスのスクレイピングを管理できるようにServiceMonitorを作成するかどうか。これを有効にすると、`prometheus.io`スクレイピングアノテーションが削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | ServiceMonitorの追加のエンドポイント設定 |
| `metrics.annotations`                                    |                                                         | **非推奨** 明示的なメトリクス注釈を設定します。テンプレートコンテンツに置き換えられました。 |
| `metrics.tls.enabled`                                    | `false`                                                 | メトリクスエンドポイントのTLSが有効 |
| `metrics.tls.secretName`                                 | `{Release.Name}-pages-metrics-tls`                      | メトリクスエンドポイントのTLS証明書とキーのシークレット |
| `priorityClassName`                                      |                                                         | ポッドに割り当てられる[Priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `podLabels`                                              |                                                         | 追加のポッドラベル。セレクターには使用されません。 |
| `resources.requests.cpu`                                 | `900m`                                                  | GitLab Pagesの最小CPU |
| `resources.requests.memory`                              | `2G`                                                    | GitLab Pagesの最小メモリ |
| `securityContext.fsGroup`                                | `1000`                                                  | ポッドの起動に使用されるグループID |
| `securityContext.runAsUser`                              | `1000`                                                  | ポッドの起動に使用されるユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                         | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                         | コンテナの起動時に適用される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドする |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | コンテナの起動に使用される特定のセキュリティコンテキストユーザーIDを上書きできるようにします |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | コンテナのプロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `service.externalPort`                                   | `8090`                                                  | GitLab Pagesの公開ポート |
| `service.internalPort`                                   | `8090`                                                  | GitLab Pagesの内部ポート |
| `service.name`                                           | `gitlab-pages`                                          | GitLab Pagesサービス名 |
| `service.annotations`                                    |                                                         | すべてのPagesサービスの注釈。 |
| `service.primary.annotations`                            |                                                         | プライマリサービスのみの注釈。 |
| `service.metrics.annotations`                            |                                                         | メトリクスサービスのみの注釈。 |
| `service.customDomains.annotations`                      |                                                         | カスタムドメインサービスのみの注釈。 |
| `service.customDomains.type`                             | `LoadBalancer`                                          | カスタムドメインの処理用に作成されたサービスの種類 |
| `service.customDomains.internalHttpsPort`                | `8091`                                                  | PagesデーモンがHTTPSリクエストをリッスンするポート |
| `service.customDomains.internalHttpsPort`                | `8091`                                                  | PagesデーモンがHTTPSリクエストをリッスンするポート |
| `service.customDomains.nodePort.http`                    |                                                         | HTTP接続用に開かれるノードポート。`service.customDomains.type`が`NodePort`の場合にのみ有効です |
| `service.customDomains.nodePort.https`                   |                                                         | HTTPS接続用に開かれるノードポート。`service.customDomains.type`が`NodePort`の場合にのみ有効です |
| `service.sessionAffinity`                                | `None`                                                  | セッションアフィニティの種類。`ClientIP`または`None`のいずれかである必要があります（これは、クラスタ内から発信されたトラフィックにのみ意味があります）。 |
| `service.sessionAffinityConfig`                          |                                                         | セッションアフィニティ設定。`service.sessionAffinity` == `ClientIP`の場合、デフォルトのセッションスティッキー時間は3時間（`10800`）です |
| `serviceAccount.annotations`                             | `{}`                                                    | ServiceAccount注釈 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                 | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                 | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                         | ServiceAccountの名前。設定しない場合、チャートの完全な名前が使用されます |
| `serviceLabels`                                          | `{}`                                                    | 補足サービスラベル |
| `tolerations`                                            | `[]`                                                    | ポッド割り当てのTolerationラベル |

### Pages固有の設定 {#pages-specific-settings}

| パラメータ                   | デフォルト | 説明 |
|-----------------------------|---------|-------------|
| `artifactsServerTimeout`    | `10`    | アーティファクトサーバーへのプロキシリクエストのタイムアウト（秒単位）。 |
| `artifactsServerUrl`        |         | アーティファクトリクエストのプロキシ先となるAPI URL。 |
| `extraVolumeMounts`         |         | 追加する追加ボリュームマウントのリスト |
| `extraVolumes`              |         | 作成する追加ボリュームのリスト |
| `gitlabCache.cleanup`       | int     | 参照: [Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabCache.expiry`        | int     | 参照: [Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabCache.refresh`       | int     | 参照: [Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabClientHttpTimeout`   |         | GitLab API HTTPクライアント接続タイムアウト（秒単位）。 |
| `gitlabClientJwtExpiry`     |         | JWTトークンの有効期限（秒単位）。 |
| `gitlabRetrieval.interval`  | int     | 参照: [Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabRetrieval.retries`   | int     | 参照: [Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabRetrieval.timeout`   | int     | 参照: [Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabServer`              |         | GitLabサーバーFQDN |
| `headers`                   | `[]`    | 各応答とともにクライアントに送信する必要がある追加のHTTPヘッダーを指定します。複数のヘッダーを配列として指定でき、ヘッダーと値は1つの文字列として記述します（例: `['my-header: myvalue', 'my-other-header: my-other-value']`）。 |
| `insecureCiphers`           | `false` | 3DESやRC4などの脆弱な暗号を含む可能性のある、暗号スイートのデフォルトリストを使用します。 |
| `internalGitlabServer`      |         | APIリクエストに使用される内部GitLabサーバー |
| `logFormat`                 | `json`  | ログ出力形式 |
| `logVerbose`                | `false` | 詳細ログ |
| `maxConnections`            |         | HTTP、HTTPS、またはプロキシリスナーへの同時接続数の制限。 |
| `maxURILength`              |         | URIの長さを制限します。無制限の場合は0。デフォルトの設定については、[GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings)の`max_uri_length`を参照してください |
| `propagateCorrelationId`    |         | 受信リクエストヘッダー`X-Request-ID`に既存の相関IDが存在する場合、それを再利用します |
| `redirectHttp`              | `false` | HTTPからHTTPSにページをリダイレクトします。 |
| `sentry.enabled`            | `false` | Sentryレポートを有効にします |
| `sentry.dsn`                |         | Sentryクラッシュレポートの送信先アドレス |
| `sentry.environment`        |         | Sentryクラッシュレポートの環境 |
| `serverShutdowntimeout`     | `30s`   | GitLab Pagesサーバーのシャットダウンタイムアウト（秒単位） |
| `statusUri`                 |         | ステータスページのURIパス |
| `tls.minVersion`            |         | 最小SSL/TLSバージョンを指定します |
| `tls.maxVersion`            |         | 最大SSL/TLSバージョンを指定します |
| `useHTTPProxy`              | `false` | GitLab Pagesがリバースプロキシの背後にある場合は、このオプションを使用します。 |
| `useProxyV2`                | `false` | PROXYv2プロトコルを利用するためにHTTPSリクエストを強制します。 |
| `zipCache.cleanup`          | int     | 参照: [Zip Serving and Cache Configuration](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipCache.expiration`       | int     | 参照: [Zip Serving and Cache Configuration](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipCache.refresh`          | int     | 参照: [Zip Serving and Cache Configuration](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipOpenTimeout`            | int     | 参照: [Zip Serving and Cache Configuration](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipHTTPClientTimeout`      | int     | 参照: [Zip Serving and Cache Configuration](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `rateLimitSourceIP`         |         | 参照: [GitLab Pagesレート制限](https://docs.gitlab.com/administration/pages/#rate-limits)。 |
| `rateLimitSourceIPBurst`    |         | 参照: [GitLab Pagesレート制限](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitDomain`           |         | 参照: [GitLab Pagesレート制限](https://docs.gitlab.com/administration/pages/#rate-limits)。 |
| `rateLimitDomainBurst`      |         | 参照: [GitLab Pagesレート制限](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitTLSSourceIP`      |         | 参照: [GitLab Pagesレート制限](https://docs.gitlab.com/administration/pages/#rate-limits)。 |
| `rateLimitTLSSourceIPBurst` |         | 参照: [GitLab Pagesレート制限](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitTLSDomain`        |         | 参照: [GitLab Pagesレート制限](https://docs.gitlab.com/administration/pages/#rate-limits)。 |
| `rateLimitTLSDomainBurst`   |         | 参照: [GitLab Pagesレート制限](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitSubnetsAllowList` |         | 参照: [GitLab Pagesレート制限](#rate-limits) |
| `serverReadTimeout`         | `5s`    | 参照: [GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverReadHeaderTimeout`   | `1s`    | 参照: [GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverWriteTimeout`        | `5m`    | 参照: [GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverKeepAlive`           | `15s`   | 参照: [GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `authTimeout`               | `5s`    | 参照: [GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `authCookieSessionTimeout`  | `10m`   | 参照: [GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |

### `ingress`を設定する {#configuring-the-ingress}

このセクションでは、GitLab Pages Ingressを制御します。

| 名前                   |  型   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | 文字列  |         | `apiVersion`フィールドで使用する値。 |
| `annotations`          | 文字列  |         | このフィールドは、[Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)の標準`annotations`と完全に一致します。 |
| `configureCertmanager` | ブール値 | `false` | Ingress注釈`cert-manager.io/issuer`および`acme.cert-manager.io/http01-edit-in-place`を切り替えます。ワイルドカード証明書の取得には[DNS01ソルバー](https://cert-manager.io/docs/configuration/acme/dns01/)を備えたcert-manager Issuerが必要であり、このチャートによってデプロイされたIssuerは[HTTP01ソルバー](https://cert-manager.io/docs/configuration/acme/http01/)のみを提供するため、cert-managerを介したGitLab PagesのTLS証明書の取得は無効になっています。詳細については、[GitLab PagesのTLS要件](../../../installation/tls.md)を参照してください。 |
| `enabled`              | ブール値 |         | サービスでサポートするIngressオブジェクトを作成するかどうかを制御するための設定。設定されていない場合、`global.ingress.enabled`設定が使用されます。 |
| `tls.enabled`          | ブール値 |         | `false`に設定すると、PagesサブチャートのTLSが無効になります。これは、`ingress-level`でTLS終端を使用できない場合（TLS終端プロキシがIngressコントローラーの前にある場合など）に特に役立ちます。 |
| `tls.secretName`       | 文字列  |         | ページURIの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定されていない場合、代わりに`global.ingress.tls.secretName`が使用されます。設定されていないデフォルト。 |

## チャート設定例 {#chart-configuration-examples}

### extraVolumes {#extravolumes}

`extraVolumes`を使用すると、チャート全体の追加ボリュームを設定できます。

`extraVolumes`の使用例を以下に示します:

```yaml
extraVolumes: |
  - name: example-volume
    persistentVolumeClaim:
      claimName: example-pvc
```

### extraVolumeMounts {#extravolumemounts}

`extraVolumeMounts`を使用すると、チャート全体のすべてのコンテナで追加のvolumeMountsを設定できます。

`extraVolumeMounts`の使用例を以下に示します:

```yaml
extraVolumeMounts: |
  - name: example-volume
    mountPath: /etc/example
```

### `networkpolicy`を設定する {#configuring-the-networkpolicy}

このセクションでは、[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この設定はオプションで、ポッドのエグレスとイングレスを特定エンドポイントに制限するために使用されます。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定は`NetworkPolicy`を有効にします |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークポリシーがアクティブになります。ルールが指定されていない限り、これによりすべてのIngress接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | Ingressポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および以下の例を参照してください |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークポリシーがアクティブになります。ルールが指定されていない限り、これによりすべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および以下の例を参照してください |

### ネットワークポリシーの例 {#example-network-policy}

`gitlab-pages`サービスには、ポート80および443のIngress接続と、デフォルトのworkhorseポート8181へのさまざまなエグレス接続が必要です。この例では、次のネットワークポリシーを追加します:

- Ingressリクエストを許可:
  - `nginx-ingress`ポッドからポート`8090`へ
  - `prometheus`ポッドからポート`9235`へ
- エグレスリクエストを許可:
  - `kube-dns`のポート`53`へ
  - `webservice`ポッドからポート`8181`へ
  - S3のAWS VPCエンドポイントなどのエンドポイントから、ポート`443`の`172.16.1.0/24`へ

_提供されている例は単なる例であり、完全ではない可能性があることに注意してください_

この例は、`kube-dns`がネームスペース`kube-system`に、`prometheus`がネームスペース`monitoring`に、`nginx-ingress`がネームスペース`nginx-ingress`にデプロイされたという前提に基づいています。

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
          - port: 9235
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 8090
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
          - podSelector:
              matchLabels:
                app: webservice
        ports:
          - port: 8181
```

### GitLab PagesへのTLSアクセス {#tls-access-to-gitlab-pages}

GitLab Pages機能へのTLSアクセスを実現するには、次の手順に従ってください:

1. この形式でGitLab Pagesドメイン専用のワイルドカード証明書を作成します: `*.pages.<yourdomain>`。

1. Kubernetesでシークレットを作成します:

   ```shell
   kubectl create secret tls tls-star-pages-<mysecret> --cert=<path/to/fullchain.pem> --key=<path/to/privkey.pem>
   ```

1. このシークレットを使用するようにGitLab Pagesを設定します:

   ```yaml
   gitlab:
     gitlab-pages:
       ingress:
         tls:
           secretName: tls-star-pages-<mysecret>
   ```

1. `*.pages.<yourdomaindomain>`を指す名前で、DNSプロバイダーにDNSエントリを作成します。

### ワイルドカードDNSのないPagesドメイン {#pages-domain-without-wildcard-dns}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5570) (GitLab 17.2の[ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)版として)。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)になりました。

{{< /history >}}

{{< alert type="warning" >}}

GitLab Pagesは、一度に1つのURIスキームのみをサポートします: ワイルドカードDNSを使用するか、ワイルドカードDNSを使用しないかのいずれかです。`namespaceInPath`を有効にすると、既存のGitLab Pages Webサイトには、ワイルドカードDNSなしで、ドメイン上でのみアクセスできます。

{{< /alert >}}

1. グローバルなPages設定で`namespaceInPath`を有効にします。

   ```yaml
   global:
     pages:
       namespaceInPath: true
   ```

1. `pages.<yourdomaindomain>`という名前で、お使いのDNSプロバイダーにエントリを作成し、ロードバランサーを指すようにします。

#### ワイルドカードDNSなしのGitLab PagesドメインへのTLSアクセス {#tls-access-to-gitlab-pages-domain-without-wildcard-dns}

1. この形式で、GitLab Pagesドメインの証明書を作成します: `pages.<yourdomain>`。
1. Kubernetesでシークレットを作成します:

   ```shell
   kubectl create secret tls tls-star-pages-<mysecret> --cert=<path/to/fullchain.pem> --key=<path/to/privkey.pem>
   ```

1. このシークレットを使用するようにGitLab Pagesを設定します:

   ```yaml
   gitlab:
     gitlab-pages:
       ingress:
         tls:
           secretName: tls-star-pages-<mysecret>
   ```

#### アクセス制御の設定 {#configure-access-control}

1. グローバルなPages設定で`accessControl`を有効にします。

   ```yaml
   global:
     pages:
       accessControl: true
   ```

1. オプション。[TLSアクセス](#tls-access-to-gitlab-pages-domain-without-wildcard-dns)が構成されている場合は、GitLab Pagesの[システムOAuthアプリケーション](https://docs.gitlab.com/integration/oauth_provider/#create-an-instance-wide-application)のリダイレクトURIを更新して、HTTPSプロトコルを使用してください。

{{< alert type="warning" >}}

GitLab PagesはOAuthアプリケーションを更新せず、デフォルトの`authRedirectUri`が`https://pages.<yourdomaindomain>/projects/auth`に更新されます。プライベートのPagesサイトにアクセス中に「リダイレクトURIが無効です」というエラーが発生した場合は、GitLab Pagesの[システムOAuthアプリケーション](https://docs.gitlab.com/integration/oauth_provider/#create-an-instance-wide-application)のリダイレクトURIを`https://pages.<yourdomaindomain>/projects/auth`に更新してください。

{{< /alert >}}

### レート制限 {#rate-limits}

サービス拒否（DoS）攻撃のリスクを最小限に抑えるために、レート制限を適用できます。詳細な[レート制限のドキュメント](https://docs.gitlab.com/administration/pages/#rate-limits)をご利用いただけます。

特定のIP範囲（サブネット）がすべてのレート制限を回避できるようにするには、次の手順に従います:

- `rateLimitSubnetsAllowList`: すべてのレート制限を回避させるIP範囲（サブネット）を指定する許可リストを設定します。

#### レート制限のサブネット許可リストを設定する {#configure-rate-limits-subnets-allow-list}

`charts/gitlab/charts/gitlab-pages/values.yaml`で、IP範囲（サブネット）を持つ許可リストを設定します:

```yaml
gitlab:
  gitlab-pages:
    rateLimitSubnetsAllowList:
     - "1.2.3.4/24"
     - "2001:db8::1/32"
```

### KEDAの設定 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルト設定されています。

以下が当てはまる場合、`hpa`セクションで設定されたCPUとメモリのしきい値に基づいて、CPUとメモリのトリガーが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定も、ゼロ以外の値に設定されます。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAのドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | 最後のアクティブとレポートされたトリガーの後に、リソースを0にスケールバックするまで待機する期間 |
| `minReplicaCount`               | 整数 | `hpa.minReplicas`               | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `maxReplicaCount`               | 整数 | `hpa.maxReplicas`               | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `fallback`                      |   マップ   |                                 | KEDAのフォールバックの設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | アップスケールとダウンスケール動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`からコンピューティングされたトリガーにデフォルト設定されます |

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成する必要があるかどうか、およびデフォルトのアクセストークンをポッドにマウントする必要があるかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountの注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | の設定は、デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定しない場合、チャートのフルネームが使用されます。 |

### アフィニティ {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。
