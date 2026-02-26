---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenBaoチャート
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3では、`ci_tanukey_ui`と`secrets_manager`という名前の[フラグ](https://docs.gitlab.com/administration/feature_flags/)を立てて[実験](https://docs.gitlab.com/policy/development_stages_support/#experiment)的に導入されました。デフォルトでは無効になっています。
- GitLab 18.4で`ci_tanukey_ui`[フラグ](https://docs.gitlab.com/administration/feature_flags/)は`secrets_manager`にマージされました。
- GitLab 18.8のクローズドベータで一部のユーザーが利用できるようになりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

[OpenBao chart](https://gitlab.com/gitlab-org/cloud-native/charts/openbao)を使用してOpenBaoをインストールできます。これは、[GitLab Secrets Manager](https://docs.gitlab.com/ci/secrets/secrets_manager/)を有効にするために必要です。

## 既知の問題 {#known-issues}

- ダウンタイムなしでOpenBaoをアップグレードすることはできません。ダウンタイムなしのアップグレードは、[OpenBaoチャートのイシュー13](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/issues/13)で提案されています。
- GitLab Geoはサポートされていません。基本的な検証は合格しましたが、フェイルオーバーと推奨設定はまだテストおよび文書化されていません。完全な検証については、[GitLabイシュー568357](https://gitlab.com/gitlab-org/gitlab/-/issues/568357)で説明されています。
- [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator)でOpenBaoをデプロイすることはできません。
- OpenBaoイメージのFIPSバリアントはすでにビルドされていますが、OpenBaoはFIPSで検証されていません。FIPSの検証は、[GitLabイシュー574875](https://gitlab.com/gitlab-org/gitlab/-/issues/574875)で追跡されています。
- OpenBaoチャートと、OpenBao監査イベントのGitLabへのストリーミングを同時に有効にすることはできません。詳細については、[イシュー582828](https://gitlab.com/gitlab-org/gitlab/-/issues/582828)を参照してください。

## GitLabシークレットマネージャーとOpenBaoのセットアップ {#setup-gitlab-secret-manager-and-openbao}

1. 既存のGitLabインスタンスで、OpenBaoを有効にします:

   ```yaml
   # Enable OpenBao integration
   global:
     openbao:
       enabled: true
   # Install bundled OpenBao
   openbao:
     install: true
   ```

1. GitLabの上部バーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > 一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **Secrets Manager**のトグルをオンにして、Secrets Managerがプロビジョニングされるまで待ちます。

## OpenBaoのアップグレードのロールバック {#rolling-back-openbao-upgrades}

OpenBaoのアップグレードは、下位互換性のないPostgreSQLデータへの変更を行う可能性があり、OpenBaoのアップグレードをロールバックする必要がある場合、互換性の問題が発生する可能性があります。

OpenBaoをアップグレードする前に、必ず[バックアップ](#back-up-openbao)してください。OpenBaoのアップグレードをロールバックする必要がある場合は、OpenBaoのバージョンに一致するデータベースバックアップも復元します。

詳細については、[OpenBao upgrade documentation](https://openbao.org/docs/upgrading/)を参照してください。

## OpenBaoのバックアップ {#back-up-openbao}

OpenBaoを完全にバックアップするには、以下が必要です:

- Unsealキー。これらのキーは、復元後にOpenBaoデータにアクセスするために不可欠です。OpenBaoシークレットの[secret backup procedures](../../backup-restore/backup.md#back-up-the-secrets)に従ってください。
- PostgreSQLデータベース。

デフォルトでは、OpenBao PostgreSQLデータはチャートのバンドルされたバックアップ手順の一部としてバックアップされます。

別のデータベース（論理または物理）を使用するようにOpenBaoを設定した場合は、このデータベースを手動でバックアップする必要があります。デフォルトのバックアップツールは、他の外部データベースを認識していないため、標準のPostgreSQL設定のみを対象としています。同期の問題を回避するために、GitLabデータベースとOpenBaoデータベースを同時にバックアップする必要があります。

## OpenBaoの復元 {#restore-openbao}

デフォルトでは、OpenBao PostgreSQLデータはチャートのバンドルされた復元手順の一部として復元されます。

別のデータベース（論理的または物理的）を使用するようにOpenBaoを設定した場合、OpenBaoデータベースのバックアップはバンドルされたバックアップユーティリティで復元できず、手動で復元する必要があります。

OpenBaoのバックアップを復元する前に、OpenBaoがスケールダウンされていることを確認してください。データベーススキーマを再作成しようとし、予期しないエラーが発生する可能性があります。OpenBaoをスケールダウンするには、以下を実行します:

```shell
kubectl scale deploy -lapp=openbao,release=<helm release name> -n <namespace> --replicas=0
```

## OpenBaoの設定オプション {#openbao-configuration-options}

次の表に、使用可能なすべてのOpenBao設定オプションを示します。

### インストールコマンドラインオプション {#installation-command-line-options}

以下の表には、`--set`フラグを使用して、`helm install`コマンドに指定できるすべてのチャート構成が記載されています。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `logLevel`                                               | info                                                    | OpenBaoログレベル。 |
| `logRequestLevel`                                        | off                                                     | OpenBaoリクエストログレベル。リクエストログを有効にするには、これを`logLevel`と同じ値またはそれより高いレベルに設定します。 |
| `logFormat`                                              | `json`                                                  | OpenBaoログ形式。`json`または`standard`のいずれか。 |
| `serviceAccount.create`                                  | はい                                                    | OpenBaoのサービスアカウントを作成します。 |
| `serviceAccount.automount`                               | はい                                                    | |
| `serviceAccount.annotations`                             | `{}`                                                    | 追加のサービスアカウントの注釈。 |
| `serviceAccount.name`                                    |                                                         | 生成されたサービスアカウント名をオーバーライドします。 |
| `role.create`                                            |                                                         | 必要なRBAC権限を持つロールを作成します。 |
| `securityContext.capabilities`                           | `{ drop: ["ALL"] }`                                     | |
| `securityContext.runAsNonRoot`                           | はい                                                    | |
| `securityContext.allowPrivilegeEscalation`               | false                                                   | |
| `securityContext.runAsUser`                              | 65532                                                   | |
| `podSecurityContext.seccompProfile`                      | `RuntimeDefault`                                        | |
| `podSecurityContext.runAsUser`                           | 65532                                                   | |
| `podSecurityContext.fsGroup`                             | 65532                                                   | |
| `serviceActive.type`                                     | ClusterIP                                               | アクティブなOpenBaoポッドのサービスタイプ。 |
| `serviceActive.annotations`                              | `{}`                                                    | アクティブなOpenBaoポッドのサービス注釈。 |
| `serviceInactive.type`                                   | ClusterIP                                               | スタンバイOpenBaoポッドのサービスタイプ。 |
| `serviceInactive.annotations`                            | `{}`                                                    | スタンバイOpenBaoポッドのサービス注釈。 |
| `resources`                                              | `{}`                                                    | リソースの制限とリクエスト。 |
| `autoscaling.minReplicas`                                | 2                                                       | 最小OpenBaoレプリカ。 |
| `autoscaling.maxReplicas`                                | 2                                                       | 最大OpenBaoレプリカ。 |
| `autoscaling.targetCPUUtilizationPercentage`             | 80                                                      | オートスケールのターゲットCPU使用率。 |
| `autoscaling.targetCPUMemoryPercentage`                  |                                                         | オートスケールのターゲットメモリ使用率。 |
| `livenessProbe`                                          |                                                         | OpenBao活性プローブ。デフォルトについては、[OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)を確認してください。 |
| `readinessProbe`                                         |                                                         | OpenBao準備プローブ。デフォルトについては、[OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)を確認してください。 |
| `nodeSelector`                                           | {}                                                      | ノードセレクターラベル。 |
| `tolerations`                                            | []                                                      | ポッドの割り当ての容認ラベル。 |
| `affinity`                                               | {}                                                      | ポッド割り当てのアフィニティラベル。 |
| `config.ui`                                              | false                                                   | OpenBao UIを有効にします。 |
| `config.clusterPort`                                     | 8201                                                    | OpenBaoクラスターポート。 |
| `config.apiPort`                                         | 8200                                                    | OpenBao APIポート。 |
| `config.cacheSize`                                       | 8200                                                    | 物理ストレージサブシステムで使用される読み取りキャッシュのサイズ（エントリ数）。 |
| `config.maxRequestSize`                                  | 786432                                                  | 最大リクエストサイズ（バイト単位）。デフォルトは768KBです。 |
| `config.maxRequestJsonMemory`                            | 1048576                                                 | JSON解析されたリクエストボディの最大サイズ（バイト単位）。デフォルトは1MBです。 |

### コンテナイメージオプション {#container-image-options}

OpenBaoチャートは、[クラウドネイティブGitLabコンテナイメージ](https://gitlab.com/gitlab-org/build/CNG)をデプロイしてOpenBaoをデプロイします。OpenBaoビルドには、アップストリームバージョンからの[modifications](https://gitlab.com/gitlab-org/govern/secrets-management/openbao-internal)が含まれています。その結果、一部の機能が標準のOpenBaoリリースと異なる場合があります。

| パラメータ                                                | デフォルト                                                   | 説明 |
|----------------------------------------------------------|-----------------------------------------------------------|-------------|
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-openbao` | OpenBaoイメージのリポジトリ。 |
| `image.pullPolicy`                                       | `IfNotPresent`                                            | イメージプルポリシー。 |
| `image.tag`                                              |                                                           | これをオーバーライドして、カスタムOpenBaoバージョンをデプロイします。 |
| `imagePullSecrets`                                       | `[]`                                                      | プライベートリポジトリからイメージをプルするためのシークレット。 |

### IngressおよびTLS設定オプション {#ingress-and-tls-configuration-options}

OpenBaoチャートは、デフォルトでIngressターミネートTLS暗号化を使用します。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.host`                                    | `openbao.<GitLab Domain>`                                 | OpenBaoホスト。GitLab WebサービスとOpenBaoチャートの設定に使用されます。 |
| `ingress.enabled`                                        | はい                                                    | RunnerがOpenBaoに到達できるように、OpenBao Ingressを有効にします。 |
| `ingress.hostname`                                       | グローバルホスト構成に基づいた外部OpenBaoホスト。     | Ingressが一致する必要があるホスト名。 |
| `ingress.tls.enabled`                                    | はい                                                    | Ingress TLSを有効にします。 |
| `ingress.tls.secretName`                                 |                                                         | [Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)の名前。デフォルトではcertmanagerによって管理されます。 |
| `ingress.annotations`                                    | はい                                                    | Ingressにレンダリングされる注釈。これを使用して、非NGINX Ingressコントローラー用にOpenBaoを設定します。 |
| `ingress.configureCertmanager`                           | グローバルcertmanager構成                               | certmanagerを使用してTLS証明書を管理します。 |
| `ingress.certmanagerIssuer`                              | `<release>-issuer`                                       | certmanager発行者の名前。 |
| `ingress.sslPassthroughNginx`                            | false                                                   | 着信TLS接続をOpenBaoにパススルーするように、Ingressにアノテーションを付けます。certmanagerが設定されている場合、新しいHTTP01チャレンジは別のIngressを介して行われます。 |
| `config.tlsDisable`                                      | はい                                                    | 内部TLSを無効にします。無効にすると、Ingress TLSパススルーも無効になります。 |
| `config.metricsListener.tlsDisable`                      | はい                                                    | メトリクスリスナーの内部TLSを無効にします。 |

エンドツーエンドの暗号化されたTLSでOpenBaoを操作する必要があります。エンドツーエンドTLSを有効にするには、TLS接続を予期し、NGINX Ingressを介してTLS接続を渡すようにOpenBaoを設定します:

```yaml
global:
  ingress:
    useNewIngressForCerts: true
config:
  tlsDisable: false
ingress:
  sslPassthroughNginx: true
```

注: SSLパススルーを有効にすると、cert-managerは別のIngressを作成してHTTP01チャレンジを完了する必要があります。バンドルされたcertmanagerと`Issuer`を使用する場合は、[`global.ingress.useNewIngressForCerts`](../globals.md#globalingressusenewingressforcerts)を設定して、発行者が正しい`IngressClass`を設定していることを確認してください。

### ゲートウェイAPI {#gateway-api}

OpenBaoチャートを使用すると、`HTTPRoute`を介してトラフィックを公開できます。[がグローバルに有効になっている](../globals.md#gateway-api)場合、OpenBaoのリスナーは管理対象の`Gateway`リソースに作成されます。

| パラメータ                  | デフォルト                                                 | 説明 |
|----------------------------|---------------------------------------------------------|-------------|
| `gatewayRoute.enabled`     | `global.gatewayApi.enabled`の値にデフォルト設定されます        | `HTTPRoute`を介してOpenBaoを公開できるようにします。 |
| `gatewayRoute.sectionName` | openbao-web                                             | `HTTPRoute`で使用されるゲートウェイセクション。 |
| `gatewayRoute.gatewayName` | GitLabチャート管理対象ゲートウェイ                            | `HTTPRoute`で使用されるゲートウェイ名。 |
| `gatewayRoute.annotations` | `{}`                                                    | `HTTPRoute`の追加の注釈。 |
| `gatewayRoute.timeouts`    | `{}`                                                    | `HTTPRoute`のカスタムタイムアウト構成。 |

### モニタリング設定オプション {#monitoring-configuration-options}

OpenBaoは、バンドルされたPrometheusサブチャートによってスクレイプされるPrometheusメトリクスを公開するように事前構成されています。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.telemetry.enabled`                               | はい                                                    | テレメトリとモニタリングを有効にします。 |
| `config.telemetry.disableHostname`                       | はい                                                    | ゲージ値にローカルホスト名を付加します。 |
| `config.telemetry.prometheusRetentionTime`               | `24h`                                                   | メトリクスの保持時間。 |
| `config.telemetry.metricsPrefix`                         | `openbao`                                               | すべてのメトリクスのプレフィックス。 |
| `config.telemetry.usageGaugePeriod`                      | 0                                                       | トークン数、エンティティ数、シークレット数など、高カーディナリティの使用状況データが収集される間隔。 |
| `config.telemetry.numLeaseMetricsBuckets`                | 1                                                       | リース有効期限バケットの数。 |
| `config.metricsListener.enabled`                         | はい                                                    | メトリクスのリクエストを処理するために、2番目のAPIポートを有効にします。リスナーはすべてのAPIリクエストを処理できますが、認証なしでメトリクスのリクエストを処理します。 |
| `config.metricsListener.tlsDisable`                      | はい                                                    | メトリクスリスナーの内部TLSを無効にします。 |
| `config.metricsListener.port`                            | 8209                                                    | メトリクスリスナーのポート。 |
| `config.metricsListener.unauthenticatedMetricsAccess`    | はい                                                    | メトリクスのリクエストが認証なしで処理されるように許可します。 |
| `podMonitor.enabled`                                     | false                                                   | Prometheus OperatorのPodMonitorリソースを有効にします。クラスターにPrometheus Operatorがインストールされている必要があります。 |
| `podMonitor.additionalLabels`                            | `{}`                                                    | PodMonitorリソースに追加する追加のラベル。 |
| `podMonitor.selectorLabels`                              | `{}`                                                    | スクレイプするポッドをフィルタリングするための追加のセレクターラベル。 |
| `podMonitor.endpointConfig`                              | `{}`                                                    | 追加のエンドポイント設定（例: `interval`、`scrapeTimeout`）。 |

### 封印解除および初期化オプション {#unsealing-and-initialization-options}

OpenBaoチャートは、[静的自動封印解除](https://openbao.org/docs/configuration/seal/static/)とOpenBao宣言型[自己初期化](https://openbao.org/docs/configuration/self-init/)を利用します。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.unseal.static.enabled`                           | はい                                                    | 静的自動封印解除を有効にします。 |
| `config.unseal.static.currentKeyId`                      | `static-unseal-0`                                       | 現在の静的封印解除キーのID。 |
| `config.unseal.static.currentKey`                        | `/srv/openbao/keys/static-unseal-0`                     | 現在の静的封印解除キーのパス。 |
| `config.unseal.static.previousKeyId`                     |                                                         | 以前の静的封印解除キーのID。 |
| `config.unseal.static.previousKey`                       | `/srv/openbao/keys/static-unseal-1`                     | 以前の静的封印解除キーのパス。前のキーIDも設定されている場合にのみ、レンダリングされます。 |
| `config.initialize.enabled`                              | はい                                                    | OpenBaoの自己初期化を有効にします。 |
| `config.initialize.oidcDiscoveryUrl`                     | 外部GitLabホスト                                    | OIDCディスカバリURL。デフォルトは外部GitLabホスト名です。 |
| `config.initialize.boundIssuer`                          | 外部OpenBaoホスト                                   | OIDC発行者。デフォルトは外部OpenBaoホスト名です。 |
| `config.initialize.boundAudiences`                       | 外部OpenBaoホスト                                   | OIDCロールオーディエンス。デフォルトは外部OpenBaoホスト名です。 |
| `staticUnsealSecret.generate`                            | false                                                   | OpenBaoを自動封印解除するための静的キーを生成します。GitLabチャートの共有シークレットチャートで管理されているため、デフォルトはfalseです。 |
| `initializeTpl`                                          |                                                         | OpenBaoを自己初期化するために渡されるテンプレート。デフォルトについては、[OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)を確認してください。 |

### 監査イベントストリーミングオプション {#audit-event-streaming-options}

OpenBaoチャートは、イベントをGitLabにストリーミングするように[監査デバイス](https://openbao.org/docs/audit/)を設定します。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.httpAudit.secret`                        | `<release>-openbao-audit-secret`                        | OpenBaoとGitLabの間で共有されるトークンを格納するシークレットの名前。 |
| `global.openbao.httpAudit.key`                           | `token`                                                 | 共有トークンを格納するシークレットキー。 |
| `config.audit.http.enabled`                              | false                                                   | HTTPを使用して、監査イベントのGitLabへのストリーミングを有効にします。OpenBaoチャートを有効にする場合は、無効にする必要があります。詳細については、[イシュー582828](https://gitlab.com/gitlab-org/gitlab/-/issues/582828)を参照してください。 |
| `config.audit.http.streamingUri`                         | 内部workhorse URL                                  | 監査イベントのストリーミング先のエンドポイント。 |
| `config.audit.http.authTokenPath`                        | `/srv/openbao/audit/gitlab-auth`                        | GitLabと共有されるトークンがマウントされているパス。 |
| `httpAuditSecret.generate`                               | false                                                   | 認証済み監査のために、GitLabと共有されるシークレットを生成します。GitLabチャートの共有シークレットチャートで管理されているため、デフォルトはfalseです。 |
| `initializeTpl`                                          |                                                         | OpenBao監査を設定するために渡されるテンプレート。デフォルトについては、[OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)を確認してください。 |

## 外部データベースを設定する {#configure-an-external-database}

デフォルトでは、OpenBaoは同じ認証情報と設定でメインのGitLabデータベースに接続します。

外部データベースを設定するには:

1. データベースサーバーでPostgreSQLユーザーとデータベースを作成します:

   ```sql
   -- Create the OpenBao user
   CREATE USER openbao WITH PASSWORD '<password>';

   -- Create the OpenBao database
   CREATE DATABASE openbao OWNER openbao;
   ```

1. パスワードを含むKubernetesシークレットを作成します:

   ```shell
   kubectl create secret -n bao generic openbao-db-password --from-literal=password="<password>"
   ```

1. 外部データベースに接続するようにOpenBaoを設定します:

   ```yaml
   openbao:
     config:
       storage:
         postgresql:
           connection:
             host: "psql.openbao.example.com"
             port: 5432
             database: openbao
             username: openbao
             # connectTimeout:
             # keepalives:
             # keepalivesIdle:
             # keepalivesInterval:
             # keepalivesCount:
             # tcpUserTimeout:
             # sslMode: "disable"
             password:
               secret: openbao-db-password
               key: password
   ```

1. OpenBaoをデプロイまたはアップグレードします。起動すると、OpenBaoは指定されたデータベースにデータベーススキーマを自動的に作成します。
