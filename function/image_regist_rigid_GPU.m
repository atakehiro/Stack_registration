function [dif, f] = image_regist_rigid_GPU(source, target, range_xy, range_theta)
[height,width] = size(source);

theta_i = 0;
theta_step= 0.001; %�p�x�ω��̃X�e�b�v�����߂邽�߂�1������
dx = 0;
while dx == 0
    theta_i = theta_i + theta_step;
    y1 = cos(theta_i * (pi / 180));
    y2 = sin(theta_i * (pi / 180));
    dx = round(width/2 * y1 - height/2 * y2) - width/2;
end
if theta_i == theta_step
    disp('�p�x�̃X�e�b�v���傫�����܂��B�u�p�x�ω��̃X�e�b�v�����߂邽�߂�1�������v�����������Ă�������');
end
if range_theta == 0
    disp('��]�ړ����l�����Ȃ����W�X�g���s���܂��B');
else
    disp(['�p�x�ω���1�X�e�b�v�� ',num2str(theta_i),'��']);
end

sourceG = gpuArray(single(source));
targetG = gpuArray(single(target));

C_G = gpuArray(ones(2*round(range_theta/theta_i)+1, 2*range_xy+1, 2*range_xy+1)); %���֌W���̕\
for i = -round(range_theta/theta_i):round(range_theta/theta_i)
    Source_tmp1 = imrotate(sourceG, theta_i * i, 'crop');
    Region_tmp1 = imrotate(gpuArray(ones(height,width) > 0), theta_i * i, 'crop');
    Target_tmp1 = targetG;
    for j = -range_xy:range_xy %Y����
        if j < 0
            Source_tmp2 = Source_tmp1(:,1:end+j);
            Region_tmp2 = Region_tmp1(:,1:end+j);
            Target_tmp2 = Target_tmp1(:,1-j:end);
        else
            Source_tmp2 = Source_tmp1(:,1:end-j);
            Region_tmp2 = Region_tmp1(:,1:end-j);
            Target_tmp2 = Target_tmp1(:,1+j:end);
        end
        for k = -range_xy:range_xy %X����
            if k < 0
                Source = Source_tmp2(1-k:end,:);
                Region = Region_tmp2(1-k:end,:);
                Target = Target_tmp2(1:end+k,:);
            else
                Source = Source_tmp2(1:end-k,:);
                Region = Region_tmp2(1:end-k,:);
                Target = Target_tmp2(1+k:end,:);
            end
            A_tmp = Source(:);
             B_tmp = Target(:); 
            A = A_tmp(Region(:)>0);
            B = B_tmp(Region(:)>0);
            C_G(round(range_theta/theta_i) + i + 1 ,range_xy + j + 1,range_xy + k + 1) = corr(A,B);
        end
    end
end
C = gather(C_G);
M = max(C(:));
disp(['�ő�̑��֌W���́@',num2str(M)]);
[i1, ~] = find(C == M);
[i2, i3] = find(reshape(C(fix(median(i1)),:,:),[2*range_xy+1 2*range_xy+1]) == M);
theta = (fix(median(i1)) - round(range_theta/theta_i) - 1) * theta_i;
x = median(i2) - range_xy - 1;
y = median(i3) - range_xy - 1;
disp(['�œK�Ȉړ��ʂ� theta=', num2str(theta),' x=',num2str(x),' y=',num2str(y)]);
if abs(x) >= range_xy || abs(y) >= range_xy
    disp('���s�ړ��ł���͈͂����������܂��Brange_xy��傫�����Ă�������');
end
if abs(theta) >= range_theta && range_theta > 0
    disp('��]�ړ��ł���͈͂����������܂��Brange_theta��傫�����Ă�������');
end
dif = [M, theta, x, y];
tmp = imrotate(source, theta, 'crop');
f = imtranslate(tmp,[x, y]);
end
