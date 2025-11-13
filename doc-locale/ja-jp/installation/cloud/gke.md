---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GKEリソースをGitLabチャート用に準備する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

完全に機能するGitLabインスタンスの場合、GitLabチャートをデプロイする前に、いくつかのリソースが必要になります。以下に、これらのチャートがGitLab内でどのようにデプロイおよびテストされるかを示します。

## GKEクラスタの作成 {#creating-the-gke-cluster}

簡単に開始できるように、クラスターの作成を自動化するスクリプトが用意されています。または、クラスターを手動で作成することもできます。

前提要件: 

- [前提要件](../tools.md)をインストールします。
- [Google SDK](https://cloud.google.com/sdk/docs/install)をインストールします。

### スクリプト化されたクラスターの作成 {#scripted-cluster-creation}

[ブートストラップスクリプト](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/gke_bootstrap_script.sh)が作成され、GCP/GKEのユーザー向けに設定プロセスの多くを自動化します。

このスクリプトは次のことを行います:

1. 新しいGKEクラスタを作成します。
1. クラスタがDNSレコードを変更できるようにします。
1. `kubectl`をセットアップし、それをクラスターに接続します。

このスクリプトは、環境変数と、ブートストラップの場合は`up`、クリーンアップの場合は`down`の引数から、さまざまなパラメータを読み取ります。

以下の表に、すべての変数を示します。

| 変数              | デフォルト値                     | 説明 |
|-----------------------|-----------------------------------|-------------|
| `ADMIN_USER`          | 現在のgcloudユーザー               | セットアップ中にクラスタの管理者アクセスを割り当てるユーザー。 |
| `AUTOSCALE_MAX_NODES` | `NUM_NODES`                       | オートスケーラーがスケールアップするノードの最大数。 |
| `AUTOSCALE_MIN_NODES` | `0`                               | オートスケーラーがスケールダウンするノードの最小数。 |
| `CLUSTER_NAME`        | `gitlab-cluster`                  | クラスターの名前。 |
| `CLUSTER_VERSION`     | GKEのデフォルト、[GKEリリースノート](https://cloud.google.com/kubernetes-engine/docs/release-notes)を確認してください | お使いのGKEクラスタのバージョン。 |
| `INT_NETWORK`         | デフォルトはです。                           | このクラスタ内で使用するIP空間。 |
| `MACHINE_TYPE`        | `n2d-standard-4`                  | クラスタインスタンスのタイプ。 |
| `NUM_NODES`           | `2`                               | 必要なノードの数。 |
| `PREEMPTIBLE`         | `false`                           | より安価なクラスタは、*最大*24時間稼働します。ノード/ディスクにSLAはありません。 |
| `PROJECT`             | デフォルトはありません。設定する必要があります。  | GCPプロジェクトのID。 |
| `RBAC_ENABLED`        | `true`                            | クラスタでRBACが有効になっているかどうかを知っている場合は、この変数を設定します。 |
| `REGION`              | `us-central1`                     | クラスタが存在するリージョン。 |
| `SUBNETWORK`          | デフォルトはです。                           | このクラスタ内で使用するサブネットワーク。 |
| `USE_STATIC_IP`       | `false`                           | 管理対象のDNSを持つ一時的なIPの代わりに、GitLabの静的IPを作成します。 |
| `ZONE_EXTENSION`      | `b`                               | クラスタインスタンスが存在するゾーン名の拡張子（`a`、`b`、`c`）。 |

必要なパラメータを渡して、スクリプトを実行します。必須の`PROJECT`を除き、デフォルトのパラメータで動作します:

```shell
PROJECT=<gcloud project id> ./scripts/gke_bootstrap_script.sh up
```

このスクリプトは、作成されたGKEリソースのクリーンアップにも使用できます:

```shell
PROJECT=<gcloud project id> ./scripts/gke_bootstrap_script.sh down
```

クラスタが作成されたら、[DNSエントリの作成](#dns-entry)に進みます。

### 手動によるクラスターの作成 {#manual-cluster-creation}

GCPで作成する必要のあるリソースは、Kubernetesクラスタと外部IPの2つです。

#### Kubernetesクラスタの作成 {#creating-the-kubernetes-cluster}

Kubernetesクラスタを手動でプロビジョニングするには、[GKEの手順](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster)に従ってください。

- 4vCPUと15GBのRAMを搭載したノードを少なくとも2つ持つクラスタをお勧めします。
- クラスタのリージョンをメモしておいてください。次のステップで必要になります。

#### 外部IPの作成 {#creating-the-external-ip}

クラスターを到達可能にするため、外部IPが必要です。外部IPは、リージョンであり、クラスタ自体と同じリージョンにある必要があります。グローバルIPまたはクラスタのリージョン外のIPは**機能しません**。

静的IPを実行するには、次のようにします:

`gcloud compute addresses create ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT`

新しく作成されたIPのアドレスを取得するには:

`gcloud compute addresses describe ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT --format='value(address)'`

次のセクションでは、このIPを使用してDNS名にバインドします。

## DNSエントリ {#dns-entry}

クラスタを手動で作成した場合、またはスクリプトによる作成で`USE_STATIC_IP`オプションを使用した場合は、作成したIPを指すAレコードワイルドカードDNSエントリを含むパブリックドメインが必要になります。

[Google DNSクイックスタートガイド](https://cloud.google.com/dns/docs/set-up-dns-records-domain-name)に従って、DNSエントリを作成します。

## 次の手順 {#next-steps}

クラスタが起動して実行され、静的IPとDNSエントリの準備ができたら、[チャートのインストール](../deployment.md)に進みます。
