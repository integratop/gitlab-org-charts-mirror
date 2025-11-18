---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Helmチャートをアンインストールする
---

GitLab Helmチャートをアンインストールするには、次のコマンドを実行します:

```shell
helm uninstall gitlab
```

継続性のために、これらのチャートには、`helm uninstall`を実行しても削除されないKubernetesオブジェクトがいくつかあります。これらは、再デプロイに影響を与えるため、お客様が_意識して_削除する必要がある項目です。

- ステートフルデータのPVC。これらは、お客様が_意識して_削除する必要があります。
  - Gitaly: これはお客様のリポジトリデータです。
  - PostgreSQL（内部の場合）: これはお客様のメタデータです。
  - Redis（内部の場合）: これはキャッシュとジョブキューで、安全に削除できます。
- シークレット（共有シークレットジョブによって生成された場合）。これらのチャートは、Helmを介してKubernetes Secretsを直接生成しないように設計されています。そのため、Helmはそれらを削除できません。これらには、パスワード、暗号化シークレットなどが含まれています。これらを無謀に削除するべきではありません。
- ConfigMaps
  - `ingress-controller-leader-RELEASE-nginx`: これはNGINX Ingressコントローラー自体によって生成され、当社のチャートの制御外にあります。これは安全に削除できます。

PVCとシークレットには、`release`ラベルが設定されているため、これらは次のコマンドで見つけることができます:

```shell
kubectl get pvc,secret -lrelease=gitlab
```

{{< alert type="warning" >}}

シークレット`RELEASE-gitlab-initial-root-password`を手動で削除しない場合、次のリリースで再利用されます。このパスワードが何らかの形で（たとえば、録画されたデモで）公開されている場合は、手動で削除する必要があります。これにより、公開されたパスワードが将来のリリースでインスタンスにサインインするために使用できなくなります。

{{< /alert >}}
