%信息隐藏实验一
%2024年9月28日
%1.4 图像变换域冗余特性及隐写方法
%离散傅里叶(DFT)、快速傅里叶(FFT)、离散余弦(DCT)、离散小波变换(DWT)

%1.4.1
% 观察图像FFT变换，DCT变换和逆变换，观察数据的变化
data=imread('C:\Users\Administrator\Desktop\信息隐藏\LSB.jpg');
data1=data(:,:,1);
DCTdata=dct2(data1);
FFTdata=fft2(data1);
figure,
subplot(221);imshow(data);
title('原始图像');
subplot(222);imshow(mat2gray(log(abs(DCTdata)+1))); %取对数并归一化
title('DCT 变换');
%DCT结果的值可能跨度很大，取对数后可以更容易看到细节。
subplot(223);imshow(mat2gray(log(abs(fftshift(FFTdata))+1)));
title('FFT 变换');
subplot(224);image(DCTdata);
%首先使用 fftshift 将低频成分移到图像中心，然后取其幅值 abs()，
% 最后同样使用 log 和 mat2gray 来处理。
% fftshift 是为了便于观察中心区域的低频信息。

data = rgb2gray(data);
data = im2double(data);
T=dctmtx(8);
result=blkproc(data,[8 8],'P1*x*P2',T,T');
result2=blkproc(result,[8 8],'P1*x*P2',T',T);
figure,
subplot(121);imshow(result);
subplot(122);imshow(result2);%逆变换

%1.4.2
% 1）编写两个函数，实现两点法或三点法的嵌入和提取。
% 2）要求适应任意载体图像。
% 3）分析隐写图像在JPEG压缩条件下的健壮参数a与算法鲁棒性的关系 （两点法）

%两点法
function EmbedImg = DCT2PointEmbed(CarrierImg, SecretImg, alpha)
    CarrierImg = rgb2gray(CarrierImg);
    CarrierImg = im2double(CarrierImg);
    [crow, ccol] = size(CarrierImg);

    crow = floor(crow/8) * 8;
    ccol = floor(ccol/8) * 8;
    CarrierImg = CarrierImg(1:crow, 1:ccol);
    
    SecretImg = imresize(SecretImg, [floor(crow/8), floor(ccol/8)]);
    SecretImg = imbinarize(SecretImg, 0.5);
    [srow, scol] = size(SecretImg);
   

    T = dctmtx(8); 
    dct_carrier = blkproc(CarrierImg,[8 8],'P1*x*P2',T,T');
    % 嵌入秘密信息
    idx = 1;
    for i = 1:srow
        for j = 1:scol
            if (i-1)*8+8 <= crow && (j-1)*8+8 <= ccol
                block_dct = dct_carrier((i-1)*8+1:i*8, (j-1)*8+1:j*8);
            % 两点法嵌入：在 DCT 块的两个中频系数中嵌入秘密信息
            ref = block_dct(5,2); % 参考系数
            embed = block_dct(4,3); % 嵌入系数
            dif = ref - embed;
           
            if SecretImg(i,j) == 1
                new_dif = dif + alpha;
            else
                new_dif = dif - alpha;
            end
            
            % 调整DCT块中的系数
            block_dct(4,4) = ref - new_dif;
            
            % 更新嵌入后的DCT块
            dct_carrier((i-1)*8+1:i*8, (j-1)*8+1:j*8) = block_dct;
            end
        end
    end
    EmbedImg = blkproc(dct_carrier, [8 8], 'P1*x*P2',T',T); % 逆DCT
    EmbedImg = uint8(EmbedImg);
end


function ExtractedImg = DCT2PointExtract(EmbedImg, alpha,srow, scol)
    EmbedImg = im2gray(EmbedImg);
    EmbedImg = im2double(EmbedImg);
    [crow, ccol] = size(EmbedImg);
    
    T = dctmtx(8); 
    dct_embed = blkproc(EmbedImg, [8 8], 'P1*x*P2', T, T');

    srow = floor(crow / 8);
    scol = floor(ccol / 8);
    ExtractedImg = zeros(srow, scol); 

    for i = 1:srow
        for j = 1:scol
            if (i-1)*8+8 <= crow && (j-1)*8+8 <= ccol
                block_dct = dct_embed((i-1)*8+1:i*8, (j-1)*8+1:j*8);
            block_dct = dct_embed((i-1)*8+1:i*8, (j-1)*8+1:j*8);
            ref = block_dct(5, 2);
            embed = block_dct(4, 3);
            dif = ref - embed;

            % 判断秘密信息的值
            if dif > 0
                ExtractedImg(i, j) = 1; % 嵌入了1
            else
                ExtractedImg(i, j) = 0; % 嵌入了0
            end
            end
        end
    end
    ExtractedImg = imresize(ExtractedImg, [8 * srow, 8 * scol]); % 恢复到原始大小
    ExtractedImg = uint8(ExtractedImg * 255); % 转换为8位图像格式
end


CarrierImg = imread('C:\Users\Administrator\Desktop\信息隐藏\LSB.jpg');
SecretImg = imread('C:\Users\Administrator\Desktop\信息隐藏\whu.jfif');

alpha = 5;

EmbedImg = DCT2PointEmbed(CarrierImg, SecretImg, alpha);
imwrite(EmbedImg, 'C:\Users\Administrator\Desktop\信息隐藏\embedimage.jpg');
figure, image(EmbedImg);
title('Embeded Img');

SecretImgResized = imresize(SecretImg, [floor(size(CarrierImg,1)/8), floor(size(CarrierImg,2)/8)]);
[srow, scol] = size(SecretImgResized);

ExtractedImg = DCT2PointExtract(EmbedImg, alpha,srow, scol);
imwrite(ExtractedImg, 'extractedimage.png');
figure, image(ExtractedImg);
title('Extracted Image'); 


% 小 𝛼
% 嵌入信息的影响较小，可能在JPEG压缩过程中保留更多信息，因此鲁棒性较高。
% 然而，信息容量相对较低。
% 大 𝛼
% 嵌入信息的影响较大，虽然可以嵌入更多信息，但在JPEG压缩后，DCT系数的改变可能会导致信息的丢失，因此鲁棒性下降。
% JPEG的压缩程度决定了量化的级别和DCT系数的保留情况。高压缩比会导致更多的DCT系数被量化为零，从而增加了隐写信息丢失的风险。


quality = 50; % 可调整不同压缩质量
imwrite(EmbedImg, 'C:\Users\Administrator\Desktop\信息隐藏\compressed_image.jpg', 'Quality', quality);
CompressedImg = imread('C:\Users\Administrator\Desktop\信息隐藏\compressed_image.jpg');
SecretImgResized = imresize(SecretImg, [floor(size(CarrierImg,1)/8), floor(size(CarrierImg,2)/8)]);
[srow, scol] = size(SecretImgResized);

ExtractedImg = DCT2PointExtract(CompressedImg, alpha, srow, scol);

% % 显示提取的秘密图像
% figure, imshow(ExtractedImg);
% title('提取的秘密图像');
% 
% % 4. 计算误码率 (BER)
% OriginalSecretImg = imbinarize(SecretImgResized, 0.5);
% ExtractedSecretImg = imbinarize(im2double(ExtractedImg), 0.5);
% ExtractedSecretImg = imresize(ExtractedSecretImg, size(OriginalSecretImg));
% % 计算总位数
% total_bits = numel(OriginalSecretImg);
% 
% 
% % 计算误码位数
% error_bits = sum(sum(OriginalSecretImg ~= ExtractedSecretImg));
% 
% % 计算BER
% BER = error_bits / total_bits;
% 
% fprintf('JPEG压缩质量: %d%%\n', quality);
% fprintf('比特错误率（BER）: %.4f\n', BER);
