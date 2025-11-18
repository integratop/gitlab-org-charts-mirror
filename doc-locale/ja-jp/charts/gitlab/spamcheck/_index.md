---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-Spamcheckチャートの使用
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`spamcheck`サブチャートは、元々GitLab.comでのスパムの増加に対抗するためにGitLabによって開発され、後にGitLab自己管理で使用するために公開されたアンチスパムエンジンである[Spamcheck](https://gitlab.com/gitlab-org/spamcheck)のデプロイを提供します。

## 要件 {#requirements}

このチャートは、GitLab APIへのアクセスに依存します。

## 設定 {#configuration}

### Spamcheckを有効にする {#enable-spamcheck}

`spamcheck`は、デフォルトで無効になっています。GitLabインスタンスで有効にするには、Helmプロパティ`global.spamcheck.enabled`を`true`に設定します。以下に例を示します:

```shell
helm upgrade --force --install gitlab . \
--set global.hosts.domain='your.domain.com' \
--set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
--set certmanager-issuer.email='me@example.com' \
--set global.spamcheck.enabled=true
```

### Spamcheckを使用するようにGitLabを設定する {#configure-gitlab-to-use-spamcheck}

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. 左側のサイドバーの下部にある**設定 > レポート**を選択します。
1. **スパムとアンチボット対策**を展開します。
1. スパムチェック設定を更新します:
   1. 「外部APIエンドポイント経由でスパムチェックを有効にする」チェックボックスをオンにします。
   1. 外部スパムチェックエンドポイントのURLには、`grpc://gitlab-spamcheck.default.svc:8001`を使用します。`default`は、GitLabがデプロイされているKubernetesネームスペースに置き換えられます。
   1. 「スパムチェックAPIキー」は空白のままにします。
1. **変更を保存**を選択します。

## インストールコマンドラインオプション {#installation-command-line-options}

以下の表に、`helm install`フラグを使用して`--set`コマンドに指定できるすべてのチャートの設定を示します。

| パラメータ                                       | デフォルト                                                                                              | 説明 |
|-------------------------------------------------|------------------------------------------------------------------------------------------------------|-------------|
| `affinity`                                      | `{}`                                                                                                 | ポッドの割り当てに対する[アフィニティールール](../_index.md#affinity) |
| `annotations`                                   | `{}`                                                                                                 | ポッド注釈 |
| `common.labels`                                 | `{}`                                                                                                 | このチャートによって作成されたすべてのオブジェクトに適用される補足的なラベル。 |
| `deployment.livenessProbe.initialDelaySeconds`  | `20`                                                                                                 | 活性プローブが開始されるまでの遅延 |
| `deployment.livenessProbe.periodSeconds`        | `60`                                                                                                 | 活性プローブを実行する頻度 |
| `deployment.livenessProbe.timeoutSeconds`       | `30`                                                                                                 | 活性プローブがタイムアウトになるタイミング |
| `deployment.livenessProbe.successThreshold`     | `1`                                                                                                  | 失敗後に活性プローブが成功したと見なされるための最小連続成功数 |
| `deployment.livenessProbe.failureThreshold`     | `3`                                                                                                  | 活性プローブが成功後に失敗したと見なされるための最小連続失敗数 |
| `deployment.readinessProbe.initialDelaySeconds` | `0`                                                                                                  | 準備プローブが開始されるまでの遅延 |
| `deployment.readinessProbe.periodSeconds`       | `10`                                                                                                 | 準備プローブを実行する頻度 |
| `deployment.readinessProbe.timeoutSeconds`      | `2`                                                                                                  | 準備プローブがタイムアウトになるタイミング |
| `deployment.readinessProbe.successThreshold`    | `1`                                                                                                  | 失敗後に準備プローブが成功したと見なされるための最小連続成功数 |
| `deployment.readinessProbe.failureThreshold`    | `3`                                                                                                  | 準備プローブが成功後に失敗したと見なされるための最小連続失敗数 |
| `deployment.strategy`                           | `{}`                                                                                                 | デプロイで使用される更新仕様を設定できます。指定されていない場合、クラスタリングのデフォルトが使用されます。 |
| `hpa.behavior`                                  | `{scaleDown: {stabilizationWindowSeconds: 300 }}`                                                    | 動作には、スケールアップおよびダウンスケール動作の仕様が含まれています（`autoscaling/v2beta2`以降が必要です）。 |
| `hpa.customMetrics`                             | `[]`                                                                                                 | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で設定された平均CPU使用率のデフォルトの使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                            | `AverageValue`                                                                                       | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                    | `100m`                                                                                               | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`              |                                                                                                      | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                         |                                                                                                      | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                 |                                                                                                      | オートスケールメモリターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`           |                                                                                                      | オートスケールメモリターゲット使用率を設定します |
| `hpa.targetAverageValue`                        |                                                                                                      | **非推奨** オートスケールCPUターゲット値を設定します |
| `image.registry`                                |                                                                                                      | Spamcheckイメージレジストリ |
| `image.repository`                              | `registry.gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/spam/spamcheck` | Spamcheckイメージリポジトリ |
| `image.tag`                                     |                                                                                                      | Spamcheckイメージタグ |
| `image.digest`                                  |                                                                                                      | Spamcheckイメージダイジェスト |
| `keda.enabled`                                  | `false`                                                                                              | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                          | `30`                                                                                                 | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                           | `300`                                                                                                | リソースを0にスケールバックする前に、最後のトリガーがアクティブをレポートしてから待機する期間 |
| `keda.minReplicaCount`                          | `hpa.minReplicas`                                                                                    | レプリカの最小数。KEDAはリソースをそれ以下にスケールダウンします。 |
| `keda.maxReplicaCount`                          | `hpa.maxReplicas`                                                                                    | レプリカの最大数。KEDAはリソースをそれ以上にスケールアップします。 |
| `keda.fallback`                                 |                                                                                                      | KEDAフォールバック設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                  | `keda-hpa-{scaled-object-name}`                                                                      | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`            |                                                                                                      | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                 | `hpa.behavior`                                                                                       | スケールアップおよびスケールダウン動作の仕様。 |
| `keda.triggers`                                 |                                                                                                      | ターゲットリソースのスケールをアクティブ化するトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーがデフォルトです。 |
| `listenAddr`                                    | `[::]`                                                                                               | 内部リッスンアドレス。 |
| `logging.level`                                 | `info`                                                                                               | ログレベル   |
| `maxReplicas`                                   | `10`                                                                                                 | HPA `maxReplicas` |
| `maxUnavailable`                                | `1`                                                                                                  | HPA `maxUnavailable` |
| `minReplicas`                                   | `2`                                                                                                  | HPA `maxReplicas` |
| `podLabels`                                     | `{}`                                                                                                 | 補足的なポッドラベル。セレクターには使用されません。 |
| `resources.requests.cpu`                        | `100m`                                                                                               | Spamcheckの最小CPU |
| `resources.requests.memory`                     | `100M`                                                                                               | Spamcheckの最小メモリ |
| `securityContext.fsGroup`                       | `1000`                                                                                               | ポッドを開始するグループID |
| `securityContext.runAsUser`                     | `1000`                                                                                               | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`           |                                                                                                      | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `serviceLabels`                                 | `{}`                                                                                                 | 補足的なサービスラベル |
| `service.externalPort`                          | `8001`                                                                                               | Spamcheckの外部ポート |
| `service.internalPort`                          | `8001`                                                                                               | Spamcheckの内部ポート |
| `service.type`                                  | `ClusterIP`                                                                                          | Spamcheckサービスタイプ |
| `serviceAccount.automountServiceAccountToken`   | `false`                                                                                              | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                         | `false`                                                                                              | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                        | `false`                                                                                              | ServiceAccountを使用するかどうかを示します |
| `tolerations`                                   | `[]`                                                                                                 | ポッド割り当てのトレランスラベル |
| `extraEnvFrom`                                  | `{}`                                                                                                 | 公開する他のデータソースからの追加の環境変数のリスト |
| `priorityClassName`                             |                                                                                                      | ポッドに割り当てられる[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |

## KEDAの設定 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムメトリクスまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルト設定されます。

以下が当てはまる場合、`hpa`セクションで設定されたCPUおよびメモリのしきい値に基づいて、CPUおよびメモリのトリガーが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定も、ゼロ以外の値に設定されます。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | リソースを0にスケールバックする前に、最後のトリガーがアクティブをレポートしてから待機する期間 |
| `minReplicaCount`               | 整数 | `hpa.minReplicas`               | レプリカの最小数。KEDAはリソースをそれ以下にスケールダウンします。 |
| `maxReplicaCount`               | 整数 | `hpa.maxReplicas`               | レプリカの最大数。KEDAはリソースをそれ以上にスケールアップします。 |
| `fallback`                      |   マップ   |                                 | KEDAフォールバック設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | スケールアップおよびスケールダウン動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケールをアクティブ化するトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーがデフォルトです。 |

## チャート設定の例 {#chart-configuration-examples}

### `serviceAccount` {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | ブール値 | `false` | の設定は、デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |

### トレランス {#tolerations}

`tolerations`を使用すると、汚染されたワーカーノードでポッドをスケジュールできます

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

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

### annotations {#annotations}

`annotations`を使用すると、Spamcheckポッドに注釈を追加できます。例: 

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### リソース {#resources}

`resources`を使用すると、Spamcheckポッドが消費できるリソース（メモリとCPU）の最小量と最大量を設定できます。

例: 

```yaml
resources:
  requests:
    memory: 100m
    cpu: 100M
```

### 活性プローブ/準備プローブ {#livenessprobereadinessprobe}

`deployment.livenessProbe`および`deployment.readinessProbe`は、コンテナが破損状態にある場合など、特定のシナリオでSpamcheckポッドの終了を制御するのに役立つメカニズムを提供します。

例: 

```yaml
deployment:
  livenessProbe:
    initialDelaySeconds: 10
    periodSeconds: 20
    timeoutSeconds: 3
    successThreshold: 1
    failureThreshold: 10
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 2
    successThreshold: 1
    failureThreshold: 3
```

この設定に関する追加の詳細については、公式の[Kubernetesドキュメント](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)を参照してください。
