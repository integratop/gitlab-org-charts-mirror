---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのTLSを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このチャートは、NGINX Ingressコントローラーを使用してTLS終了を実行できます。デプロイメントのTLS証明書を取得する方法を選択できます。詳細については、[グローバルIngress設定](../charts/globals.md#configure-ingress-settings)を参照してください。

## オプション1: cert-managerとLet's Encrypt {#option-1-cert-manager-and-lets-encrypt}

Let's Encryptは、無料で自動化されたオープンCAです。証明書は、さまざまなツールを使用して自動的にリクエストできます。このチャートには、一般的な選択肢である[cert-manager](https://github.com/cert-manager/cert-manager)と統合する準備ができています。

*すでにcert-managerを使用している場合*は、`global.ingress.annotations`を使用して、cert-managerデプロイメントに[適切な注釈](https://cert-manager.io/docs/usage/ingress/#supported-annotations)を設定できます。

*クラスターにcert-managerがまだインストールされていない場合*は、このチャートの依存関係としてインストールして構成できます。

### 内部cert-managerとIssuer {#internal-cert-manager-and-issuer}

```shell
helm repo update
helm dep update
helm install gitlab gitlab/gitlab \
  --set certmanager-issuer.email=you@example.com
```

`cert-manager`のインストールは`installCertmanager`設定で制御され、チャートでの使用は`global.ingress.configureCertmanager`設定で制御されます。これらは両方とも`true`がデフォルトであるため、 メールのみデフォルトで指定する必要があります。

### 外部cert-managerと内部Issuer {#external-cert-manager-and-internal-issuer}

外部の`cert-manager`を使用できますが、このチャートの一部としてを提供します。

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set certmanager-issuer.email=you@example.com \
  --set global.ingress.annotations."kubernetes\.io/tls-acme"=true
```

### 外部cert-managerとIssuer（外部） {#external-cert-manager-and-issuer-external}

外部`cert-manager`および`Issuer`リソースを使用するには、いくつかの項目を指定して、自己署名証明書がアクティブにならないようにする必要があります。

1. 外部`cert-manager`をアクティブにするための注釈（詳細については、[ドキュメント](https://cert-manager.io/docs/usage/ingress/#supported-annotations)を参照してください）
1. 各サービスのTLSシークレットの名前（これにより、[自己署名動作](#option-4-use-auto-generated-self-signed-wildcard-certificate)が無効になります）

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.annotations."kubernetes\.io/tls-acme"=true \
  --set gitlab.webservice.ingress.tls.secretName=RELEASE-gitlab-tls \
  --set registry.ingress.tls.secretName=RELEASE-registry-tls \
  --set minio.ingress.tls.secretName=RELEASE-minio-tls \
  --set gitlab.kas.ingress.tls.secretName=RELEASE-kas-tls
```

## オプション2: 独自のワイルドカード証明書を使用する {#option-2-use-your-own-wildcard-certificate}

完全な証明書チェーンとキーを`Secret`としてクラスターに追加します。例:

```shell
kubectl create secret tls <tls-secret-name> --cert=<path/to-full-chain.crt> --key=<path/to.key>
```

オプションを含めます

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.tls.secretName=<tls-secret-name>
```

### AWS ACMを使用して証明書を管理する {#use-aws-acm-to-manage-certificates}

AWS ACMを使用してワイルドカード証明書を作成する場合、ACM証明書をダウンロードできないため、シークレット経由で指定することはできません。代わりに、`nginx-ingress.controller.service.annotations`を使用して指定します:

```yaml
nginx-ingress:
  controller:
    service:
      annotations:
        ...
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:{region}:{user id}:certificate/{id}
```

## オプション3: サービスごとに個別の証明書を使用する {#option-3-use-individual-certificate-per-service}

完全な証明書チェーンをシークレットとしてクラスタに追加し、それらのシークレット名を各Ingressに渡します。

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.tls.enabled=true \
  --set gitlab.webservice.ingress.tls.secretName=RELEASE-gitlab-tls \
  --set registry.ingress.tls.secretName=RELEASE-registry-tls \
  --set minio.ingress.tls.secretName=RELEASE-minio-tls \
  --set gitlab.kas.ingress.tls.secretName=RELEASE-kas-tls
```

{{< alert type="note" >}}

GitLabインスタンスを構成して他のサービスと通信する場合、これらのサービスの[証明書チェーンを提供する](../charts/globals.md#custom-certificate-authorities)ことが必要になる場合があります。

{{< /alert >}}

## オプション4: 自動生成された自己署名ワイルドカード証明書を使用する {#option-4-use-auto-generated-self-signed-wildcard-certificate}

これらのチャートは、自動生成された自己署名ワイルドカード証明書を提供する機能も提供します。これは、Let's Encryptがオプションではない環境では役立ちますが、SSLによるセキュリティは依然として必要です。この機能は、[共有シークレット](../charts/shared-secrets.md)ジョブによって提供されます。

{{< alert type="note" >}}

`gitlab-runner`チャートは、自己署名証明書では適切に機能しません。以下に示すように、無効にすることをお勧めします。

{{< /alert >}}

{{< alert type="note" >}}

`--set global.ingres.tls.enabled=false`のように、TLSをグローバルに無効にしている場合、自己署名証明書は生成されません。

{{< /alert >}}

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set gitlab-runner.install=false
```

次に、`shared-secrets`ジョブは、CA証明書、ワイルドカード証明書、および外部からアクセス可能なすべてのサービスで使用するための証明書チェーンを生成します。これらを含むシークレットは、`RELEASE-wildcard-tls`、`RELEASE-wildcard-tls-ca`、および`RELEASE-wildcard-tls-chain`になります。`RELEASE-wildcard-tls-ca`には、デプロイされたGitLabインスタンスにアクセスするユーザーおよびシステムに配布できるパブリックCA証明書が含まれています。`RELEASE-wildcard-tls-chain`には、GitLab Runnerに`gitlab-runner.certsSecretName=RELEASE-wildcard-tls-chain`を介して直接使用できるCA証明書とワイルドカード証明書の両方が含まれています。

## GitLab PagesのTLS要件 {#tls-requirement-for-gitlab-pages}

[TLSをサポートするGitLab Pages](https://docs.gitlab.com/administration/pages/#wildcard-domains-with-tls-support)の場合、`*.<pages domain>`（`<pages domain>`のデフォルト値は`pages.<base domain>`）に適用可能なワイルドカード証明書が必要です。

ワイルドカード証明書が必要なため、cert-managerとLet's Encryptによって自動的に作成することはできません。そのため、cert-managerはGitLab Pages（`gitlab-pages.ingress.configureCertmanager`経由）ではデフォルトで無効になっているため、ワイルドカード証明書を含む独自のk8sシークレットを提供する必要があります。`global.ingress.annotations`を使用して構成された外部cert-managerがある場合は、`gitlab-pages.ingress.annotations`でそのような注釈をオーバーライドすることもできます。

デフォルトでは、このシークレットの名前は`<RELEASE>-pages-tls`です。`gitlab.gitlab-pages.ingress.tls.secretName`設定を使用して、別の名前を指定できます:

```shell
helm install gitlab gitlab/gitlab \
  --set global.pages.enabled=true \
  --set gitlab.gitlab-pages.ingress.tls.secretName=<secret name>
```

## トラブルシューティング {#troubleshooting}

このセクションでは、発生する可能性のある問題の考えられる解決策について説明します。

### SSL終了エラー {#ssl-termination-errors}

TLSプロバイダーとしてLet's Encryptを使用しているときに、証明書関連のエラーが発生した場合は、これをデバッグするためのオプションがいくつかあります:

1. 考えられるエラーについて、[letsdebug](https://letsdebug.net/)でドメインを確認してください。
1. letsdebugがエラーを返さない場合は、cert-managerに関連する問題があるかどうかを確認してください:

   ```shell
   kubectl describe certificate,order,challenge --all-namespaces
   ```

   エラーが表示された場合は、証明書オブジェクトを削除して、新しい証明書のリクエストを強制的にリクエストしてみてください。

1. 上記の方法で解決しない場合は、[既存のcert-managerリソース](https://cert-manager.io/docs/installation/kubectl/#uninstalling)を削除して、cert-managerを再インストールすることを検討してください。内部cert-managerを使用している場合は、名前に`certmanager`が含まれるデプロイメントを削除し、Helm Chartを再インストールします。たとえば、`gitlab`という名前のリリースを想定します:

   ```shell
   kubectl -n <namespace> delete deployment gitlab-certmanager gitlab-certmanager-cainjector gitlab-certmanager-webhook
   helm upgrade --install -n <namespace> gitlab gitlab/gitlab
   ```
