%% �p�����[�^�ݒ�
GPU_flag = 0; %GPU���g���ꍇ�͂P
range_xy = 10; %���炷�ő�l�i�{,�[�j�i���A�������j
range_theta = 1;%��]����ő�l(�x)
addpath('function')
%% ���W�X�g
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
disp('�f�[�^�ǂݎ�芮��')
toc
for i = 4:size(S,1)
    path2 = [inputdir, '\'];
    filename2 = S(i).name;
    %% source�t�@�C���̓ǂݎ��
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
    disp('�f�[�^�ǂݎ�芮��')
    toc
    %% �t�@�C���Ԃ̃��W�X�g
    % �Y���̎Z�o
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
    disp('���W�X�g����')
    disp(['�t�@�C���Ԃ̂���́@theta =',num2str(dif(2)),' x = ',num2str(dif(3)),' y = ',num2str(dif(4))])
    toc

    figure
    subplot(1,2,1)
        imshowpair(source,target);
        title("���W�X�g�O")
    subplot(1,2,2)
        imshowpair(f,target);
        title("���W�X�g��")
    %% �}�̕ۑ�
    savefig(['Regist result of', filename1,'AND', filename2,'.fig']);
    %% �S�̂����炷
    Theta = dif(2);
    X = dif(3);
    Y = dif(4);
    post_IMG = imtranslate(imrotate(source_IMG, Theta, 'crop'), [X, Y, 0]);
    clear source_IMG
    %% post�摜��ۑ�
    tic
    post_IMG = cast(post_IMG,['uint',num2str(bit2)]);
    imwrite(post_IMG(:,:,1),[pwd, '\','Cross_reged_', filename2]);
    for t = 2:T
        imwrite(post_IMG(:,:,t),[pwd, '\','Cross_reged_', filename2],'WriteMode','append');
    end
    disp('�������݊���')
    toc
end