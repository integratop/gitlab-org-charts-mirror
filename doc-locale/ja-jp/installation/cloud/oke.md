---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャート用のOKEリソースの準備
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

完全に機能するGitLabインスタンスの場合、GitLabチャートを[Oracle Container Engine for Kubernetes（OKE）](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengoverview.htm)にデプロイする前に、いくつかのリソースが必要です。OKEクラスターを作成する前に、Oracle Cloud Infrastructureテナンシーを[準備](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengprerequisites.htm)する方法を確認してください。

## OKEクラスターの作成 {#creating-the-oke-cluster}

前提要件: 

- [前提要件](../tools.md)をインストールします。

Kubernetesクラスターを手動でプロビジョニングするには、[OKEの手順](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm)に従ってください。OKEでサポートされているワーカーノードで使用可能なコンピューティング[シェイプ](https://docs.oracle.com/en-us/iaas/Content/ContEng/Reference/contengimagesshapes.htm#shapes)のリストを確認してください。

4つのOCPUと30GBのRAMを持つクラスターをお勧めします。

### GitLabへの外部アクセス {#external-access-to-gitlab}

デフォルトでは、GitLabチャートは、100Mbpsのシェイプを持つOracle Cloud Infrastructureパブリックロードバランサーを作成するIngressコントローラーをデプロイします。ロードバランサーサービスは、ホストサブネットからのものではないフローティングパブリックIPアドレスを割り当てます。

チャートのインストール中にシェイプやその他の設定（ポート、SSL、セキュリティリストなど）を変更するには、次のコマンドライン引数`nginx-ingress.controller.service.annotations`を使用します。たとえば、400Mbpsのシェイプでロードバランサーを指定するには、次のようにします:

```shell
--set nginx-ingress.controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape"="400Mbps"
```

デプロイしたら、Ingressコントローラーサービスに関連付けられている注釈を確認できます:

```plaintext
$ kubectl get service gitlab-nginx-ingress-controller -o yaml

apiVersion: v1
kind: Service
metadata:
  annotations:
    ...
    service.beta.kubernetes.io/oci-load-balancer-shape: 400Mbps
    ...
```

詳細については、[OKEロードバランサーのドキュメント](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingloadbalancer.htm)を確認してください。

## 次の手順 {#next-steps}

クラスターが起動して実行されたら、[チャートのインストール](../deployment.md)を続行します。`global.hosts.domain`オプションでDNSドメイン名を設定しますが、`global.hosts.externalIP`オプションによる静的IPの設定は省略します。

デプロイが完了したら、ロードバランサーのIPアドレスをクエリして、DNSレコードの種類に関連付けることができます:

```shell
kubectl get ingress/<RELEASE>-webservice-default -ojsonpath='{.status.loadBalancer.ingress[0].ip}'
```

`<RELEASE>`は、`helm install <RELEASE>`で使用されるリリース名に置き換える必要があります。
