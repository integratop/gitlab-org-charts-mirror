---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スタンドアロンRedisをセットアップ
---

この手順では、Ubuntu用の[Linuxパッケージ](https://about.gitlab.com/install/#ubuntu)を使用します。このパッケージは、チャートのサービスとの互換性が保証されているバージョンのサービスを提供します。

## Linuxパッケージで仮想マシンを作成します {#create-vm-with-the-linux-package}

任意のプロバイダーまたはローカルで仮想マシンを作成します。これはVirtualBox、KVM、Bhyveでテストされました。そのインスタンスがクラスタリングから到達可能であることを確認してください。

作成した仮想マシンにUbuntu Serverをインストールします。`openssh-server`がインストールされていることと、すべてのパッケージが最新の状態になっていることを確認してください。ネットワークとホスト名を設定します。ホスト名/IPをメモし、それが解決可能であり、Kubernetesクラスタリングから到達可能であることを確認してください。トラフィックを許可するようにファイアウォールポリシーが設定されていることを確認してください。

[Linuxパッケージ](https://docs.gitlab.com/install/package/ubuntu/)のインストール手順に従ってください。

{{< alert type="note" >}}

パッケージのインストールを実行するときは、`EXTERNAL_URL=`値を指定しないでください。自動設定は不要です。次のステップで非常に具体的な設定を行います。

{{< /alert >}}

## Linuxパッケージインストールを設定する {#configure-linux-package-installation}

`/etc/gitlab/gitlab.rb`に配置する最小限の`gitlab.rb`ファイルを作成します。このノードで何が有効になっているかを_非常に_明示的に指定し、以下のコンテンツを使用します。

{{< alert type="note" >}}

この例は、[スケーリング用のRedis](https://docs.gitlab.com/administration/redis/)を提供することを目的としていません。

{{< /alert >}}

- `REDIS_PASSWORD`は、[`gitlab-redis`シークレット](../../installation/secrets.md#redis-password)の値に置き換える必要があります。

```Ruby
# Listen on all addresses
redis['bind'] = '0.0.0.0'
# Set the defaul port, must be set.
redis['port'] = 6379
# Set password, as in the secret `gitlab-redis` populated in Kubernetes
redis['password'] = 'REDIS_PASSWORD'

## Disable everything else
gitlab_rails['enable'] = false
sidekiq['enable'] = false
puma['enable']=false
registry['enable'] = false
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = false
prometheus_monitoring['enable'] = false
postgresql['enable'] = false
```

`gitlab.rb`を作成したら、`gitlab-ctl reconfigure`でパッケージを再設定します。タスクが完了したら、`gitlab-ctl status`で実行中のプロセスを確認します。出力は次のように表示されます:

```plaintext
# gitlab-ctl status
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
run: redis: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```
