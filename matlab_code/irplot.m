clc;
clear all;

% 获取当前工作目录
currentFolder = pwd;

% 定义存储伪彩色图的文件夹路径
outputFolder = fullfile(currentFolder, 'injection_ratio_plot');

% 如果 injection_ratio_plot 文件夹不存在，创建它
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

% 获取当前文件夹下的所有文件夹
folders = dir(currentFolder);

% 筛选出所有文件夹（排除 . 和 .. 文件夹）
folders = folders([folders.isdir] & ~ismember({folders.name}, {'.', '..'}));

% 初始化结果存储
allResults = struct();

% 设置波长区间和步长
startWavelength = 1546.051;
endWavelength = 1546.25;
numFiles = 200;
wavelengths = linspace(startWavelength, endWavelength, numFiles);

% 遍历每个文件夹
for folderIdx = 1:length(folders)
    % 跳过 master 和 master_ref 文件夹
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
            % 初始化当前文件夹的结果存储
            folderResults = {};
            dataSample = readmatrix(fullfile(folderPathOSA, filesOSA(1).name), 'Range', 1);
            numWavelengths = size(dataSample, 2) - 1; % 数据除去第一列的列数
            OSA_PowerData = NaN(length(filesOSA), numWavelengths);  % 初始化为 NaN 表示空白
            OSA_Wavelengths = [];
            
            % 生成伪彩色图数据矩阵
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
                    % 获取两个峰值之间的谷值
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
                    % 按峰值大小排序，获取最大和第二大峰值及其波长
                    [sortedPeaks, sortIdx] = sort(validPeaks, 'descend');
                    maxPeak = sortedPeaks(1);
                    secondMaxPeak = sortedPeaks(2);
                    maxPeakWavelength = validWavelengths(sortIdx(1));
                    secondMaxPeakWavelength = validWavelengths(sortIdx(2));
                elseif length(validPeaks) == 1
                    % 只有一个峰值时，只输出一个
                    maxPeak = validPeaks(1);
                    secondMaxPeak = NaN;
                    maxPeakWavelength = validWavelengths(1);
                    secondMaxPeakWavelength = NaN;
                else
                    % 没有符合条件的峰值
                    maxPeak = NaN;
                    secondMaxPeak = NaN;
                    maxPeakWavelength = NaN;
                    secondMaxPeakWavelength = NaN;
                end

                % 仅保存最大峰值在指定波长范围内的文件，并将符合要求的数据绘制到伪彩图
                if ~isnan(maxPeak) && maxPeakWavelength >= startWavelength && maxPeakWavelength <= endWavelength
                    folderResults{end+1} = struct( ...
                        'Wavelength', currentWavelength, ...
                        'MaxPeak', maxPeak, ...
                        'MaxPeakWavelength', maxPeakWavelength, ...
                        'SecondMaxPeak', secondMaxPeak, ...
                        'SecondMaxPeakWavelength', secondMaxPeakWavelength ...
                    );
                    OSA_PowerData(fileIdx, :) = powerOSA;  % 添加数据
                    OSA_Wavelengths = wavelengthOSA;
                end
            end
            
            % 将当前文件夹的结果添加到总体结果中，字段名替换特殊字符
            sanitizedFolderName = regexprep(folders(folderIdx).name, '[^a-zA-Z0-9_]', '_'); % 替换非法字符
            if ~isempty(folderResults)
                allResults.(sanitizedFolderName) = folderResults;
            end

            % 创建并保存伪彩色图，仅包含符合条件的数据，其他位置为空白
            if ~isempty(OSA_Wavelengths)
                pseudoColorFilename = fullfile(outputFolder, sprintf('PseudoColor_OSA_%s.png', sanitizedFolderName));
                figure;
                imagesc(OSA_Wavelengths, wavelengths, OSA_PowerData);
                colorbar;
                caxis([-65 -10]); % 固定 colorbar 的范围为 -65 dB 到 -10 dB
                xlabel('Wavelength (nm)');
                ylabel('Corresponding Wavelength (nm)');
                title(sprintf('Pseudo Color Plot - OSA - %s', sanitizedFolderName));
                
                % 保存伪彩色图
                saveas(gcf, pseudoColorFilename);
                
                % 保存为 EPS 格式
                epsFilename = fullfile(outputFolder, sprintf('PseudoColor_OSA_%s.eps', sanitizedFolderName));
                exportgraphics(gcf, epsFilename, 'BackgroundColor', 'none', 'ContentType', 'vector');
                
                % 关闭伪彩色图 figure
                close(gcf);
            end
        end
    else
        warning('OSA_data 文件夹不存在：%s', folderPathOSA);
    end
end

% 创建 wavelength_conditions_plot 图
figure;
hold on;

% 获取文件夹名称
folderNames = fieldnames(allResults);
numFolders = length(folderNames);

% 设置 y 轴刻度位置
yTickPositions = linspace(1, numFolders, numFolders);

% 初始化图例内容
legendEntries = {};
legendHandles = [];

for i = 1:numFolders
    folderName = folderNames{i};
    folderResults = allResults.(folderName);
    
    wavelengths_below_20dB = [];
    wavelengths_20dB = [];
    wavelengths_30dB = [];
    maxDifferenceWavelength = NaN;
    maxDifference = -Inf;
    
    for j = 1:length(folderResults)
        fileResult = folderResults{j};
        if ~isnan(fileResult.SecondMaxPeak) && (fileResult.MaxPeak - fileResult.SecondMaxPeak < 20)
            wavelengths_below_20dB = [wavelengths_below_20dB, fileResult.Wavelength];
        end
        if ~isnan(fileResult.SecondMaxPeak) && (fileResult.MaxPeak - fileResult.SecondMaxPeak >= 20)
            wavelengths_20dB = [wavelengths_20dB, fileResult.Wavelength];
        end
        if ~isnan(fileResult.SecondMaxPeak) && (fileResult.MaxPeak - fileResult.SecondMaxPeak >= 30)
            wavelengths_30dB = [wavelengths_30dB, fileResult.Wavelength];
        end
        if ~isnan(fileResult.SecondMaxPeak)
            difference = fileResult.MaxPeak - fileResult.SecondMaxPeak;
            if difference > maxDifference
                maxDifference = difference;
                maxDifferenceWavelength = fileResult.Wavelength;
            end
        end
    end
    
    yPosition = yTickPositions(i);
    % 蓝色点：不足20 dB的点
    plot(wavelengths_below_20dB, yPosition * ones(size(wavelengths_below_20dB)), 'bo', 'MarkerFaceColor', 'b');
    % 粉色点：高于20 dB但不足30 dB
    plot(wavelengths_20dB, yPosition * ones(size(wavelengths_20dB)), 'mo', 'MarkerFaceColor', 'm');
    % 红色点：高于30 dB
    plot(wavelengths_30dB, yPosition * ones(size(wavelengths_30dB)), 'ro', 'MarkerFaceColor', 'r');
    % 绿色菱形：最大差值点
    if ~isnan(maxDifferenceWavelength)
        plot(maxDifferenceWavelength, yPosition, 'gd', 'MarkerFaceColor', 'g', 'MarkerSize', 8);
    end
end

ylim([0.5, numFolders + 0.5]);
set(gca, 'YTick', yTickPositions, 'YTickLabel', folderNames);
xlabel('Wavelength (nm)');
ylabel('Folder');
title('Wavelengths Matching Various Conditions Across Folders');

% 保存 wavelength_conditions_plot 图
saveas(gcf, fullfile(outputFolder, 'wavelength_conditions_plot.png'));
exportgraphics(gcf, fullfile(outputFolder, 'wavelength_conditions_plot.eps'), 'BackgroundColor', 'none', 'ContentType', 'vector');

hold off;

