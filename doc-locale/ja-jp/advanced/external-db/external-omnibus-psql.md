---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スタンドアロンPostgreSQLデータベースをセットアップする
---

Ubuntu用の[Linuxパッケージ](https://about.gitlab.com/install/#ubuntu)を使用します。このパッケージは、チャートのサービスとの互換性が保証されたサービスのバージョンを提供します。

## LinuxパッケージでVMを作成する {#create-vm-with-the-linux-package}

お好みのプロバイダーまたはローカルでVMを作成します。これはVirtualBox、KVM、Bhyveでテストされました。インスタンスがクラスタリングから到達可能であることを確認してください。

作成したVMにUbuntu Serverをインストールします。`openssh-server`がインストールされていること、およびすべてのパッケージが最新であることを確認してください。ネットワーキングとホスト名を設定します。ホスト名/IPをメモし、それがKubernetesクラスターから解決可能で到達可能であることを確認します。トラフィックを許可するために、ファイアウォールポリシーが適切に設定されていることを確認してください。

[Linuxパッケージ](https://docs.gitlab.com/install/package/ubuntu/)のインストール手順に従ってください。

{{< alert type="note" >}}

パッケージのインストールを実行するときは、`EXTERNAL_URL=`値を指定しないでください。次の手順で非常に具体的な設定を行うので、自動設定は不要です。

{{< /alert >}}

## Linuxパッケージインストールを設定する {#configure-linux-package-installation}

`/etc/gitlab/gitlab.rb`に配置する最小限の`gitlab.rb`ファイルを作成します。このノードで有効になっていることを非常に明確にし、以下のコンテンツを使用します。

この例は、スケーリングのために[PostgreSQL](https://docs.gitlab.com/administration/postgresql/)を提供するものではありません。

次の値を置き換える必要があります:

- `DB_USERNAME`デフォルトのユーザー名は`gitlab`です
- `DB_PASSSWORD`エンコードされていない値
- `DB_ENCODED_PASSWORD` `DB_PASSWORD`のエンコードされた値。`DB_USERNAME`および`DB_PASSWORD`を実際の値に置き換えることで生成できます: `echo -n 'DB_PASSSWORDDB_USERNAME' | md5sum - | cut -d' ' -f1`
- `AUTH_CIDR_ADDRESS` MD5認証のCIDRを設定します。これは、クラスタリングまたはゲートウェイの可能な限り最小のサブネットである必要があります。minikubeの場合、この値は`192.168.100.0/12`です

```ruby
# Change the address below if you do not want PG to listen on all available addresses
postgresql['listen_address'] = '0.0.0.0'
# Set to approximately 1/4 of available RAM.
postgresql['shared_buffers'] = "512MB"
# This password is: `echo -n '${password}${username}' | md5sum - | cut -d' ' -f1`
# The default username is `gitlab`
postgresql['sql_user_password'] = "DB_ENCODED_PASSWORD"
# Configure the CIDRs for MD5 authentication
postgresql['md5_auth_cidr_addresses'] = ['AUTH_CIDR_ADDRESSES']
# Configure the CIDRs for trusted authentication (passwordless)
postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/24']

## Configure gitlab_rails
gitlab_rails['auto_migrate'] = false
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = "DB_PASSSWORD"


## Disable everything else
sidekiq['enable'] = false
puma['enable'] = false
registry['enable'] = false
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = false
prometheus_monitoring['enable'] = false
redis['enable'] = false
gitlab_kas['enable'] = false
```

`gitlab.rb`を作成したら、`gitlab-ctl reconfigure`でパッケージを再設定します。タスクが完了したら、`gitlab-ctl status`で実行中のプロセスを確認します。出力は次のようになります:

```plaintext
# gitlab-ctl status
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
run: postgresql: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```
