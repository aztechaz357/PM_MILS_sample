%% main.m - IPMSM MILS シミュレーションの実行
%   モデルを開き、パラメータとソルバを設定してシミュレーションを実行する。
%   実行後、Plant 内の Scope に 相電流 / 速度 / トルク が表示される。

mdl = 'MILS_PM';
here = fileparts(mfilename('fullpath'));
mdlpath = fullfile(here, '..', 'models', [mdl '.slx']);

% --- モデルを開く（未ロードならロード） ---
if ~any(strcmp(find_system('SearchDepth', 0, 'type', 'block_diagram'), mdl))
    open_system(mdlpath);
end

% --- パラメータ設定（base ワークスペースへ展開） ---
run(fullfile(here, '.\parameter\main_parameter.m'));

% --- コンフィギュレーション（ソルバ設定） ---
run(fullfile(here, '.\configure\configuration.m'));

% --- シミュレーション実行 ---
tic
sim(mdl);
toc


disp('シミュレーションが完了しました。Plant の Scope を確認してください。');
