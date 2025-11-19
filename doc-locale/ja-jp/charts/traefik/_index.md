---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#designated-technical-writers
title: Traefikの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Traefik Helmチャート](https://artifacthub.io/packages/helm/traefik/traefik)は、Ingressコントローラーとして[バンドルされたNGINX Helmチャート](../nginx/_index.md)を置き換えることができます。

Traefikは、ネイティブKubernetes Ingressオブジェクトを[IngressRoute](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute)オブジェクトに[変換](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)します。

Traefikは、[IngressRouteTCP](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroutetcp)オブジェクトを介してSSH経由でのGitもサポートしています。これは、[`global.ingress.provider`](../globals.md#configure-ingress-settings)が`traefik`として構成されている場合、GitLab Shellチャートによってデプロイされます。

## Traefikの設定 {#configuring-traefik}

設定の詳細については、[Traefik Helmチャートドキュメント](https://github.com/traefik/traefik-helm-chart/tree/master/traefik)を参照してください。

GitLab Helmチャートでテストされた値の詳細なYAMLについては、[Traefikの設定例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-traefik-ingress.yaml)を参照してください。

### グローバル設定 {#global-settings}

いくつかの一般的なグローバル設定をチャート間で共有します。GitLabやレジストリのホスト名など、一般的な設定オプションについては、[グローバルIngressドキュメント](../globals.md#configure-ingress-settings)を参照してください。

### FIPS準拠のTraefik {#fips-compliant-traefik}

[Traefik Enterprise](https://doc.traefik.io/traefik-enterprise/)はFIPSコンプライアンスを提供します。Traefik Enterpriseにはライセンスが必要ですが、このチャートには含まれていません。

Traefik Enterpriseの詳細については、以下のリンクを参照してください:

- [Traefik Enterpriseの機能](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
- [Traefik Enterprise FIPSイメージ](https://doc.traefik.io/traefik-enterprise/operations/fips-image/)
- [Traefik Enterprise Helmチャート](https://doc.traefik.io/traefik-enterprise/installing/kubernetes/helm/)
- [ArtifactHub上のTraefik Enterprise Operator](https://artifacthub.io/packages/olm/community-operators/traefikee-operator)
- [RedHat Catalog上のTraefik Enterprise Certified OpenShift Operator](https://catalog.redhat.com/software/container-stacks/detail/5e98745a6c5dcb34dfbb1a0a)
