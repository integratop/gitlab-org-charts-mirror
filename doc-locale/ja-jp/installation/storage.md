---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのストレージを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

以下のアプリケーションは、ステートを維持するためにGitLabチャート内の永続ストレージを必要とします。

- [Gitaly](../charts/gitlab/gitaly/_index.md)（Gitリポジトリを保持）
- [PostgreSQL](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)（GitLabデータベースデータを保持）
- [Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis)（GitLabジョブデータを保持）
- [MinIO](../charts/minio/_index.md)（オブジェクトストレージデータを保持）

管理者は、[動的](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic)または[静的](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static)ボリュームプロビジョニングを使用して、このストレージをプロビジョニングすることを選択できます。

> **重要**: 事前計画を通じて、インストール後の追加のストレージ移行タスクを最小限に抑える。最初のデプロイ後に行われた変更では、`helm upgrade`を実行する前に、既存のKubernetesオブジェクトを手動で編集する必要があります。

## 標準的なインストール方法 {#typical-installation-behavior}

インストーラーは、デフォルトのストレージクラスと[動的ボリュームプロビジョニング](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic)を使用してストレージを作成します。アプリケーションは、[Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)を通じてこのストレージに接続します。管理者は、可能な場合は、[動的ボリュームプロビジョニング](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic)の代わりに[静的ボリュームプロビジョニング](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static)を使用することをお勧めします。

> 管理者は、`kubectl get storageclass`を使用して本番環境内のデフォルトのストレージクラスを決定し、次に`kubectl describe storageclass *STORAGE_CLASS_NAME*`を使用して調べます。Amazon EKSなどの一部のプロバイダーは、デフォルトのストレージクラスを提供していません。

## クラスタリングストレージの設定 {#configuring-cluster-storage}

### 推奨事項 {#recommendations}

デフォルトのストレージクラスは、次のとおりである必要があります:

- 可能な場合は、高速ソリッドステートドライブストレージを使用する
- `reclaimPolicy`を`Retain`に設定する

> `reclaimPolicy`が`Retain`に設定されていない状態でGitLabをアンインストールすると、自動化されたジョブはボリューム、ディスク、およびデータを完全に削除できます。一部のプラットフォームでは、デフォルトの`reclaimPolicy`が`Delete`に設定されています。`gitaly`永続ボリュームクレームは、[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)に属しているため、このルールに従いません。

### 最小ストレージクラス構成 {#minimal-storage-class-configurations}

以下の`YAML`構成は、GitLab用のカスタムストレージクラスを作成するために必要な最小限の構成を提供します。`CUSTOM_STORAGE_CLASS_NAME`を、ターゲットインストール環境に適した値に置き換えます。

- [Google Cloud上のGKEのストレージクラスの例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_storage_class.yml)
- [Amazon Web Services上のEKSのストレージクラスの例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_storage_class.yml)

> 一部のユーザーは、Amazon EKSが、ポッドと同じゾーンにノードの作成が常に存在するとは限らないという動作を示すとレポートしています。上記の***zone**（ゾーン）*パラメータを設定すると、リスクが軽減されます。

### カスタムストレージクラスの使用 {#using-the-custom-storage-class}

カスタムストレージクラスをクラスタのデフォルトに設定すると、すべての動的プロビジョニングに使用されます。

```shell
kubectl patch storageclass CUSTOM_STORAGE_CLASS_NAME -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

または、カスタムストレージクラスおよびその他のオプションは、インストール中にサービスごとにHelmに提供できます。提供されている[設定ファイルの例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/helm_options.yml)を表示し、環境に合わせて変更します。

```shell
helm install -upgrade gitlab gitlab/gitlab -f HELM_OPTIONS_YAML_FILE
```

詳細と追加の永続オプションについては、以下のリンクを参照してください:

- [Gitalyの永続構成](../charts/gitlab/gitaly/_index.md#git-repository-persistence)
- [MinIOの永続構成](../charts/minio/_index.md#persistence)
- [Redisの永続構成](https://github.com/bitnami/charts/tree/main/bitnami/redis#persistence)
- [アップストリームPostgreSQLチャート構成](https://github.com/bitnami/charts/tree/main/bitnami/postgresql#configuration-and-installation-details)

> **メモ**: 高度な永続オプションの一部はPostgreSQLと他のオプションで異なるため、変更を行う前に、それぞれの特定のドキュメントを確認することが重要です。

## 静的ボリュームプロビジョニングの使用 {#using-static-volume-provisioning}

動的ボリュームプロビジョニングが推奨されますが、一部のクラスタリングまたは環境ではサポートされていない場合があります。管理者は、[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)を手動で作成する必要があります。

### Google GKEの使用 {#using-google-gke}

1. [クラスタ内に永続ディスクを作成します。](https://kubernetes.io/docs/concepts/storage/volumes/#creating-a-pd)

```shell
gcloud compute disks create --size=50GB --zone=*GKE_ZONE* *DISK_VOLUME_NAME*
```

1. [`YAML`構成例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_pv_example.yml)を変更した後、Persistent Volumeを作成します。

```shell
kubectl create -f *PV_YAML_FILE*
```

### Amazon EKSの使用 {#using-amazon-eks}

{{< alert type="note" >}}

複数のゾーンにデプロイする必要がある場合は、ストレージソリューションを定義するときに、[ストレージクラスに関するAmazon独自のドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)を確認する必要があります。

{{< /alert >}}

1. [クラスタ内に永続ディスクを作成します。](https://kubernetes.io/docs/concepts/storage/volumes/#creating-an-ebs-volume)

```shell
aws ec2 create-volume --availability-zone=*AWS_ZONE* --size=10 --volume-type=gp2
```

1. [`YAML`構成例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_pv_example.yml)を変更した後、Persistent Volumeを作成します。

```shell
kubectl create -f *PV_YAML_FILE*
```

### PersistentVolumeClaimの手動作成 {#manually-creating-persistentvolumeclaims}

Gitalyサービスは、[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)を使用してデプロイします。適切に認識され、使用されるように、次の命名規則を使用して[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)を作成します。

```plaintext
<mount-name>-<statefulset-pod-name>
```

Gitalyの`mount-name`は`repo-data`です。StatefulSetポッド名は、次を使用して作成されます:

```plaintext
<statefulset-name>-<pod-index>
```

GitLabチャートは、次を使用して`statefulset-name`を決定します:

```plaintext
<chart-release-name>-<service-name>
```

Gitaly PersistentVolumeClaimの正しい名前は`repo-data-gitlab-gitaly-0`です。

> **メモ**: 複数の仮想ストレージでPraefectを使用している場合は、定義された仮想ストレージごとにGitalyレプリカごとに1つのPersistentVolumeClaimが必要になります。たとえば、`default`および`vs2`仮想ストレージが定義されていて、それぞれに2つのレプリカがある場合、次のPersistentVolumeClaimが必要になります:
>
> - `repo-data-gitlab-gitaly-default-0`
> - `repo-data-gitlab-gitaly-default-1`
> - `repo-data-gitlab-gitaly-vs2-0`
> - `repo-data-gitlab-gitaly-vs2-1`

環境に合わせて[設定ファイル例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gitaly_persistent_volume_claim.yml)を変更し、`helm`を実行するときに参照します。

> [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)を使用しない他のサービスでは、管理者が設定に`volumeName`を提供できます。このチャートは、[ボリュームクレーム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)の作成を処理し、手動で作成されたボリュームへのバインドを試みます。含まれている各アプリケーションのチャートドキュメントを確認してください。
>
> ほとんどの場合、手動で作成したディスクボリュームを使用するサービスのみを保持して、[設定ファイル例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/use_manual_volumes.yml)を変更するだけです。

## インストール後にストレージを変更する {#making-changes-to-storage-after-installation}

最初のインストール後、新しいボリュームへの移行やディスクサイズの変更などのストレージ変更を行うには、Helmアップグレードコマンドの外部でKubernetesオブジェクトを編集する必要があります。

[永続ボリュームの管理ドキュメント](../advanced/persistent-volumes/_index.md)を参照してください。

## オプションのボリューム {#optional-volumes}

大規模なインストールの場合は、バックアップと復元するを機能させるために、Toolboxに永続ストレージを追加する必要がある場合があります。これを行う方法については、[トラブルシューティングドキュメント](../backup-restore/_index.md#pod-eviction-issues)を参照してください。
