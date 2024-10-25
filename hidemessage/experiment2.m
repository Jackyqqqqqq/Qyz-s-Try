%信息隐藏实验一
%2024年9月28日
%1.4 图像变换域冗余特性及隐写方法
%离散傅里叶(DFT)、快速傅里叶(FFT)、离散余弦(DCT)、离散小波变换(DWT)

% %1.4.1
% % 观察图像FFT变换，DCT变换和逆变换，观察数据的变化
% data=imread('C:\Users\Administrator\Desktop\信息隐藏\LSB.jpg');
% data1=data(:,:,1);
% DCTdata=dct2(data1);
% FFTdata=fft2(data1);
% figure,
% subplot(231);imshow(data);
% title('原始图像');
% subplot(232);imshow(mat2gray(log(abs(DCTdata)+1))); %取对数并归一化
% title('DCT 变换');
% %DCT结果的值可能跨度很大，取对数后可以更容易看到细节。
% subplot(233);imshow(mat2gray(log(abs(fftshift(FFTdata))+1)));
% title('FFT 变换');
% subplot(234);image(DCTdata);
% %首先使用 fftshift 将低频成分移到图像中心，然后取其幅值 abs()，
% % 最后同样使用 log 和 mat2gray 来处理。
% % fftshift 是为了便于观察中心区域的低频信息。
% 
% data = rgb2gray(data);
% data = im2double(data);
% T=dctmtx(8);
% result=blkproc(data,[8 8],'P1*x*P2',T,T');
% result2=blkproc(result,[8 8],'P1*x*P2',T',T);
% subplot(235);imshow(result);
% subplot(236);imshow(result2);%逆变换

%1.4.2
% 1）编写两个函数，实现两点法或三点法的嵌入和提取。
% 2）要求适应任意载体图像。
% 3）分析隐写图像在JPEG压缩条件下的健壮参数a与算法鲁棒性的关系 （两点法）

%两点法
function EmbedImg = DCT2PointEmbed(CarrierImg, SecretImg, alpha)
    CarrierImg = double(CarrierImg) / 255;
    [crow, ccol, ~] = size(CarrierImg);
    crow = floor(crow / 8) * 8;
    ccol = floor(ccol / 8) * 8;
    CarrierImg = CarrierImg(1:crow, 1:ccol, :);
   
    SecretImg = imresize(SecretImg, [floor(crow / 8), floor(ccol / 8)], 'nearest');
    SecretImg = imbinarize(SecretImg, 0.8);
    [srow, scol] = size(SecretImg);

    T = dctmtx(8); 
    dct_carrier = blkproc(CarrierImg(:,:,1), [8 8], 'P1*x*P2', T, T');
    
    for i = 1:srow
        for j = 1:scol
            rowIndex = (i-1)*8+1;
            colIndex = (j-1)*8+1;
            if rowIndex + 7 <= crow && colIndex + 7 <= ccol
                block_dct = dct_carrier(rowIndex:rowIndex+7, colIndex:colIndex+7);
               
                if SecretImg(i,j) == 0
                    if block_dct(4,3) < block_dct(5,2)
                        block_dct(4,3) = block_dct(4,3) + alpha;
                    else
                        block_dct(5,2) = block_dct(5,2) - alpha;
                    end
                else
                    if block_dct(4,3) > block_dct(5,2)
                        block_dct(4,3) = block_dct(4,3) - alpha;
                    else
                        block_dct(5,2) = block_dct(5,2) + alpha;
                    end
                end
                
                dct_carrier(rowIndex:rowIndex+7, colIndex:colIndex+7) = block_dct;
            end
        end
    end
    
    Writeback = blkproc(dct_carrier, [8 8], 'P1*x*P2', T', T);
    EmbedImg = uint8(Writeback * 255);
end




function ExtractedImg = DCT2PointExtract(EmbedImg, alpha, srow, scol)
    EmbedImg = double(EmbedImg) / 255;
    T = dctmtx(8);
    dct_carrier = blkproc(EmbedImg(:,:,1), [8 8], 'P1*x*P2', T, T');
    
    ExtractedImg = zeros(srow, scol);
    
    for i = 1:srow
        for j = 1:scol
            rowIndex = (i-1)*8+1;
            colIndex = (j-1)*8+1;
            if rowIndex + 7 <= size(dct_carrier, 1) && colIndex + 7 <= size(dct_carrier, 2)
                block_dct = dct_carrier(rowIndex:rowIndex+7, colIndex:colIndex+7);
                if block_dct(4,3) < block_dct(5,2)
                    ExtractedImg(i,j) = 1; 
                else
                    ExtractedImg(i,j) = 0; 
                end
            end
        end
    end
    
    ExtractedImg = uint8(ExtractedImg * 255); 
end


CarrierImg = imread('C:\Users\Administrator\Desktop\信息隐藏\LSB.jpg');
SecretImg = imread('C:\Users\Administrator\Desktop\信息隐藏\whu.jpg');

alpha = 1;

EmbedImg = DCT2PointEmbed(CarrierImg, SecretImg, alpha);
imwrite(EmbedImg, 'C:\Users\Administrator\Desktop\信息隐藏\embedimage.jpg');
figure, imshow(EmbedImg);
title('Embeded Img');

SecretImgResized = imresize(SecretImg, [floor(size(CarrierImg, 1) / 8), floor(size(CarrierImg, 2) / 8)], 'nearest');

ExtractedImg = DCT2PointExtract(EmbedImg,alpha,floor(size(CarrierImg, 1) / 8), floor(size(CarrierImg, 2) / 8));
imwrite(ExtractedImg, 'extractedimage.png');
figure, imshow(ExtractedImg);
title('Extracted Image'); 


% JPEG压缩是一种有损压缩方式，特别是在DCT域中，
% 它会对高频系数的精度产生影响。
% 隐写信息如果嵌入在较高频的DCT系数中，压缩过程中这些系数可能会发生较大变化，导致提取时发生错误。
% 通过调整 alpha 参数，嵌入信息的强度也会改变：
% 较小的 alpha 值：嵌入的变化量较小，可能无法有效抵抗JPEG压缩，提取时误差较大。
% 较大的 alpha 值：嵌入的变化量较大，可以增强抗压缩的能力，但过大的 alpha 可能会影响图像质量，容易被检测到

%1.4.3

function BER = CalculateBER(OriginalSecretImg, ExtractedSecretImg)
    error_bits = sum(sum(OriginalSecretImg ~= ExtractedSecretImg));  % 计算错误的比特数
    total_bits = numel(OriginalSecretImg);  % 总比特数
    BER = error_bits / total_bits;  % 计算误码率
end

function [CompressedEmbedImg, BER] = AnalyzeRobustness(CarrierImg, SecretImg, alpha, jpeg_quality)
    EmbedImg = DCT2PointEmbed(CarrierImg, SecretImg, alpha);
    imwrite(EmbedImg, 'compressed_embed_img.jpg', 'jpg', 'Quality', jpeg_quality);
    CompressedEmbedImg = imread('compressed_embed_img.jpg');
    SecretImgResized = imresize(SecretImg, [floor(size(CarrierImg, 1) / 8), floor(size(CarrierImg, 2) / 8)], 'nearest');
    ExtractedImg = DCT2PointExtract(CompressedEmbedImg, alpha, floor(size(CarrierImg, 1) / 8), floor(size(CarrierImg, 2) / 8));
    BER = CalculateBER(SecretImgResized, ExtractedImg);
end

% 测试不同alpha和JPEG质量下的鲁棒性
CarrierImg = imread('C:\Users\Administrator\Desktop\信息隐藏\LSB.jpg');
SecretImg = imread('C:\Users\Administrator\Desktop\信息隐藏\whu.jpg');

alpha_values = [1, 5, 10];
jpeg_quality_values = [50, 70, 90];

for alpha = alpha_values
    for jpeg_quality = jpeg_quality_values
        [CompressedEmbedImg, BER] = AnalyzeRobustness(CarrierImg, SecretImg, alpha, jpeg_quality);
        fprintf('\nalpha = %d, JPEG Quality = %d, BER = %.10f\n', alpha, jpeg_quality, BER);
        figure, imshow(CompressedEmbedImg);
        title(sprintf('Compressed Embed Img (alpha = %d, quality = %d)', alpha, jpeg_quality));
    end
end

