import pandas as pd
import matplotlib.pyplot as plt
import os
import numpy as np

# 文件路径
folder_path = './0909_vna/inter/'
# 创建保存图像的文件夹
output_folder = './0909_vna/inter_plot/'
os.makedirs(output_folder, exist_ok=True)

# 获取所有CSV文件列表
csv_files = [f for f in os.listdir(folder_path) if f.endswith('.csv')]

# 读取每个CSV文件并绘图
for file in csv_files:
    file_path = os.path.join(folder_path, file)

    # 读取CSV文件，从第14行开始读取（跳过前13行）
    data = pd.read_csv(file_path, skiprows=13)

    # 假设第一列是频率，第二列是功率(dB)
    frequency = data.iloc[:, 0]
    power_db = data.iloc[:, 1]

    # 计算y轴的最小和最大值，以1 dB为单位调整
    min_power = np.floor(power_db.min())
    max_power = np.ceil(power_db.max())
    y_min = min_power - 1  # 给最小值留点空间
    y_max = max_power + 1  # 给最大值留点空间

    # 画图
    plt.figure()
    plt.plot(frequency, power_db)
    plt.title('inter Laser at 1548.453nm')
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Power (dB)')
    plt.ylim([y_min, y_max])  # 设置y轴范围
    plt.yticks(np.arange(y_min, y_max + 1, 1))  # 设置y轴以1 dB为间隔
    plt.grid(True)

    # 构造保存图像的路径
    output_file = os.path.join(output_folder, f'{os.path.splitext(file)[0]}.png')

    # 保存图像
    plt.savefig(output_file)
    plt.close()

print(f'所有图像已保存到: {output_folder}')




