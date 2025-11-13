---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャート用のEKSリソースの準備
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

完全に機能するGitLabインスタンスの場合、GitLabチャートをデプロイする前に、いくつかのリソースが必要です。

## EKSクラスタの作成 {#creating-the-eks-cluster}

簡単に開始できるように、クラスターの作成を自動化するスクリプトが用意されています。または、クラスターを手動で作成することもできます。

前提要件: 

- [前提要件](../tools.md)をインストールします。
- [`eksctl`](https://github.com/weaveworks/eksctl#installation)をインストールします。

クラスタを手動で作成するには、[Amazon AWSのAmazon EKSの開始方法](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)を参照してください。EKSクラスタには、[Fargate](https://docs.aws.amazon.com/en_us/eks/latest/userguide/fargate.html)ではなく、EC2マネージドノードを使用してください。Fargateにはいくつかの制限があり、GitLab Helmチャートでの使用はサポートされていません。

### スクリプト化されたクラスターの作成 {#scripted-cluster-creation}

EKSのユーザー向けに、設定プロセスの大部分を自動化する[bootstrap script](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/eks_bootstrap_script)が作成されました。スクリプトを実行する前に、このリポジトリをクローンする必要があります。

このスクリプトは次のことを行います:

1. 新しいEKSクラスタを作成します。
1. `kubectl`をセットアップし、それをクラスターに接続します。

認証するために、`eksctl`はAWSのコマンドラインと同じオプションを使用します。[環境変数](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)または[設定ファイル](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)の使用方法については、AWSのドキュメントを参照してください。

スクリプトは、環境変数、またはコマンドライン引数からさまざまなパラメータを読み込むと、bootstrapの場合は`up`、クリーンアップの場合は`down`を読み込みます。

以下の表に、すべての変数を示します。

| 変数          | デフォルト値    | 説明 |
|-------------------|------------------|-------------|
| `REGION`          | `us-east-2`      | クラスタが存在するリージョン |
| `CLUSTER_NAME`    | `gitlab-cluster` | クラスターの名前 |
| `CLUSTER_VERSION` | `1.29`           | EKSクラスタのバージョン |
| `NUM_NODES`       | `2`              | 必要なノードの数 |
| `MACHINE_TYPE`    | `m5.xlarge`      | デプロイするノードのタイプ |

必要なパラメータを渡して、スクリプトを実行します。デフォルトのパラメータで使用できます。

```shell
./scripts/eks_bootstrap_script up
```

このスクリプトは、作成されたEKSリソースをクリーンアップするためにも使用できます:

```shell
./scripts/eks_bootstrap_script down
```

### 手動によるクラスターの作成 {#manual-cluster-creation}

- 8vCPUと30GBのRAMを搭載したクラスタをお勧めします。

最新の手順については、Amazonの[EKSの開始方法](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)に従ってください。

管理者は、このプロセスを簡素化するために、[新しいKubernetes用AWSサービスオペレーター](https://aws.amazon.com/blogs/opensource/aws-service-operator-kubernetes-available/)を検討することもできます。

{{< alert type="note" >}}

AWSサービスオペレーターを有効にするには、クラスタ内でロールを管理する方法が必要です。その管理タスクを処理する初期サービスは、サードパーティのデベロッパーによって提供されます。管理者は、デプロイを計画する際に、そのことを念頭に置いておく必要があります。

{{< /alert >}}

## 永続ボリュームの管理 {#persistent-volume-management}

Kubernetesでボリューム要求を管理するには、次の2つの方法があります:

- 永続ボリュームを手動で作成します。
- 動的プロビジョニングによる自動永続ボリュームの作成。

現在、永続ボリュームの手動プロビジョニングを使用することをお勧めします。Amazon EKSクラスタはデフォルトで複数のゾーンにまたがっています。特定のゾーンにロックされたストレージクラスを使用するように設定されていない場合、動的プロビジョニングにより、ポッドがストレージボリュームとは異なるゾーンに存在し、データにアクセスできなくなるシナリオが発生する可能性があります。詳細については、[永続ボリュームをプロビジョンする方法](../storage.md)を参照してください。

Amazon EKS 1.23以降のクラスタでは、手動プロビジョニングと動的プロビジョニングのどちらであっても、[Amazon EBS CSIアドオン](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html#adding-ebs-csi-eks-add-on)をクラスタにインストールする必要があります。

```shell
eksctl utils associate-iam-oidc-provider --cluster **CLUSTER_NAME** --approve

eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster **CLUSTER_NAME** \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve \
    --role-only \
    --role-name *ROLE_NAME*

eksctl create addon --name aws-ebs-csi-driver --cluster **CLUSTER_NAME** --service-account-role-arn arn:aws:iam::*AWS_ACCOUNT_ID*:role/*ROLE_NAME* --force

kubectl annotate serviceaccount ebs-csi-controller-sa -n kube-system eks.amazonaws.com/role-arn=arn:aws:iam::*AWS_ACCOUNT_ID*:role/*ROLE_NAME*
```

## GitLabへの外部アクセス {#external-access-to-gitlab}

デフォルトでは、GitLabチャートをインストールすると、関連付けられたElasticロードバランサー（ELB）を作成するIngressがデプロイされます。ELBのDNS名が事前にわからないため、[Let's Encrypt](https://letsencrypt.org/)を使用してHTTPS証明書を自動的にプロビジョンすることは困難です。

[独自の証明書を使用する](../tls.md#option-2-use-your-own-wildcard-certificate)ことをお勧めします。次に、CNAMEレコードを使用して、目的のDNS名を、作成されたELBにマップします。ELBは、そのホスト名が取得される前に最初に作成する必要があるため、次の手順に従ってGitLabをインストールしてください。

{{< alert type="note" >}}

AWSロードバランサーが必要な環境では、[AmazonのElasticロードバランサー](https://docs.aws.amazon.com/eks/latest/userguide/load-balancing.html)には特別な設定が必要です。[クラウドプロバイダーのロードバランサー](../../charts/globals.md#cloud-provider-loadbalancers)を参照してください

{{< /alert >}}

## 次の手順 {#next-steps}

クラスタが起動して実行されたら、[チャートのインストール](../deployment.md)を続行します。`global.hosts.domain`オプションを使用してドメインネームサービスを設定しますが、既存のElastic IPを使用する予定がない限り、`global.hosts.externalIP`オプションを使用して静的IP設定を省略します。

Helmのインストール後、次の手順で、ELBのホスト名をフェッチして、CNAMEレコードに配置できます:

```shell
kubectl get ingress/RELEASE-webservice-default -ojsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

`RELEASE`は、`helm install <RELEASE>`で使用されるリリース名に置き換える必要があります。
