function save_MILS_PM_to_mdl()
%% save_MILS_PM_to_mdl.m
%   models/MILS_PM.slx の内容を「ネイティブテキスト形式 (.mdl)」へ保存する。
%
%   .slx はバイナリ (zip) のため差分 (diff) が取れず Git 管理に向かない。
%   一方 .mdl は Simulink のネイティブな *テキスト* 形式で、人間が読めて
%   diff も取れるうえ、ブロック・パラメータ・信号名・マスク・Stateflow
%   チャート内部まで含めて **完全に保存** できる（情報の欠落なし）。
%
%   出力先: models_mdl/MILS_PM.mdl   （models フォルダとは別の保存用フォルダ）
%       └ generate_MILS_PM.m で .slx を完全に再生成できる。
%
%   ※ .mdl は .slx とは別フォルダ (models_mdl) に置く。
%     同一フォルダに同名モデルの .slx と .mdl を共存させると、Simulink が
%     .slx を models/MILS_PM.slx.r2025b としてバックアップ退避してしまうため。
%
%   使い方:
%       >> save_MILS_PM_to_mdl
%
%   推奨ワークフロー:
%       モデル編集 → save_MILS_PM_to_mdl → MILS_PM.mdl を commit
%       （変更内容を diff で追跡できる）

    mdl = 'MILS_PM';

    here    = fileparts(mfilename('fullpath'));
    slxpath = fullfile(here, '..', '..', 'models', [mdl '.slx']);
    outdir  = fullfile(here, '..', '..', 'models_mdl');
    mdlpath = fullfile(outdir, [mdl '.mdl']);

    if ~isfile(slxpath)
        error('元モデルが見つかりません: %s', slxpath);
    end
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end

    % --- 既存ロードを閉じてから .slx をフルパスでロード ---
    if bdIsLoaded(mdl)
        close_system(mdl, 0);
    end
    load_system(slxpath);

    % --- .mdl テキスト形式へ書き出し（既存があれば置き換え） ---
    if isfile(mdlpath)
        delete(mdlpath);
    end
    save_system(mdl, mdlpath, 'OverwriteIfChangedOnDisk', true);

    % モデルを .slx 側に戻さず、ここでは閉じるだけ（.slx は変更しない）
    close_system(mdl, 0);

    fprintf('MILS_PM.slx をテキスト形式で保存しました:\n  %s\n', mdlpath);
end
