% 读取载体图像并转换为灰度图像
data = imread('C:\Users\Administrator\Desktop\信息隐藏\LSB.jpg');
CarrierImg = rgb2gray(data);
[crow,ccol] = size(CarrierImg);

% 显示载体图像
figure;
subplot(2,1,1);
imshow(CarrierImg);
title('Carrier Image');

% 读取秘密图像、转换为灰度图像并二值化
SecretImg = imread('C:\Users\Administrator\Desktop\信息隐藏\whu.jpg');
SecretImg = rgb2gray(SecretImg);
[srow,scol] = size(SecretImg);

if srow > crow || scol > ccol;
    SecretImg = imresize(SecretImg,[crow,ccol]);
end
SecretImg = im2double(SecretImg);
SecretImg = imbinarize(SecretImg,0.9);

% 显示二值化后的秘密图像
subplot(2,1,2);
imshow(SecretImg);
title('Binarized Secret Image');

% 加密函数
function CarrierImg=RandomLSB(CarrierImg,SecretImg,interval,crow,ccol,srow,scol,embeddingRate)
    Ci = 1;
    Cj = 1;
    count = 0;
    num_pixels_to_embed = floor(embeddingRate * crow * ccol);
    for i = 1:srow
        for j = 1:scol
            if count< num_pixels_to_embed
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
                    %plot(Ci,Cj,'r.')
                    %hold on
                elseif SecretImg(i,j) == 0 && bitget(CarrierImg(Ci,Cj), 1) == 1
                    CarrierImg(Ci,Cj) = CarrierImg(Ci,Cj) - 1;
                    %plot(Ci,Cj,'b.')
                    %hold on
                end
            end
            count = count+1;
        end
    end    
    
end

function p=kafang(x)
    n=sum(hist(x,[0:255]),2);
    h2i=n([3:2:255]);
    h2is=(h2i+n([4:2:256]))/2;
    filter=(h2is~=0);
    k=sum(filter);
    idx=zeros(1,k);
    for i=1:127
        if filter(i)==1
            idx(sum(filter(1:i)))=i;
        end
    end
    r=sum(((h2i(idx)-h2is(idx)).^2)./(h2is(idx)));
    p=1-chi2cdf(r,k-1); 
end

embeddingRates = [0.1,0.3,0.5,0.7,0.9]; % 这里可以设置不同的嵌入率
for i = 1:length(embeddingRates)
    rand('seed',10);
    interval1 = randi(10,srow,scol);
    EncryptedImg1 = RandomLSB(CarrierImg,SecretImg,interval1,crow,ccol,srow,scol,embeddingRates(i));
    
    %间隔为全 0 的加密图像，这里可以不显示
    interval2=zeros(srow,scol);
    EncryptedImg2=RandomLSB(CarrierImg,SecretImg,interval2,crow,ccol,srow,scol,embeddingRates(i));
    
    figure,
    subplot(1, 3, 1);
    imhist(CarrierImg); 
    title('Carrier Image');
    subplot(1, 3, 2);
    imhist(EncryptedImg1); 
    title(['R Encrypted Image with Embedding Rate ', num2str(embeddingRates(i))]);
    subplot(1, 3, 3);
    imhist(EncryptedImg2); 
    title(['Encrypted Image with Embedding Rate ', num2str(embeddingRates(i))])
    p=kafang(uint8(EncryptedImg1));
    fprintf('嵌入率为%.2f时，随机LSB卡方分析结果p值为：%f\n', embeddingRates(i), p);
    p=kafang(uint8(EncryptedImg2));
    fprintf('嵌入率为%.2f时，LSB卡方分析结果p值为：%f\n', embeddingRates(i), p);
end

