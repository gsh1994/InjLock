clc
clear all

% 获取当前文件夹路径
currentFolder = pwd;

% 创建保存伪彩色图的文件夹路径
outputFolder = fullfile(currentFolder, 'VNA_color');
if ~isfolder(outputFolder)
    mkdir(outputFolder); % 如果文件夹不存在，则创建
end

% 获取当前文件夹下的所有文件夹
folders = dir(currentFolder);

% 筛选出所有文件夹（排除当前文件夹和父文件夹）
folders = folders([folders.isdir] & ~ismember({folders.name}, {'.', '..'}));

% 遍历每个文件夹
for folderIdx = 1:length(folders)
    % 获取当前文件夹的路径
    currentFolderPath = fullfile(currentFolder, folders(folderIdx).name);
    
    % 构建当前文件夹下 VNA_data 文件夹的路径
    folderPathVNA = fullfile(currentFolderPath, 'VNA_data');
    
    % 如果 VNA_data 文件夹存在，继续处理
    if isfolder(folderPathVNA)
        % 搜索 VNA_data 文件夹中的所有 .mat 文件
        matFiles = dir(fullfile(folderPathVNA, '*.mat'));
        if ~isempty(matFiles) % 确保有 .mat 文件存在
            % 加载唯一的 .mat 文件
            dataFilePath = fullfile(folderPathVNA, matFiles(1).name);
            dataStruct = load(dataFilePath);
            
            % 假设变量名是通用的 Data
            varName = 'Data';
            assignin('base', varName, dataStruct);

            % 处理 spectrum 数据
            spectrumMeasurements = eval([varName '.spectrum_measurements']);
            spectrumFrequency = eval([varName '.spectrum_frequencies']);
            wavelengths = eval([varName '.wavelengths']);

            % 生成 Spectrum 伪彩色图文件名
            pseudoColorFilenameSpectrum = fullfile(outputFolder, sprintf('%s_spectrum_pseudo_color.png', folders(folderIdx).name));
            pseudoColorEpsFilenameSpectrum = fullfile(outputFolder, sprintf('%s_spectrum_pseudo_color.eps', folders(folderIdx).name));
            
            % 创建 Spectrum 伪彩色图
            figure;
            imagesc(spectrumFrequency, wavelengths, spectrumMeasurements);
            colorbar;
            caxis([-65 -10]); % 固定 colorbar 范围为 -65 dB 到 -10 dB
            xlabel('Frequency (Hz)');
            ylabel('Wavelength (nm)');
            title(sprintf('%s - Spectrum Pseudo Color', folders(folderIdx).name));
            
            % 保存 Spectrum 伪彩色图为 PNG 和 EPS
            saveas(gcf, pseudoColorFilenameSpectrum);
            exportgraphics(gcf, pseudoColorEpsFilenameSpectrum, 'ContentType', 'vector', 'BackgroundColor', 'none');
            close(gcf);

            % 处理 VNA 数据
            VNA_Measurements = eval([varName '.vector_network_measurements']);
            VNA_Frequency = eval([varName '.vector_network_frequencies']);
            
            % 生成 VNA 伪彩色图文件名
            pseudoColorFilenameVNA = fullfile(outputFolder, sprintf('%s_VNA_pseudo_color.png', folders(folderIdx).name));
            pseudoColorEpsFilenameVNA = fullfile(outputFolder, sprintf('%s_VNA_pseudo_color.eps', folders(folderIdx).name));
            
            % 创建 VNA 伪彩色图
            figure;
            imagesc(VNA_Frequency, wavelengths, VNA_Measurements);
            colorbar;
            caxis([-65 -10]); % 固定 colorbar 范围为 -65 dB 到 -10 dB
            xlabel('Frequency (Hz)');
            ylabel('Wavelength (nm)');
            title(sprintf('%s - VNA Pseudo Color', folders(folderIdx).name));
            
            % 保存 VNA 伪彩色图为 PNG 和 EPS
            saveas(gcf, pseudoColorFilenameVNA);
            exportgraphics(gcf, pseudoColorEpsFilenameVNA, 'ContentType', 'vector', 'BackgroundColor', 'none');
            close(gcf);
        end
    end
end


