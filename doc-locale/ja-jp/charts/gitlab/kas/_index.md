---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab `kas` チャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`kas`サブチャートは、構成可能な[Kubernetes向けGitLabエージェントサーバー (KAS)](https://docs.gitlab.com/administration/clusters/kas/)のデプロイを提供します。エージェントサーバーは、GitLabと共にインストールするコンポーネントです。[Kubernetes向けGitLabエージェント](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent)の管理に必要です。

このチャートは、GitLab APIおよびGitalyサーバーへのアクセスに依存します。このチャートを有効にすると、Ingressがデプロイされます。

リソース消費を最小限に抑えるため、`kas`コンテナはディストロレスイメージを使用します。デプロイされたサービスはIngressによって公開され、通信には[WebSocketプロキシ](https://nginx.org/en/docs/http/websocket.html)が使用されます。このプロキシにより、外部コンポーネントである[`agentk`](https://docs.gitlab.com/user/clusters/agent/install/)との長期接続が可能になります。`agentk`はKubernetesクラスタ側のエージェントの対応物です。

サービスにアクセスするためのルートは、[Ingress設定](#specify-an-ingress)によって異なります。

詳しくは、[Kubernetes向けGitLabエージェントのアーキテクチャ](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md)をご覧ください。

## エージェントサーバーを無効にする {#disable-the-agent-server}

GitLabエージェントサーバー（`kas`）は、デフォルトで有効になっています。GitLabインスタンスで無効にするには、Helmプロパティ`global.kas.enabled`を`false`に設定します。

例: 

```shell
helm upgrade --install kas --set global.kas.enabled=false
```

### Ingressの指定 {#specify-an-ingress}

チャートのIngressをデフォルトの設定で使用すると、エージェントサーバーのサービスはサブドメインで到達可能になります。たとえば、`global.hosts.domain: example.com`の場合、エージェントサーバーは`kas.example.com`で到達可能です。

[KAS Ingress](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/kas/templates/ingress.yaml)は、`global.hosts.domain`とは異なるドメインを使用できます。

`global.hosts.kas.name`を設定します。例:

```shell
global.hosts.kas.name: kas.my-other-domain.com
```

この例では、KAS Ingressのホストとして`kas.my-other-domain.com`のみを使用します。その他のサービス（GitLab、レジストリ、MinIOなど）は、`global.hosts.domain`で指定されたドメインを使用します。

### コマンドラインオプションのインストール {#installation-command-line-options}

これらのパラメータを、`--set`フラグを使用して、`helm install`コマンドに渡すことができます。

| パラメータ                                                | デフォルト                                               | 説明 |
|----------------------------------------------------------|-------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                  | ポッドの割り当てに関する[アフィニティルール](../_index.md#affinity) |
| `annotations`                                            | `{}`                                                  | ポッドの注釈。 |
| `common.labels`                                          | `{}`                                                  | このチャートによって作成されたすべてのオブジェクトに適用される補助ラベル。 |
| `securityContext.runAsUser`                              | `65532`                                               | ポッドが起動されるユーザーID |
| `securityContext.runAsGroup`                             | `65534`                                               | ポッドが起動されるグループID |
| `securityContext.fsGroup`                                | `65532`                                               | ポッドが起動されるグループID |
| `securityContext.fsGroupChangePolicy`                    |                                                       | ボリュームの所有権と許可を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                      | 使用するSeccompプロファイル |
| `containerSecurityContext.runAsUser`                     | `65532`                                               | コンテナが起動される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)ユーザーIDのオーバーライド |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                               | コンテナのプロセスが、親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                           | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `extraContainers`                                        |                                                       | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列。 |
| `extraEnv`                                               |                                                       | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                       | 公開する他のデータソースからの追加の環境変数のリスト |
| `init.containerSecurityContext`                          |                                                       | initコンテナsecurityContextオーバーライド |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                               | initContainer固有: プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                | initContainer固有: コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                           | initContainer固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-kas` | イメージリポジトリ。 |
| `image.tag`                                              | `v13.7.0`                                             | イメージバージョン。  |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`     | 動作には、アップスケールとダウンスケールの動作の仕様が含まれています（`autoscaling/v2beta2`以降が必要です）。 |
| `hpa.customMetrics`                                      | `[]`                                                  | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                                     | `AverageValue`                                        | オートスケールCPUターゲットの種類を設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                | オートスケールCPUターゲット値を設定します。 |
| `hpa.cpu.targetAverageUtilization`                       |                                                       | オートスケールCPUターゲット使用率を設定します。 |
| `hpa.memory.targetType`                                  |                                                       | オートスケールメモリターゲットの種類を設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.memory.targetAverageValue`                          |                                                       | オートスケールメモリターゲット値を設定します。 |
| `hpa.memory.targetAverageUtilization`                    |                                                       | オートスケールメモリターゲット使用率を設定します。 |
| `hpa.targetAverageValue`                                 |                                                       | **非推奨** オートスケールCPUターゲット値を設定します |
| `ingress.enabled`                                        | `global.kas.enabled=true`の場合`true`                   | `kas.ingress.enabled`を使用して、明示的にオンまたはオフにすることができます。設定されていない場合は、オプションで`global.ingress.enabled`を同じ目的で使用できます。 |
| `ingress.apiVersion`                                     |                                                       | `apiVersion`フィールドで使用する値。 |
| `ingress.annotations`                                    | `{}`                                                  | Ingressの注釈。 |
| `ingress.tls`                                            | `{}`                                                  | Ingress TLS設定。 |
| `ingress.agentPath`                                      | `/`                                                   | エージェントAPIエンドポイントのIngressパス。 |
| `ingress.k8sApiPath`                                     | `/k8s-proxy`                                          | Kubernetes APIエンドポイントのIngressパス。 |
| `keda.enabled`                                           | `false`                                               | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                  | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                 | 最後のアクティブと報告されたトリガーの後、リソースを0にスケールバックするまで待機する期間 |
| `keda.minReplicaCount`                                   |                                                       | KEDAがリソースをスケールダウンするレプリカの最小数。`minReplicas`がデフォルトです |
| `keda.maxReplicaCount`                                   |                                                       | KEDAがリソースをスケールアップするレプリカの最大数。`maxReplicas`がデフォルトです |
| `keda.fallback`                                          |                                                       | KEDAフォールバック設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           |                                                       | KEDAが作成するHPAリソースの名前。`keda-hpa-{scaled-object-name}`がデフォルトです |
| `keda.restoreToOriginalReplicaCount`                     |                                                       | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          |                                                       | アップスケールとダウンスケールの動作の仕様。`hpa.behavior`がデフォルトです |
| `keda.triggers`                                          |                                                       | ターゲットリソースのスケールをアクティブ化するトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーがデフォルトです |
| `metrics.enabled`                                        | `true`                                                | メトリクスエンドポイントをスクレイプするために使用可能にする必要がある場合。 |
| `metrics.path`                                           | `/metrics`                                            | メトリクスエンドポイントのパス。 |
| `metrics.serviceMonitor.enabled`                         | `false`                                               | Prometheus Operatorがメトリクスのスクレイプを管理できるようにServiceMonitorを作成する必要がある場合。有効にすると、`prometheus.io`スクレイプ注釈が削除されます。`metrics.podMonitor.enabled`と一緒に有効にすることはできません。 |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                  | ServiceMonitorに追加する追加のラベル。 |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                  | ServiceMonitorの追加のエンドポイント設定。 |
| `metrics.podMonitor.enabled`                             | `false`                                               | Prometheus Operatorがメトリクスのスクレイプを管理できるようにPodMonitorを作成する必要がある場合。有効にすると、`prometheus.io`スクレイプ注釈が削除されます。`metrics.serviceMonitor.enabled`と一緒に有効にすることはできません。 |
| `metrics.podMonitor.additionalLabels`                    | `{}`                                                  | PodMonitorに追加する追加のラベル。 |
| `metrics.podMonitor.endpointConfig`                      | `{}`                                                  | PodMonitorの追加のエンドポイント設定。 |
| `maxReplicas`                                            | `10`                                                  | HPA `maxReplicas`。 |
| `maxUnavailable`                                         | `1`                                                   | HPA `maxUnavailable`。 |
| `minReplicas`                                            | `2`                                                   | HPA `maxReplicas`。 |
| `nodeSelector`                                           |                                                       | 存在する場合は、この`Deployment`の`Pod`の[ノードセレクター](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)を定義します。 |
| `observability.port`                                     | `8151`                                                | 可観測性エンドポイントのポート。メトリクスおよびプローブエンドポイントに使用されます。 |
| `observability.livenessProbe.path`                       | `/liveness`                                           | ライブネスプローブエンドポイントのURI。この値は、KASサービス設定の`observability.liveness_probe.url_path`値と一致する必要があります。 |
| `observability.readinessProbe.path`                      | `/readiness`                                          | ReadinessプローブエンドポイントのURI。この値は、KASサービス設定の`observability.readiness_probe.url_path`値と一致する必要があります。 |
| `serviceAccount.annotations`                             | `{}`                                                  | サービスアカウントの注釈。 |
| `podLabels`                                              | `{}`                                                  | 補助ポッドのラベル。セレクターには使用されません。 |
| `serviceLabels`                                          | `{}`                                                  | 補助サービスラベル。 |
| `common.labels`                                          |                                                       | このチャートによって作成されたすべてのオブジェクトに適用される補助ラベル。 |
| `resources.requests.cpu`                                 | `100m`                                                | KASポッドあたりの最小CPUリクエスト |
| `resources.requests.memory`                              | `256Mi`                                               | KASポッドメモリあたりの最小メモリリクエスト。 |
| `service.externalPort`                                   | `8150`                                                | 外部ポート（`agentk`接続用）。 |
| `service.internalPort`                                   | `8150`                                                | 内部ポート（`agentk`接続用）。 |
| `service.apiInternalPort`                                | `8153`                                                | 内部API（GitLabバックエンド用）の内部ポート。 |
| `service.loadBalancerIP`                                 | `nil`                                                 | `service.type`が`LoadBalancer`の場合のカスタムロードバランサーIP。 |
| `service.loadBalancerSourceRanges`                       | `nil`                                                 | `service.type`が`LoadBalancer`の場合のカスタムロードバランサーソース範囲のリスト。 |
| `service.kubernetesApiPort`                              | `8154`                                                | プロキシされたKubernetes APIを公開するための外部ポート。 |
| `service.privateApiPort`                                 | `8155`                                                | `kas`のプライベートAPIを公開する内部ポート（`kas` -> `kas`通信用）。 |
| `serviceAccount.annotations`                             | `{}`                                                  | サービスアカウントの注釈。 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                               | デフォルトのサービスアカウントのアクセストークンをポッドにマウントするかどうかを示します。 |
| `serviceAccount.create`                                  | `false`                                               | サービスアカウントを作成するかどうかを示します。 |
| `serviceAccount.enabled`                                 | `false`                                               | サービスアカウントを使用するかどうかを示します。 |
| `serviceAccount.name`                                    |                                                       | サービスアカウントの名前。設定しない場合は、チャートのフルネームが使用されます。 |
| `websocketToken.secret`                                  | 自動生成                                         | WebSocketトークンの署名と検証に使用するシークレットの名前。 |
| `websocketToken.key`                                     | 自動生成                                         | 使用する`websocketToken.secret`の中のキーの名前。 |
| `privateApi.secret`                                      | 自動生成                                         | データベースの認証に使用するシークレットの名前。 |
| `privateApi.key`                                         | 自動生成                                         | 使用する`privateApi.secret`の中のキーの名前。 |
| `global.kas.service.apiExternalPort`                     | `8153`                                                | 内部API（GitLabバックエンド用）の外部ポート。 |
| `service.type`                                           | `ClusterIP`                                           | サービスタイプ。 |
| `tolerations`                                            | `[]`                                                  | ポッドの割り当てに関する容認ラベル。 |
| `customConfig`                                           | `{}`                                                  | 指定された場合、`kas`のデフォルトの設定をこれらの値とマージし、ここに定義されたものを優先します。 |
| `deployment.minReadySeconds`                             | `0`                                                   | `kas`ポッドが準備完了と見なされるまでに経過する必要がある最小秒数。 |
| `deployment.strategy`                                    | `{}`                                                  | デプロイで使用される更新戦略を構成できます。 |
| `deployment.terminationGracePeriodSeconds`               | `300`                                                 | ポッドがSIGTERMを受信した後、シャットダウンに費やすことができる時間（秒単位）。 |
| `priorityClassName`                                      |                                                       | ポッドに割り当てられた[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |

## TLS通信を有効にする {#enable-tls-communication}

[グローバルKAS属性](../../globals.md#tls-settings-1)を介して、`kas`ポッドと他のGitLabチャートコンポーネント間のTLS通信を有効にします。

## `kas`チャートをテストする {#test-the-kas-chart}

チャートをインストールするには:

1. 独自のKubernetesクラスタを作成します。
1. マージリクエストの作業ブランチをチェックアウトします。
1. ローカルチャートブランチからデフォルトで有効になっている`kas`を使用してGitLabをインストール（またはアップグレード）します:

   ```shell
   helm upgrade --force --install gitlab . \
     --timeout 600s \
     --set global.hosts.domain=your.domain.com \
     --set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
     --set certmanager-issuer.email=your@email.com
   ```

1. GDKを使用して、[Kubernetes向けGitLabエージェント](https://docs.gitlab.com/user/clusters/agent/)を構成および使用するプロセスを実行します: （エージェントを手動で構成して使用する手順に従うこともできます）。

   1. GDK GitLabリポジトリから、QAフォルダーに移動します: `cd qa`。
   1. 次のコマンドを実行して、QAテストを実行します:

      ```shell
      GITLAB_USERNAME=$ROOT_USER
      GITLAB_PASSWORD=$ROOT_PASSWORD
      GITLAB_ADMIN_USERNAME=$ROOT_USER
      GITLAB_ADMIN_PASSWORD=$ROOT_PASSWORD
      bundle exec bin/qa Test::Instance::All https://your.gitlab.domain/ -- --tag orchestrated --tag quarantine qa/specs/features/ee/api/7_configure/kubernetes/kubernetes_agent_spec.rb
      ```

      また、環境変数を使用してインストールする`agentk`バージョンをカスタマイズすることもできます: `GITLAB_AGENTK_VERSION=v13.7.1`

## KEDAの設定 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに、[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムメトリクスまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する`hpa`セクションで設定された値にデフォルト設定されます。

次がtrueの場合、`hpa`セクションで設定されたCPUおよびメモリのしきい値に基づいて、CPUおよびメモリトリガーが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定も、ゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト | 説明 |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | ブール値 | `false` | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`    | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`   | 最後のアクティブと報告されたトリガーの後、リソースを0にスケールバックするまで待機する期間 |
| `minReplicaCount`               | 整数 |         | KEDAがリソースをスケールダウンするレプリカの最小数。`minReplicas`がデフォルトです |
| `maxReplicaCount`               | 整数 |         | KEDAがリソースをスケールアップするレプリカの最大数。`maxReplicas`がデフォルトです |
| `fallback`                      |   マップ   |         | KEDAフォールバック設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  |         | KEDAが作成するHPAリソースの名前。`keda-hpa-{scaled-object-name}`がデフォルトです |
| `restoreToOriginalReplicaCount` | ブール値 |         | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   |         | アップスケールとダウンスケールの動作の仕様。`hpa.behavior`がデフォルトです |
| `triggers`                      |  配列  |         | ターゲットリソースのスケールをアクティブ化するトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーがデフォルトです |

### サービスアカウント {#serviceaccount}

このセクションでは、サービスアカウントを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | サービスアカウントの注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかは、の設定で制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | サービスアカウントを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | サービスアカウントを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | サービスアカウントの名前。設定しない場合は、チャートのフルネームが使用されます。 |

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

## デバッグログを有効にする {#enable-debug-logging}

KASサブチャートのデバッグロギングを有効にするには、`values.yaml`ファイルの`kas`セクションに以下を追加します:

```yaml
customConfig:
   observability:
      logging:
         level: debug
         grpc_level: debug
```
