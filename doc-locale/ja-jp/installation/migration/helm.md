---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Helm v2からHelm v3への移行
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Helm v2は、2020年11月に正式に非推奨になりました](https://helm.sh/blog/helm-v2-deprecation-timeline/)。GitLab Helm Chartバージョン5.0（GitLab Appバージョン14.0）以降、Helm v2.xを使用したインストールとアップグレードはサポートされなくなりました。今後のGitLabのアップデートを入手するには、Helm v3に移行する必要があります。

## Helm v2とHelm v3の変更点 {#changes-between-helm-v2-and-helm-v3}

Helm v3では、Helm v2との下位互換性のない多くの変更が導入されています。主な変更点としては、Tillerの要件の削除や、クラスタ上でのリリース情報の保存方法などが挙げられます。詳細については、[Helm v3の変更点の概要](https://helm.sh/docs/topics/v2_v3_migration/#overview-of-helm-3-changes)と[Helm v2以降のFAQ](https://helm.sh/docs/faq/changes_since_helm2/)をご覧ください。

アプリケーションのデプロイに使用するHelm Chartは、新しいバージョンのHelmと互換性がない可能性があります。複数のアプリケーションがHelm v2でデプロイおよび管理されている場合は、それらも変換する場合は、Helm v3と互換性があるかどうかを確認する必要があります。GitLab Helm Chartは、GitLab Helm Chartのバージョンv3.0.0以降、Helm v3.0.2以上をサポートしています。Helm v2はサポートされなくなりました。

現在実行中のアプリケーションの観点からは、Helm v2からv3への移行を実行しても何も変更されません。一般的に、Helm v2からv3への移行を実行しても非常に安全ですが、念のため、Helm v2のバックアップを作成してください。

## Helm v2からHelm v3への移行方法 {#how-to-migrate-from-helm-v2-to-helm-v3}

[Helm 2to3プラグイン](https://github.com/helm/helm-2to3)を使用して、GitLabのリリースをHelm v2からHelm v3に移行できます。この移行プラグインに関するいくつかの例を含むより詳細な説明については、Helmのブログ記事を参照してください: [Helm v2からHelm v3への移行方法](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/)。

複数の人がGitLab Helmのインストールを管理している場合は、各ローカルマシンで`helm3 2to3 move config`を実行する必要がある場合があります。`helm3 2to3 convert`は1回だけ実行する必要があります。

## 既知の問題 {#known-issues}

### 移行後に「UPGRADE FAILED: cannot patch」エラーが表示される {#upgrade-failed-cannot-patch-error-is-shown-after-the-migration}

移行後、**その後のアップグレードが失敗する可能性があり**、次のようなエラーが表示されます:

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind Deployment: Deployment.apps "..." is invalid: spec.selector:
Invalid value: v1.LabelSelector{...}: field is immutable
```

または

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind StatefulSet: StatefulSet.apps "..." is invalid:
spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', and 'updateStrategy' are forbidden
```

これは、[Cert Manager](https://github.com/jetstack/cert-manager/issues/2451)と[Redis](https://github.com/bitnami/charts/issues/3482)の依存関係におけるHelm 2から3への移行に関する既知の問題が原因です。一言で言えば、一部のDeploymentsおよびStatefulSetsの`heritage`ラベルはイミュータブルであり、`Tiller`（Helm 2によって設定）から`Helm`（Helm 3によって設定）に変更できません。そのため、_強制的に_置き換える必要があります。

これを回避するには、次の手順を使用します:

{{< alert type="note" >}}

これらの手順は、特にRedis StatefulSetなど、_リソースを強制的に置き換えます_。このStatefulSetにアタッチされたデータボリュームが安全で、そのまま残っていることを確認する必要があります。

{{< /alert >}}

1. cert-manager Deploymentsを置き換えます（有効になっている場合）。

```shell
kubectl get deployments -l app=cert-manager -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
kubectl get deployments -l app=cainjector -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
```

1. （オプション）Redis StatefulSetによって要求されるPV上の`persistentVolumeReclaimPolicy`を`Retain`に設定します。これは、PVが誤って削除されないようにするためです。

```shell
kubectl patch pv <PV-NAME> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

1. 既存のRedis PVCの`heritage`ラベルを`Helm`に設定します。

```shell
kubectl label pvc -l app=redis --overwrite heritage=Helm
```

1. Redis StatefulSetを**カスケードなしで**置き換えます。

```shell
kubectl get statefulsets.apps -l app=redis -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true --cascade=false -f -
```

### Helmアップグレードの実行時に移行後にRBACのイシューが発生する {#rbac-issues-after-the-migration-when-running-helm-upgrade}

変換が完了した後、Helmアップグレードを実行すると、次のエラーが発生する可能性があります:

```shell
Error: UPGRADE FAILED: pre-upgrade hooks failed: warning: Hook pre-upgrade gitlab/templates/shared-secrets/rbac-config.yaml failed: roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden: user "your-user-name@domain.tld" (groups=["system:authenticated"]) is attempting to grant RBAC permissions not currently held:
{APIGroups:[""], Resources:["secrets"], Verbs:["get" "list" "create" "patch"]}
```

Helm2は、Tillerサービスアカウントを使用して、このような操作を実行していました。Helm3はTillerを使用しなくなり、クラスタ管理者として`helm upgrade`を実行している場合でも、コマンドを実行するには、ユーザーアカウントに適切なRBACの権限が必要です。完全なRBACの権限を自分自身に付与するには、次を実行します:

```shell
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=your-user-name@domain.tld
```

その後、`helm upgrade`は正常に動作するはずです。
