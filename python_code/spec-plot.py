import os
import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import find_peaks

# Define folder paths
spec_folder = './1116/osa'
plot_folder_full = './1116/osa/full'
plot_folder_zoom = './1116/osa/zoom'

# Create plot folders if they don't exist
os.makedirs(plot_folder_full, exist_ok=True)
os.makedirs(plot_folder_zoom, exist_ok=True)

# Loop through all txt files in the spec folder
for filename in os.listdir(spec_folder):
    if filename.endswith('.txt'):
        # File path
        file_path = os.path.join(spec_folder, filename)

        # Read the txt file starting from the 154th row, skipping irrelevant rows
        try:
            data = pd.read_csv(file_path, sep='\s+', skiprows=153, header=None, names=['Wavelength (nm)', 'Power (dB)'])

            # Convert the data to numeric, forcing errors to NaN and dropping any rows with NaN values
            data['Wavelength (nm)'] = pd.to_numeric(data['Wavelength (nm)'], errors='coerce')
            data['Power (dB)'] = pd.to_numeric(data['Power (dB)'], errors='coerce')
            data = data.dropna()

            # Find all peaks in the data with a minimum prominence to avoid noise
            peaks, properties = find_peaks(data['Power (dB)'], prominence=5, distance=5)

            if len(peaks) == 0:
                print(f'No peaks found in {filename}')
                continue

            # Find the global maximum peak
            global_max_idx = data['Power (dB)'].idxmax()
            global_max_wavelength = data.loc[global_max_idx, 'Wavelength (nm)']

            # Find local maxima around the global maximum (2 on each side)
            peak_indices = data.iloc[peaks].index
            global_max_position = (peak_indices == global_max_idx).argmax()

            # Select two peaks before and two peaks after the global maximum, if available
            left_peaks = peak_indices[max(global_max_position - 2, 0):global_max_position]
            right_peaks = peak_indices[global_max_position + 1:min(global_max_position + 3, len(peak_indices))]

            # Combine the global maximum with the local maxima
            selected_peaks = pd.Index(left_peaks.tolist() + [global_max_idx] + right_peaks.tolist())
            top_5_peaks = data.loc[selected_peaks]

            # Prepare the text for the selected 5 peaks
            peak_text = '\n'.join([f'{i+1}: ({row["Wavelength (nm)"]:.2f} nm, {row["Power (dB)"]:.2f} dB)'
                                   for i, (_, row) in enumerate(top_5_peaks.iterrows())])

            # Plotting without zoom
            plt.figure()
            plt.plot(data['Wavelength (nm)'], data['Power (dB)'], label='Power vs Wavelength')
            plt.xlabel('Wavelength (nm)')
            plt.ylabel('Power (dB)')
            plt.title(f'{filename} Plot - Full Range')
            plt.grid(True)

            # Add the top 5 peaks as text in the upper right corner of the plot
            plt.text(0.95, 0.95, peak_text, transform=plt.gca().transAxes, fontsize=9,
                     verticalalignment='top', horizontalalignment='right', bbox=dict(facecolor='white', alpha=0.5))

            # Mark selected peaks on the plot
            plt.scatter(top_5_peaks['Wavelength (nm)'], top_5_peaks['Power (dB)'], color='red', marker='o')

            # Save the plot in the full range folder with the same name as the txt file
            plot_filename = os.path.splitext(filename)[0] + '_full.png'
            plot_path = os.path.join(plot_folder_full, plot_filename)
            plt.tight_layout()
            plt.savefig(plot_path)
            plt.close()

            # Plotting with zoom
            plt.figure()
            plt.plot(data['Wavelength (nm)'], data['Power (dB)'], label='Power vs Wavelength')
            plt.xlabel('Wavelength (nm)')
            plt.ylabel('Power (dB)')
            plt.title(f'{filename} Plot - Zoomed In')
            plt.grid(True)

            # Add the top 5 peaks as text in the upper right corner of the plot
            plt.text(0.95, 0.95, peak_text, transform=plt.gca().transAxes, fontsize=9,
                     verticalalignment='top', horizontalalignment='right', bbox=dict(facecolor='white', alpha=0.5))

            # Mark selected peaks on the plot
            plt.scatter(top_5_peaks['Wavelength (nm)'], top_5_peaks['Power (dB)'], color='red', marker='o')

            # Zoom in to ±1 nm around the global maximum
            plt.xlim(global_max_wavelength - 1, global_max_wavelength + 1)

            # Save the plot in the zoomed-in folder with the same name as the txt file
            plot_filename_zoom = os.path.splitext(filename)[0] + '_zoom.png'
            plot_path_zoom = os.path.join(plot_folder_zoom, plot_filename_zoom)
            plt.tight_layout()
            plt.savefig(plot_path_zoom)
            plt.close()

        except Exception as e:
            print(f'Error processing {filename}: {e}')

print(f'Plots saved in {plot_folder_full} and {plot_folder_zoom} folders.')

