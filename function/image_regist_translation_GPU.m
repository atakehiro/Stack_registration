function [dif, f] = image_regist_translation_GPU(source, target, range_xy)

sourceG = gpuArray(source);
targetG = gpuArray(target);

C_G = gpuArray(ones(2*range_xy+1)); %相関係数の表
for i = -range_xy:range_xy %Y方向
    if i < 0
         A_tmp = sourceG(:,1-i:end);
         B_tmp = targetG(:,1:end+i);
    else
         A_tmp = sourceG(:,1:end-i);
         B_tmp = targetG(:,1+i:end);
    end
    for j = -range_xy:range_xy %X方向
        if j < 0
             A = A_tmp(1-j:end,:);
             B = B_tmp(1:end+j,:);
        else
             A = A_tmp(1:end-j,:);
             B = B_tmp(1+j:end,:);
        end
        C_G(range_xy + i + 1,range_xy + j + 1) = corr(A(:),B(:));
    end
end
C = gather(C_G);
M = max(C(:));
disp(['最大の相関係数は　',num2str(M)]);
[i1, i2] = find(C == M);
x = median(i1) - range_xy - 1;
y = median(i2) - range_xy - 1;
disp(['最適な移動量は x=',num2str(x),' y=',num2str(y)]);
if abs(x) >= range_xy || abs(y) >= range_xy
    disp('平行移動できる範囲が小さすぎます。range_xyを大きくしてください');
end
dif = [M, 0, x, y];
f = imtranslate(source,[x, y]);
end
