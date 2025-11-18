---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Helmのデプロイオプション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、一般的に使用されるGitLabチャートの値を一覧表示します。使用可能なオプションの完全なリストについては、各サブチャートのドキュメントを参照してください。

YAMLファイルと`--values <values file>`フラグを使用するか、複数の`--set`フラグを使用して、値を`helm install`コマンドに渡すことができます。リリースに必要なオーバーライドのみを含むvaluesファイルを使用することをお勧めします。

デフォルトの`values.yaml`ファイルのソースについては、[GitLabチャートリポジトリ](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/values.yaml)を参照してください。これらのコンテンツはリリースによって変更されますが、Helm自体を使用して、バージョンごとにこれら取得できます:

```shell
helm inspect values gitlab/gitlab
```

## 基本設定 {#basic-configuration}

| パラメータ                                            | デフォルト                                       | 説明 |
|------------------------------------------------------|-----------------------------------------------|-------------|
| `gitlab.migrations.initialRootPassword.key`          | `password`                                    | 移行シークレット内のルートアカウントパスワードを指すキー |
| `gitlab.migrations.initialRootPassword.secret`       | `{Release.Name}-gitlab-initial-root-password` | ルートアカウントパスワードを含むシークレットのグローバル名 |
| `global.gitlab.license.key`                          | `license`                                     | ライセンスシークレット内のエンタープライズライセンスを指すキー |
| `global.gitlab.license.secret`                       | _なし_                                        | エンタープライズライセンスを含むシークレットのグローバル名 |
| `global.application.create`                          | `false`                                       | GitLabの[Applicationリソース](https://github.com/kubernetes-sigs/application)を作成します |
| `global.edition`                                     | `ee`                                          | インストールするGitLabのエディション。Enterprise Edition（`ee`）かCommunity Edition（`ce`）か。 |
| `global.gitaly.enabled`                              | `true`                                        | Gitalyの有効フラグ |
| `global.hosts.domain`                                | 必須                                      | すべての公開サービスに使用されるドメイン名 |
| `global.hosts.externalIP`                            | 必須                                      | NGINX Ingressコントローラーに割り当てる静的IP |
| `global.hosts.ssh`                                   | `gitlab.{global.hosts.domain}`                | Git SSHアクセスに使用されるドメイン名 |
| `global.imagePullPolicy`                             | `IfNotPresent`                                | 非推奨: 代わりに`global.image.pullPolicy`を使用してください。 |
| `global.image.pullPolicy`                            | _なし_（デフォルトの動作は`IfNotPresent`です）   | すべてのチャートに対してデフォルトのimagePullPolicyを設定します |
| `global.image.pullSecrets`                           | _なし_                                        | すべてのチャートに対してデフォルトのimagePullSecretsを設定します（`name`と値のペアのリストを使用） |
| `global.minio.enabled`                               | `true`                                        | MinIOの有効フラグ |
| `global.psql.host`                                   | _インクラスタの非本番環境PostgreSQLを使用_   | サブチャートのpsql設定をオーバーライドする、外部psqlのグローバルホスト名 |
| `global.psql.password.key`                           | _インクラスタの非本番環境PostgreSQLを使用_   | psqlシークレット内のpsqlパスワードを指すキー |
| `global.psql.password.secret`                        | _インクラスタの非本番環境PostgreSQLを使用_   | psqlパスワードを含むシークレットのグローバル名 |
| `global.registry.bucket`                             | `registry`                                    | レジストリのバケット名 |
| `global.service.annotations`                         | `{}`                                          | すべての`Service`に追加する注釈 |
| `global.rails.sessionStore.sessionCookieTokenPrefix` | `""`                                          | 生成されたセッションクッキーのプレフィックス |
| `global.deployment.annotations`                      | `{}`                                          | すべての`Deployment`に追加する注釈 |
| `global.time_zone`                                   | UTC                                           | グローバルタイムゾーン |

## TLSの {#tls-configuration}

| パラメータ                                           | デフォルト | 説明 |
|-----------------------------------------------------|---------|-------------|
| `certmanager-issuer.email`                          | `false` | Let's Encryptアカウントのメール |
| `gitlab.webservice.ingress.tls.secretName`          | _なし_  | GitLabのTLS証明書とキーを含む既存の`Secret` |
| `gitlab.webservice.ingress.tls.smartcardSecretName` | _なし_  | GitLabスマートカード認証ドメインのTLS証明書とキーを含む既存の`Secret` |
| `global.hosts.https`                                | `true`  | https経由でサービスを提供する |
| `global.ingress.configureCertmanager`               | `true`  | Let's Encryptから証明書を取得するようにcert-managerを設定する |
| `global.ingress.tls.secretName`                     | _なし_  | ワイルドカードTLS証明書とキーを含む既存の`Secret` |
| `minio.ingress.tls.secretName`                      | _なし_  | MinIOのTLS証明書とキーを含む既存の`Secret` |
| `registry.ingress.tls.secretName`                   | _なし_  | レジストリのTLS証明書とキーを含む既存の`Secret` |

## 送信メールの設定 {#outgoing-email-configuration}

| パラメータ                         | デフォルト               | 説明 |
|-----------------------------------|-----------------------|-------------|
| `global.email.display_name`       | `GitLab`              | GitLabから送信されるメールの送信者として表示される名前 |
| `global.email.from`               | `gitlab@example.com`  | GitLabから送信されるメールの送信者として表示されるメールアドレス |
| `global.email.reply_to`           | `noreply@example.com` | GitLabから送信されるメールにリストされている返信先メール |
| `global.email.smime.certName`     | `tls.crt`             | S/MIME証明書ファイルの場所を特定するためのシークレットオブジェクトキー値 |
| `global.email.smime.enabled`      | `false`               | 送信メールにS/MIME署名を追加する |
| `global.email.smime.keyName`      | `tls.key`             | S/MIMEキーファイルの場所を特定するためのシークレットオブジェクトキー値 |
| `global.email.smime.secretName`   | `""`                  | X.509証明書を検索するKubernetesシークレットオブジェクト（作成用の[S/MIME証明書](secrets.md#smime-certificate)） |
| `global.email.subject_suffix`     | `""`                  | GitLabから送信されるすべてのメールの件名のサフィックス |
| `global.smtp.address`             | `smtp.mailgun.org`    | リモートメールサーバーのホスト名またはIP |
| `global.smtp.authentication`      | `plain`               | SMTP認証のタイプ（「plain」、「login」、「cram_md5」、または認証なしの場合は「」） |
| `global.smtp.domain`              | `""`                  | SMTPのオプションのHELOドメイン |
| `global.smtp.enabled`             | `false`               | 送信メールを有効にする |
| `global.smtp.openssl_verify_mode` | `peer`                | TLS検証モード（「none」、「peer」、「client_once」、または「fail_if_no_peer_cert」） |
| `global.smtp.password.key`        | `password`            | `global.smtp.password.secret`に含まれるSMTPパスワードのキー |
| `global.smtp.password.secret`     | `""`                  | SMTPパスワードを含む`Secret`の名前 |
| `global.smtp.port`                | `2525`                | SMTPのポート |
| `global.smtp.starttls_auto`       | `false`               | メールサーバーで有効になっている場合はSTARTTLSを使用する |
| `global.smtp.tls`                 | _なし_                | SMTP/TLSを有効にします（SMTPS: ダイレクトTLS接続経由のSMTP） |
| `global.smtp.user_name`           | `""`                  | SMTP認証httpsのユーザー名 |
| `global.smtp.open_timeout`        | `30`                  | 接続を開こうとしている間の待機時間（秒）。 |
| `global.smtp.read_timeout`        | `60`                  | 1つのブロックの読み取り中に待機する秒数。 |
| `global.smtp.pool`                | `false`               | SMTP接続プールを有効にする |

### Microsoft Graph Mailer設定 {#microsoft-graph-mailer-settings}

| パラメータ                                                      | デフォルト                             | 説明 |
|----------------------------------------------------------------|-------------------------------------|-------------|
| `global.appConfig.microsoft_graph_mailer.enabled`              | `false`                             | Microsoft Graph API経由で送信メールを有効にする |
| `global.appConfig.microsoft_graph_mailer.user_id`              | `""`                                | Microsoft Graph APIを使用するユーザーの固有識別子 |
| `global.appConfig.microsoft_graph_mailer.tenant`               | `""`                                | アプリケーションが対象とするディレクトリテナント。GUIDまたはドメイン名形式 |
| `global.appConfig.microsoft_graph_mailer.client_id`            | `""`                                | アプリに割り当てられているアプリケーションID。この情報は、アプリを登録したポータルにあります |
| `global.appConfig.microsoft_graph_mailer.client_secret.key`    | `secret`                            | アプリ登録ポータルでアプリ用に生成したクライアントのシークレットキーを含む`global.appConfig.microsoft_graph_mailer.client_secret.secret`のキー |
| `global.appConfig.microsoft_graph_mailer.client_secret.secret` | `""`                                | アプリ登録ポータルでアプリ用に生成したクライアントのシークレットキーを含む`Secret`の名前 |
| `global.appConfig.microsoft_graph_mailer.azure_ad_endpoint`    | `https://login.microsoftonline.com` | Azure Active DirectoryエンドポイントのURL |
| `global.appConfig.microsoft_graph_mailer.graph_endpoint`       | `https://graph.microsoft.com`       | Microsoft GraphエンドポイントのURL |

## 受信メールの設定 {#incoming-email-configuration}

### 共通設定 {#common-settings}

詳細については、[受信メールの設定例のドキュメント](https://docs.gitlab.com/administration/incoming_email/#configuration-examples)を参照してください。

| パラメータ                                            | デフォルト                                    | 説明 |
|------------------------------------------------------|--------------------------------------------|-------------|
| `global.appConfig.incomingEmail.address`             | 空                                      | 返信されるアイテムを参照するメールアドレス（例: `gitlab-incoming+%{key}@gmail.com`）。`+%{key}`サフィックスは、メールアドレス全体に含める必要があり、別の値に置き換えないでください。 |
| `global.appConfig.incomingEmail.enabled`             | `false`                                    | 受信メールを有効にする |
| `global.appConfig.incomingEmail.deleteAfterDelivery` | `true`                                     | メッセージを削除済みとしてマークするかどうか。IMAPの場合、`expungedDeleted`が`true`に設定されている場合、削除済みとしてマークされているメッセージは完全に削除されます。Microsoft Graphの場合、削除されたメッセージはしばらくすると自動的に完全に削除されるため、受信トレイにメッセージを保持するには、これをfalseに設定します。 |
| `global.appConfig.incomingEmail.expungeDeleted`      | `false`                                    | 配信後に削除済みとしてマークされたときに、メッセージをメールボックスから完全に削除するかどうか。Microsoft Graphは削除されたメッセージを自動的に完全に削除するため、IMAPにのみ関連します。 |
| `global.appConfig.incomingEmail.logger.logPath`      | `/dev/stdout`                              | JSON構造化ログを書き込むパス。このログを無効にするには、""に設定します |
| `global.appConfig.incomingEmail.inboxMethod`         | `imap`                                     | IMAP（`imap`）またはOAuth2（`microsoft_graph`）を使用したMicrosoft Graph APIでメールを読み取る |
| `global.appConfig.incomingEmail.deliveryMethod`      | `webhook`                                  | Mailroomが処理のためにメールコンテンツをRailsアプリに送信する方法。`sidekiq`または`webhook`のいずれか。 |
| `gitlab.appConfig.incomingEmail.authToken.key`       | `authToken`                                | 受信メールシークレット内の受信メールトークンへのキー。デリバリー方法がWebhookの場合に有効です。 |
| `gitlab.appConfig.incomingEmail.authToken.secret`    | `{Release.Name}-incoming-email-auth-token` | 受信メール認証シークレット。デリバリー方法がWebhookの場合に有効です。 |

### IMAP設定 {#imap-settings}

| パラメータ                                        | デフォルト    | 説明 |
|--------------------------------------------------|------------|-------------|
| `global.appConfig.incomingEmail.host`            | 空      | IMAPのホスト |
| `global.appConfig.incomingEmail.idleTimeout`     | `60`       | IDLEコマンドタイムアウト |
| `global.appConfig.incomingEmail.mailbox`         | `inbox`    | 受信メールの宛先となるメールボックス。 |
| `global.appConfig.incomingEmail.password.key`    | `password` | IMAPパスワードを含む`global.appConfig.incomingEmail.password.secret`のキー |
| `global.appConfig.incomingEmail.password.secret` | 空      | IMAPパスワードを含む`Secret`の名前 |
| `global.appConfig.incomingEmail.port`            | `993`      | IMAPのポート |
| `global.appConfig.incomingEmail.ssl`             | `true`     | IMAPサーバーがSSLを使用するかどうか |
| `global.appConfig.incomingEmail.startTls`        | `false`    | IMAPサーバーがStartTLSを使用するかどうか |
| `global.appConfig.incomingEmail.user`            | 空      | IMAP認証のユーザー名 |

### Microsoft Graph設定 {#microsoft-graph-settings}

| パラメータ                                            | デフォルト | 説明 |
|------------------------------------------------------|---------|-------------|
| `global.appConfig.incomingEmail.tenantId`            | 空   | Microsoft Azure Active DirectoryのテナントID |
| `global.appConfig.incomingEmail.clientId`            | 空   | OAuth2アプリのクライアントID |
| `global.appConfig.incomingEmail.clientSecret.key`    | 空   | OAuth2クライアントのシークレットキーを含む`appConfig.incomingEmail.clientSecret.secret`のキー |
| `global.appConfig.incomingEmail.clientSecret.secret` | シークレット  | OAuth2クライアントのシークレットキーを含む`Secret`の名前 |
| `global.appConfig.incomingEmail.pollInterval`        | `60`    | 新しいメールのポーリングの間隔（秒単位） |
| `global.appConfig.incomingEmail.azureAdEndpoint`     | 空   | Azure Active DirectoryエンドポイントのURL（例: `https://login.microsoftonline.com`） |
| `global.appConfig.incomingEmail.graphEndpoint`       | 空   | Microsoft GraphエンドポイントのURL（例: `https://graph.microsoft.com`） |

[シークレットを作成するための手順](secrets.md)を参照してください。

## サービスデスクのメールの設定 {#service-desk-email-configuration}

サービスデスクの要件として、受信メールを[設定する](#incoming-email-configuration)必要があります。受信メールとサービスデスクのメールアドレスは両方とも、[メールのサブアドレス](https://docs.gitlab.com/administration/incoming_email/#email-sub-addressing)を使用する必要があることに注意してください。各セクションでメールアドレスを設定する場合、ユーザー名に追加されるタグは`+%{key}`である必要があります。

### 共通設定 {#common-settings-1}

| パラメータ                                               | デフォルト                                        | 説明 |
|---------------------------------------------------------|------------------------------------------------|-------------|
| `global.appConfig.serviceDeskEmail.address`             | 空                                          | 返信されるアイテムを参照するメールアドレス（例: `project_contact+%{key}@gmail.com`） |
| `global.appConfig.serviceDeskEmail.enabled`             | `false`                                        | サービスデスクのメールを有効にする |
| `global.appConfig.serviceDeskEmail.deleteAfterDelivery` | `true`                                         | メッセージを削除済みとしてマークするかどうか。IMAPの場合、`expungedDeleted`が`true`に設定されている場合、削除済みとしてマークされているメッセージは完全に削除されます。Microsoft Graphの場合、削除されたメッセージはしばらくすると自動的に完全に削除されるため、受信トレイにメッセージを保持するには、これをfalseに設定します。 |
| `global.appConfig.serviceDeskEmail.expungeDeleted`      | `false`                                        | 配信後に削除済みとしてマークされたときに、メッセージをメールボックスから完全に削除するかどうか。Microsoft Graphは削除されたメッセージを自動的に完全に削除するため、IMAPにのみ関連します。 |
| `global.appConfig.serviceDeskEmail.logger.logPath`      | `/dev/stdout`                                  | JSON構造化ログを書き込むパス。このログを無効にするには、""に設定します |
| `global.appConfig.serviceDeskEmail.inboxMethod`         | `imap`                                         | IMAP（`imap`）またはOAuth2（`microsoft_graph`）を使用したMicrosoft Graph APIでメールを読み取る |
| `global.appConfig.serviceDeskEmail.deliveryMethod`      | `webhook`                                      | Mailroomが処理のためにメールコンテンツをRailsアプリに送信する方法。`sidekiq`または`webhook`のいずれか。 |
| `gitlab.appConfig.serviceDeskEmail.authToken.key`       | `authToken`                                    | サービスデスクメールシークレットのサービスデスクのメールトークンへのキー。デリバリー方法がWebhookの場合に有効です。 |
| `gitlab.appConfig.serviceDeskEmail.authToken.secret`    | `{Release.Name}-service-desk-email-auth-token` | サービスデスクのメール認証シークレット。デリバリー方法がWebhookの場合に有効です。 |

### IMAP設定 {#imap-settings-1}

| パラメータ                                           | デフォルト    | 説明 |
|-----------------------------------------------------|------------|-------------|
| `global.appConfig.serviceDeskEmail.host`            | 空      | IMAPのホスト |
| `global.appConfig.serviceDeskEmail.idleTimeout`     | `60`       | IDLEコマンドタイムアウト |
| `global.appConfig.serviceDeskEmail.mailbox`         | `inbox`    | サービスデスクのメールの宛先となるメールボックス。 |
| `global.appConfig.serviceDeskEmail.password.key`    | `password` | IMAPパスワードを含む`global.appConfig.serviceDeskEmail.password.secret`のキー |
| `global.appConfig.serviceDeskEmail.password.secret` | 空      | IMAPパスワードを含む`Secret`の名前 |
| `global.appConfig.serviceDeskEmail.port`            | `993`      | IMAPのポート |
| `global.appConfig.serviceDeskEmail.ssl`             | `true`     | IMAPサーバーがSSLを使用するかどうか |
| `global.appConfig.serviceDeskEmail.startTls`        | `false`    | IMAPサーバーがStartTLSを使用するかどうか |
| `global.appConfig.serviceDeskEmail.user`            | 空      | IMAP認証のユーザー名 |

### Microsoft Graph設定 {#microsoft-graph-settings-1}

| パラメータ                                               | デフォルト | 説明 |
|---------------------------------------------------------|---------|-------------|
| `global.appConfig.serviceDeskEmail.tenantId`            | 空   | Microsoft Azure Active DirectoryのテナントID |
| `global.appConfig.serviceDeskEmail.clientId`            | 空   | OAuth2アプリのクライアントID |
| `global.appConfig.serviceDeskEmail.clientSecret.key`    | 空   | OAuth2クライアントのシークレットキーを含む`appConfig.serviceDeskEmail.clientSecret.secret`のキー |
| `global.appConfig.serviceDeskEmail.clientSecret.secret` | シークレット  | OAuth2クライアントのシークレットキーを含む`Secret`の名前 |
| `global.appConfig.serviceDeskEmail.pollInterval`        | `60`    | 新しいメールのポーリングの間隔（秒単位） |
| `global.appConfig.serviceDeskEmail.azureAdEndpoint`     | 空   | Azure Active DirectoryエンドポイントのURL（例: `https://login.microsoftonline.com`） |
| `global.appConfig.serviceDeskEmail.graphEndpoint`       | 空   | Microsoft GraphエンドポイントのURL（例: `https://graph.microsoft.com`） |

[シークレットを作成するための手順](secrets.md)を参照してください。

## デフォルトのプロジェクト機能設定 {#default-project-features-configuration}

| パラメータ                                                    | デフォルト | 説明 |
|--------------------------------------------------------------|---------|-------------|
| `global.appConfig.defaultProjectsFeatures.builds`            | `true`  | プロジェクトビルドを有効にする |
| `global.appConfig.defaultProjectsFeatures.containerRegistry` | `true`  | コンテナレジストリプロジェクト機能を有効にする |
| `global.appConfig.defaultProjectsFeatures.issues`            | `true`  | プロジェクトイシューを有効にする |
| `global.appConfig.defaultProjectsFeatures.mergeRequests`     | `true`  | プロジェクトのマージリクエストを有効にする |
| `global.appConfig.defaultProjectsFeatures.snippets`          | `true`  | プロジェクトスニペットを有効にする |
| `global.appConfig.defaultProjectsFeatures.wiki`              | `true`  | プロジェクトWikiを有効にする |

## GitLab Shell {#gitlab-shell}

| パラメータ                        | デフォルト | 説明 |
|----------------------------------|---------|-------------|
| `global.shell.authToken`         |         | 共有シークレットを含むシークレット |
| `global.shell.hostKeys`          |         | SSHホストキーを含むシークレット |
| `global.shell.port`              |         | SSHのIngressで公開するポート番号 |
| `global.shell.tcp.proxyProtocol` | `false` | SSH IngressでProxyProtocolを有効にする |

## RBAC設定 {#rbac-settings}

| パラメータ                              | デフォルト | 説明 |
|----------------------------------------|---------|-------------|
| `certmanager.rbac.create`              | `true`  | RBACリソースを作成して使用する |
| `gitlab-runner.rbac.create`            | `true`  | RBACリソースを作成して使用する |
| `nginx-ingress.rbac.create`            | `false` | デフォルトのRBACリソースを作成して使用する |
| `nginx-ingress.rbac.createClusterRole` | `false` | クラスターロールを作成して使用する |
| `nginx-ingress.rbac.createRole`        | `true`  | 名前空間ロールを作成して使用する |
| `prometheus.rbac.create`               | `true`  | RBACリソースを作成して使用する |

RBACルールを自分で設定するために`nginx-ingress.rbac.create`を`false`に設定している場合は、[チャートのバージョンに応じて](../releases/8_0.md#upgrade-to-86x-851-843-836)特定のRBACルールを追加する必要がある場合があります。

## 高度なNGINX Ingressの設定 {#advanced-nginx-ingress-configuration}

NGINX Ingressの値を`nginx-ingress`でプレフィックスします。たとえば、コントローラーイメージタグを`nginx-ingress.controller.image.tag`を使用して設定します。

[`nginx-ingress`チャート](../charts/nginx/_index.md)を参照してください。

## 高度なインクラスタRedisの設定 {#advanced-in-cluster-redis-configuration}

| パラメータ                 | デフォルト               | 説明 |
|---------------------------|-----------------------|-------------|
| `redis.install`           | `true`                | `bitnami/redis`チャートをインストールします |
| `redis.existingSecret`    | `gitlab-redis-secret` | Redisサーバーが使用するシークレットを指定します |
| `redis.existingSecretKey` | `redis-password`      | パスワードが保存されているシークレットキー |

Redisサービスの追加設定は、[Redisチャート](https://github.com/bitnami/charts/tree/main/bitnami/redis)からの設定設定を使用する必要があります。

## 高度なレジストリの設定 {#advanced-registry-configuration}

| パラメータ                                           | デフォルト                                     | 説明 |
|-----------------------------------------------------|---------------------------------------------|-------------|
| `registry.authEndpoint`                             | デフォルトでは未定義                        | 認証エンドポイント |
| `registry.enabled`                                  | `true`                                      | Dockerレジストリを有効にする |
| `registry.httpSecret`                               |                                             | Httpsシークレット |
| `registry.minio.bucket`                             | `registry`                                  | MinIOレジストリバケット名 |
| `registry.service.annotations`                      | `{}`                                        | `Service`に追加する注釈 |
| `registry.securityContext.fsGroup`                  | `1000`                                      | ポッドを開始するグループID |
| `registry.securityContext.runAsUser`                | `1000`                                      | ポッドを開始するユーザーID |
| `registry.tokenIssuer`                              | `gitlab-issuer`                             | JWTトークン発行者 |
| `registry.tokenService`                             | `container_registry`                        | JWTトークンサービス |
| `registry.profiling.stackdriver.enabled`            | `false`                                     | Stackdriverを使用した継続的なプロファイリングを有効にする |
| `registry.profiling.stackdriver.credentials.secret` | `gitlab-registry-profiling-creds`           | 認証情報を含むシークレットの名前 |
| `registry.profiling.stackdriver.credentials.key`    | `credentials`                               | 認証情報が保存されているシークレットキー |
| `registry.profiling.stackdriver.service`            | `RELEASE-registry`（テンプレート化されたサービス名） | プロファイルを記録するStackdriverサービスの名前 |
| `registry.profiling.stackdriver.projectid`          | 実行中のGCPプロジェクト                   | プロファイルをレポートするGCPプロジェクト |

## MinIOの高度な設定 {#advanced-minio-configuration}

| パラメータ                            | デフォルト                        | 説明 |
|--------------------------------------|--------------------------------|-------------|
| `minio.defaultBuckets`               | `[{"name": "registry"}]`       | MinIOのデフォルトのバケット |
| `minio.image`                        | `minio/minio`                  | MinIODockerイメージ |
| `minio.imagePullPolicy`              |                                | MinIODockerイメージのプルポリシー |
| `minio.imageTag`                     | `RELEASE.2017-12-28T01-21-00Z` | MinIODockerイメージのタグ |
| `minio.minioConfig.browser`          | `on`                           | MinIOブラウザフラグ |
| `minio.minioConfig.domain`           |                                | MinIOドメイン |
| `minio.minioConfig.region`           | `us-east-1`                    | MinIOリージョン |
| `minio.mountPath`                    | `/export`                      | MinIO設定ファイルのマウントパス |
| `minio.persistence.accessMode`       | `ReadWriteOnce`                | MinIO永続アクセスモード |
| `minio.persistence.enabled`          | `true`                         | MinIOの永続化を有効にするフラグ |
| `minio.persistence.matchExpressions` |                                | バインドするMinIOラベル式の一致 |
| `minio.persistence.matchLabels`      |                                | バインドするMinIOラベル値の一致 |
| `minio.persistence.size`             | `10Gi`                         | MinIO永続ボリュームサイズ |
| `minio.persistence.storageClass`     |                                | プロビジョニングのMinIOストレージクラス名 |
| `minio.persistence.subPath`          |                                | MinIO永続ボリュームのマウントパス |
| `minio.persistence.volumeName`       |                                | MinIOの既存の永続ボリューム名 |
| `minio.resources.requests.cpu`       | `250m`                         | リクエストされたMinIOの最小CPU |
| `minio.resources.requests.memory`    | `256Mi`                        | リクエストされたMinIOの最小メモリ |
| `minio.service.annotations`          | `{}`                           | `Service`に追加する注釈 |
| `minio.servicePort`                  | `9000`                         | MinIOサービスのポート |
| `minio.serviceType`                  | `ClusterIP`                    | MinIOサービスタイプ |

## GitLabの高度な設定 {#advanced-gitlab-configuration}

| パラメータ                                                  | デフォルト                                                         | 説明 |
|------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `gitlab-runner.checkInterval`                              | `30s`                                                           | ポーリングの間隔 |
| `gitlab-runner.concurrent`                                 | `20`                                                            | 並行ジョブ数 |
| `gitlab-runner.imagePullPolicy`                            | `IfNotPresent`                                                  | Dockerイメージのプルポリシー |
| `gitlab-runner.image`                                      | `gitlab/gitlab-runner:alpine-v10.5.0`                           | RunnerDockerイメージ |
| `gitlab-runner.gitlabUrl`                                  | GitLabの外部URL                                             | RunnerがGitLabサーバーへの登録に使用するURL |
| `gitlab-runner.install`                                    | `true`                                                          | `gitlab-runner`チャートをインストールする |
| `gitlab-runner.rbac.clusterWideAccess`                     | `false`                                                         | ジョブのコンテナをクラスタリング全体にデプロイする |
| `gitlab-runner.rbac.create`                                | `true`                                                          | RBACサービスアカウントを作成するかどうか |
| `gitlab-runner.rbac.serviceAccountName`                    | `default`                                                       | 作成するRBACサービスアカウントの名前 |
| `gitlab-runner.resources.limits.cpu`                       |                                                                 | Runnerのリソース |
| `gitlab-runner.resources.limits.memory`                    |                                                                 | Runnerのリソース |
| `gitlab-runner.resources.requests.cpu`                     |                                                                 | Runnerのリソース |
| `gitlab-runner.resources.requests.memory`                  |                                                                 | Runnerのリソース |
| `gitlab-runner.runners.privileged`                         | `false`                                                         | 特権モードで実行。dindに必要`dind` |
| `gitlab-runner.runners.cache.secretName`                   | `gitlab-minio`                                                  | `accesskey`と`secretkey`を取得するためのシークレット |
| `gitlab-runner.runners.config`                             | [チャートドキュメント](../charts/gitlab/gitlab-runner/_index.md#default-runner-configuration)を参照してください | 文字列としてのRunner設定 |
| `gitlab-runner.unregisterRunners`                          | `true`                                                          | チャートのインストール時に、ローカルの`config.toml`にあるすべてのRunnerの登録を解除します。トークンのプレフィックスが`glrt-`の場合、RunnerではなくRunnerマネージャーが削除されます。Runnerマネージャーは、Runnerと`config.toml`を含むマシンによって識別されます。Runnerが登録トークンで登録された場合、Runnerは削除されます。 |
| `gitlab.geo-logcursor.securityContext.fsGroup`             | `1000`                                                          | ポッドを開始するグループID |
| `gitlab.geo-logcursor.securityContext.runAsUser`           | `1000`                                                          | ポッドを開始するユーザーID |
| `gitlab.gitaly.authToken.key`                              | `token`                                                         | シークレット内のGitalyキー |
| `gitlab.gitaly.authToken.secret`                           | `{.Release.Name}-gitaly-secret`                                 | Gitalyシークレット名 |
| `gitlab.gitaly.image.pullPolicy`                           |                                                                 | GitalyDockerイメージのプルポリシー |
| `gitlab.gitaly.image.repository`                           | `registry.gitlab.com/gitlab-org/build/cng/gitaly`               | GitalyDockerイメージのリポジトリ |
| `gitlab.gitaly.image.tag`                                  | `master`                                                        | GitalyDockerイメージのタグ |
| `gitlab.gitaly.persistence.accessMode`                     | `ReadWriteOnce`                                                 | Gitaly永続アクセスモード |
| `gitlab.gitaly.persistence.enabled`                        | `true`                                                          | Gitalyの永続化を有効にするフラグ |
| `gitlab.gitaly.persistence.matchExpressions`               |                                                                 | バインドするラベル式の一致 |
| `gitlab.gitaly.persistence.matchLabels`                    |                                                                 | バインドするラベル値の一致 |
| `gitlab.gitaly.persistence.size`                           | `50Gi`                                                          | Gitaly永続ボリュームサイズ |
| `gitlab.gitaly.persistence.storageClass`                   |                                                                 | プロビジョニングのストレージクラス名 |
| `gitlab.gitaly.persistence.subPath`                        |                                                                 | Gitaly永続ボリュームのマウントパス |
| `gitlab.gitaly.persistence.volumeName`                     |                                                                 | 既存の永続ボリューム名 |
| `gitlab.gitaly.securityContext.fsGroup`                    | `1000`                                                          | ポッドを開始するグループID |
| `gitlab.gitaly.securityContext.runAsUser`                  | `1000`                                                          | ポッドを開始するユーザーID |
| `gitlab.gitaly.service.annotations`                        | `{}`                                                            | `Service`に追加する注釈 |
| `gitlab.gitaly.service.externalPort`                       | `8075`                                                          | Gitalyサービスの公開ポート |
| `gitlab.gitaly.service.internalPort`                       | `8075`                                                          | Gitalyの内部ポート |
| `gitlab.gitaly.service.name`                               | `gitaly`                                                        | Gitalyサービス名 |
| `gitlab.gitaly.service.type`                               | `ClusterIP`                                                     | Gitalyサービスタイプ |
| `gitlab.gitaly.serviceName`                                | `gitaly`                                                        | Gitalyサービス名 |
| `gitlab.gitaly.shell.authToken.key`                        | `secret`                                                        | Shellキー   |
| `gitlab.gitaly.shell.authToken.secret`                     | `{Release.Name}-gitlab-shell-secret`                            | Shellシークレット |
| `gitlab.gitlab-exporter.securityContext.fsGroup`           | `1000`                                                          | ポッドを開始するグループID |
| `gitlab.gitlab-exporter.securityContext.runAsUser`         | `1000`                                                          | ポッドを開始するユーザーID |
| `gitlab.gitlab-shell.authToken.key`                        | `secret`                                                        | Shell Authシークレットキー |
| `gitlab.gitlab-shell.authToken.secret`                     | `{Release.Name}-gitlab-shell-secret`                            | Shell Authシークレット |
| `gitlab.gitlab-shell.enabled`                              | `true`                                                          | Shellを有効にするフラグ |
| `gitlab.gitlab-shell.image.pullPolicy`                     |                                                                 | ShellDockerイメージのプルポリシー |
| `gitlab.gitlab-shell.image.repository`                     | `registry.gitlab.com/gitlab-org/build/cng/gitlab-shell`         | ShellDockerイメージのリポジトリ |
| `gitlab.gitlab-shell.image.tag`                            | `master`                                                        | ShellDockerイメージのタグ |
| `gitlab.gitlab-shell.replicaCount`                         | `1`                                                             | Shellのレプリカ |
| `gitlab.gitlab-shell.securityContext.fsGroup`              | `1000`                                                          | ポッドを開始するグループID |
| `gitlab.gitlab-shell.securityContext.runAsUser`            | `1000`                                                          | ポッドを開始するユーザーID |
| `gitlab.gitlab-shell.service.annotations`                  | `{}`                                                            | `Service`に追加する注釈 |
| `gitlab.gitlab-shell.service.internalPort`                 | `2222`                                                          | Shellの内部ポート |
| `gitlab.gitlab-shell.service.name`                         | `gitlab-shell`                                                  | Shellサービス名 |
| `gitlab.gitlab-shell.service.type`                         | `ClusterIP`                                                     | Shellサービスタイプ |
| `gitlab.gitlab-shell.webservice.serviceName`               | `global.webservice.serviceName`から継承されます                  | Webserviceサービス名 |
| `gitlab.mailroom.securityContext.fsGroup`                  | `1000`                                                          | ポッドを開始するグループID |
| `gitlab.mailroom.securityContext.runAsUser`                | `1000`                                                          | ポッドを開始するユーザーID |
| `gitlab.migrations.bootsnap.enabled`                       | `true`                                                          | 移行BootSnapを有効にするフラグ |
| `gitlab.migrations.enabled`                                | `true`                                                          | 移行を有効にするフラグ |
| `gitlab.migrations.image.pullPolicy`                       |                                                                 | 移行のプルポリシー |
| `gitlab.migrations.image.repository`                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee`    | 移行Dockerイメージのリポジトリ |
| `gitlab.migrations.image.tag`                              | `master`                                                        | 移行Dockerイメージのタグ |
| `gitlab.migrations.psql.password.key`                      | `psql-password`                                                 | psqlシークレット内のpsqlパスワードキー |
| `gitlab.migrations.psql.password.secret`                   | `gitlab-postgres`                                               | psqlシークレット |
| `gitlab.migrations.psql.port`                              |                                                                 | PostgreSQLサーバーのポートを設定します。`global.psql.port`よりも優先されます。 |
| `gitlab.migrations.securityContext.fsGroup`                | `1000`                                                          | ポッドを開始するグループID |
| `gitlab.migrations.securityContext.runAsUser`              | `1000`                                                          | ポッドを開始するユーザーID |
| `gitlab.sidekiq.concurrency`                               | `20`                                                            | Sidekiqのデフォルト並行処理 |
| `gitlab.sidekiq.enabled`                                   | `true`                                                          | Sidekiqを有効にするフラグ |
| `gitlab.sidekiq.gitaly.authToken.key`                      | `token`                                                         | Gitalyシークレット内のGitalyトークンキー |
| `gitlab.sidekiq.gitaly.authToken.secret`                   | `{.Release.Name}-gitaly-secret`                                 | Gitalyシークレット |
| `gitlab.sidekiq.gitaly.serviceName`                        | `gitaly`                                                        | Gitalyサービス名 |
| `gitlab.sidekiq.image.pullPolicy`                          |                                                                 | SidekiqDockerイメージのプルポリシー |
| `gitlab.sidekiq.image.repository`                          | `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ee`    | SidekiqDockerイメージのリポジトリ |
| `gitlab.sidekiq.image.tag`                                 | `master`                                                        | SidekiqDockerイメージのタグ |
| `gitlab.sidekiq.psql.password.key`                         | `psql-password`                                                 | psqlシークレット内のpsqlパスワードキー |
| `gitlab.sidekiq.psql.password.secret`                      | `gitlab-postgres`                                               | psqlパスワードシークレット |
| `gitlab.sidekiq.psql.port`                                 |                                                                 | PostgreSQLサーバーのポートを設定します。`global.psql.port`よりも優先されます。 |
| `gitlab.sidekiq.replicas`                                  | `1`                                                             | Sidekiqのレプリカ |
| `gitlab.sidekiq.resources.requests.cpu`                    | `100m`                                                          | Sidekiqに必要な最小CPU |
| `gitlab.sidekiq.resources.requests.memory`                 | `600M`                                                          | Sidekiqに必要な最小メモリ |
| `gitlab.sidekiq.securityContext.fsGroup`                   | `1000`                                                          | ポッドを開始するグループID |
| `gitlab.sidekiq.securityContext.runAsUser`                 | `1000`                                                          | ポッドを開始するユーザーID |
| `gitlab.sidekiq.timeout`                                   | `5`                                                             | Sidekiqジョブのタイムアウト |
| `gitlab.toolbox.annotations`                               | `{}`                                                            | ツールボックスに追加する注釈 |
| `gitlab.toolbox.backups.cron.enabled`                      | `false`                                                         | バックアップCronJobを有効にするフラグ |
| `gitlab.toolbox.backups.cron.extraArgs`                    |                                                                 | バックアップユーティリティに渡す引数の文字列 |
| `gitlab.toolbox.backups.cron.persistence.accessMode`       | `ReadWriteOnce`                                                 | バックアップCron永続アクセスモード |
| `gitlab.toolbox.backups.cron.persistence.enabled`          | `false`                                                         | バックアップCronの永続化を有効にするフラグ |
| `gitlab.toolbox.backups.cron.persistence.matchExpressions` |                                                                 | バインドするラベル式の一致 |
| `gitlab.toolbox.backups.cron.persistence.matchLabels`      |                                                                 | バインドするラベル値の一致 |
| `gitlab.toolbox.backups.cron.persistence.size`             | `10Gi`                                                          | バックアップCron永続ボリュームサイズ |
| `gitlab.toolbox.backups.cron.persistence.storageClass`     |                                                                 | プロビジョニングのストレージクラス名 |
| `gitlab.toolbox.backups.cron.persistence.subPath`          |                                                                 | バックアップCron永続ボリュームのマウントパス |
| `gitlab.toolbox.backups.cron.persistence.volumeName`       |                                                                 | 既存の永続ボリューム名 |
| `gitlab.toolbox.backups.cron.resources.requests.cpu`       | `50m`                                                           | バックアップCronに必要な最小CPU |
| `gitlab.toolbox.backups.cron.resources.requests.memory`    | `350M`                                                          | バックアップCronに必要な最小メモリ |
| `gitlab.toolbox.backups.cron.schedule`                     | `0 1 * * *`                                                     | Cronスタイルのスケジュール文字列 |
| `gitlab.toolbox.backups.objectStorage.backend`             | `s3`                                                            | 使用するオブジェクトストレージプロバイダー（`s3`、`gcs`、または`azure`） |
| `gitlab.toolbox.backups.objectStorage.config.gcpProject`   | `""`                                                            | バックエンドが`gcs`の場合に使用するGCPプロジェクト |
| `gitlab.toolbox.backups.objectStorage.config.key`          | `""`                                                            | シークレットに認証情報を含むキー |
| `gitlab.toolbox.backups.objectStorage.config.secret`       | `""`                                                            | オブジェクトストレージの認証情報シークレット |
| `gitlab.toolbox.backups.objectStorage.config`              | `{}`                                                            | オブジェクトストレージの認証情報 |
| `gitlab.toolbox.bootsnap.enabled`                          | `true`                                                          | ツールボックスでBootSnapキャッシュを有効にする |
| `gitlab.toolbox.enabled`                                   | `true`                                                          | ツールボックスを有効にするフラグ |
| `gitlab.toolbox.image.pullPolicy`                          | `IfNotPresent`                                                  | ツールボックスDockerイメージのプルポリシー |
| `gitlab.toolbox.image.repository`                          | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee`    | ツールボックスDockerイメージのリポジトリ |
| `gitlab.toolbox.image.tag`                                 | `master`                                                        | ツールボックスDockerイメージのタグ |
| `gitlab.toolbox.init.image.repository`                     |                                                                 | ツールボックス初期化Dockerイメージのリポジトリ |
| `gitlab.toolbox.init.image.tag`                            |                                                                 | ツールボックス初期化Dockerイメージのタグ |
| `gitlab.toolbox.init.resources.requests.cpu`               | `50m`                                                           | ツールボックスの初期化に必要な最小CPU |
| `gitlab.toolbox.persistence.accessMode`                    | `ReadWriteOnce`                                                 | ツールボックス永続アクセスモード |
| `gitlab.toolbox.persistence.enabled`                       | `false`                                                         | ツールボックスの永続化を有効にするフラグ |
| `gitlab.toolbox.persistence.matchExpressions`              |                                                                 | バインドするラベル式の一致 |
| `gitlab.toolbox.persistence.matchLabels`                   |                                                                 | バインドするラベル値の一致 |
| `gitlab.toolbox.persistence.size`                          | `10Gi`                                                          | ツールボックス永続ボリュームサイズ |
| `gitlab.toolbox.persistence.storageClass`                  |                                                                 | プロビジョニングのストレージクラス名 |
| `gitlab.toolbox.persistence.subPath`                       |                                                                 | ツールボックス永続ボリュームのマウントパス |
| `gitlab.toolbox.persistence.volumeName`                    |                                                                 | 既存の永続ボリューム名 |
| `gitlab.toolbox.psql.port`                                 |                                                                 | PostgreSQLサーバーのポートを設定します。`global.psql.port`よりも優先されます。 |
| `gitlab.toolbox.resources.requests.cpu`                    | `50m`                                                           | ツールボックスに必要な最小CPU |
| `gitlab.toolbox.resources.requests.memory`                 | `350M`                                                          | ツールボックスに必要な最小メモリ |
| `gitlab.toolbox.securityContext.fsGroup`                   | `1000`                                                          | ポッドを開始するグループID |
| `gitlab.toolbox.securityContext.runAsUser`                 | `1000`                                                          | ポッドを開始するユーザーID |
| `gitlab.webservice.enabled`                                | `true`                                                          | Webサービスを有効にするフラグ |
| `gitlab.webservice.gitaly.authToken.key`                   | `token`                                                         | Gitalyシークレット内のGitalyトークンキー |
| `gitlab.webservice.gitaly.authToken.secret`                | `{.Release.Name}-gitaly-secret`                                 | Gitalyシークレット名 |
| `gitlab.webservice.gitaly.serviceName`                     | `gitaly`                                                        | Gitalyサービス名 |
| `gitlab.webservice.image.pullPolicy`                       |                                                                 | WebサービスDockerイメージのプルポリシー |
| `gitlab.webservice.image.repository`                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee` | WebサービスDockerイメージのリポジトリ |
| `gitlab.webservice.image.tag`                              | `master`                                                        | WebサービスDockerイメージのタグ |
| `gitlab.webservice.psql.password.key`                      | `psql-password`                                                 | psqlシークレット内のpsqlパスワードキー |
| `gitlab.webservice.psql.password.secret`                   | `gitlab-postgres`                                               | psqlシークレット名 |
| `gitlab.webservice.psql.port`                              |                                                                 | PostgreSQLサーバーのポートを設定します。`global.psql.port`よりも優先されます。 |
| `global.registry.enabled`                                  | `true`                                                          | レジストリを有効にします。`registry.enabled`をミラーします |
| `global.registry.api.port`                                 | `5000`                                                          | レジストリポート |
| `global.registry.api.protocol`                             | `http`                                                          | レジストリプロトコル |
| `global.registry.api.serviceName`                          | `registry`                                                      | レジストリサービス名 |
| `global.registry.tokenIssuer`                              | `gitlab-issuer`                                                 | レジストリトークン発行者 |
| `gitlab.webservice.replicaCount`                           | `1`                                                             | Webサービスのレプリカ数 |
| `gitlab.webservice.resources.requests.cpu`                 | `200m`                                                          | Webサービスに必要な最小CPU |
| `gitlab.webservice.resources.requests.memory`              | `1.4G`                                                          | Webサービスに必要な最小メモリ |
| `gitlab.webservice.securityContext.fsGroup`                | `1000`                                                          | ポッドを開始するグループID |
| `gitlab.webservice.securityContext.runAsUser`              | `1000`                                                          | ポッドを開始するユーザーID |
| `gitlab.webservice.service.annotations`                    | `{}`                                                            | `Service`に追加する注釈 |
| `gitlab.webservice.http.enabled`                           | `true`                                                          | WebサービスのHTTPを有効にする |
| `gitlab.webservice.service.externalPort`                   | `8080`                                                          | Webサービスの公開ポート |
| `gitlab.webservice.service.internalPort`                   | `8080`                                                          | Webサービスの内部ポート |
| `gitlab.webservice.tls.enabled`                            | `false`                                                         | WebサービスのTLSを有効にする |
| `gitlab.webservice.tls.secretName`                         | `{Release.Name}-webservice-tls`                                 | WebサービスのTLSキーのシークレット名 |
| `gitlab.webservice.service.tls.externalPort`               | `8081`                                                          | WebサービスのTLS公開ポート |
| `gitlab.webservice.service.tls.internalPort`               | `8081`                                                          | webservice TLS内部ポート |
| `gitlab.webservice.service.type`                           | `ClusterIP`                                                     | webserviceサービスタイプ |
| `gitlab.webservice.service.workhorseExternalPort`          | `8181`                                                          | Workhorse公開ポート |
| `gitlab.webservice.service.workhorseInternalPort`          | `8181`                                                          | Workhorse内部ポート |
| `gitlab.webservice.shell.authToken.key`                    | `secret`                                                        | ShellシークレットのShellトークンへのキー |
| `gitlab.webservice.shell.authToken.secret`                 | `{Release.Name}-gitlab-shell-secret`                            | Shellトークンシークレット |
| `gitlab.webservice.workerProcesses`                        | `2`                                                             | webserviceワーカーの数 |
| `gitlab.webservice.workerTimeout`                          | `60`                                                            | webserviceワーカーのタイムアウト |
| `gitlab.webservice.workhorse.extraArgs`                    | `""`                                                            | Workhorseの追加パラメータの文字列 |
| `gitlab.webservice.workhorse.image`                        | `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee`  | Workhorse Dockerイメージリポジトリ |
| `gitlab.webservice.workhorse.sentryDSN`                    | `""`                                                            | エラーレポート用のSentryインスタンスのDSN |
| `gitlab.webservice.workhorse.tag`                          |                                                                 | Workhorse Dockerイメージのタグ |

## 外部チャート {#external-charts}

GitLabは他のいくつかのチャートを利用します。これらは[親子関係として扱われます](https://helm.sh/docs/topics/charts/#chart-dependencies)。設定するプロパティは`chart-name.property`として指定してください。

### Prometheus {#prometheus}

Prometheusの値には、`prometheus`というプレフィックスを付けます。たとえば、`prometheus.server.persistentVolume.size`を使用して、永続ストレージ値を設定します。Prometheusを無効にするには、`prometheus.install=false`を設定します。

設定オプションの網羅的なリストについては、[Prometheusチャートのドキュメント](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)を参照してください。

### PostgreSQL {#postgresql}

PostgreSQLの値には、`postgresql`というプレフィックスを付けます。たとえば、`postgresql.primary.persistence.storageClass`を使用して、プライマリのストレージクラスを設定します。

設定オプションの網羅的なリストについては、[Bitnami PostgreSQLチャートのドキュメント](https://artifacthub.io/packages/helm/bitnami/postgresql)を参照してください。

## 独自のDockerイメージの持ち込み {#bringing-your-own-images}

特定のシナリオ（オフライン環境など）では、インターネットからダウンロードするのではなく、独自のDockerイメージを持ち込むことができます。これには、GitLabリリースを構成する各チャートに、独自のDockerイメージレジストリ/リポジトリを指定する必要があります。

詳細については、[カスタムDockerイメージのドキュメント](../advanced/custom-images/_index.md)を参照してください。
