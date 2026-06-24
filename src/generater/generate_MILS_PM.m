%% generate_MILS_PM.m
%   save_MILS_PM_to_mdl.m が書き出したテキスト形式 (models_mdl/MILS_PM.mdl) を
%   読み込み、models/MILS_PM.slx を完全に再生成する。
%
%   フロー:
%       1. src/save/save_MILS_PM_to_mdl  →  models_mdl/MILS_PM.mdl を生成（テキスト）
%       2. (このスクリプト) src/generater/generate_MILS_PM  →  models/MILS_PM.slx を再生成
%
%   使い方:
%       >> generate_MILS_PM
%
%   .mdl はブロック・パラメータ・信号名・マスク・Stateflow まで完全保持するため、
%   再生成された .slx は元モデルと一致する。
%   既存の .slx は上書き前にタイムスタンプ付きでバックアップする
%   (backupExisting = false にすると無効化できる)。

here      = fileparts(mfilename('fullpath'));
mdl       = 'MILS_PM';
modelsDir = fullfile(here, '..', '..', 'models');
mdlpath   = fullfile(here, '..', '..', 'models_mdl', [mdl '.mdl']);
slxpath   = fullfile(modelsDir, [mdl '.slx']);

backupExisting = true;

% --- テキストモデルの存在チェック ---
if ~isfile(mdlpath)
    error(['テキストモデルが見つかりません:\n  %s\n' ...
           '先に src/save/save_MILS_PM_to_mdl を実行してください。'], mdlpath);
end

if ~exist(modelsDir, 'dir')
    mkdir(modelsDir);
end

% --- 既存 .slx のバックアップ ---
if backupExisting && isfile(slxpath)
    bak = fullfile(modelsDir, sprintf('%s_backup_%s.slx', mdl, datestr(now, 'yyyymmdd_HHMMSS')));
    copyfile(slxpath, bak);
    fprintf('既存モデルをバックアップしました: %s\n', bak);
end

% --- .mdl をフルパスでロードして .slx へ保存 ---
if bdIsLoaded(mdl)
    close_system(mdl, 0);
end
load_system(mdlpath);
save_system(mdl, slxpath, 'OverwriteIfChangedOnDisk', true);
close_system(mdl, 0);

fprintf('モデルを再生成しました: %s\n', slxpath);
