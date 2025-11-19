---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのコンポーネント間でTLSを使用する
---

GitLabチャートは、さまざまなコンポーネント間でトランスポートレイヤーセキュリティ（TLS）を使用できます。これには、有効にするサービス用の証明書を提供し、それらの証明書と、それらに署名した認証局（CA）を利用するようにそれらのサービスを設定する必要があります。

## 準備 {#preparation}

各チャートには、そのサービスのTLSを有効にすることに関するドキュメントと、適切な設定を保証するために必要なさまざまな設定があります。

### 内部使用向けの証明書の生成 {#generating-certificates-for-internal-use}

{{< alert type="note" >}}

GitLabは、高度なPKIインフラストラクチャまたは認証局を提供することを目的としていません。

{{< /alert >}}

このドキュメントでは、**Proof of Concept**（概念実証）スクリプトを以下に示します。これは、[CloudflareのCFSSL](https://github.com/cloudflare/cfssl/)を利用して、自己署名認証局と、すべてのサービスに使用できるワイルドカード証明書を生成するものです。

このスクリプト:

- CAキーペアを生成します。
- すべてのGitLabコンポーネントサービスのエンドポイントに対応するように設計された証明書に署名します。
- 2つのKubernetesシークレットオブジェクトを作成します:
  - サーバー証明書とキーペアを持つ、`kuberetes.io/tls`タイプのシークレット。
  - `Opaque`タイプのシークレット。CAの公開証明書**のみ**を`ca.crt`として含み、NGINX Ingressで必要とされます。

前提要件: 

- Bash、または互換性のあるシェル。
- `cfssl`がシェルで使用可能で、`PATH`内にあります。
- `kubectl`が利用可能であり、GitLabを以降にインストールするKubernetesクラスターを指すように設定されています。
  - スクリプトを操作する前に、これらの証明書をインストールするネームスペースを作成していることを確認してください。

このスクリプトのコンテンツをコンピューターにコピーして、結果のファイルを実行可能にすることができます。`poc-gitlab-internal-tls.sh`をお勧めします。

```shell
#!/bin/bash
set -e
#############
## make and change into a working directory
pushd $(mktemp -d)

#############
## setup environment
NAMESPACE=${NAMESPACE:-default}
RELEASE=${RELEASE:-gitlab}
## stop if variable is unset beyond this point
set -u
## known expected patterns for SAN
CERT_SANS="*.${NAMESPACE}.svc,${RELEASE}-metrics.${NAMESPACE}.svc,*.${RELEASE}-gitaly.${NAMESPACE}.svc"

#############
## generate default CA config
cfssl print-defaults config > ca-config.json
## generate a CA
echo '{"CN":"'${RELEASE}.${NAMESPACE}.internal.ca'","key":{"algo":"ecdsa","size":256}}' | \
  cfssl gencert -initca - | \
  cfssljson -bare ca -
## generate certificate
echo '{"CN":"'${RELEASE}.${NAMESPACE}.internal'","key":{"algo":"ecdsa","size":256}}' | \
  cfssl gencert -config=ca-config.json -ca=ca.pem -ca-key=ca-key.pem -profile www -hostname="${CERT_SANS}" - |\
  cfssljson -bare ${RELEASE}-services

#############
## load certificates into K8s
kubectl -n ${NAMESPACE} create secret tls ${RELEASE}-internal-tls \
  --cert=${RELEASE}-services.pem \
  --key=${RELEASE}-services-key.pem
kubectl -n ${NAMESPACE} create secret generic ${RELEASE}-internal-tls-ca \
  --from-file=ca.crt=ca.pem
```

{{< alert type="note" >}}

このスクリプトは、CAの秘密キーを保持_しません_。これは概念実証ヘルパーであり、_本番環境での使用は意図されていません_。

{{< /alert >}}

スクリプトは、設定される2つの環境変数を想定しています:

1. `NAMESPACE`: GitLabを以降にインストールするKubernetesネームスペース。これは`default`がデフォルトで、`kubectl`と同様です。
1. `RELEASE`: GitLabのインストールに以降使用するHelmリリース名。これは`gitlab`がデフォルトです。

このスクリプトを操作するには、2つの変数を`export`するか、スクリプト名の先頭にそれらの値を付加します。

```shell
export NAMESPACE=testing
export RELEASE=gitlab

./poc-gitlab-internal-tls.sh
```

スクリプトの実行後、作成された2つのシークレットが見つかり、一時的な作業ディレクトリにはすべての証明書とそれらのキーが含まれています。

```plaintext
$ pwd
/tmp/tmp.swyMgf9mDs
$ kubectl -n ${NAMESPACE} get secret | grep internal-tls
testing-internal-tls      kubernetes.io/tls                     2      11s
testing-internal-tls-ca   Opaque                                1      10s
$ ls -1
ca-config.json
ca.csr
ca-key.pem
ca.pem
testing-services.csr
testing-services-key.pem
testing-services.pem
```

#### 必要な証明書のCNとSAN {#required-certificate-cn-and-sans}

さまざまなGitLabコンポーネントは、それらのサービスのDNS名を介してお互いに通信します。GitLabチャートによって生成されたIngressオブジェクトは、`tls.verify: true`（デフォルト）の場合、検証する名前をNGINXに提供する必要があります。この結果、各GitLabコンポーネントは、サービスのDNS名、またはKubernetesサービスのDNSエントリに受け入れ可能なワイルドカードを含むSANを持つ証明書を受信する必要があります。

- `service-name.namespace.svc`
- `*.namespace.svc`

証明書内でこれらのSANを確保できないと、機能しないインスタンスになり、「接続の失敗」または「SSL検証に失敗しました」という非常に不可解なログが_生成されます_。

必要に応じて、`helm template`を使用して、すべてのサービスオブジェクト名の完全なリストを取得することができます。GitLabがTLSなしでデプロイされている場合は、Kubernetesにそれらの名前をクエリできます:

`kubectl -n ${NAMESPACE} get service -lrelease=${RELEASE}`

## 設定 {#configuration}

[examples/internal-tls](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/internal-tls/)に設定例があります。

このドキュメントでは、上記のスクリプトで生成された証明書を消費するようにGitLabコンポーネントを設定する`shared-cert-values.yaml`を、[内部使用向けの証明書の生成](#generating-certificates-for-internal-use)で提供しました。

設定するキー項目:

1. グローバル[カスタム認証局](../../charts/globals.md#custom-certificate-authorities)。
1. サービスリスナーごとのTLS。（[charts/](../../charts/_index.md)の各チャートのドキュメントを参照してください）

このプロセスは、YAMLのネイティブアンカー機能を使用することで大幅に簡素化されます。`shared-cert-values.yaml`の切り詰めるされたスニペットは、これを示しています:

```yaml
.internal-ca: &internal-ca gitlab-internal-tls-ca
.internal-tls: &internal-tls gitlab-internal-tls

global:
  certificates:
    customCAs:
    - secret: *internal-ca
  workhorse:
    tls:
      enabled: true
gitlab:
  webservice:
    tls:
      secretName: *internal-tls
    workhorse:
       tls:
          verify: true # default
          secretName: *internal-tls
          caSecretName: *internal-ca
```

## 結果 {#result}

すべてのコンポーネントがサービスのリスナーでTLSを提供するように設定されている場合、NGINX Ingressから各GitLabコンポーネントへの接続を含め、GitLabコンポーネント間のすべての通信はTLSセキュリティでネットワークをトラフィックします。

NGINX Ingressは、_受信_TLSを終了し、トラフィックを渡す適切なサービスを決定し、GitLabコンポーネントへの新しいTLS接続を確立します。ここに示されているように設定すると、CAに対してGitLabコンポーネントによって提供される証明書も_検証_します。

これは、Toolboxポッドに接続し、さまざまなコンポーネントサービスにクエリすることで検証できます。そのような例の1つとして、NGINX Ingressが使用するWebserviceポッドのプライマリサービスポートへの接続があります:

```plaintext
$ kubectl -n ${NAMESPACE} get pod -lapp=toolbox,release=${RELEASE}
NAME                              READY   STATUS    RESTARTS   AGE
gitlab-toolbox-5c447bfdb4-pfmpc   1/1     Running   0          65m
$ kubectl exec -ti gitlab-toolbox-5c447bfdb4-pfmpc -c toolbox -- \
    curl -Iv "https://gitlab-webservice-default.testing.svc:8181"
```

出力は、次の例のようになります:

```plaintext
*   Trying 10.60.0.237:8181...
* Connected to gitlab-webservice-default.testing.svc (10.60.0.237) port 8181 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
* ALPN, server did not agree to a protocol
* Server certificate:
*  subject: CN=gitlab.testing.internal
*  start date: Jul 18 19:15:00 2022 GMT
*  expire date: Jul 18 19:15:00 2023 GMT
*  subjectAltName: host "gitlab-webservice-default.testing.svc" matched cert's "*.testing.svc"
*  issuer: CN=gitlab.testing.internal.ca
*  SSL certificate verify ok.
> HEAD / HTTP/1.1
> Host: gitlab-webservice-default.testing.svc:8181
```

## トラブルシューティング {#troubleshooting}

GitLabインスタンスがブラウザからアクセスできないように見える場合、HTTP 503エラーをレンダリングすると、NGINX IngressがGitLabコンポーネントの証明書の検証に問題がある可能性があります。

これを回避するには、一時的に`gitlab.webservice.workhorse.tls.verify`を`false`に設定します。

NGINX Ingressコントローラーに接続でき、証明書の検証に関する問題について、`nginx.conf`にメッセージが表示されます。

シークレットに到達できない場合のコンテンツ例:

```plaintext
# Location denied. Reason: "error obtaining certificate: local SSL certificate
  testing/gitlab-internal-tls-ca was not found"
return 503;
```

これが発生する一般的な問題:

- CA証明書が、シークレット内の`ca.crt`という名前のキーにありません。
- シークレットが適切に提供されていないか、ネームスペース内に存在しない可能性があります。
