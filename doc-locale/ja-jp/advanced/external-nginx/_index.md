---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部NGINX IngressコントローラーでGitLabチャートを設定する
---

このチャートは、公式の[NGINX Ingress](https://github.com/kubernetes/ingress-nginx)実装で使用するための`Ingress`リソースを設定します。NGINX Ingressコントローラーは、このチャートの一部としてデプロイされます。クラスタ内で既に利用可能な既存のNGINX Ingressコントローラーを再利用する場合は、このガイドが役立ちます。

## 外部IngressコントローラーのTCPサービス {#tcp-services-in-the-external-ingress-controller}

GitLab Shellコンポーネントは、ポート22（デフォルト）でTCPトラフィックが通過する必要があります（変更可能）。IngressはTCPサービスを直接サポートしていないため、追加の設定が必要です。NGINX Ingressコントローラーは、（Kubernetes仕様ファイルを使用して）[直接デプロイされた](https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md)か、[公式Helm Chart](https://github.com/kubernetes/ingress-nginx)を介してデプロイされた可能性があります。TCPパススルーの設定は、デプロイアプローチによって異なります。

### 直接デプロイ {#direct-deployment}

直接デプロイでは、NGINX Ingressコントローラーは`ConfigMap`を使用してTCPサービスの設定を処理します。詳細については、Ingress NGINXコントローラーのドキュメントの[TCPおよびUDPサービスの公開](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)を参照してください。GitLabチャートがネームスペース`gitlab`にデプロイされ、Helmリリースに`mygitlab`という名前が付けられているとすると、`ConfigMap`は次のようになります:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-configmap-example
data:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

その`ConfigMap`を取得したら、NGINX Ingressコントローラーの[ドキュメント](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)に記載されているように、`--tcp-services-configmap`オプションを使用して有効にできます。

```yaml
args:
  - /nginx-ingress-controller
  - --tcp-services-configmap=gitlab/tcp-configmap-example
```

最後に、NGINX Ingressコントローラーの`Service`が、80および443に加えてポート22を公開していることを確認してください。

### Helmデプロイ {#helm-deployment}

NGINX Ingressコントローラーを[Helmチャート](https://github.com/kubernetes/ingress-nginx)を使用してインストールした場合、またはインストールを計画している場合は、コマンドラインを使用してチャートに値を追加する必要があります:

```shell
--set tcp.22="gitlab/mygitlab-gitlab-shell:22"
```

または、`values.yaml`ファイルを使用します:

```yaml
tcp:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

値の形式は、上記の「直接デプロイメント」セクションで説明されているものと同じです。

## GitLab Ingressオプションをカスタマイズする {#customize-the-gitlab-ingress-options}

NGINX Ingressコントローラーは注釈を使用して、どのIngressコントローラーが特定の`Ingress`にサービスを提供するかをマークします（[ドキュメント](https://github.com/kubernetes/ingress-nginx#annotation-ingressclass)を参照）。`global.ingress.class`設定を使用して、このチャートで使用するIngressクラスを設定できます。必ずHelmオプションでこれを設定してください。

```shell
--set global.ingress.class=myingressclass
```

必ずしも必須ではありませんが、外部のIngressコントローラーを使用している場合は、デフォルトでこのチャートとともにデプロイされるIngressコントローラーを無効にすることをお勧めします:

```shell
--set nginx-ingress.enabled=false
```

## カスタム証明書管理 {#custom-certificate-management}

TLSオプションの完全なスコープは、[別の場所](../../installation/tls.md)にドキュメント化されています。

外部のIngressコントローラーを使用している場合は、外部のcert-managerインスタンスを使用したり、他のカスタム方法で証明書を管理したりすることもできます。TLSオプションに関する完全なドキュメントについては、[GitLabチャートのTLSを設定する](../../installation/tls.md)を参照してください。ただし、このディスカッションの目的のために、cert-managerチャートを無効にし、GitLabコンポーネントチャートに組み込みの証明書リソースを探さないように指示するために設定する必要がある2つの値があります:

```shell
--set installCertmanager=false
--set global.ingress.configureCertmanager=false
```
