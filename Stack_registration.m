%% パラメータ設定
GPU_flag = 0; %GPUを使う場合は１
range_xy = 10; %ずらす最大値（＋,ー）（ｘ、ｙ方向）
range_theta = 1;%回転する最大値(度)
addpath('function')
%% レジスト
inputdir = uigetdir;
S = dir(inputdir);
path1 = [inputdir, '\'];
filename1 = S(3).name;
tic
file_info = imfinfo([path1, filename1]);
d1 = file_info(1).Height;
d2 = file_info(1).Width;
T = numel(file_info);
bit1 = file_info(1).BitDepth;

target_IMG = zeros(d1,d2,T);
for t = 1:T
    target_IMG(:,:,t) = imread([path1, filename1], t);
end
disp('データ読み取り完了')
toc
for i = 4:size(S,1)
    path2 = [inputdir, '\'];
    filename2 = S(i).name;
    %% sourceファイルの読み取り
    tic
    file_info = imfinfo([path2, filename2]);
    d1 = file_info(1).Height;
    d2 = file_info(1).Width;
    T = numel(file_info);
    bit2 = file_info(1).BitDepth;

    source_IMG = zeros(d1,d2,T);
    for t = 1:T
        source_IMG(:,:,t) = imread([path2, filename2], t);
    end
    disp('データ読み取り完了')
    toc
    %% ファイル間のレジスト
    % ズレの算出
    tic
    source = mean(source_IMG,3);
    target = mean(target_IMG,3);
    if GPU_flag == 1
        if range_theta == 0
            [dif, f] = image_regist_translation_GPU(source, target, range_xy);
        else
            [dif, f] = image_regist_rigid_GPU(source, target, range_xy, range_theta);
        end
    else
        [dif, f] = image_regist_rigid(source, target, range_xy, range_theta);
    end
    disp('レジスト完了')
    disp(['ファイル間のずれは　theta =',num2str(dif(2)),' x = ',num2str(dif(3)),' y = ',num2str(dif(4))])
    toc

    figure
    subplot(1,2,1)
        imshowpair(source,target);
        title("レジスト前")
    subplot(1,2,2)
        imshowpair(f,target);
        title("レジスト後")
    %% 図の保存
    savefig(['Regist result of', filename1,'AND', filename2,'.fig']);
    %% 全体をずらす
    Theta = dif(2);
    X = dif(3);
    Y = dif(4);
    post_IMG = imtranslate(imrotate(source_IMG, Theta, 'crop'), [X, Y, 0]);
    clear source_IMG
    %% post画像を保存
    tic
    post_IMG = cast(post_IMG,['uint',num2str(bit2)]);
    imwrite(post_IMG(:,:,1),[pwd, '\','Cross_reged_', filename2]);
    for t = 2:T
        imwrite(post_IMG(:,:,t),[pwd, '\','Cross_reged_', filename2],'WriteMode','append');
    end
    disp('書き込み完了')
    toc
end