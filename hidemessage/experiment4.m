% JSteg信息隐藏算法嵌入流程如下：
% （1）提取原始图像的DCT系数，获取AC系数；
% （2）将秘密信息转换为二进制序列，并按照JSteg信息隐藏算法替换规则，将原始图像中AC系数的最低比特位替换为二进制序列中的每一比特信息；
% （3）在替换过程结束后，将原始图像中AC系数的二进制数据转换回十进制数据，保存为载密图像。
function stego = Jsteg_in(cover,data)
% 使用jpeg进行信息藏入
%标准量化表
Q=[16 11 10 16 24 40 51 61
    12 12 14 19 26 58 60 55
    14 13 16 24 40 57 69 56
    14 17 22 29 51 87 80 62
    18 22 37 56 68 109 103 77
    24 35 55 64 81 104 113 92
    49 64 78 87 103 121 120 101
    72 92 95 98 112 100 103 99];
%初始化，DCT转换和量化
[h,w]=size(cover);
data_len=numel(data);
D=zeros(h,w);       %零时存储矩阵
for i=1:h/8
    for j=1:w/8
        D(8*(i-1)+1:8*i,8*(j-1)+1:8*j)=dct2(cover(8*(i-1)+1:8*i,8*(j-1)+1:8*j));%二维离散余弦变换
        D(8*(i-1)+1:8*i,8*(j-1)+1:8*j)=round(D(8*(i-1)+1:8*i,8*(j-1)+1:8*j)./Q);%除以Q中的对应元素，对除法的结果进行四舍五入取整操作
    end
end
 
%LSB嵌入
stego=D;
num=1;      %表示data的嵌入进度
for i=1:h
    for j=1:w
        if(abs(D(i,j))>1)
            if(D(i,j)>1)
                stego(i,j)=bitset(D(i,j),1,data(num));%设置D(i,j)LSB位
            else
                stego(i,j)=bitset(-D(i,j),1,data(num));%设置相反数的LSB
                stego(i,j)=-stego(i,j);%再取反
            end
            num=num+1;
        end
        if(num>data_len)
            break;
        end
    end
    if(num>data_len)
        break;
    end
end
%DCT转换，转换成伪装图像
for i=1:h/8
    for j=1:w/8
        stego(8*(i-1)+1:8*i,8*(j-1)+1:8*j)=stego(8*(i-1)+1:8*i,8*(j-1)+1:8*j).*Q;
        stego(8*(i-1)+1:8*i,8*(j-1)+1:8*j)=idct2(stego(8*(i-1)+1:8*i,8*(j-1)+1:8*j));
    end
end
stego=uint8(stego);

end



function extract = Jsteg_out(stego,ER)
%jpeg提取秘密信息
%标准量化表
Q=[16 11 10 16 24 40 51 61
    12 12 14 19 26 58 60 55
    14 13 16 24 40 57 69 56
    14 17 22 29 51 87 80 62
    18 22 37 56 68 109 103 77
    24 35 55 64 81 104 113 92
    49 64 78 87 103 121 120 101
    72 92 95 98 112 100 103 99];
[h,w]=size(stego);
data_len=floor(ER*h*w);
extract=zeros(data_len,1);
%数据提取,DCT转换和量化
D=zeros(h,w);       %零时存储矩阵
for i=1:h/8
    for j=1:w/8
        D(8*(i-1)+1:8*i,8*(j-1)+1:8*j)=dct2(stego(8*(i-1)+1:8*i,8*(j-1)+1:8*j));
        D(8*(i-1)+1:8*i,8*(j-1)+1:8*j)=round(D(8*(i-1)+1:8*i,8*(j-1)+1:8*j)./Q);
    end
end
%数据提取
num=1;      %表示data的提取进度
for i=1:h
    for j=1:w
        if(abs(D(i,j))>1)       %即不为-1，0，1
            extract(num,1)=bitget(abs(D(i,j)),1);
            num=num+1;
        end
        if(num>data_len)
            break;
        end
    end
    if(num>data_len)
        break;
    end
end
extract=logical(extract);
end




cover = imread('C:\Users\Administrator\Desktop\信息隐藏\LSB.jpg');  % 读取载体图像
fileID = fopen('C:\Users\Administrator\Desktop\信息隐藏\secret.txt', 'r');  % 打开待隐藏的文本信息文件
data = fread(fileID, '*ubit1');  
fclose(fileID);
stego = Jsteg_in(cover, data); 
% 定义信息提取率 ER，假设为嵌入的比特数比例（比如 100%）
ER = length(data) / (numel(cover) * 8); 
extracted_data = Jsteg_out(stego, ER);

fileID = fopen('C:\Users\Administrator\Desktop\信息隐藏\extracted_secret.txt', 'w');  % 打开输出文件
fwrite(fileID, extracted_message);
fclose(fileID);

figure,
imshow(stego), title('Stego Image');