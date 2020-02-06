function [dif, f] = image_regist_rigid(source, target, range_xy, range_theta)
[height,width] = size(source);

theta_i = 0;
theta_step= 0.001; %角度変化のステップを決めるための1メモリ
dx = 0;
while dx == 0
    theta_i = theta_i + theta_step;
    y1 = cos(theta_i * (pi / 180));
    y2 = sin(theta_i * (pi / 180));
    dx = round(width/2 * y1 - height/2 * y2) - width/2;
end
if theta_i == theta_step
    disp('角度のステップが大きすぎます。「角度変化のステップを決めるための1メモリ」を小さくしてください');
end
if range_theta == 0
    disp('回転移動を考慮しないレジストを行います。');
else
    disp(['角度変化の1ステップは ',num2str(theta_i),'°']);
end

C = ones(2*round(range_theta/theta_i)+1, 2*range_xy+1, 2*range_xy+1); %相関係数の表
for i = -round(range_theta/theta_i):round(range_theta/theta_i)
    SourceM_tmp = imrotate(source, theta_i * i, 'crop');
    Region_tmp = imrotate(ones(height,width), theta_i * i, 'crop');
    for j = -range_xy:range_xy %Y方向
        for k = -range_xy:range_xy %X方向
            SourceM = imtranslate(SourceM_tmp,[j, k]);
            Region = imtranslate(Region_tmp,[j, k]);
            A_tmp = SourceM(:);
            B_tmp = target(:); 
            A = A_tmp(Region(:)>0);
            B = B_tmp(Region(:)>0);
            C(round(range_theta/theta_i) + i + 1 ,range_xy + j + 1,range_xy + k + 1) = corr(A,B);
        end
    end
end
M = max(C(:));
disp(['最大の相関係数は　',num2str(M)]);
[i1, ~] = find(C == M);
[i2, i3] = find(reshape(C(fix(median(i1)),:,:),[2*range_xy+1 2*range_xy+1]) == M);
theta = (fix(median(i1)) - round(range_theta/theta_i) - 1) * theta_i;
x = median(i2) - range_xy - 1;
y = median(i3) - range_xy - 1;
disp(['最適な移動量は theta=', num2str(theta),' x=',num2str(x),' y=',num2str(y)]);
if abs(x) >= range_xy || abs(y) >= range_xy
    disp('平行移動できる範囲が小さすぎます。range_xyを大きくしてください');
end
if abs(theta) >= range_theta && range_theta > 0
    disp('回転移動できる範囲が小さすぎます。range_thetaを大きくしてください');
end
dif = [M, theta, x, y];
tmp = imrotate(source, theta, 'crop');
f = imtranslate(tmp,[x, y]);
end
