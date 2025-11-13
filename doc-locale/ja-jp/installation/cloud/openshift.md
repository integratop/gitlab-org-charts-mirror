---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのOpenShiftリソースの準備
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このドキュメントでは、このプロジェクトの自動化スクリプトを使用して、Google CloudにOpenShiftクラスターを作成する方法を説明します。

## 準備 {#preparation}

まず、GitLabメールに関連付けられたRed Hatアカウントが必要です。Red Hat Allianceの担当者にお問い合わせください。メールでアカウント招待状が送信されるように手配します。Red Hatアカウントをアクティブにすると、OpenShiftの実行に必要なライセンスとサブスクリプションにアクセスできるようになります。

Google Cloudでクラスターを起動するには、パブリックCloud DNSゾーンを登録済みドメインに接続し、Google Cloud DNSで構成する必要があります。ドメインがまだ利用できない場合は、[このガイド](https://github.com/openshift/installer/blob/master/docs/user/gcp/dns.md)の手順に従って作成してください。

### CLIツールとプルシークレットを取得する {#get-the-cli-tools-and-pull-secret}

OpenShiftクラスター（`openshift-install`）を作成し、クラスター（`oc`）を操作するには、2つのCLIツールが必要です。

Red HatのプライベートDockerレジストリからイメージをフェッチするには、プルシークレットが必要です。すべてのデベロッパーには、Red Hatアカウントに関連付けられた異なるプルシークレットがあります。

CLIツールとプルシークレットを取得するには、[Red Hatのクラウド](https://cloud.redhat.com/openshift/install/gcp/installer-provisioned)にアクセスし、Red Hatアカウントでログインします。このページで、インストーラーとコマンドラインツールの最新バージョンを、指定されたリンクからダウンロードします。これらのパッケージを解凍し、`openshift-install`と`oc`を`PATH`に配置します。

プルシークレットをクリップボードにコピーし、コンテンツをこのリポジトリのルートにあるファイル`pull_secret`に書き込みます。このファイルはgitignoredです。

### Google Cloud（GCP）サービスアカウントを作成する {#create-a-google-cloud-gcp-service-account}

[これらの手順](https://docs.openshift.com/container-platform/4.9/installing/installing_gcp/installing-gcp-account.html#installation-gcp-service-account_installing-gcp-account)に従って、Google Cloudのサービスアカウントを`cloud-native`プロジェクトに作成します。そのドキュメントで必須とマークされているすべてのロールをアタッチします。サービスアカウントが作成されたら、JSONキーを生成し、このリポジトリのルートに`gcloud.json`として保存します。このファイルはgitignoredです。

## OpenShiftクラスターを作成する {#create-your-openshift-cluster}

OpenShiftクラスターを作成するには、次の手順を実行します:

1. GitLab Operatorリポジトリをクローンします:

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git
   ```

1. スクリプトを実行して、Google CloudにOpenShiftクラスターを作成します:

   ```shell
   cd gitlab-operator
   ./scripts/create_openshift_cluster.sh
   ```

これは、3つのコントロールプレーン（メイン）ノードと3つのワーカーノードを持つ6ノードクラスターになります。このプロセスには約40分かかります。コンソールの出力の最後にある指示に従って、クラスターに接続します。

作成が完了すると、[Red Hatクラウド](https://cloud.redhat.com/openshift/)にクラスターが登録されていることがわかります。すべてのインストールログとメタデータは、このリポジトリの`install-$CLUSTER_NAME/`ディレクトリに保存されます。このディレクトリはgitignoredです。

### 設定オプション {#configuration-options}

設定は、環境変数を設定することにより、ランタイム時に適用できます。すべてのオプションにはデフォルトがあるため、オプションは必要ありません。

| 変数                         | デフォルト                                      | 説明 |
|----------------------------------|----------------------------------------------|-------------|
| `CLUSTER_NAME`                   | `ocp-$USER`                                  | クラスターの名前 |
| `BASE_DOMAIN`                    | `k8s-ft.win`                                 | クラスターのルートドメイン |
| `GCP_PROJECT_ID`                 | `cloud-native-182609`                        | Google CloudプロジェクトID |
| `GCP_REGION`                     | `us-central1`                                | クラスターのGoogle Cloudリージョン |
| `GOOGLE_APPLICATION_CREDENTIALS` | `gcloud.json`                                | Google CloudサービスアカウントJSONファイルへのパス |
| `GOOGLE_CREDENTIALS`             | `$GOOGLE_APPLICATION_CREDENTIALS`の内容 | Google CloudサービスアカウントJSONファイルの内容 |
| `PULL_SECRET_FILE`               | `pull_secret`                                | Red Hatプルシークレットファイルへのパス |
| `PULL_SECRET`                    | `$PULL_SECRET_FILE`の内容               | Red Hatプルシークレットファイルの内容 |
| `SSH_PUBLIC_KEY_FILE`            | `$HOME/.ssh/id_rsa.pub`                      | SSH公開キーファイルへのパス |
| `SSH_PUBLIC_KEY`                 | `$SSH_PUBLIC_KEY_FILE`の内容            | SSH公開キーファイルの内容 |
| `LOG_LEVEL`                      | `info`                                       | `openshift-install`出力の詳細度 |
| `INSTALL_DIR`                    | `install-$CLUSTER_NAME`                      | 複数のクラスターの起動に役立つインストールアセット用のディレクトリ |

{{< alert type="note" >}}

変数`CLUSTER_NAME`と`BASE_DOMAIN`を組み合わせて、クラスターのドメイン名を作成します。

{{< /alert >}}

## OpenShiftクラスターを削除する {#destroy-your-openshift-cluster}

OpenShiftクラスターを削除するには、次の手順を実行します:

1. GitLab Operatorリポジトリをクローンします:

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git
   ```

1. スクリプトを実行して、Google CloudでOpenShiftクラスターを削除します。これには約4分かかります:

   ```shell
   cd gitlab-operator
   ./scripts/destroy_openshift_cluster.sh
   ```

環境変数を設定することにより、ランタイム時に設定を適用できます。すべてのオプションにはデフォルトがあるため、オプションは必要ありません。

| 変数                         | デフォルト------------------------------------- | 説明 |
|----------------------------------|----------------------------------------------|-------------|
| `GOOGLE_APPLICATION_CREDENTIALS` | `gcloud.json`                                | Google CloudサービスアカウントJSONファイルへのパス |
| `GOOGLE_CREDENTIALS`             | `$GOOGLE_APPLICATION_CREDENTIALS`の内容 | Google CloudサービスアカウントJSONファイルの内容 |
| `LOG_LEVEL`                      | `info`                                       | `openshift-install`出力の詳細度 |
| `INSTALL_DIR`                    | `install-$CLUSTER_NAME`                      | 複数のクラスターの起動に役立つインストールアセット用のディレクトリ |

## 次の手順 {#next-steps}

クラスターが起動して実行されたら、[GitLabのインストール](https://docs.gitlab.com/operator/)を続行できます。

## リソース {#resources}

- [`openshift-installer`のソースコード](https://github.com/openshift/installer)
- [`oc`のソースコード](https://github.com/openshift/oc)
- [`openshift-installer`および`oc`パッケージ](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/)
- [OpenShift Container Project（OCP）アーキテクチャドキュメント](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.9/html/architecture/architecture)
- [OpenShift GCPドキュメント](https://docs.openshift.com/container-platform/4.9/installing/installing_gcp/installing-gcp-account.html)
- [OpenShiftトラブルシューティングガイド](https://docs.openshift.com/container-platform/4.9/support/troubleshooting/troubleshooting-installations.html)
