# ControlStudy_0004 — IPMSM MILS シミュレーション

IPMSM（埋込磁石同期モータ）の **MILS（Model-In-the-Loop Simulation）** を
MATLAB / Simulink で行うための学習・検証用プロジェクトです。

電圧方程式・dq/uvw 変換・モータパラメータの考え方を `docs/Note/` に整理しつつ、
Simulink モデル `MILS_PM.slx` でプラント＋制御＋PWM を回して
相電流・速度・トルクを確認します。

---

## ディレクトリ構成

```
ControlStudy_0004/
├─ README.md
├─ models/
│  └─ MILS_PM.slx            … メインの Simulink モデル（プラント / 制御 / PWM）
├─ models_mdl/
│  └─ MILS_PM.mdl            … モデルのテキスト版（save 実行で生成・Git diff 用）
├─ ref/models/
│  └─ MILS.slx               … 参考モデル
├─ src/
│  ├─ main.m                  … シミュレーション実行のエントリポイント
│  ├─ parameter/
│  │  └─ main_parameter.m     … モータ / シミュレーション パラメータ
│  ├─ configure/
│  │  └─ configuration.m      … ソルバ・コンフィギュレーション設定
│  ├─ save/
│  │  └─ save_MILS_PM_to_mdl.m … .slx をテキスト形式 .mdl へ保存（完全保存）
│  └─ generater/
│     └─ generate_MILS_PM.m   … .mdl から .slx を再生成
├─ docs/Note/                … 理論メモ（電圧方程式 / dq変換 / 回転速度換算 など）
├─ img/                      … ブロック図などの画像
└─ build/                    … Simulink のキャッシュ・生成物（中間ファイル）
```

---

## 使い方

### 1. シミュレーションを実行する

MATLAB のカレントフォルダを `src/` にして：

```matlab
>> main
```

`main.m` が以下を自動で行います。

1. `models/MILS_PM.slx` を開く（未ロードならロード）
2. `parameter/main_parameter.m` を base ワークスペースへ展開
3. `configure/configuration.m` でソルバ（固定ステップ ode4）を設定
4. `sim('MILS_PM')` を実行

実行後、Plant 内の Scope に **相電流 / 速度 / トルク** が表示されます。

### 2. モデルをテキスト形式で保存する（バージョン管理用）

バイナリの `.slx`（中身は zip）は差分が取れず Git 管理に向きません。
Simulink の**ネイティブテキスト形式 `.mdl`** へ変換すると、
人間が読めて diff も取れ、かつ **ブロック・パラメータ・信号名・マスク・
Stateflow チャート内部まで完全に保存**されます（情報の欠落なし）。

```matlab
>> save_MILS_PM_to_mdl
```

→ `models_mdl/MILS_PM.mdl` が生成されます。`.slx` は変更しません。

### 3. テキスト形式からモデルを再生成する

```matlab
>> generate_MILS_PM
```

→ `models_mdl/MILS_PM.mdl` を読み込み、`models/MILS_PM.slx` を完全に再生成します。
上書き前に既存 `.slx` をタイムスタンプ付きでバックアップします
（`generate_MILS_PM.m` 内の `backupExisting = false` で無効化可能）。

> **推奨ワークフロー**
> モデルを編集 → `save_MILS_PM_to_mdl` で `.mdl` を更新 → `.mdl` を commit。
> こうすると変更内容を diff で追跡できます。
>
> **なぜ `models_mdl/`（models と別フォルダ）に置くのか**
> 同じフォルダに同名モデルの `.slx` と `.mdl` を共存させると、Simulink が
> `.slx` を `MILS_PM.slx.r2025b` としてバックアップ退避してしまうため、
> `.mdl` は `models/` とは別の `models_mdl/` に分離しています。

---

## 主なパラメータ（`src/parameter/main_parameter.m`）

| 変数 | 意味 | 既定値 |
|------|------|--------|
| `SimEnd` | シミュレーション終了時間 [s] | `0.5` |
| `dt` | 基本ステップ（連続系プラント）[s] | `1.0e-6` |
| `fc` | キャリア周波数 [Hz] | `2000` |
| `Psi_a` | 永久磁石鎖交磁束（電力不変）[Wb] | `0.06` |
| `Ld` / `Lq` | d軸 / q軸 インダクタンス [H] | `0.0005` / `0.0012` |
| `R` | 相抵抗 [Ω] | `0.05` |
| `Pp` | 極対数 | `4` |
| `Vdc` | 直流リンク電圧 [V] | `240` |
| `Id_ref` / `Iq_ref` | dq 電流指令 [A] | `-100` / `200` |
| `fault_U/V/W` | 各相の故障モードフラグ | `1` / `0` / `0` |

タスク周期 `Tc`（キャリア）/ `T1ms` / `T5ms` / `T10ms` で
マルチレート制御（電流制御・トルク→電流・速度→トルク・指令生成）を構成しています。

### 故障モードフラグ（`fault_U/V/W`）

| 値 | 内容 |
|----|------|
| `0` | 正常（Normal） |
| `1` | 上アーム・オープン故障（Stuck OFF） |
| `2` | 上アーム・ショート故障（Stuck ON） |
| `3` | 下アーム・オープン故障（Stuck OFF） |
| `4` | 下アーム・ショート故障（Stuck ON） |

---

## ポイント / 注意

- **絶対値変換（電力不変）** を採用しているため、`Psi_a` などのパラメータは
  その規約に合わせた値です（`docs/Note/` 参照）。
- ソルバは **固定ステップ ode4**、基本ステップ `dt = 1µs`。
  プラントは連続系、制御は離散マルチレートで動作します。
- **save / generate は `.mdl`（ネイティブテキスト）方式**で、Stateflow チャート内部・
  マスク・信号名・全パラメータを含めて完全保存できます（R2025b で
  `.slx → .mdl → .slx` のラウンドトリップが一致することを確認済み）。
- `.mdl` は `.slx` と同名モデルのため、**同一フォルダに置くと `.slx` が
  退避リネームされます**。必ず `models_mdl/`（models と別フォルダ）に分離してください
  （save スクリプトは自動でそうします）。
- `build/` 配下は Simulink のキャッシュ・中間生成物です（コミット不要）。

---

## 理論メモ（`docs/Note/`）

- `20260624_01_電圧方程式` … IPMSM の電圧方程式
- `20260624_02_Vdq_Vuvw` … dq ⇔ uvw 電圧変換
- `20260624_03_モータパラメータ` … モータパラメータの考え方
- `rpm.md` … 回転速度・機械角・電気角・極対数の換算
