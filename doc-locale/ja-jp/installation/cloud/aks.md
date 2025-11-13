---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Azure Kubernetes ServiceのGitLabチャート用AKSリソースの準備
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

完全に機能するGitLabインスタンスの場合、GitLabチャートを[Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/what-is-aks)にデプロイする前に、いくつかのリソースが必要です。

## AKSクラスターの作成 {#creating-the-aks-cluster}

簡単に開始できるように、クラスターの作成を自動化するスクリプトが用意されています。または、クラスターを手動で作成することもできます。

前提要件: 

- [前提要件](../tools.md)をインストールします。
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)をインストールし、それを使用して[Azureにサインイン](https://learn.microsoft.com/en-us/cli/azure/get-started-with-azure-cli#how-to-sign-into-the-azure-cli)します。
- [Install `jq`](https://stedolan.github.io/jq/download/)。

### スクリプト化されたクラスターの作成 {#scripted-cluster-creation}

Azureのユーザー向けに、セットアッププロセスの多くを自動化する[bootstrap script](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/aks_bootstrap_script.sh)が作成されました。

環境変数またはコマンドライン引数からの追加のオプションパラメータを使用して、`up`、`down`、または`creds`の引数を読み取ります:

- クラスターを作成するには:

  ```shell
  ./scripts/aks_bootstrap_script.sh up
  ```

  これは次のようになります:

  1. 新しいリソースグループを作成します（オプション）。
  1. 新しいAKSクラスターを作成します。
  1. 新しいパブリックIPを作成します (オプション)。

- 作成されたAKSリソースをクリーンアップするには:

  ```shell
  ./scripts/aks_bootstrap_script.sh down
  ```

  これは次のようになります:

  1. 指定されたリソースグループを削除します（オプション）。
  1. AKSクラスターを削除します。
  1. クラスターによって作成されたリソースグループを削除します。

  `down`引数は、すべてのリソースを削除して即座に終了するコマンドを送信します。実際の削除が完了するまでに数分かかる場合があります。

- クラスターに`kubectl`を接続するには:

  ```shell
  ./scripts/aks_bootstrap_script.sh creds
  ```

以下の表に、利用可能なすべての変数を示します。

| 変数                  | デフォルト値      | スコープ   | 説明 |
|---------------------------|--------------------|---------|-------------|
| `-g --resource-group`     | `gitlab-resources` | すべて     | 使用するリソースグループの名前。 |
| `-n --cluster-name`       | `gitlab-cluster`   | すべて     | 使用するクラスターの名前。 |
| `-r --region`             | `eastus`           | `up`    | クラスターをインストールするリージョン。 |
| `-v --cluster-version`    | 最新             | `up`    | クラスターの作成に使用するKubernetesのバージョン。 |
| `-c --node-count`         | `2`                | `up`    | 使用するノード数。 |
| `-s --node-vm-size`       | `Standard_D4s_v3`  | `up`    | 使用するノードのタイプ。 |
| `-p --public-ip-name`     | `gitlab-ext-ip`    | `up`    | 作成するパブリックIPの名前。 |
| `--create-resource-group` | `false`            | `up`    | 作成されたすべてのリソースを保持するための新しいリソースグループを作成します。 |
| `--create-public-ip`      | `false`            | `up`    | 新しいクラスターで使用するパブリックIPを作成します。 |
| `--delete-resource-group` | `false`            | `down`  | downコマンドを使用するときにリソースグループを削除します。 |
| `-f --kubectl-config-file` | `~/.kube/config`   | `creds` | アップデートするKubernetesの設定ファイル。代わりに、YAMLを`stdout`に出力するには、`-`を使用します。 |

### 手動によるクラスターの作成 {#manual-cluster-creation}

8vCPUと30GBのRAMを搭載したクラスターをお勧めします。

最新の手順については、Microsoftの[AKSウォークスルー](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-portal)に従ってください。

## GitLabへの外部アクセス {#external-access-to-gitlab}

クラスターを到達可能にするため、外部IPが必要です。最新の手順については、Microsoftの[静的IPアドレスを作成する](https://learn.microsoft.com/en-us/azure/aks/static-ip)ガイドに従ってください。

## 次の手順 {#next-steps}

クラスターが起動して実行され、静的IPとDNSエントリの準備ができたら、[チャートのインストール](../deployment.md)に進みます。
