---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リソース使用量
---

## リソースリクエスト {#resource-requests}

すべてのコンテナには、事前定義されたリソースリクエスト値が含まれています。デフォルトでは、リソース制限は設定されていません。ノードに十分なメモリ容量がない場合、1つのオプションはメモリ制限を適用することですが、メモリ（またはノード）を追加することをお勧めします。(Linuxカーネルの[out of memory manager](https://www.kernel.org/doc/gorman/html/understand/understand016.html)が不可欠なKubeプロセスを終了させる可能性があるため、Kubernetesノードでメモリ不足にならないようにする必要があります)

デフォルトのリクエスト値を考案するために、アプリケーションを実行し、各サービスのさまざまなレベルのロードを生成する方法を考え出します。サービスを監視し、最適なデフォルト値を呼び出すします。

測定内容は次のとおりです:

- **Idle Load**（アイドルロード） - デフォルト値はこれらの値より低くすべきではありませんが、アイドルプロセスは役に立たないため、通常、この値に基づいてデフォルトを設定することはありません。

- **Minimal Load**（最小ロード） - 最も基本的な有用な作業量を行うために必要な値。通常、CPUの場合、これはデフォルトとして使用されますが、メモリリクエストにはカーネルがプロセスを回収するリスクがあるため、これをメモリデフォルトとして使用することは避けます。

- **Average Loads**（平均ロード） - *平均*と見なされるものはインストールに大きく依存します。 デフォルトの場合、妥当なロードと考えるいくつかの測定を試みます。（使用するロードをリストします）。サービスにポッドオートスケーラーがある場合、通常、これらに基づいてスケールターゲット値を設定しようとします。また、デフォルトのメモリリクエスト。

- **Stressful Task**（ストレスのかかるタスク） - サービスが実行する必要がある最もストレスのかかるタスクの使用状況を測定します。（ロード中は不要）。リソース制限を適用する場合は、この制限と平均ロード値を上回るように設定してください。

- **Heavy Load**（高ロード） - サービスのストレステストを考案し、それを行うために必要なリソース使用量を測定してみてください。現在、これらの値をデフォルトに使用していませんが、ユーザーは平均ロード/ストレスタスクとこの値の間のどこかにリソース制限を設定する可能性があります。

### GitLab Shell {#gitlab-shell}

ロードは、並行処理を行うために`nohup git clone <project> <random-path-name>`を呼び出すbashループを使用してテストされました。将来のテストでは、他のサービスに対して行ったテストの種類とより一致するように、持続的な並行処理のロードを含めるようにします。

- **Idle values**（アイドル値）
  - 0タスク、2ポッド
    - CPU: 0
    - メモリ: `5M`

- **Minimal Load**（最小ロード）
  - 1タスク（空のクローン1つ）、2ポッド
    - CPU: 0
    - メモリ: `5M`

- **Average Loads**（平均ロード）
  - 5つの同時クローン、2ポッド
    - CPU: `100m`
    - メモリ: `5M`
  - 20の同時クローン、2ポッド
    - CPU: `80m`
    - メモリ: `6M`

- **Stressful Task**（ストレスのかかるタスク）
  - SSHはLinuxカーネル（17MB/秒）を複製します
    - CPU: `280m`
    - メモリ: `17M`
  - SSHはLinuxカーネル（2MB/秒）をプッシュします
    - CPU: `140m`
    - メモリ: `13M`
    - *アップロード接続速度は、テスト中の要因である可能性が高いです*

- **Heavy Load**（高ロード）
  - 100の同時クローン、4ポッド
    - CPU: `110m`
    - メモリ: `7M`

- **Default Requests**（デフォルトリクエスト）
  - CPU: 0（最小ロードから）
  - メモリ: `6M`（平均ロードから）
  - ターゲットCPU平均: `100m`（平均ロードから）

- **Recommended Limits**（推奨制限）
  - CPU: > `300m`（ストレスタスクより大きい）
  - メモリ: > `20M`（ストレスタスクより大きい）

`gitlab.gitlab-shell.resources.limits.memory`が低すぎる場合に何が起こるかの詳細については、[トラブルシューティングドキュメント](../troubleshooting/_index.md#git-over-ssh-the-remote-end-hung-up-unexpectedly)を確認してください。

### Webservice {#webservice}

Webサービスのリクエストは、[10kリファレンスアーキテクチャ](https://docs.gitlab.com/administration/reference_architectures/10k_users/)を使用したテスト中に分析されました。注記は、[Webサービスリソースのドキュメント](../charts/gitlab/webservice/_index.md#resources)にあります。

### Sidekiq {#sidekiq}

Sidekiqリソースは、[10kリファレンスアーキテクチャ](https://docs.gitlab.com/administration/reference_architectures/10k_users/)を使用したテスト中に分析されました。注記は、[Sidekiqリソースドキュメント](../charts/gitlab/sidekiq/_index.md#resources)にあります。

### KAS {#kas}

ユーザーのニーズについて詳しく知るまで、ユーザーは次の方法でKubernetes向けGitLabエージェントを使用すると予想されます。

- **Idle values**（アイドル値）
  - 0エージェント接続、2ポッド
    - CPU: `10m`
    - メモリ: `55M`
- **Minimal Load**（最小ロード）:
  - 1エージェント接続、2ポッド
    - CPU: `10m`
    - メモリ: `55M`
- **Average Load**（平均ロード）: 1つのエージェントがクラスタリングに接続されています。
  - 5エージェント接続、2ポッド
    - CPU: `10m`
    - メモリ: `65M`
- **Stressful Task**（ストレスのかかるタスク）:
  - 20エージェント接続、2ポッド
    - CPU: `30m`
    - メモリ: `95M`
- **Heavy Load**（高ロード）:
  - 50エージェント接続、2ポッド
    - CPU: `40m`
    - メモリ: `150M`
- **Extra Heavy Load**（超高ロード）:
  - 200エージェント接続、2ポッド
    - CPU: `50m`
    - メモリ: `315M`

このチャートで設定されたKubernetes向けGitLabエージェントリソースのデフォルトは、50エージェントのシナリオでも処理するのに十分すぎるほどです。**Extra Heavy Load**（非常に高いロード）に達することを計画している場合は、デフォルトを微調整してスケールアップすることを検討する必要があります。

- **Defaults**（デフォルト）: それぞれ2つのポッド。
  - CPU: `100m`
  - メモリ: `100M`

これらの数値がどのように計算されたかの詳細については、[イシューディスカッション](https://gitlab.com/gitlab-org/gitlab/-/issues/296789#note_542196438)を参照してください。
