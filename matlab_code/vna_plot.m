clc
clear all

% 获取当前文件夹路径
currentFolder = pwd;

% 创建保存图片的文件夹路径
outputFolder = fullfile(currentFolder, 'VNA_plot');
if ~isfolder(outputFolder)
    mkdir(outputFolder); % 如果文件夹不存在，则创建
end

% 加载 master_ref 文件夹下的参考数据
masterRefFolder = fullfile(currentFolder, 'MasterRef', 'VNA_data');
masterRefFile = dir(fullfile(masterRefFolder, '*.mat'));
if isempty(masterRefFile)
    error('No .mat file found in master_ref/VNA_data folder.');
end

% 假设 master_ref 文件夹下只有一个 .mat 文件
masterRefPath = fullfile(masterRefFolder, masterRefFile(1).name);
masterRefData = load(masterRefPath);
masterVNA_Measurements = masterRefData.vector_network_measurements;
masterVNA_Frequency = masterRefData.vector_network_frequencies;

% 获取当前文件夹下的所有文件夹
folders = dir(currentFolder);

% 筛选出所有文件夹（排除当前文件夹和父文件夹）
folders = folders([folders.isdir] & ~ismember({folders.name}, {'.', '..'}));

% 遍历每个文件夹
for folderIdx = 1:length(folders)
    % 获取当前子文件夹路径
    currentFolderPath = fullfile(currentFolder, folders(folderIdx).name);
    
    % 构建当前子文件夹下 VNA_data 文件夹的路径
    folderPathVNA = fullfile(currentFolderPath, 'VNA_data');
    
    % 如果 VNA_data 文件夹存在，继续处理
    if isfolder(folderPathVNA)
        % 搜索 VNA_data 文件夹中的所有 .mat 文件
        matFiles = dir(fullfile(folderPathVNA, '*.mat'));
        
        % 遍历每个 .mat 文件
        for matIdx = 1:length(matFiles)
            % 加载数据文件
            dataFilePath = fullfile(folderPathVNA, matFiles(matIdx).name);
            dataStruct = load(dataFilePath);
            
            % 处理 spectrum 数据
            spectrumMeasurements = dataStruct.spectrum_measurements;
            spectrumFrequency = dataStruct.spectrum_frequencies;
            wavelengths = dataStruct.wavelengths;

            % 生成 GIF 文件名
            gifFilenameSpectrum = fullfile(outputFolder, sprintf('%s_%s_spectrum_animation.gif', folders(folderIdx).name, matFiles(matIdx).name));

            % 准备绘制 spectrum 动图
            figure;
            for k = 1:size(spectrumMeasurements, 1)
                % 绘制当前帧
                plot(spectrumFrequency, spectrumMeasurements(k, :));
                xlabel('Frequency (Hz)');
                ylabel('dB');
                title(sprintf('%s - Wavelength: %.4f nm', folders(folderIdx).name, wavelengths(k)));
                grid on;
                
                % 保存当前帧为 PNG 和 EPS
                pngFilename = fullfile(outputFolder, sprintf('%s_%s_spectrum_frame_%03d.png', folders(folderIdx).name, matFiles(matIdx).name, k));
                epsFilename = fullfile(outputFolder, sprintf('%s_%s_spectrum_frame_%03d.eps', folders(folderIdx).name, matFiles(matIdx).name, k));
                saveas(gcf, pngFilename);
                exportgraphics(gcf, epsFilename, 'ContentType', 'vector', 'BackgroundColor', 'none');
                
                % 捕获当前图形窗口
                frame = getframe(gcf);
                im = frame2im(frame);
                [imind, cm] = rgb2ind(im, 256);
                
                % 将图像写入GIF文件
                if k == 1
                    imwrite(imind, cm, gifFilenameSpectrum, 'gif', 'Loopcount', inf, 'DelayTime', 0.5);
                else
                    imwrite(imind, cm, gifFilenameSpectrum, 'gif', 'WriteMode', 'append', 'DelayTime', 0.5);
                end
            end

            close(gcf);

            % 处理 VNA 数据
            VNA_Measurements = dataStruct.vector_network_measurements;
            VNA_Frequency = dataStruct.vector_network_frequencies;
            
            % 生成 GIF 文件名
            gifFilenameVNA = fullfile(outputFolder, sprintf('%s_%s_VNA_animation.gif', folders(folderIdx).name, matFiles(matIdx).name));

            % 准备绘制 VNA 动图
            figure;
            yMin = min([VNA_Measurements(:); masterVNA_Measurements(:)]);
            yMax = max([VNA_Measurements(:); masterVNA_Measurements(:)]);
            yRange = [yMin yMax];
            
            for k = 1:size(VNA_Measurements, 1)
                % 绘制当前帧
                plot(VNA_Frequency, VNA_Measurements(k, :), 'b', 'LineWidth', 1.5);
                hold on;
                plot(masterVNA_Frequency, masterVNA_Measurements(k, :), 'r--', 'LineWidth', 1.5);
                hold off;

                ylim(yRange);
                xlabel('Frequency (Hz)');
                ylabel('dB');
                title(sprintf('%s - Wavelength: %.4f nm', folders(folderIdx).name, wavelengths(k)));
                legend('Slave laser', 'Master laser(Reference)', 'Location', 'best');
                grid on;
                
                % 保存当前帧为 PNG 和 EPS
                pngFilename = fullfile(outputFolder, sprintf('%s_%s_VNA_frame_%03d.png', folders(folderIdx).name, matFiles(matIdx).name, k));
                epsFilename = fullfile(outputFolder, sprintf('%s_%s_VNA_frame_%03d.eps', folders(folderIdx).name, matFiles(matIdx).name, k));
                saveas(gcf, pngFilename);
                exportgraphics(gcf, epsFilename, 'ContentType', 'vector', 'BackgroundColor', 'none');

                % 捕获当前图形窗口
                frame = getframe(gcf);
                im = frame2im(frame);
                [imind, cm] = rgb2ind(im, 256);
                
                % 将图像写入GIF文件
                if k == 1
                    imwrite(imind, cm, gifFilenameVNA, 'gif', 'Loopcount', inf, 'DelayTime', 0.5);
                else
                    imwrite(imind, cm, gifFilenameVNA, 'gif', 'WriteMode', 'append', 'DelayTime', 0.5);
                end
            end

            close(gcf);
        end
    end
end






