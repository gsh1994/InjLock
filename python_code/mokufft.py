import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import glob
import os

# 定义文件夹路径
folder_path = './moku/slave'
output_folder = './moku/slave_plot'

# 如果output_folder不存在，创建文件夹
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# 获取文件夹内所有CSV文件
csv_files = glob.glob(os.path.join(folder_path, "*.csv"))

# 遍历每个CSV文件并进行处理
for file_path in csv_files:
    # 获取文件名（不包含路径和后缀）
    file_name = os.path.splitext(os.path.basename(file_path))[0]

    # 读取CSV文件，从第11行开始读取数据
    data = pd.read_csv(file_path, skiprows=10)

    # 假设第一列是时间，第二列是slave信号，第三列是local oscillator信号
    time = data.iloc[:, 0]
    slave_signal = data.iloc[:, 1]
    local_oscillator_signal = data.iloc[:, 2]

    # 计算采样率（假设时间是等间隔的）
    sampling_rate = 1 / (time[1] - time[0])  # 采样率（假设时间间隔是恒定的）

    # 执行FFT
    fft_slave = np.fft.fft(slave_signal)
    fft_local_oscillator = np.fft.fft(local_oscillator_signal)
    fft_freq = np.fft.fftfreq(len(slave_signal), d=(time[1] - time[0]))  # 计算频率轴

    # 只保留正频率部分
    positive_freqs = fft_freq[:len(fft_freq) // 2] / 1e6  # 转换为MHz
    positive_fft_slave = np.abs(fft_slave[:len(fft_slave) // 2])
    positive_fft_local_oscillator = np.abs(fft_local_oscillator[:len(fft_local_oscillator) // 2])

    # 找到slave信号频域的峰值
    peak_slave_idx = np.argmax(positive_fft_slave)
    peak_slave_freq = positive_freqs[peak_slave_idx]
    peak_slave_value = positive_fft_slave[peak_slave_idx]

    # 找到local oscillator信号频域的峰值
    peak_local_oscillator_idx = np.argmax(positive_fft_local_oscillator)
    peak_local_oscillator_freq = positive_freqs[peak_local_oscillator_idx]
    peak_local_oscillator_value = positive_fft_local_oscillator[peak_local_oscillator_idx]

    # 绘制时间域信号
    plt.figure(figsize=(10, 6))
    plt.subplot(2, 1, 1)  # 时间域图
    plt.plot(time, slave_signal, label='slave Signal (Time Domain)')
    plt.plot(time, local_oscillator_signal, label='Local Oscillator Signal (Time Domain)')
    plt.title(f"{file_name} - Time Domain")
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude (V)')
    plt.legend()

    # 绘制频域图，x轴限制在0到3GHz
    plt.subplot(2, 1, 2)  # 频域图
    plt.plot(positive_freqs, positive_fft_slave, label='slave Signal (Frequency Domain)')
    plt.plot(positive_freqs, positive_fft_local_oscillator, label='Local Oscillator Signal (Frequency Domain)')
    plt.title(f"{file_name} - Frequency Domain")
    plt.xlabel('Frequency (MHz)')
    plt.ylabel('Amplitude')
    plt.xlim([0, 3000])  # 将x轴限制在0到3GHz (即0到3000MHz)
    plt.ylim([0, 0.1])

    # 标注峰值频率和对应幅值，单位MHz
    # plt.scatter([peak_slave_freq], [peak_slave_value], color='red')
    # plt.text(peak_slave_freq, peak_slave_value,
    #          f'{peak_slave_freq:.5f} MHz, {peak_slave_value:.3f} ', color='red')

    # plt.scatter([peak_local_oscillator_freq], [peak_local_oscillator_value], color='blue')
    # plt.text(peak_local_oscillator_freq, peak_local_oscillator_value,
    #          f'{peak_local_oscillator_freq:.5f} MHz, {peak_local_oscillator_value:.3f} ', color='blue')

    plt.legend()

    # 保存图片到slave_plot文件夹
    output_path = os.path.join(output_folder, f"{file_name}_Time_Frequency_slave.png")
    plt.tight_layout()
    plt.savefig(output_path)

    # 显示图表
    # plt.show()




