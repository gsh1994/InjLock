import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import glob
import os

# 定义四个文件夹的路径
base_folder_path = './1004/AMP/vna20db/osc'
subfolders = ['master_amp', 'master_no', 'slave_amp', 'slave_no']

# 遍历每个子文件夹
for subfolder in subfolders:
    folder_path = os.path.join(base_folder_path, subfolder)
    output_folder = folder_path  # 输出文件夹与输入文件夹相同

    # 获取文件夹内所有CSV文件
    csv_files = glob.glob(os.path.join(folder_path, "*.csv"))

    # 遍历每个CSV文件并进行处理
    for file_idx, file_path in enumerate(csv_files, start=1):
        # 获取文件名（不包含路径和后缀）
        file_name = os.path.splitext(os.path.basename(file_path))[0]

        # 读取CSV文件，从第二行开始读取数据
        data = pd.read_csv(file_path, skiprows=1)

        # 假设第一列是时间，第二列是电压
        time = data.iloc[:, 0]
        voltage_signal = data.iloc[:, 1]

        # 去除重复时间，只保留第一个出现的时间点及其对应的电压
        data_unique = data.drop_duplicates(subset=[data.columns[0]], keep='first')

        # 更新去重后的时间和电压信号
        time = data_unique.iloc[:, 0]
        voltage_signal = data_unique.iloc[:, 1]

        # 检查数据是否有足够的点进行处理
        if len(time) < 2:
            print(f"Error: Not enough data points in file {file_name}")
            continue  # 跳过此文件的处理

        # 计算时间差并检查是否为零
        time_diff = time.iloc[1] - time.iloc[0]
        if time_diff == 0:
            print(f"Error: Time interval is zero in file {file_name}")
            continue  # 跳过此文件的处理

        # 计算采样率
        sampling_rate = 1 / time_diff  # 采样率（假设时间间隔是恒定的）

        # 执行FFT
        fft_voltage = np.fft.fft(voltage_signal)
        fft_freq = np.fft.fftfreq(len(voltage_signal), d=time_diff)  # 计算频率轴

        # 只保留正频率部分
        positive_freqs = fft_freq[:len(fft_freq) // 2] / 1e6  # 转换为MHz
        positive_fft_voltage = np.abs(fft_voltage[:len(fft_voltage) // 2])

        # 忽略 0 Hz，找到非 0 Hz 的最大值
        nonzero_mask = positive_freqs > 0
        peak_voltage_idx = np.argmax(positive_fft_voltage[nonzero_mask])
        peak_voltage_freq = positive_freqs[nonzero_mask][peak_voltage_idx]
        peak_voltage_value = positive_fft_voltage[nonzero_mask][peak_voltage_idx]

        # 绘制时间域信号
        plt.figure(figsize=(10, 6))
        plt.subplot(2, 1, 1)  # 时间域图
        plt.plot(time, voltage_signal, label='Interference Signal (Time Domain)')
        plt.title(f"{subfolder} - {file_name} - Time Domain")
        plt.xlabel('Time (s)')
        plt.ylabel('Voltage (V)')
        plt.legend()

        # 绘制频域图，x轴限制在0到7.5GHz
        plt.subplot(2, 1, 2)  # 频域图
        plt.plot(positive_freqs, positive_fft_voltage, label='Interference Signal (Frequency Domain)')
        plt.title(f"{subfolder} - {file_name} - Frequency Domain (Up to 7.5 GHz)")
        plt.xlabel('Frequency (MHz)')
        plt.ylabel('Amplitude')
        plt.xlim([0, 7500])  # 将x轴限制在0到7.5GHz (即0到7500MHz)

        # 标注非 0 Hz 的最大值，单位MHz
        plt.scatter([peak_voltage_freq], [peak_voltage_value], color='red')
        plt.text(peak_voltage_freq, peak_voltage_value,
                 f'{peak_voltage_freq:.3f} MHz, {peak_voltage_value:.3f}', color='red')

        plt.legend()

        # 保存图片到对应的子文件夹
        output_path = os.path.join(output_folder, f"{subfolder}_{file_idx}_Time_Frequency_interference.png")
        plt.tight_layout()
        plt.savefig(output_path)

        # 显示图表
        plt.show()



