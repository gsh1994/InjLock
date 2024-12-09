clc
clear all

% 获取当前文件夹路径
currentFolder = pwd;

% 创建保存图片的文件夹路径
outputFolder = fullfile(currentFolder, 'OSA_plot');
if ~isfolder(outputFolder)
    mkdir(outputFolder); % 如果文件夹不存在，则创建
end

% 获取当前文件夹下的所有文件夹
folders = dir(currentFolder);

% 筛选出所有文件夹（排除当前文件夹和父文件夹）
folders = folders([folders.isdir] & ~ismember({folders.name}, {'.', '..'}));

% 遍历每个文件夹
for folderIdx = 1:length(folders)
    % 获取当前文件夹的路径和名字
    currentFolderPath = fullfile(currentFolder, folders(folderIdx).name);
    
    % 构建当前文件夹下 OSA_data 文件夹的路径
    folderPathOSA = fullfile(currentFolderPath, 'OSA_data');
    
    % 如果 OSA_data 文件夹存在，继续处理
    if isfolder(folderPathOSA)
        filesOSA = dir(fullfile(folderPathOSA, '*.csv'));
        
        % 如果有 OSA_data 数据文件
        if ~isempty(filesOSA)
            % 指定GIF文件名和伪彩色图文件名，包含当前文件夹名字
            gifFilenameOSA = fullfile(outputFolder, sprintf('OSA_data_%s.gif', folders(folderIdx).name));
            pseudoColorFilename = fullfile(outputFolder, sprintf('PseudoColor_%s.png', folders(folderIdx).name));
            pseudoColorEpsFilename = fullfile(outputFolder, sprintf('PseudoColor_%s.eps', folders(folderIdx).name)); % EPS 文件名
            
            % 生成标题的波长范围
            wavelengthTitles = 1546.051:0.001:1546.25; % 动图中波长的变化范围
            
            % 确保文件数量和标题数量一致
            numFiles = min(length(filesOSA), length(wavelengthTitles));
            
            % 初始化伪彩色图数据存储
            powerData = [];
            wavelengths = [];
            
            % 准备绘图
            figure;
            set(gcf, 'Position', [100, 100, 800, 600]);

            % 生成 OSA 动图
            for i = 1:numFiles
                % 读取 OSA_data 数据
                filePathOSA = fullfile(folderPathOSA, filesOSA(i).name);
                dataOSA = readmatrix(filePathOSA, 'Range', 1); % 使用 readmatrix 读取数据
                power = dataOSA(1, 2:end); % 跳过第一列，读取功率
                wavelength = dataOSA(2, 2:end); % 跳过第一列，读取波长
                
                % 将数据存入伪彩色图数据矩阵
                powerData(i, :) = power;
                wavelengths = wavelength;

                % 找到 OSA 数据中的最大值及其对应的波长
                [maxPower, idxMax] = max(power);
                maxWavelength = wavelength(idxMax);
                
                % 绘制图形
                plot(wavelength, power, 'b', 'LineWidth', 1.5); % OSA 数据，蓝色
                
                % 标记最大值
                hold on;
                plot(maxWavelength, maxPower, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8); % OSA 最大值，蓝色圆圈
                hold off;

                % 使用 legend 显示最大值
                legendText = {
                    sprintf('(Max: %.4f nm, %.2f dB)', maxWavelength, maxPower)
                };
                legend(legendText, 'Location', 'northeast');
                
                % 设置图形参数
                xlabel('Wavelength (nm)');
                ylabel('Power (dB)');
                title(sprintf('OSA Data (%.6f nm) - %s', wavelengthTitles(i), folders(folderIdx).name));
                grid on;
                ylim([-70, 0]); % 固定Y轴范围
                yticks(-70:10:0); % 设置Y轴刻度
                
                drawnow; % 更新图形窗口

                % 捕获当前图形窗口
                frame = getframe(gcf);
                im = frame2im(frame);
                [imind, cm] = rgb2ind(im, 256);

                % 将图像写入GIF文件
                if i == 1
                    imwrite(imind, cm, gifFilenameOSA, 'gif', 'Loopcount', inf, 'DelayTime', 2.0); % 延迟时间为2秒
                else
                    imwrite(imind, cm, gifFilenameOSA, 'gif', 'WriteMode', 'append', 'DelayTime', 2.0); % 延迟时间为2秒
                end
            end

            % 关闭当前 figure，准备绘制伪彩色图
            close(gcf);

            % 创建伪彩色图
            figure;
            imagesc(wavelengths, linspace(1546.051, 1546.25, numFiles), powerData);
            colorbar;
            caxis([-65 -10]); % 固定 colorbar 的范围为 -65 dB 到 -10 dB
            xlabel('Wavelength (nm)');
            ylabel('Master Max Wavelength (nm)');
            title(sprintf('Pseudo Color Plot - %s', folders(folderIdx).name));
            
            % 保存伪彩色图为 PNG
            saveas(gcf, pseudoColorFilename);
            
            % 保存伪彩色图为 EPS
            exportgraphics(gcf, pseudoColorEpsFilename, 'ContentType', 'vector', 'BackgroundColor', 'none');
            
            % 关闭伪彩色图 figure
            close(gcf);
        end
    end
end




