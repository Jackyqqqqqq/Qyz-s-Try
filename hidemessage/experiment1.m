%信息隐藏实验一
%2024年9月28日
%1.3 图像空域LSB冗余特性及隐写方法


data = imread('C:\Users\Administrator\Desktop\信息隐藏\LSB.jpg');

%1.3.1
%观察LSB的位平面特性，修改LSB之后的图像特性

% %将图像各个分量的LSB清0
% data1 = bitand(data,254);
% %将图像各个分量的MSB清0
% data2 = bitand(data,127);
% 
% subplot(2,2,1);imshow(data);
% subplot(2,2,3);imshow(data1);
% subplot(2,2,4);imshow(data2);


%1.3.2
% 设计随机取点的算法，随机选取像素点嵌入秘密信息
% 提取秘密信息	      
% 画出随机位置
% 对比隐写前后图像直方图，分析LSB隐写导致的值对效应

function CarrierImg=RandomLSB(CarrierImg,SecretImg,interval,crow,ccol,srow,scol)
Ci = 1;
Cj = 1;
for i = 1:srow
    for j = 1:scol
    Cj = Cj + interval(i,j);
        if Cj > ccol
            Ci = Ci + 1;
            Cj = mod(Cj - 1, ccol) + 1; 
        end

        if Ci > crow
            break;
        end

        if SecretImg(i,j) == 1 && bitget(CarrierImg(Ci,Cj), 1) == 0
            CarrierImg(Ci,Cj) = CarrierImg(Ci,Cj) + 1;
            % plot(Ci,Cj,'r.');
            % hold on 
        elseif SecretImg(i,j) == 0 && bitget(CarrierImg(Ci,Cj), 1) == 1
            CarrierImg(Ci,Cj) = CarrierImg(Ci,Cj) - 1;
            % plot(Ci,Cj,'r.');
            % hold on
        end
    end
end

end


function DecodeImg=Decode_LSB(EncryptedImg,interval,crow,ccol,srow,scol)
Ci = 1;
Cj = 1;
DecodeImg = zeros(srow, scol);
for i = 1:srow
    for j = 1:scol
        Cj = Cj + interval(i,j);
            if Cj > ccol
                Ci = Ci + 1;
                Cj = mod(Cj - 1, ccol) + 1;
            end
            if Ci > crow
                break;
            end
            if bitget(EncryptedImg(Ci,Cj),1) == 1
                DecodeImg(i,j) = 255;
            else
                DecodeImg(i,j) = 0;
            end
    end
end

end



CarrierImg = rgb2gray(data);
[crow,ccol] = size(CarrierImg);
figure,
subplot(2,2,1);imshow(CarrierImg);
title('Carrier Image');



SecretImg = imread('C:\Users\Administrator\Desktop\信息隐藏\whu.jfif');
SecretImg = rgb2gray(SecretImg);
[srow,scol] = size(SecretImg); 
if srow > crow || scol > ccol;
    SecretImg = imresize(SecretImg,[crow-1,ccol-1]);
end
SecretImg = im2double(SecretImg);
SecretImg = imbinarize(SecretImg,0.9);
subplot(2,2,2);imshow(SecretImg);
title('Binarized Secret Image');



rand('seed',2024);
interval = randi(10,srow,scol);
EncryptedImg=RandomLSB(CarrierImg,SecretImg,interval,crow,ccol,srow,scol);
subplot(2,2,3);imshow(EncryptedImg);
title('LSB Encrypt Image');


DecodeImg=Decode_LSB(EncryptedImg,interval,crow,ccol,srow,scol)
subplot(2,2,4);imshow(DecodeImg);
title('LSB Decode Image');


figure,
subplot(1, 2, 1);
imhist(CarrierImg); 
title('Histogram of Carrier Image');

subplot(1, 2, 2);
imhist(EncryptedImg); 
title('Histogram of Encrypted Image');
