import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import glob
import os

# 定义目标文件夹路径
base_folder_path = './1116/ramp'
output_folder_path = './1116/ramp_plot'

# 如果目标文件夹不存在，则创建
if not os.path.exists(output_folder_path):
    os.makedirs(output_folder_path)

# 获取文件夹内所有CSV文件
csv_files = glob.glob(os.path.join(base_folder_path, "*.csv"))

# 遍历每个CSV文件并进行处理
for file_idx, file_path in enumerate(csv_files, start=1):
    # 获取文件名（不包含路径和后缀）
    file_name = os.path.splitext(os.path.basename(file_path))[0]

    # 读取CSV文件，从第二行开始读取数据
    data = pd.read_csv(file_path, skiprows=1)

    # 假设第一列是时间，第二列是电压
    time = pd.to_numeric(data.iloc[:, 0], errors='coerce')
    voltage_signal = pd.to_numeric(data.iloc[:, 1], errors='coerce')

    # 去除重复时间和空值（NaN），只保留第一个出现的时间点及其对应的电压
    data_unique = pd.DataFrame({'time': time, 'voltage': voltage_signal}).drop_duplicates(subset='time').dropna()

    # 更新去重后的时间和电压信号
    time = data_unique['time']
    voltage_signal = data_unique['voltage']

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
    top5_indices = np.argsort(positive_fft_voltage[nonzero_mask])[-5:][::-1]  # 获取最大的5个值的索引并反转顺序
    top5_freqs = positive_freqs[nonzero_mask][top5_indices]
    top5_values = positive_fft_voltage[nonzero_mask][top5_indices]

    # 构造 legend 标签内容
    legend_text = "\n".join([f"{freq:.3f} MHz, {value:.3f}" for freq, value in zip(top5_freqs, top5_values)])

    # 确定频域图的y轴最大值

    y_limit = 100

    # 绘制时间域信号
    plt.figure(figsize=(10, 6))
    plt.subplot(2, 1, 1)  # 时间域图
    plt.plot(time, voltage_signal)
    plt.title(f"{file_name} - Time Domain")
    plt.xlabel('Time (s)')
    plt.ylabel('Voltage (V)')

    # 绘制频域图，x轴限制在0到500MHz
    plt.subplot(2, 1, 2)  # 频域图
    plt.plot(positive_freqs, positive_fft_voltage)
    plt.title(f"{file_name} - Frequency Domain (Up to 500 MHz)")
    plt.xlabel('Frequency (MHz)')
    plt.ylabel('Amplitude')
    plt.xlim([0, 500])  # 将x轴限制在0到500MHz
    plt.ylim([0, y_limit])  # 设置y轴限制

    # 设置 legend 为前5个最大值
    plt.legend([legend_text], loc='upper right')

    # 保存图片到新的文件夹
    output_path = os.path.join(output_folder_path, f"{file_name}_Time_Frequency_interference.png")
    plt.tight_layout()
    plt.savefig(output_path)

    # 关闭图表，释放内存
    plt.close()


