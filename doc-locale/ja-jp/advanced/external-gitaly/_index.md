---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部GitalyでGitLabチャートを設定する
---

このドキュメントでは、外部GitalyサービスでこのHelm Chartを設定する方法について説明します。

Gitalyが構成されていない場合は、オンプレミスまたはVMへのデプロイのために、弊社の[Linuxパッケージ](external-omnibus-gitaly.md)の使用をご検討ください。

{{< alert type="note" >}}

外部Gitaly _サービス_は、Gitalyノード、または[Praefect](https://docs.gitlab.com/administration/gitaly/praefect/)クラスタリングによって提供できます。

{{< /alert >}}

## チャートを設定する {#configure-the-chart}

`gitaly`チャートと、それが提供するGitalyサービスを無効にし、他のサービスを外部サービスに向けるようにします。

次のプロパティを設定する必要があります:

- `global.gitaly.enabled`: `false`に設定して、含まれているGitalyチャートを無効にします。
- `global.gitaly.external`: これは、[外部Gitalyサービス](../../charts/globals.md#external)の配列です。
- `global.gitaly.authToken.secret`: [認証用のトークンを含むシークレット](../../installation/secrets.md#gitaly-secret)の名前。
- `global.gitaly.authToken.key`: シークレット内のトークンコンテンツを含むキー。

外部Gitalyサービスは、GitLab Shellの独自のインスタンスを利用します。実装によっては、このチャートのシークレットでそれらを構成するか、このチャートのシークレットを事前定義されたソースのコンテンツで構成することができます。

次のプロパティを設定する必要がある**場合があります**:

- `global.shell.authToken.secret`: [GitLab Shellのシークレットを含むシークレット](../../installation/secrets.md#gitlab-shell-secret)の名前。
- `global.shell.authToken.key`: シークレット内のシークレットコンテンツを含むキー。

2つの外部Gitalyサービスを含む完全な設定例（`external-gitaly.yml`）:

```yaml
global:
  gitaly:
    enabled: false
    external:
      - name: default                   # required, at least one service must be called 'default'.
        hostname: node1.git.example.com # required
        port: 8075                      # optional, default shown
      - name: default2                  # required
        hostname: node2.git.example.com # required
        port: 8075                      # optional, default shown
        tlsEnabled: false               # optional, overrides gitaly.tls.enabled
    authToken:
      secret: external-gitaly-token     # required
      key: token                        # optional, default shown
    tls:
      enabled: false                    # optional, default shown
```

外部Praefectサービスをセットアップする完全な例。

{{< alert type="note" >}}

Praefectサービス名は[`default`である必要があります](../../charts/globals.md#external)。

{{< /alert >}}

```yaml
global:
  gitaly:
    enabled: false
    external:
      - name: default                   # required
        hostname: ha.git.example.com    # required
        port: 2305                      # Praefect uses port 2305
        tlsEnabled: false               # optional, overrides gitaly.tls.enabled
    authToken:
      secret: external-gitaly-token     # required
      key: token                        # optional, default shown
    tls:
      enabled: false                    # optional, default shown
```

上記の設定ファイルを、`gitlab.yml`を介した他の設定と組み合わせて使用​​する場合のインストール例:

```shell
helm upgrade --install gitlab gitlab/gitlab  \
  -f gitlab.yml \
  -f external-gitaly.yml
```

## 複数の外部Gitaly {#multiple-external-gitaly}

実装でこれらのチャートの外部にある複数のGitalyノードを使用している場合は、複数のホストを定義することもできます。必要な複雑さを考慮して、構文がわずかに異なります。

適切な設定セットを示す[値ファイルの例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-external.yaml)が提供されています。この値ファイルの内容は、`--set`引数を介して正しく解釈されないため、Helmに`-f / --values`フラグを付けて渡す必要があります。

### TLS経由で外部Gitalyに接続する {#connecting-to-external-gitaly-over-tls}

外部[GitalyサーバーがTLSポートでリッスンしている](https://docs.gitlab.com/administration/gitaly/#enable-tls-support)場合、GitLabインスタンスにTLS経由で通信させることができます。これを行うには、次の手順を実行する必要があります

1. Gitalyサーバーの証明書を含むKubernetesシークレットを作成します

   ```shell
   kubectl create secret generic gitlab-gitaly-tls-certificate --from-file=gitaly-tls.crt=<path to certificate>
   ```

1. 外部Gitalyサーバーの証明書を[カスタム認証局](../../charts/globals.md#custom-certificate-authorities)のリストに追加します。値ファイルで、以下を指定します

   ```yaml
   global:
     certificates:
       customCAs:
         - secret: gitlab-gitaly-tls-certificate
   ```

   または、`helm upgrade`コマンドに`--set`を使用して渡します

   ```shell
   --set global.certificates.customCAs[0].secret=gitlab-gitaly-tls-certificate
   ```

1. すべてのGitalyインスタンスに対してTLSを有効にするには、`global.gitaly.tls.enabled: true`を設定します。

   ```yaml
   global:
     gitaly:
       tls:
         enabled: true
   ```

   個々のインスタンスに対して有効にするには、そのエントリに`tlsEnabled: true`を設定します。

   ```yaml
   global:
     gitaly:
       external:
         - name: default
           hostname: node1.git.example.com
           tlsEnabled: true
   ```

{{< alert type="note" >}}

これには有効なシークレット名とキーを選択できますが、シークレット内のすべてのキーがマウントされるため、`customCAs`で指定されたすべてのシークレット間でキーが一意であることを確認してください。これが_クライアント側_であるため、証明書のキーを提供する必要は**ありません**。

{{< /alert >}}

## GitLabがGitalyに接続できることをテストする {#test-that-gitlab-can-connect-to-gitaly}

GitLabが外部Gitalyサーバーに接続できることを確認するには:

```shell
kubectl exec -it <toolbox-pod> -- gitlab-rake gitlab:gitaly:check
```

TLSでGitalyを使用している場合は、GitLabチャートがGitaly証明書を信頼しているかどうかを確認することもできます:

```shell
kubectl exec -it <toolbox-pod> -- echo | /usr/bin/openssl s_client -connect <gitaly-host>:<gitaly-port>
```

## Gitalyチャートから外部Gitalyに移行する {#migrate-from-gitaly-chart-to-external-gitaly}

Gitalyチャートを使用してGitalyサービスを提供していて、すべてのリポジトリを外部Gitalyサービスに移行する必要がある場合は、次のいずれかの方法で実行できます:

- [リポジトリストレージ移動APIを使用して移行する（推奨）](#migrate-with-the-repository-storage-moves-api)。
- [バックアップ/復元メソッドを使用して移行する](#migrate-with-the-backuprestore-method)。

### リポジトリストレージ移動APIで移行する {#migrate-with-the-repository-storage-moves-api}

この方法:

- Gitalyチャートから外部Gitalyサービスにリポジトリを移行するために、[リポジトリストレージ移動API](https://docs.gitlab.com/api/project_repository_storage_moves/)を使用します。
- ダウンタイムなしで実行できます。
- 外部GitalyサービスがGitalyポッドと同じVPC/ゾーン内にある必要があります。
- [Praefectチャート](../../charts/gitlab/praefect/_index.md)ではテストされておらず、サポートされていません。

#### ステップ1: 外部GitalyサービスまたはGitaly Cluster (Praefect)をセットアップする {#step-1-set-up-external-gitaly-service-or-gitaly-cluster-praefect}

[外部Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/)または[外部Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)をセットアップします。これらの手順の一部として、チャートインストールからGitalyトークンとGitLab Shellのシークレットを提供する必要があります:

```shell
# Get the GitLab Shell secret
kubectl get secret <release>-gitlab-shell-secret -ojsonpath='{.data.secret}' | base64 -d

# Get the Gitaly token
kubectl get secret <release>-gitaly-secret -ojsonpath='{.data.token}' | base64 -d
```

{{< tabs >}}

{{< tab title="Gitaly" >}}

- ここで抽出されたGitalyトークンは、`AUTH_TOKEN`の値に使用する必要があります。
- ここで抽出されたGitLab Shellのシークレットは、`shellsecret`の値に使用する必要があります。

{{< /tab >}}

{{< tab title="Gitaly Cluster (Praefect)" >}}

- ここで抽出されたGitalyトークンは、`PRAEFECT_EXTERNAL_TOKEN`に使用する必要があります。
- ここで抽出されたGitLab Shellのシークレットは、`GITLAB_SHELL_SECRET_TOKEN`に使用する必要があります。

{{< /tab >}}

{{< /tabs >}}

最後に、外部Gitalyサービスのファイアウォールが、KubernetesポッドIP範囲の構成済みGitalyポートでトラフィックを許可していることを確認してください。

#### ステップ2: 新しいGitalyサービスを使用するようにインスタンスを設定する {#step-2-configure-instance-to-use-new-gitaly-service}

1. 外部Gitalyを使用するようにGitLabを構成します。メインの`gitlab.yml`設定ファイルにGitalyに関する記述がある場合は、それらを削除し、次の内容で新しい`mixed-gitaly.yml`ファイルを作成します。

   以前に追加のGitalyストレージを定義している場合は、新しい設定で同じ名前の対応するGitalyストレージが指定されていることを確認する必要があります。そうでない場合、復元操作は失敗します。

   TLSを設定する場合は、[TLS経由で外部Gitalyに接続する](#connecting-to-external-gitaly-over-tls)セクションを参照してください:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       internal:
         names:
           - default
       external:
         - name: ext-gitaly                # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   ```yaml
   global:
     gitaly:
       internal:
         names:
           - default
       external:
         - name: ext-gitaly-cluster        # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. `gitlab.yml`ファイルと`mixed-gitaly.yml`ファイルを使用して、新しい設定を適用します:

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml \
     -f mixed-gitaly.yml
   ```

1. Toolboxポッドで、GitLabが外部Gitalyに正常に接続できることを確認します:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:gitaly:check
   ```

1. 外部Gitalyがチャートインストールにコールバックできることを確認します:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   GitalyサービスがGitLab APIへのコールバックを正常に実行できることを確認します:

   ```shell
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   すべてのPraefectノードで、PraefectサービスがGitalyノードに接続できることを確認します:

   ```shell
   # Run on Praefect nodes
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes
   ```

   すべてのGitalyノードで、GitalyサービスがGitLab APIへのコールバックを正常に実行できることを確認します:

   ```shell
   # Run on Gitaly nodes
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

      {{< /tab >}}

   {{< /tabs >}}

#### ステップ3: GitalyポッドのIPとホスト名を取得する {#step-3-get-the-gitaly-pod-ip-and-hostnames}

リポジトリストレージ移動APIを成功させるには、外部Gitalyサービスがポッドサービスホスト名を使用してGitalyポッドにコールバックできる必要があります。ポッドサービスホスト名を解決できるようにするには、Gitalyプロセスを実行している各外部Gitalyサービスのホストファイルにホスト名を追加する必要があります。

1. Gitalyポッドとそのそれぞれの内部IPアドレス/ホスト名のリストをフェッチします:

   ```shell
   kubectl get pods -l app=gitaly -o jsonpath='{range .items[*]}{.status.podIP}{"\t"}{.spec.hostname}{"."}{.spec.subdomain}{"."}{.metadata.namespace}{".svc\n"}{end}'
   ```

1. Gitalyプロセスを実行している各外部Gitalyサービスの`/etc/hosts`ファイルに、最後のステップからの出力を追加します。
1. Gitalyプロセスを実行している各外部GitalyサービスからGitalyポッドのホスト名にpingを実行できることを確認します:

   ```shell
   ping <gitaly pod hostname>
   ```

接続が確認されたら、リポジトリストレージの移動のスケジュールに進むことができます。

#### ステップ4: リポジトリストレージの移動をスケジュールする {#step-4-schedule-the-repository-storage-move}

[リポジトリの移動](https://docs.gitlab.com/administration/operations/moving_repositories/#moving-repositories)に示されている手順に従って、移動をスケジュールします。

#### ステップ5: 最終的な設定と検証 {#step-5-final-configuration-and-validation}

1. 複数のGitalyストレージがある場合は、[新しいリポジトリの保存場所を設定](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored)します。

1. 将来的に、外部Gitaly設定を含む統合された`gitlab.yml`を生成することを検討してください:

   ```shell
   helm get values <RELEASE_NAME> -o yaml > gitlab.yml
   ```

1. `gitlab.yml`ファイルで内部Gitalyサブチャートを無効にし、新しい`default`リポジトリストレージを外部Gitalyサービスに向けます。[GitLabには、デフォルトのリポジトリストレージが必要です](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage):

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       enabled: false                      # Disable the internal Gitaly subchart
       external:
         - name: ext-gitaly                # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
         - name: default                   # Add the default repository storage, use the same settings as ext-gitaly
           hostname: node1.git.example.com
           port: 8075
           tlsEnabled: false
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   ```yaml
   global:
     gitaly:
       enabled: false                      # Disable the internal Gitaly subchart
       external:
         - name: ext-gitaly-cluster        # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
         - name: default                   # Add the default repository storage, use the same settings as ext-gitaly-cluster
           hostname: ha.git.example.com
           port: 2305
           tlsEnabled: false
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. 新しい設定を適用します:

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml
   ```

1. オプション。[Gitaly](#step-3-get-the-gitaly-pod-ip-and-hostnames)ポッドのIPとホスト名の取得の手順に従って、各外部Gitaly `/etc/hosts`ファイルに加えられた変更を削除します。

1. すべてが期待どおりに動作していることを確認したら、Gitaly PVCを削除できます:

   警告: すべてが期待どおりに動作していることを再確認するまで、Gitaly PVCを削除しないでください。

   ```shell
   kubectl delete pvc repo-data-<release>-gitaly-0
   ```

### バックアップ/復元メソッドで移行する {#migrate-with-the-backuprestore-method}

この方法:

- GitalyチャートPersistentVolumeClaim（PVC）からリポジトリをバックアップし、外部Gitalyサービスに復元します。
- すべてのユーザーにダウンタイムが発生します。
- [Praefectチャート](../../charts/gitlab/praefect/_index.md)ではテストされておらず、サポートされていません。

#### ステップ1: GitLabチャートの現在のリリースリビジョンを取得する {#step-1-get-the-current-release-revision-of-the-gitlab-chart}

万が一、移行中に問題が発生した場合、GitLabチャートの現在のリリースリビジョンを取得します。[ロールバック](#rollback)を実行する必要がある場合に備えて、出力をコピーして保管しておいてください:

```shell
helm history <release> --max=1
```

#### ステップ2: 外部GitalyサービスまたはGitaly Cluster (Praefect)を設定する {#step-2-setup-external-gitaly-service-or-gitaly-cluster-praefect}

[外部Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/)または[外部Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)をセットアップします。これらの手順の一部として、チャートインストールからGitalyトークンとGitLab Shellのシークレットを提供する必要があります:

```shell
# Get the GitLab Shell secret
kubectl get secret <release>-gitlab-shell-secret -ojsonpath='{.data.secret}' | base64 -d

# Get the Gitaly token
kubectl get secret <release>-gitaly-secret -ojsonpath='{.data.token}' | base64 -d
```

{{< tabs >}}

{{< tab title="Gitaly" >}}

- ここで抽出されたGitalyトークンは、`AUTH_TOKEN`の値に使用する必要があります。
- ここで抽出されたGitLab Shellのシークレットは、`shellsecret`の値に使用する必要があります。

{{< /tab >}}

{{< tab title="Gitaly Cluster (Praefect)" >}}

- ここで抽出されたGitalyトークンは、`PRAEFECT_EXTERNAL_TOKEN`に使用する必要があります。
- ここで抽出されたGitLab Shellのシークレットは、`GITLAB_SHELL_SECRET_TOKEN`に使用する必要があります。

{{< /tab >}}

{{< /tabs >}}

#### ステップ3: 移行中にGitの変更が行われないことを確認する {#step-3-verify-no-git-changes-can-be-made-during-migration}

移行のデータの整合性を確保するために、次の手順でGitリポジトリに​​加えられる変更を防ぎます:

**1\.メンテナンスモードを有効にする**

GitLab Enterprise Editionを使用している場合は、[メンテナンスモード](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode)をUI、API、またはRailsコンソールから有効にします:

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Gitlab::CurrentSettings.update!(maintenance_mode: true)'
```

**2\.Runnerポッドをスケールダウンする**

GitLab Community Editionを使用している場合は、クラスタリングで実行されているGitLab Runnerポッドをスケールダウンする必要があります。これにより、RunnerがCI/CDジョブを処理するためにGitLabに接続できなくなります。

GitLab Enterprise Editionを使用している場合、この手順はオプションです。[メンテナンスモード](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode)により、クラスタリング内のRunnerがGitLabに接続できなくなるためです。

```shell
# Make note of the current number of replicas for Runners so we can scale up to this number later
kubectl get deploy -lapp=gitlab-gitlab-runner,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'

# Scale down the Runners pods to zero
kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=0
```

**3\.実行中のCIジョブがないことを確認する**

管理者エリアで、**CI/CD > ジョブ**に移動します。このページにはすべてのジョブが表示されますが、**実行中**ステータスのジョブがないことを確認してください。次の手順に進む前に、ジョブが完了するのを待つ必要があります。

**4\.Sidekiq cronジョブを無効にする**

移行中にSidekiqジョブがスケジュールおよび実行されないようにするには、すべてのSidekiq cronジョブを無効にします:

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:disable!)'
```

**5\.実行中のバックグラウンドジョブがないことを確認する**

次の手順に進む前に、エンキューされたジョブまたは進行中のジョブが完了するのを待つ必要があります。

1. 管理者エリアで、[**モニタリング**](https://docs.gitlab.com/administration/admin_area/#background-jobs)に移動し、**バックグラウンドジョブ**を選択します。
1. Sidekiqダッシュボードで、**Queues**を選択し、次に**Live Poll**を選択します。
1. **ビジー**および**Enqueued**が0になるまで待ちます。

   ![Sidekiqのバックグラウンドジョブ](img/sidekiq_bg_jobs_v16_5.png)

**6\.SidekiqとWebサービスのポッドをスケールダウンする**

一貫性のあるバックアップが作成されるように、SidekiqとWebサービスのポッドをスケールダウンします。両方のサービスは、後の段階でスケールアップされます:

- Sidekiqポッドは、復元ステップ中にスケールバックされます
- Webサービスのポッドは、接続をテストするために外部Gitalyサービスに切り替えた後にスケールバックされます

```shell
# Make note of the current number of replicas for Sidekiq and Webservice so we can scale up to this number later
kubectl get deploy -lapp=sidekiq,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'
kubectl get deploy -lapp=webservice,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'

# Scale down the Sidekiq and Webservice pods to zero
kubectl scale deploy -lapp=sidekiq,release=<release> --replicas=0
kubectl scale deploy -lapp=webservice,release=<release> --replicas=0
```

**7\.クラスタリングへの外部接続を制限する**

ユーザーと外部GitLab RunnerがGitLabに変更を加えるのを防ぐために、GitLabへの不要な接続をすべて制限する必要があります。

これらの手順が完了すると、復元が完了するまで、GitLabはブラウザで完全に利用できなくなります。

移行中に新しい外部Gitalyサービスがクラスタリングにアクセスできるようにするために、外部GitalyサービスのIPアドレスを唯一の外部例外として`nginx-ingress`設定に追加する必要があります。

1. 次の内容の`ingress-only-allow-ext-gitaly.yml`ファイルを作成します:

   ```yaml
   nginx-ingress:
     controller:
       service:
         loadBalancerSourceRanges:
          - "x.x.x.x/32"
   ```

   `x.x.x.x`は、外部GitalyサービスのIPアドレスである必要があります。

1. `gitlab.yml`ファイルと`ingress-only-allow-ext-gitaly.yml`ファイルの両方を使用して、新しい設定を適用します:

   ```shell
   helm upgrade <release> gitlab/gitlab \
     -f gitlab.yml \
     -f ingress-only-allow-ext-gitaly.yml
   ```

**8\.リポジトリのチェックサムのリストを作成します**

バックアップを実行する前に、[すべてのGitLabリポジトリをチェック](https://docs.gitlab.com/administration/raketasks/check/#check-all-gitlab-repositories)して、リポジトリのチェックサムのリストを作成します。移行後にチェックサムを`diff`できるように、出力をファイルにパイプします:

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:git:checksum_projects > ~/checksums-before.txt
```

#### ステップ4: すべてのリポジトリをバックアップします {#step-4-backup-all-repositories}

リポジトリのみの[バックアップを作成](../../backup-restore/backup.md#create-the-backup)します:

```shell
kubectl exec <toolbox pod name> -it -- backup-utility --skip artifacts,ci_secure_files,db,external_diffs,lfs,packages,pages,registry,terraform_state,uploads
```

#### ステップ5: 新しいGitalyサービスを使用するようにインスタンスを設定する {#step-5-configure-instance-to-use-new-gitaly-service}

1. Gitalyサブチャートを無効にし、外部Gitalyを使用するようにGitLabを設定します。メインの`gitlab.yml`設定ファイルにGitalyに関する記述がある場合は、それらを削除し、次の内容で新しい`external-gitaly.yml`ファイルを作成します。

   以前に追加のGitalyストレージを定義している場合は、新しい設定で同じ名前の対応するGitalyストレージが指定されていることを確認する必要があります。そうでない場合、復元操作は失敗します。

   TLSを設定する場合は、[TLS経由で外部Gitalyに接続する](#connecting-to-external-gitaly-over-tls)セクションを参照してください:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       enabled: false
       external:
         - name: default                   # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   ```yaml
   global:
     gitaly:
       enabled: false
       external:
         - name: default                   # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. `gitlab.yml`、`ingress-only-allow-ext-gitaly.yml`、`external-gitaly.yml`のファイルを使用して、新しい設定を適用します:

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml \
     -f ingress-only-allow-ext-gitaly.yml \
     -f external-gitaly.yml
   ```

1. Webserviceポッドが実行されていない場合は、元のレプリカ数にスケールアップします。これは、以下の手順でGitLabから外部Gitalyへの接続をテストできるようにするために必要です。

   ```shell
   kubectl scale deploy -lapp=webservice,release=<release> --replicas=<value>
   ```

1. Toolboxポッドで、GitLabが外部Gitalyに正常に接続できることを確認します:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:gitaly:check
   ```

1. 外部Gitalyがチャートインストールにコールバックできることを確認します:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   GitalyサービスがGitLab APIへのコールバックを正常に実行できることを確認します:

   ```shell
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   すべてのPraefectノードで、PraefectサービスがGitalyノードに接続できることを確認します:

   ```shell
   # Run on Praefect nodes
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes
   ```

   すべてのGitalyノードで、GitalyサービスがGitLab APIへのコールバックを正常に実行できることを確認します:

   ```shell
   # Run on Gitaly nodes
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

      {{< /tab >}}

   {{< /tabs >}}

#### ステップ6: リポジトリのバックアップを復元し、検証します {#step-6-restore-and-validate-repository-backup}

1. 以前に作成した[バックアップファイルを復元](../../backup-restore/restore.md#restoring-the-backup-file)します。その結果、リポジトリは設定された外部GitalyまたはGitalyクラスタリング (Praefect)にコピーされます。

1. [すべてのGitLabリポジトリをチェック](https://docs.gitlab.com/administration/raketasks/check/#check-all-gitlab-repositories)して、リポジトリのチェックサムのリストを作成します。次のステップでチェックサムを`diff`できるように、出力をファイルにパイプします:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:git:checksum_projects  > ~/checksums-after.txt
   ```

1. リポジトリの移行の前後でリポジトリのチェックサムを比較します。チェックサムが同一の場合、このコマンドは出力を返しません:

   ```shell
   diff ~/checksums-before.txt ~/checksums-after.txt
   ```

   特定の行の`diff`出力で、空白のチェックサムが`0000000000000000000000000000000000000000`に変わる場合、これは予期されることであり、安全に無視できます。

#### ステップ7: 最終的な設定と検証 {#step-7-final-configuration-and-validation}

1. 外部ユーザーとGitLab Runnerが再度GitLabに接続できるようにするには、`gitlab.yml`ファイルと`external-gitaly.yml`ファイルを適用します。`ingress-only-allow-ext-gitaly.yml`を指定しないため、IP制限が削除されます:

    ```shell
    helm upgrade <release> gitlab/gitlab \
      -f gitlab.yml \
      -f external-gitaly.yml
    ```

    将来的に、外部Gitaly設定を含む統合された`gitlab.yml`を生成することを検討してください:

    ```shell
    helm get values <release> gitlab/gitlab -o yaml > gitlab.yml
    ```

1. GitLab Enterprise Editionを使用している場合は、[メンテナンスモード](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode)をUI、API、またはRailsコンソールから無効にします:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Gitlab::CurrentSettings.update!(maintenance_mode: false)'
   ```

1. 複数のGitalyストレージがある場合は、[新しいリポジトリの保存場所を設定](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored)します。

1. Sidekiq cronジョブを有効にします:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
   ```

1. Runnerポッドが実行されていない場合は、元のレプリカ数にスケールアップします:

   ```shell
   kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=<value>
   ```

1. すべてが期待どおりに動作していることを確認したら、Gitaly PVCを削除できます:

   警告: すべてが期待どおりに動作していることをダブルチェックするまで、Gitaly PVCを削除しないでください（[手順6](#step-6-restore-and-validate-repository-backup)に従ってチェックサムが一致していることを確認してください）。

   ```shell
   kubectl delete pvc repo-data-<release>-gitaly-0
   ```

#### ロールバック {#rollback}

問題が発生した場合は、加えられた変更をロールバックして、Gitalyサブチャートを再度使用できます。

正常にロールバックするには、元のGitaly PVCが存在する必要があります。

1. [手順1: GitLabチャートの現在のリリースリビジョンを取得する](#step-1-get-the-current-release-revision-of-the-gitlab-chart)で取得したリビジョン番号を使用して、GitLabチャートを以前のリリースにロールバックします:

   ```shell
   helm rollback <release> <revision>
   ```

1. Webserviceポッドが実行されていない場合は、元のレプリカ数にスケールアップします:

   ```shell
   kubectl scale deploy -lapp=webservice,release=<release> --replicas=<value>
   ```

1. Sidekiqポッドが実行されていない場合は、元のレプリカ数にスケールアップします:

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<release> --replicas=<value>
   ```

1. 以前に無効にした場合は、Sidekiq cronジョブを有効にします:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
   ```

1. Runnerポッドが実行されていない場合は、元のレプリカ数にスケールアップします:

   ```shell
   kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=<value>
   ```

1. GitLab Enterprise Editionを使用している場合は、有効になっている[メンテナンスモード](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode)を無効にします。

### 関連ドキュメント {#related-documentation}

- [Gitaly Cluster (Praefect)への移行](https://docs.gitlab.com/administration/gitaly/praefect/#migrate-to-gitaly-cluster-praefect)
