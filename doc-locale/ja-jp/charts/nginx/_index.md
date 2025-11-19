---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: NGINXの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Ingressコントローラーとして使用される完全なNGINXデプロイを提供します。すべてのKubernetesプロバイダーがNGINX [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)をネイティブにサポートしているわけではありません。互換性を確保してください。

{{< alert type="note" >}}

- GitLab NGINXチャートは、アップストリームのNGINX Helmチャートのフォークです。私たちのフォークで何が変更されたかについて詳しくは、[NGINXフォークへの調整](#adjustments-to-the-nginx-fork)を参照してください。
- 可能な`global.hosts.domain`値は1つだけです。複数のドメインのサポートは、[イシュー3147](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3147)で追跡されています。

{{< /alert >}}

## NGINXの設定 {#configuring-nginx}

設定の詳細については、[NGINXチャートドキュメント](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/nginx-ingress/README.md#configuration)を参照してください。

### グローバル設定 {#global-settings}

いくつかの一般的なグローバル設定をチャート間で共有します。GitLabやレジストリのホスト名など、一般的な設定オプションについては、[グローバルドキュメント](../globals.md)を参照してください。

## グローバル設定を使用したホストの設定 {#configure-hosts-using-the-global-settings}

GitLabサーバーとレジストリサーバーのホスト名は、当社の[グローバル設定](../globals.md)チャートを使用して構成できます。

## GitLab Geo {#gitlab-geo}

2番目のNGINXサブチャートは、GitLab Geoトラフィック用にバンドルされ、事前設定されており、デフォルトのコントローラーと同じ設定をサポートします。このコントローラーは、`nginx-ingress-geo.enabled=true`で有効にできます。

このコントローラーは、受信`X-Forwarded-*`ヘッダーを変更しないように設定されています。Geoトラフィックに別のプロバイダーを使用する場合は、必ず同じようにしてください。

デフォルトのコントローラー値（`nginx-ingress-geo.controller.ingressClassResource.controllerValue`）は`k8s.io/nginx-ingress-geo`に、IngressClass名は`{ReleaseName}-nginx-geo`に設定され、デフォルトのコントローラーとの干渉を回避します。IngressClass名は、`global.geo.ingressClass`でオーバーライドできます。

カスタムヘッダーの処理は、プライマリGeoサイトがセカンダリサイトから転送されたトラフィックを処理するためにのみ必要です。サイトがプライマリにプロモートされようとしている場合、セカンダリでのみ使用する必要があります。

フェイルオーバー中にIngressClassを変更すると、別のコントローラーが受信トラフィックを処理することに注意してください。別のコントローラーには異なるロードバランサーIPが割り当てられているため、DNSの設定に追加の変更が必要になる場合があります。

これは、すべてのGeoサイトでGeo Ingressコントローラーを有効にし、関連付けられたIngressClass（`useGeoClass=true`）を使用するようにデフォルトおよび追加のWebサービスのIngressを設定することで回避できます。

## 注釈値のワードブロックリスト {#annotation-value-word-blocklist}

{{< history >}}

- [GitLab Helmチャート6.6](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2713)で導入されました。

{{< /history >}}

クラスターオペレーターが生成されたNGINX設定をより詳細に制御する必要がある状況では、NGINX Ingressは、標準の注釈とConfigMapエントリで対応されていないraw NGINX設定の「スニペット」を挿入する[構成スニペット](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)を許可します。

これらの設定スニペットの欠点は、クラスターオペレーターが、GitLabインストールのセキュリティとクラスター自体を損なう可能性のあるLUAスクリプトや同様の設定を含むIngressオブジェクトをデプロイできることです。これには、サービスアカウントトークンとシークレットの公開が含まれます。

詳細については、[CVE-2021-25742](https://nvd.nist.gov/vuln/detail/CVE-2021-25742)および[このアップストリーム`ingress-nginx`イシュー](https://github.com/kubernetes/ingress-nginx/issues/7837)を参照してください。

GitLabのHelmチャートデプロイにおけるCVE-2021-25742を軽減するために、[`nginx-ingress`コミュニティによる推奨設定](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#annotation-value-word-blocklist)を使用して、[annotation-value-word-blocklist](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/v6.6.0/values.yaml#L836)を設定しています。

GitLab Ingress設定で設定スニペットを使用している場合、またはサードパーティのIngressオブジェクトでGitLab NGINX Ingressコントローラーを使用している場合は、GitLabサードパーティドメインにアクセスしようとすると`404`エラーが発生し、`nginx-controller`ログに「無効な単語」エラーが発生する可能性があります。その場合は、`nginx-ingress.controller.config.annotation-value-word-blocklist`設定を確認して調整してください。

[`nginx-controller`ログの「Invalid Word」エラーとチャートのトラブルシューティングドキュメントの`404`エラー](../../troubleshooting/_index.md#invalid-word-errors-in-the-nginx-controller-logs-and-404-errors)も参照してください。

## NGINXフォークへの調整 {#adjustments-to-the-nginx-fork}

{{< alert type="note" >}}

NGINXチャートの[フォーク](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/nginx-ingress)は、[GitHub](https://github.com/kubernetes/ingress-nginx)からプルされました。

{{< /alert >}}

次の調整がNGINXフォークに加えられました:

- SSH用のGitLab Shellを公開するために、外部TCP ConfigMapをサポートします。
- HPAやPDB値など、グローバルチャート設定をサポートするためのさまざまな変更。
- アップグレード時に中断しないように、新しいセレクターラベルを使用しないでください。
- 統合されたURLを持つGitLab Geoセットアップに必要な、いくつかの設定をテンプレート化するためのさまざまな変更。

フォークに適用されたすべてのパッチについて、[ソースディレクトリ](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/scripts/nginx-patches)を確認してください。
