---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mailroomチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Mailroomチャートは[受信](https://docs.gitlab.com/administration/incoming_email/)メールを処理します。

## 設定 {#configuration}

```yaml
image:
  repository: registry.gitlab.com/gitlab-org/build/cng/gitlab-mailroom
  # tag: v0.9.1
  pullSecrets: []
  # pullPolicy: IfNotPresent

enabled: true

init:
  image: {}
    # repository:
    # tag:
  resources:
    requests:
      cpu: 50m

annotations: {}

# Tolerations for pod scheduling
tolerations: []
affinity: {}
podLabels: {}

hpa:
  minReplicas: 1
  maxReplicas: 2
  cpu:
    targetAverageUtilization: 75

  # Note that the HPA is limited to autoscaling/v2beta1, autoscaling/v2beta2 and autoscaling/v2
  customMetrics: []
  behavior: {}

networkpolicy:
  enabled: false
  egress:
    enabled: false
    rules: []
  ingress:
    enabled: false
    rules: []
  annotations: {}

resources:
  # limits:
  #  cpu: 1
  #  memory: 2G
  requests:
    cpu: 50m
    memory: 150M

## Allow to overwrite under which User and Group we're running.
securityContext:
  runAsUser: 1000
  fsGroup: 1000

## Enable deployment to use a serviceAccount
serviceAccount:
  enabled: false
  create: false
  annotations: {}
  ## Name to be used for serviceAccount, otherwise defaults to chart fullname
  # name:
```

| パラメータ                                     | デフォルト                                                    | 説明 |
|-----------------------------------------------|------------------------------------------------------------|-------------|
| `affinity`                                    | `{}`                                                       | ポッド割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                 | `{}`                                                       | ポッドの注釈。 |
| `deployment.strategy`                         | `{}`                                                       | デプロイで使用される更新仕様を構成できます |
| `enabled`                                     | `true`                                                     | Mailroomイネーブルメントフラグ |
| `hpa.behavior`                                | `{scaleDown: {stabilizationWindowSeconds: 300 }}`          | 動作には、アップスケールとダウンスケールの動作の仕様が含まれています（`autoscaling/v2beta2`以上が必要です）。 |
| `hpa.customMetrics`                           | `[]`                                                       | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                          | `Utilization`                                              | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.cpu.targetAverageValue`                  |                                                            | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`            | `75`                                                       | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                       |                                                            | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.memory.targetAverageValue`               |                                                            | オートスケールメモリターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`         |                                                            | オートスケールメモリターゲット使用率を設定します |
| `hpa.maxReplicas`                             | `2`                                                        | レプリカの最大数 |
| `hpa.minReplicas`                             | `1`                                                        | レプリカの最小数 |
| `image.pullPolicy`                            | `IfNotPresent`                                             | Mailroomイメージプルポリシー |
| `extraEnvFrom`                                |                                                            | 公開する他のデータソースからの追加の環境変数のリスト |
| `image.pullSecrets`                           |                                                            | Mailroomイメージプルシークレット |
| `image.registry`                              |                                                            | Mailroomイメージレジストリ |
| `image.repository`                            | `registry.gitlab.com/gitlab-org/build/cng/gitlab-mailroom` | Mailroomイメージリポジトリ |
| `image.tag`                                   |                                                            | Mailroomイメージタグ |
| `init.image.repository`                       |                                                            | Mailroom initイメージリポジトリ |
| `init.image.tag`                              |                                                            | Mailroom initイメージタグ |
| `init.resources`                              | `{ requests: { cpu: 50m }}`                                | Mailroom initコンテナリソース要件 |
| `init.containerSecurityContext`               |                                                            | initコンテナ固有の[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `keda.enabled`                                | `false`                                                    | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                        | `30`                                                       | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                         | `300`                                                      | 最後トリガーがアクティブであると報告された後、リソースを0にスケールバックするまで待機する期間 |
| `keda.minReplicaCount`                        | `hpa.minReplicas`                                          | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `keda.maxReplicaCount`                        | `hpa.maxReplicas`                                          | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `keda.fallback`                               |                                                            | KEDAフォールバック構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                | `keda-hpa-{scaled-object-name}`                            | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`          |                                                            | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                               | `hpa.behavior`                                             | アップスケールとダウンスケールの動作の仕様。 |
| `keda.triggers`                               |                                                            | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーにデフォルト設定します |
| `podLabels`                                   | `{}`                                                       | Mailroomポッドを実行するためのラベル |
| `common.labels`                               | `{}`                                                       | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `resources`                                   | `{ requests: { cpu: 50m, memory: 150M }}`                  | Mailroomリソース要件 |
| `networkpolicy.annotations`                   | `{}`                                                       | ネットワークポリシーに追加する注釈 |
| `networkpolicy.egress.enabled`                | `false`                                                    | ネットワークポリシーのエグレスルールを有効にするフラグ |
| `networkpolicy.egress.rules`                  | `[]`                                                       | ネットワークポリシーのエグレスルールのリストを定義します |
| `networkpolicy.enabled`                       | `false`                                                    | ネットワークポリシーを使用するためのフラグ |
| `networkpolicy.ingress.enabled`               | `false`                                                    | ネットワークポリシーの`ingress`ルールを有効にするフラグ |
| `networkpolicy.ingress.rules`                 | `[]`                                                       | ネットワークポリシーの`ingress`ルールのリストを定義します |
| `securityContext.fsGroup`                     | `1000`                                                     | ポッドを開始するグループID |
| `securityContext.runAsUser`                   | `1000`                                                     | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`         |                                                            | ボリュームの所有権と許可を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `containerSecurityContext`                    |                                                            | コンテナが開始される[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`          | `1000`                                                     | コンテナが開始される特定のセキュリティコンテキストを上書きできます |
| `serviceAccount.annotations`                  | `{}`                                                       | ServiceAccountの注釈 |
| `serviceAccount.automountServiceAccountToken` | `false`                                                    | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.enabled`                      | `false`                                                    | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.create`                       | `false`                                                    | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.name`                         |                                                            | ServiceAccountの名前。設定しない場合、チャートの完全名が使用されます |
| `tolerations`                                 |                                                            | Mailroomに追加するToleration |
| `priorityClassName`                           |                                                            | [優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)がポッドに割り当てられます。 |

## KEDAの構成 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`ではなく、[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この構成はオプションであり、カスタムメトリクスまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルト設定されます。

以下が当てはまる場合、`hpa`セクションで設定されたCPUおよびメモリのしきい値に基づいて、CPUおよびメモリのトリガーが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定も、ゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | 最後トリガーがアクティブであると報告された後、リソースを0にスケールバックするまで待機する期間 |
| `minReplicaCount`               | 整数 | `hpa.minReplicas`               | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `maxReplicaCount`               | 整数 | `hpa.maxReplicas`               | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `fallback`                      |   マップ   |                                 | KEDAフォールバック構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | アップスケールとダウンスケールの動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーにデフォルト設定します |

## 受信メール {#incoming-email}

既定では、受信メールは無効になっています。受信メールを読み取るには、次の2つの方法があります:

- [IMAP](#imap)
- [Microsoft Graph](#microsoft-graph)

まず、[共通設定](../../../installation/command-line-options.md#common-settings)を設定して有効にします。次に、[IMAP設定](../../../installation/command-line-options.md#imap-settings)または[Microsoft Graph設定](../../../installation/command-line-options.md#microsoft-graph-settings)を構成します。

これらのメソッドは`values.yaml`で構成できます。次の例を参照してください:

- [IMAPを使用した受信メール](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-incoming-email.yaml)
- [Microsoft Graphを使用した受信メール](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-msgraph.yaml)

### IMAP {#imap}

IMAPの受信メールを有効にするには、`global.appConfig.incomingEmail`設定を使用して、IMAPサーバーと認証情報の詳細を指定します。

また、ターゲットのIMAPアカウントをGitLabがメールを受信するために使用できることを確認するには、[IMAPメールアカウントの要件](https://docs.gitlab.com/administration/incoming_email/)をレビューする必要があります。いくつかの一般的なメールサービスも同じページに記載されており、受信メールのセットアップに役立ちます。

IMAPパスワードは、[シークレットガイド](../../../installation/secrets.md#imap-password-for-incoming-emails)で説明されているように、Kubernetesシークレットとして作成する必要があります。

### Microsoft Graph {#microsoft-graph}

[Azure Active Directoryアプリケーションの作成に関するGitLabドキュメント](https://docs.gitlab.com/administration/incoming_email/#microsoft-graph)を参照してください。

テナントID、クライアントID、およびクライアントのシークレットキーを指定します。これらの設定の詳細については、[コマンドラインオプション](../../../installation/command-line-options.md#incoming-email-configuration)を参照してください。

[シークレットガイド](../../../installation/secrets.md#microsoft-graph-client-secret-for-incoming-emails)の説明に従って、クライアントのシークレットキーを含むKubernetesシークレットを作成します。

### メールで返信する {#reply-by-email}

メールで返信する機能を使用するには、ユーザーがイシューとMRにコメントするために通知メールに返信できるようにするには、[送信](../../../installation/command-line-options.md#outgoing-email-configuration)メールと受信メールの設定を構成する必要があります。

### サービスデスクのメール {#service-desk-email}

既定では、サービスデスクのメールは無効になっています。

受信メールと同様に、[共通設定](../../../installation/command-line-options.md#common-settings-1)を設定して有効にします。次に、[IMAP設定](../../../installation/command-line-options.md#imap-settings-1)または[Microsoft Graph設定](../../../installation/command-line-options.md#microsoft-graph-settings-1)を構成します。

これらのオプションは、`values.yaml`でも構成できます。次の例を参照してください:

- [IMAPを使用したサービスデスク](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-service-desk-email.yaml)
- [Microsoft Graphを使用したサービスデスク](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-msgraph.yaml)

サービスデスクのメールは、[受信](#incoming-email)メールが構成されている_必要があり_ます。

#### IMAP {#imap-1}

`global.appConfig.serviceDeskEmail`設定を使用して、IMAPサーバーと認証情報の詳細を指定します。これらの設定の詳細については、[コマンドラインオプション](../../../installation/command-line-options.md#service-desk-email-configuration)を参照してください。

[シークレットガイド](../../../installation/secrets.md#imap-password-for-service-desk-emails)の説明に従って、IMAPパスワードを含むKubernetesシークレットを作成します。

#### Microsoft Graph {#microsoft-graph-1}

[Azure Active Directoryアプリケーションの作成に関するGitLabドキュメント](https://docs.gitlab.com/administration/incoming_email/#microsoft-graph)を参照してください。

`global.appConfig.serviceDeskEmail`設定を使用して、テナントID、クライアントID、およびクライアントのシークレットキーを指定します。これらの設定の詳細については、[コマンドラインオプション](../../../installation/command-line-options.md#service-desk-email-configuration)を参照してください。

また、[シークレットガイド](../../../installation/secrets.md#imap-password-for-service-desk-emails)の説明に従って、クライアントのシークレットキーを含むKubernetesシークレットを作成する必要があります。

### サービスアカウント {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountの注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | の設定は、デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定しない場合、チャートの完全名が使用されます。 |

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。
