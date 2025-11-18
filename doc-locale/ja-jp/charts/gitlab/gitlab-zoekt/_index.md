---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Zoektチャート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 15.9で`index_code_with_zoekt`および`search_code_with_zoekt`[フラグ](https://docs.gitlab.com/administration/feature_flags/)とともに[ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049)されました。デフォルトでは無効になっています。
- GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/388519)になりました。
- 機能フラグ`index_code_with_zoekt`および`search_code_with_zoekt`は、GitLab 17.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378)されました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は[ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)版であり、予告なく変更される場合があります。詳細については、[エピック9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)を参照してください。

{{< /alert >}}

## ZoektチャートとLinuxパッケージインスタンス {#zoekt-chart-with-a-linux-package-instance}

Zoektチャートを使用して、LinuxパッケージインスタンスにZoektを接続します。

前提要件: 

- 現在の[サイズに関する推奨事項](https://docs.gitlab.com/integration/exact_code_search/zoekt/#sizing-recommendations)に基づいた、専用のZoektクラスタリング。

LinuxパッケージインスタンスでZoektチャートを使用するには:

1. `zoekt`というネームスペースを作成します:

   ```shell
   kubectl create namespace zoekt
   ```

1. [`gitlab-zoekt`チャート](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/)をローカルにクローンし、そのディレクトリに変更します:

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt.git
   cd gitlab-zoekt
   ```

1. [ロードバランサーを有効にする](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/v2.7.0/doc/load_balancer.md)。Zoektチャートはヘッドレスサービスであるため、ロードバランサーが必要です。

1. `values.yaml`で:

   1. `/etc/gitlab/gitlab-secrets.json`ファイルから`gitlab_shell`シークレットを使用して、`kubectl`シークレットを作成します:

      ```shell
      kubectl create secret generic gitlab-zoekt-secret --from-literal=secret-key="<gitlab-shell-secret>" -n zoekt
      ```

   1. シークレットを追加します:

      ```yaml
      internalApi:
       secretName: 'gitlab-zoekt-secret'
       secretKey: 'secret-key'
      ```

   1. ロードバランサーのIPポート`:8080`でGitLabインスタンスのURLとサービスURLを追加します:

      ```yaml
       internalApi:
         gitlabUrl: 'https://<gitlab_url>' # Internal URL to connect to GitLab
         serviceUrl: 'http://<loadbalancer_internal_ip>:8080' # URL to reach Zoekt service - LB internal URL
      ```

1. GitLabで、[Gitalyのリスニングインターフェースを変更](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#change-the-gitaly-listening-interface)します:

   ```ruby
   gitaly['configuration'] = {
     listen_addr: '0.0.0.0:8075',
     storage: [
       {
         name: 'default',
         path: '/var/opt/gitlab/git-data/repositories',
       },
     ]
   }
   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://<gitlab_url>:8075' },
   }
   ```

1. `helm`を使用して、Zoektをインストールします:

   ```shell
   helm install gitlab-zoekt . -f values.yaml --version <latest_version> --namespace zoekt
   ```

1. ポッドが作成されたことを確認します。ゲートウェイと`gitlab-zoekt-0`ポッドの両方があるはずです:

   ```shell
   kubectl get pods
   NAME                                  READY   STATUS    RESTARTS   AGE
   gitlab-zoekt-0                        3/3     Running   0          13d
   gitlab-zoekt-gateway-b78dbc78-hzw28   1/1     Running   0          13d
   ```

   `values.yaml`にさらに変更を加える場合は、GitLab Helmチャートをインストールまたはアップグレードしてください。

1. [完全一致コードの検索](https://docs.gitlab.com/integration/zoekt/#enable-exact-code-search)を有効にする。
1. トップレベルグループをインデックス作成するには、次のいずれかを実行します:
   - [すべてのルートネームスペースを自動的にインデックス作成](https://docs.gitlab.com/integration/zoekt/#index-root-namespaces-automatically)。
   - 特定のトップレベルグループを手動でインデックス作成します:

     ```ruby
     node = ::Search::Zoekt::Node.online.last
     namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
     Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
     ```

## GitLab Helmチャートを使用したZoektチャート {#zoekt-chart-with-the-gitlab-helm-chart}

Zoektチャートは、[完全一致コードの検索](https://docs.gitlab.com/user/search/exact_code_search/)をサポートしています。`gitlab-zoekt.install`を`true`に設定して、チャートをインストールできます。詳細については、[`gitlab-zoekt`](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt)を参照してください。

### Zoektチャートを有効にする {#enable-the-zoekt-chart}

Zoektチャートを有効にするには、次の値を設定します:

```shell
--set gitlab-zoekt.install=true \
--set gitlab-zoekt.replicas=2 \         # Number of Zoekt pods. If you want to use only one pod, you can skip this setting.
--set gitlab-zoekt.indexStorage=128Gi   # Disk size for the Zoekt node. Zoekt requires up to three times the repository's default branch's storage size, depending on the number of large and binary files.
```

### CPUとメモリ使用量を設定する {#set-cpu-and-memory-usage}

GitLab.comの[デフォルト設定を変更](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl#L6-45)することにより、Zoektチャートのリクエストと制限を定義できます。

## GitLabでZoektを設定する {#configure-zoekt-in-gitlab}

{{< history >}}

- シャードは、GitLab 16.6でノードに[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134717)。

{{< /history >}}

GitLabのトップレベルグループのZoektを設定するには:

1. toolboxポッドのRailsコンソールに接続します:

   ```shell
   kubectl exec <toolbox pod name> -it -c toolbox -- gitlab-rails console -e production
   ```

1. [完全一致コードの検索](https://docs.gitlab.com/integration/zoekt/#enable-exact-code-search)を有効にする。
1. トップレベルグループをインデックス作成するには、次のいずれかを実行します:
   - [すべてのルートネームスペースを自動的にインデックス作成](https://docs.gitlab.com/integration/zoekt/#index-root-namespaces-automatically)。
   - 特定のトップレベルグループを手動でインデックス作成します:

     {{< tabs >}}

     {{< tab title="GitLab 17.7以降" >}}

     ```shell
     node = ::Search::Zoekt::Node.online.last
     namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
     Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
     ```

     {{< /tab >}}

     {{< tab title="GitLab 17.6以前" >}}

     ```shell
     node = ::Search::Zoekt::Node.online.last
     namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
     enabled_namespace = Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
     replica = enabled_namespace.replicas.find_or_create_by(namespace_id: enabled_namespace.root_namespace_id)
     replica.ready!
     node.indices.create!(zoekt_enabled_namespace_id: enabled_namespace.id, namespace_id: namespace.id, zoekt_replica_id: replica.id, state: :ready)
     ```

     {{< /tab >}}

     {{< /tabs >}}

Zoektは、プロジェクトが更新または作成された後、そのグループ内のプロジェクトをインデックス作成できるようになりました。最初のインデックス作成では、Zoektがネームスペースのインデックス作成を開始するまで、少なくとも数分間待ちます。
