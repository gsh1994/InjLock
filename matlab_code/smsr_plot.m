clc; 
clear all;

% 获取当前工作目录
currentFolder = pwd;

% 定义存储SMSR图的文件夹路径
outputFolder = fullfile(currentFolder, 'SMSR_plots');

% 如果SMSR_plots文件夹不存在，创建它
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

% 设置波长区间和步长
startWavelength = 1546.051;
endWavelength = 1546.25;
numFiles = 200;
wavelengths = linspace(startWavelength, endWavelength, numFiles);

% 获取当前文件夹下的所有文件夹
folders = dir(currentFolder);

% 筛选出所有文件夹（排除 . 和 .. 文件夹）
folders = folders([folders.isdir] & ~ismember({folders.name}, {'.', '..'}));

% 遍历每个文件夹
for folderIdx = 1:length(folders)
    % 跳过 master 和 MasterRef 文件夹
    if strcmp(folders(folderIdx).name, 'master') || strcmp(folders(folderIdx).name, 'MasterRef')
        continue;
    end

    % 获取当前子文件夹的路径和名字
    currentFolderPath = fullfile(currentFolder, folders(folderIdx).name);
    
    % 构建当前子文件夹下 OSA_data 文件夹的路径
    folderPathOSA = fullfile(currentFolderPath, 'OSA_data');
    
    % 如果 OSA_data 文件夹存在，继续处理
    if isfolder(folderPathOSA)
        filesOSA = dir(fullfile(folderPathOSA, '*.csv'));
        
        % 如果有 OSA 数据文件
        if ~isempty(filesOSA)
            SMSR_values = [];
            SMSR_wavelengths = [];
            SMSR_colors = []; % 存储颜色信息
            
            for fileIdx = 1:length(filesOSA)
                % 对应的波长
                currentWavelength = wavelengths(fileIdx);
                
                % 读取 OSA 数据
                filePathOSA = fullfile(folderPathOSA, filesOSA(fileIdx).name);
                dataOSA = readmatrix(filePathOSA, 'Range', 1); % 使用 readmatrix 读取数据
                powerOSA = dataOSA(1, 2:end); % 跳过第一列，读取功率
                wavelengthOSA = dataOSA(2, 2:end); % 跳过第一列，读取波长

                % 找到局部峰值，且峰值不低于 -55 dB
                [peakValues, peakLocations] = findpeaks(powerOSA, wavelengthOSA, 'MinPeakHeight', -55);

                % 筛选符合条件的峰值（相邻峰之间存在低于 -60 dB 的谷值）
                validPeaks = [];
                validWavelengths = [];
                for k = 1:length(peakValues) - 1
                    valleyPower = min(powerOSA(peakLocations(k) < wavelengthOSA & wavelengthOSA < peakLocations(k+1)));
                    if valleyPower < -60
                        validPeaks = [validPeaks, peakValues(k)];
                        validWavelengths = [validWavelengths, peakLocations(k)];
                    end
                end

                % 检查最后一个峰值
                if ~isempty(peakValues) && (length(validPeaks) < length(peakValues))
                    validPeaks = [validPeaks, peakValues(end)];
                    validWavelengths = [validWavelengths, peakLocations(end)];
                end

                % 找到最大和第二大峰值
                if length(validPeaks) >= 2
                    [sortedPeaks, sortIdx] = sort(validPeaks, 'descend');
                    maxPeak = sortedPeaks(1);
                    secondMaxPeak = sortedPeaks(2);
                    maxPeakWavelength = validWavelengths(sortIdx(1));
                elseif length(validPeaks) == 1
                    maxPeak = validPeaks(1);
                    secondMaxPeak = NaN;
                    maxPeakWavelength = validWavelengths(1);
                else
                    maxPeak = NaN;
                    secondMaxPeak = NaN;
                    maxPeakWavelength = NaN;
                end

                % 仅保存最大峰值在指定波长范围内的数据
                if ~isnan(maxPeak) && maxPeakWavelength >= startWavelength && maxPeakWavelength <= endWavelength
                    SMSR = maxPeak - secondMaxPeak; % 计算SMSR
                    SMSR_values = [SMSR_values, SMSR];
                    SMSR_wavelengths = [SMSR_wavelengths, currentWavelength];
                    
                    % 根据 SMSR 的值设置颜色
                    if SMSR > 30
                        SMSR_colors = [SMSR_colors; 'r']; % 红色
                    elseif SMSR > 20
                        SMSR_colors = [SMSR_colors; 'm']; % 紫色
                    else
                        SMSR_colors = [SMSR_colors; 'b']; % 蓝色
                    end
                end
            end
            
            % 绘制SMSR图
            if ~isempty(SMSR_values)
                figure;
                hold on;
                for i = 1:length(SMSR_values)
                    plot(SMSR_values(i), SMSR_wavelengths(i), '.', 'Color', SMSR_colors(i), 'MarkerSize', 10);
                end
                hold off;
                ylabel('Wavelength (nm)');
                xlabel('SMSR (dB)');
                title(sprintf('SMSR vs Wavelength - %s', folders(folderIdx).name));
                grid on;
                ylim([startWavelength, endWavelength]); % 设置y轴范围
                set(gca, 'YDir', 'reverse'); % 翻转y轴方向
                xlim([0, 50]); % 设置x轴范围

                % 保存图像
                plotFilename = fullfile(outputFolder, sprintf('SMSR_%s.png', folders(folderIdx).name));
                epsFilename = fullfile(outputFolder, sprintf('SMSR_%s.eps', folders(folderIdx).name)); % 添加 EPS 文件名
                saveas(gcf, plotFilename);
                exportgraphics(gcf, epsFilename, 'ContentType', 'vector', 'BackgroundColor', 'none'); % 保存为 EPS
                close(gcf);
            end
        end
    else
        warning('OSA_data 文件夹不存在：%s', folderPathOSA);
    end
end


