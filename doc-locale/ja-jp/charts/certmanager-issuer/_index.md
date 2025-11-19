---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CertManager Issuerの作成にcertmanager-issuerを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このチャートは、[JetstackのCertManager](https://cert-manager.io/docs/installation/helm/)のヘルパーです。GitLab IngressesのTLS証明書をリクエストする際にCertManagerが使用するIssuerオブジェクトを自動的にプロビジョニングします。

## 設定 {#configuration}

以下に、設定の主要なセクションをすべて説明します。親チャートから設定する場合、これらの値は次のようになります:

```yaml
certmanager-issuer:
  # Configure an ACME Issuer in cert-manager. Only used if global.ingress.configureCertmanager is true.
  server: https://acme-v02.api.letsencrypt.org/directory

  # Provide an email to associate with your TLS certificates
  # email:

  rbac:
    create: true

  resources:
    requests:
      cpu: 50m

  # Priority class assigned to pods
  priorityClassName: ""

  common:
    labels: {}
```

## インストールパラメータ {#installation-parameters}

この表には、`helm install`コマンドに`--set`フラグを使用して指定できる、考えられるすべてのチャートの設定が含まれています:

| パラメータ                                           | デフォルト                                          | 説明 |
|-----------------------------------------------------|--------------------------------------------------|-------------|
| `server`                                            | `https://acme-v02.api.letsencrypt.org/directory` | [ACME CertManager Issuer](https://cert-manager.io/docs/configuration/acme/)で使用するLet's Encryptサーバー。 |
| `email`                                             |                                                  | TLS証明書に関連付けるメールアドレスを提供する必要があります。Let's Encryptは、このアドレスを使用して、証明書の有効期限切れやアカウントに関連するイシューについて連絡します。 |
| `rbac.create`                                       | `true`                                           | `true`の場合、CertManager Issuerオブジェクトの操作を許可するために、RBAC関連のリソースを作成します。 |
| `resources.requests.cpu`                            | `50m`                                            | Issuer作成ジョブにリクエストされたCPUリソース。 |
| `common.labels`                                     |                                                  | ServiceAccount、ジョブ、ConfigMap、およびIssuerに適用する共通ラベル。 |
| `priorityClassName`                                 |                                                  | ポッドに割り当てられた[優先クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `containerSecurityContext`                          |                                                  | Certmanagerの起動元のコンテナの[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                | `65534`                                          | コンテナの起動に使用するユーザーID |
| `containerSecurityContext.runAsGroup`               | `65534`                                          | コンテナの起動に使用するグループID |
| `containerSecurityContext.allowPrivilegeEscalation` | `false`                                          | プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`             | `true`                                           | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                      | コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `ttlSecondsAfterFinished`                           | `1800`                                           | 完了したジョブがカスケード削除の対象となる時期を制御します。 |
