---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#designated-technical-writers
title: HAProxyの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[HAProxy Helmチャート](https://github.com/haproxytech/helm-charts/tree/main/kubernetes-ingress)は、Ingressコントローラーとして[バンドルされたNGINX Helmチャート](../nginx/_index.md)の代わりに使用できます。また、Kubernetesの[追加のIngressコントローラーの一覧](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/#additional-controllers)に記載されています。

HAProxyはSSH経由のGitもサポートします。

[NGINX](../nginx/_index.md)をデフォルトにしているのは、主にこのツールでの過去の経験によるものですが、HAProxyは有効な代替手段であり、特にHAProxyの経験が豊富な方には好ましいかもしれません。さらに、[FIPSコンプライアンス](#fips-compliant-haproxy)を提供しますが、[NGINX Ingressコントローラー](https://github.com/kubernetes/ingress-nginx)は現在提供していません。

## HAProxyの設定 {#configuring-haproxy}

構成の詳細については、[HAProxy Helm Chartのドキュメント](https://www.haproxy.com/documentation/kubernetes-ingress/enterprise/configuration-reference/)または[Helmのvaluesファイル](https://github.com/haproxytech/helm-charts/blob/main/kubernetes-ingress/values.yaml)を参照してください。

GitLab Helm Chartでテストされた値の詳細なYAMLについては、[HAProxyの構成例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-haproxy-ingress.yaml)を参照してください。

### グローバル設定 {#global-settings}

いくつかの一般的なグローバル設定をチャート間で共有します。GitLabやレジストリのホスト名など、一般的な構成オプションについては、[グローバルIngressのドキュメント](../globals.md#configure-ingress-settings)を参照してください。

### FIPS準拠のHAProxy {#fips-compliant-haproxy}

[HAProxy Enterprise](https://www.haproxy.com/products/haproxy-enterprise-kubernetes-ingress-controller)はFIPSコンプライアンスを提供します。HAProxy Enterpriseにはライセンスが必要です。

HAProxy Enterpriseの詳細については、以下のリンクを参照してください:

- [HAProxy Enterpriseランディングページ](https://www.haproxy.com/products/haproxy-enterprise)
- [HAProxy FIPSコンプライアンスのブログ記事](https://www.haproxy.com/blog/become-fips-compliant-with-haproxy-enterprise-on-red-hat-enterprise-linux-8)
- [認定OpenShiftオペレーター](https://catalog.redhat.com/software/container-stacks/detail/5ec3f9fc110f56bd24f2dd57)
- [プライベートレジストリのイメージを使用する方法](https://github.com/haproxytech/helm-charts/blob/kubernetes-ingress-1.22.0/haproxy/README.md#installing-from-a-private-registry)
- [HAProxy Enterpriseイメージの見つけ方](https://www.haproxy.com/documentation/haproxy-enterprise/getting-started/installation/docker/)
