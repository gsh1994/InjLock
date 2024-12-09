import os
import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import find_peaks

# 文件路径
vna_folder = './1023/vna/10db/      '
output_folder = os.path.join(vna_folder, 'vna_plot')

# 如果输出文件夹不存在，则创建
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# 读取 vna 文件夹下的所有 csv 文件
for filename in os.listdir(vna_folder):
    if filename.endswith('.csv'):
        file_path = os.path.join(vna_folder, filename)
        base_name = filename[:-4].lower()

        # 读取从第14行开始的数据
        data = pd.read_csv(file_path, skiprows=13, header=None)
        data.columns = ['Frequency (Hz)', 'Power (dB)']  # 添加列名

        # 查找峰值
        peaks, _ = find_peaks(data['Power (dB)'], height=None, distance=1000)

        # 获取峰值的高度，并找到最大的三个峰值
        peak_heights = data['Power (dB)'][peaks]
        largest_peaks = peak_heights.nlargest(3).index

        # 绘图
        plt.figure()
        plt.plot(data['Frequency (Hz)'] / 1e9, data['Power (dB)'], label=base_name)
        plt.xlabel('Frequency (GHz)')
        plt.ylabel('Power (dB)')
        plt.title(base_name)
        plt.legend(loc='lower right')  # 图例放在右下角

        # 标记最大的三个峰值
        for peak in largest_peaks:
            plt.plot(data['Frequency (Hz)'][peak] / 1e9, data['Power (dB)'][peak], 'ro')  # 红点标记
            plt.text(data['Frequency (Hz)'][peak] / 1e9, data['Power (dB)'][peak],
                     f'{data["Frequency (Hz)"][peak] / 1e9:.4f} GHz',
                     fontsize=8, verticalalignment='bottom')

        # 保存图表到 vna_plot 文件夹
        output_path = os.path.join(output_folder, f'{filename[:-4]}.png')
        plt.tight_layout()
        plt.savefig(output_path)

        # 关闭当前图表以防止内存泄漏
        plt.close()

print(f"所有图表已保存到 {output_folder} 文件夹中。")




