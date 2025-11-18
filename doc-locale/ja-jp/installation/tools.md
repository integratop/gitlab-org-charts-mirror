---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートの必須コンポーネント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

KubernetesクラスタにGitLabをデプロイする前に、次の必須コンポーネントをインストールし、インストール時に使用するオプションを決定します。

## 前提要件 {#prerequisites}

### kubectl {#kubectl}

[Kubernetesのドキュメント](https://kubernetes.io/docs/tasks/tools/#kubectl)に従って、`kubectl`kubectlをインストールします。インストールするバージョンは、[クラスタで実行されているバージョンのマイナーリリース](https://kubernetes.io/releases/version-skew-policy/#kubectl)の範囲内である必要があります。

### Helm {#helm}

[Helmのドキュメント](https://helm.sh/docs/intro/install/)に従って、Helm v3.17.3以降をインストールします。

{{< alert type="warning" >}}

[Helmイシュー30878](https://github.com/helm/helm/issues/30878)のため、v3.18.0は例外的にサポートされていません。v3.17.xからv3.18.1以降に直接ジャンプする必要があります。

{{< /alert >}}

### PostgreSQL {#postgresql}

デフォルトでは、GitLabチャートには、[`bitnami/PostgreSQL`](https://artifacthub.io/packages/helm/bitnami/postgresql)によって提供される、クラスタ内PostgreSQLデプロイメントが含まれています。このデプロイはトライアル目的のみであり、**本番環境での使用は推奨されません**。

[外部の、本番環境対応のPostgreSQLインスタンス](../advanced/external-db/_index.md)をセットアップする必要があります。

サポートされているPostgreSQLのバージョンについては、[GitLabの要件](https://docs.gitlab.com/install/requirements/#postgresql)を確認してください。

GitLabチャート4.0.0の時点で、レプリケーションは内部的に利用可能ですが、デフォルトでは有効になっていません。このような機能は、GitLabではロードテストされていません。

### Redis {#redis}

デフォルトでは、GitLabチャートには、[`bitnami/Redis`](https://artifacthub.io/packages/helm/bitnami/redis)によって提供される、クラスタ内Redisデプロイメントが含まれています。このデプロイはトライアル目的のみであり、**本番環境での使用は推奨されません**。

[外部の、本番環境対応のRedisインスタンス](../advanced/external-redis/_index.md)をセットアップする必要があります。利用可能なすべての設定については、[Redisグローバルドキュメント](../charts/globals.md#configure-redis-settings)を参照してください。

GitLabチャート4.0.0の時点で、レプリケーションは内部的に利用可能ですが、デフォルトでは有効になっていません。このような機能は、GitLabではロードテストされていません。

### Gitaly {#gitaly}

デフォルトでは、GitLabチャートには、クラスタ内Gitalyデプロイメントが含まれています。本番環境では、KubernetesでのGitalyの実行はサポートされていません。[Gitaly](https://docs.gitlab.com/administration/reference_architectures/#stateful-components-in-kubernetes)は、従来の仮想マシンでのみサポートされています。

[外部の、本番環境対応のGitalyインスタンス](../advanced/external-gitaly/_index.md)をセットアップする必要があります。利用可能なすべての設定については、[Gitalyグローバルドキュメント](../charts/globals.md#configure-gitaly-settings)を参照してください。

## その他のオプションの決定 {#decide-on-other-options}

GitLabをデプロイするときは、`helm install`で次のオプションを使用します。

### シークレット {#secrets}

SSHキーのようなシークレットをいくつか作成する必要があります。デフォルトでは、これらのシークレットはデプロイメント中に自動的に生成されますが、指定する場合は、[シークレットに関するドキュメント](secrets.md)に従ってください。

### ネットワーキングとドメインネームシステム {#networking-and-dns}

デフォルトでは、サービスを公開するために、GitLabは`Ingress`オブジェクトで設定された名前ベースの仮想サーバーを使用します。これらのオブジェクトは、`type: LoadBalancer`のKubernetes `Service`オブジェクトです。

`gitlab`、`registry`、および`minio`（有効な場合）をチャートの適切なIPアドレスに解決するレコードを含むドメインを指定する必要があります。

たとえば、`helm install`で次のように使用します:

```shell
--set global.hosts.domain=example.com
```

カスタムドメインサポートが有効になっている場合、デフォルトでは`<pages domain>`である`*.<pages domain>`サブドメインは、`pages.<global.hosts.domain>`になります。このドメインは、`--set global.pages.externalHttp`または`--set global.pages.externalHttps`によってPagesに割り当てられた外部IPに解決されます。

カスタムドメインを使用するには、GitLab Pagesは、カスタムドメインを対応する`<namespace>.<pages domain>`ドメインにポイントするCNAMEレコードを使用できます。

#### `external-dns`を使用した動的IPアドレス {#dynamic-ip-addresses-with-external-dns}

[`external-dns`](https://github.com/kubernetes-sigs/external-dns)のような自動ドメインネームシステム登録サービスを使用する予定がある場合は、GitLabの追加のドメインネームシステム設定は必要ありません。ただし、`external-dns`をクラスタにデプロイする必要があります。プロジェクトページ[には、サポートされている各クラウドプロバイダーの包括的なガイド](https://github.com/kubernetes-sigs/external-dns#deploying-to-a-cluster)があります。

{{< alert type="note" >}}

GitLab Pagesのカスタムドメインサポートを有効にすると、`external-dns`はPagesドメイン（`pages.<global.hosts.domain>`、デフォルト）では機能しなくなります。Pages専用の外部IPアドレスにドメインをポイントするように、ドメインネームシステムエントリを手動で設定する必要があります。

{{< /alert >}}

提供されたスクリプトを使用して[GKEクラスタ](cloud/gke.md)をプロビジョニングする場合、`external-dns`はクラスタに自動的にインストールされます。

#### 静的IPアドレス {#static-ip-addresses}

ドメインネームシステムレコードを手動で設定する場合は、すべて静的IPアドレスを指している必要があります。たとえば、`example.com`を選択し、`10.10.10.10`の静的IPアドレスがある場合、`gitlab.example.com`、`registry.example.com`、および`minio.example.com`（MinIOを使用している場合）はすべて`10.10.10.10`に解決される必要があります。

GKEを使用している場合は、[外部IPとドメインネームシステムエントリの作成](cloud/gke.md#creating-the-external-ip)について詳細をお読みください。このプロセスの詳細については、クラウドプロバイダーまたはドメインネームシステムプロバイダーのドキュメントを参照してください。

たとえば、`helm install`で次のように使用します:

```shell
--set global.hosts.externalIP=10.10.10.10
```

#### Istioプロトコル選択との互換性 {#compatibility-with-istio-protocol-selection}

サービスポート名は、Istioの[明示的なポート選択](https://istio.io/latest/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)と互換性のある規則に従います。たとえば、`tls-gitaly`や`https-metrics`のように、`<protocol>-<suffix>`のように表示されます。

GitalyとKASはgRPCを使用しますが、[イシュー #3822](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3822)と[イシュー #4908](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4908)の調査結果により、代わりに`tcp`プレフィックスを使用することに注意してください。

### 永続 {#persistence}

デフォルトでは、GitLabチャートは、動的プロビジョニングツールが基盤となる永続ボリュームを作成することを期待して、ボリュームクレームを作成します。`storageClass`をカスタマイズしたり、手動でボリュームを作成して割り当てたりする場合は、[ストレージドキュメント](storage.md)を確認してください。

{{< alert type="note" >}}

最初のデプロイメント後、ストレージ設定を変更するには、Kubernetesオブジェクトを手動で編集する必要があります。したがって、ストレージの移行作業が余分にかからないように、本番環境インスタンスをデプロイする前に事前に計画しておくことをお勧めします。

{{< /alert >}}

### TLS certificates {#tls-certificates}

TLS証明書を必要とするHTTPSでGitLabを実行する必要があります。デフォルトでは、GitLabチャートは無料のTLS証明書を取得するために[`cert-manager`](https://github.com/cert-manager/cert-manager)をインストールして設定します。

独自のワイルドカード証明書を持っている場合、または`cert-manager`がすでにインストールされている場合、またはTLS証明書を取得する他の方法がある場合は、[TLSオプション](tls.md)の詳細をお読みください。

デフォルトの設定では、TLS証明書を登録するためにメールアドレスを指定する必要があります。たとえば、`helm install`で次のように使用します:

```shell
--set certmanager-issuer.email=me@example.com
```

### Prometheus {#prometheus}

ここでは、[アップストリームPrometheusチャート](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration)を使用し、メトリックの収集をKubernetes APIとGitLabチャートによって作成されたオブジェクトに制限するために、カスタマイズされた`prometheus.yml`ファイル以外の独自のデフォルトからの値をオーバーライドしません。ただし、デフォルトでは、`alertmanager`、`node-exporter`、`pushgateway`、および`kube-stat-metrics`を無効にします。

`prometheus.yml`ファイルは、`gitlab.com/prometheus_scrape`注釈を持つリソースからメトリクスを収集するようにPrometheusに指示します。さらに、`gitlab.com/prometheus_path`および`gitlab.com/prometheus_port`注釈を使用して、メトリクスの検出方法を設定できます。これらの各注釈は、`prometheus.io/{scrape,path,port}`注釈に匹敵します。

PrometheusのインストールでGitLabアプリケーションをモニタリングしている場合、またはモニタリングする場合は、元の`prometheus.io/*`注釈が適切なポッドとサービスに追加されます。これにより、既存のユーザーのメトリクス収集の継続性が確保され、デフォルトのPrometheus設定を使用して、Kubernetesクラスタで実行されているGitLabアプリケーションメトリクスと他のアプリケーションの両方をキャプチャできます。

網羅的な設定オプションのリストについては、[アップストリームPrometheusチャートのドキュメント](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration)を参照し、`prometheus`へのサブキーであることを確認してください。これは要件チャートとして使用するためです。

たとえば、永続ストレージのリクエストは、次のように制御できます:

```yaml
prometheus:
  alertmanager:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  prometheus-pushgateway:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  server:
    persistentVolume:
      enabled: true
      size: 8Gi
```

#### TLS対応エンドポイントをスクレイプするようにPrometheusを設定する {#configure-prometheus-to-scrape-tls-enabled-endpoints}

特定のexporterでTLSが許可され、チャートの設定でexporterのエンドポイントのTLS設定が公開されている場合、PrometheusはTLS対応エンドポイントからメトリクスをスクレイプするように設定できます。

TLSと[Kubernetesサービスディスカバリ](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)をPrometheusの[スクレイプ設定](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)に使用する場合には、いくつかの注意点があります:

- [ポッド](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#pod)と[サービスエンドポイント](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints)の検出ロールの場合、Prometheusはポッドの内部IPアドレスを使用して、スクレイプターゲットのアドレスを設定します。TLS証明書を確認するには、メトリクスエンドポイント用に作成された証明書に設定された共通名（CN）、またはサブジェクト代替名（SAN）拡張機能に含まれる名前でPrometheusを設定する必要があります。名前は解決する必要はなく、[有効なドメインネームシステム名](https://datatracker.ietf.org/doc/html/rfc1034#section-3.1)である任意の文字列にすることができます。
- exporterのエンドポイントに使用される証明書が自己署名されている場合、またはPrometheusベースイメージに存在しない場合、Prometheusポッドは、exporterのエンドポイントに使用される証明書に署名した認証局（CA）の証明書をマウントする必要があります。Prometheusは、[ベースイメージ](https://github.com/prometheus/busybox)のDebianから`ca-bundle`を使用します。
- Prometheusは、各スクレイプ設定に適用される[tls_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#tls_config)を使用して、これらの項目の両方を設定することをサポートしています。Prometheusには、ポッドの注釈やその他の検出された属性に基づいてPrometheusターゲットラベルを設定するための堅牢な[relabel_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config)メカニズムがありますが、`tls_config.server_name`と`tls_config.ca_file`の設定は`relabel_config`を使用して行うことはできません。詳細については、[Prometheusプロジェクトイシュー](https://github.com/prometheus/prometheus/issues/4827)をご覧ください。

これらの注意点を考慮すると、最も簡単な設定は、exporterのエンドポイントに使用されるすべての証明書間で「名前」とCAを共有することです:

1. `tls_config.server_name`（たとえば、`metrics.gitlab`）に使用する単一の任意の名前を選択します。
1. exporterのエンドポイントをTLSで暗号化されたするために使用される各証明書のSANリストにその名前を追加します。
1. 同じCAからすべての証明書を発行します:
   - CA証明書をクラスタシークレットとして追加します。
   - [Prometheusチャートの](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml) `extraSecretMounts:`設定を使用して、そのシークレットをPrometheusサーバーコンテナにマウントします。
   - それをPrometheusの`scrape_config`の`tls_config.ca_file`として設定します。

[Prometheus TLS値の例](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml)では、次の方法でこの共有設定の例を示します:

1. ポッド/エンドポイント`scrape_config`ロールの`tls_config.server_name`を`metrics.gitlab`に設定します。
1. exporterのエンドポイントに使用されるすべての証明書のSANリストに`metrics.gitlab`が追加されていることを前提としています。
1. CA証明書が`metrics.gitlab.tls-ca`という名前のシークレットに追加され、Prometheusチャートがデプロイされているのと同じネームスペースに作成されたシークレットキーも`metrics.gitlab.tls-ca`という名前であることを前提としています（たとえば、`kubectl create secret generic --namespace=gitlab metrics.gitlab.tls-ca --from-file=metrics.gitlab.tls-ca=./ca.pem`）。
1. その`metrics.gitlab.tls-ca`シークレットを`/etc/ssl/certs/metrics.gitlab.tls-ca`に、`extraSecretMounts:`エントリを使用してマウントします。
1. `tls_config.ca_file`を`/etc/ssl/certs/metrics.gitlab.tls-ca`に設定します。

#### Exporterエンドポイント {#exporter-endpoints}

GitLabチャートに含まれるすべてのメトリクスエンドポイントがTLSをサポートしているわけではありません。エンドポイントがTLS対応にできる場合は、`gitlab.com/prometheus_scheme: "https"`注釈と`prometheus.io/scheme: "https"`注釈も設定され、どちらも`relabel_config`で使用してPrometheus `__scheme__`ターゲットラベルを設定できます。[Prometheus TLS値の例](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml)には、`gitlab.com/prometheus_scheme: "https"`注釈を使用して`__scheme__`をターゲットとする`relabel_config`が含まれています。

次の表に、デプロイメント（またはGitalyとPraefectの両方を使用している場合は、次の場合）を示します: `gitlab.com/prometheus_scrape: true`注釈が適用されたStatefulSetとサービスエンドポイント。

以下のドキュメントリンクで、コンポーネントがSANエントリの追加について言及している場合は、Prometheusの`tls_config.server_name`に使用することにしたSANも必ず追加してください。

| サービス | メトリクスポート（デフォルト） | TLSをサポートしていますか? | 注/Doc/Issue |
| ---     | ---                   | ---           | ---              |
| [Gitaly](../charts/gitlab/gitaly/_index.md)                   | 9236  | 対応 | `global.gitaly.tls.enabled=true`を使用して有効<br>デフォルトのシークレット: `RELEASE-gitaly-tls`<br>[ドキュメント: TLS経由でGitalyを実行する](../charts/gitlab/gitaly/_index.md#running-gitaly-over-tls) |
| [GitLab Exporter](../charts/gitlab/gitlab-exporter/_index.md) | 9168  | 対応 | `gitlab.gitlab-exporter.tls.enabled=true`を使用して有効<br>デフォルトのシークレット: `RELEASE-gitlab-exporter-tls` |
| [GitLab Pages](../charts/gitlab/gitlab-pages/_index.md)       | 9235  | 対応 | `gitlab.gitlab-pages.metrics.tls.enabled=true`を使用して有効<br>デフォルトのシークレット: `RELEASE-pages-metrics-tls`<br>[ドキュメント: 一般的な設定](../charts/gitlab/gitlab-pages/_index.md#general-settings) |
| [GitLab Runner](../charts/gitlab/gitlab-runner/_index.md)     | 9252  | 非対応  | [イシュー - メトリクスエンドポイントのTLSサポートを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29176) |
| [GitLab Shell](../charts/gitlab/gitlab-shell/_index.md)       | 9122  | 非対応  | GitLabシェルメトリクスエクスポーターは、[`gitlab-sshd`](https://docs.gitlab.com/administration/operations/gitlab_sshd/)を使用する場合にのみ有効になります。TLSを必要とする環境には、OpenSSHをお勧めします |
| [KAS](../charts/gitlab/kas/_index.md)                         | 8151  | 対応 | `global.kas.customConfig.observability.listen.certificate_file`および`global.kas.customConfig.observability.listen.key_file`オプションを使用して設定できます |
| [Praefect](../charts/gitlab/praefect/_index.md)               | 9236  | 対応 | `global.praefect.tls.enabled=true`を使用して有効<br>デフォルトのシークレット: `RELEASE-praefect-tls`<br>[ドキュメント: TLS経由でPraefectを実行する](../charts/gitlab/praefect/_index.md#running-praefect-over-tls) |
| [レジストリ](../charts/registry/_index.md)                      | 5100  | 対応 | `registry.debug.tls.enabled=true`を使用して有効<br>[ドキュメント: レジストリ - デバッグポートのTLSの設定](../charts/registry/_index.md#configuring-tls-for-the-debug-port) |
| [Sidekiq](../charts/gitlab/sidekiq/_index.md)                 | 3807  | 対応 | `gitlab.sidekiq.metrics.tls.enabled=true`を使用して有効<br>デフォルトのシークレット: `RELEASE-sidekiq-metrics-tls`<br>[ドキュメント: インストールコマンドラインオプション](../charts/gitlab/sidekiq/_index.md#installation-command-line-options) |
| [Webservice](../charts/gitlab/sidekiq/_index.md)              | 8083  | 対応 | `gitlab.webservice.metrics.tls.enabled=true`を使用して有効<br>デフォルトのシークレット: `RELEASE-webservice-metrics-tls`<br>[ドキュメント: インストールコマンドラインオプション](../charts/gitlab/webservice/_index.md#installation-command-line-options) |
| [Ingress-NGINX](../charts/nginx/_index.md)                    | 10254 | 非対応  | メトリクス/ヘルスチェックポートでTLSをサポートしていません |

webserviceポッドの場合、公開されるポートは、webserviceコンテナ内のスタンドアロンのwebrickエクスポーターです。workhorseコンテナポートはスクレイプされません。詳細については、[Webservice Metricsドキュメント](../charts/gitlab/webservice/_index.md#metrics)を参照してください。

### 送信メール {#outgoing-email}

デフォルトでは、送信メールは無効になっています。有効にするには、`global.smtp`および`global.email`設定を使用して、SMTPサーバーの詳細を指定します。これらの設定の詳細は、[コマンドラインオプション](command-line-options.md#outgoing-email-configuration)にあります。

SMTPサーバーが認証を必要とする場合は、[シークレットドキュメント](secrets.md#smtp-password)でパスワードの指定に関するセクションを必ずお読みください。`--set global.smtp.authentication=""`を使用して、認証設定を無効にできます。

KubernetesクラスターがGKE上にある場合、SMTP [ポート25がブロックされている](https://cloud.google.com/compute/docs/tutorials/sending-mail/#using_standard_email_ports)ことに注意してください。

### 受信メール {#incoming-email}

受信メールの設定は、[mailroomチャート](../charts/gitlab/mailroom/_index.md#incoming-email)に記載されています。

### サービスデスクメール {#service-desk-email}

受信メールの設定は、[mailroomチャート](../charts/gitlab/mailroom/_index.md#service-desk-email)に記載されています。

### RBAC {#rbac}

GitLabチャートは、[RBAC](rbac.md)の作成と使用をデフォルトとします。クラスターでRBACが有効になっていない場合は、これらの設定を無効にする必要があります:

```shell
--set certmanager.rbac.create=false
--set nginx-ingress.rbac.createRole=false
--set prometheus.rbac.create=false
--set gitlab-runner.rbac.create=false
```

## 次の手順 {#next-steps}

[クラウドプロバイダーを設定し、クラスターを作成します](cloud/_index.md)。
