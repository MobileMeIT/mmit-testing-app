const { app, BrowserWindow, ipcMain, dialog, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const { spawn, exec } = require('child_process');
const os = require('os');

// Enhanced hardware testing capabilities for bootable version
class HardwareTestingApp {
  constructor() {
    this.mainWindow = null;
    this.testResults = {};
    this.systemInfo = {};
    this.isBootableVersion = true;
  }

  async createWindow() {
    // Create the browser window
    this.mainWindow = new BrowserWindow({
      width: 1200,
      height: 800,
      fullscreen: true, // Start fullscreen for bootable version
      frame: false, // Remove window frame for kiosk mode
      webPreferences: {
        nodeIntegration: true,
        contextIsolation: false,
        enableRemoteModule: true
      },
      icon: path.join(__dirname, 'assets/icon.png')
    });

    // Load the app
    if (fs.existsSync(path.join(__dirname, 'dist/index.html'))) {
      await this.mainWindow.loadFile(path.join(__dirname, 'dist/index.html'));
    } else {
      await this.mainWindow.loadURL('http://localhost:3000');
    }

    // Open DevTools in development
    if (process.env.NODE_ENV === 'development') {
      this.mainWindow.webContents.openDevTools();
    }

    // Collect system information
    await this.collectSystemInfo();
  }

  async collectSystemInfo() {
    this.systemInfo = {
      platform: os.platform(),
      arch: os.arch(),
      release: os.release(),
      hostname: os.hostname(),
      uptime: os.uptime(),
      totalMemory: os.totalmem(),
      freeMemory: os.freemem(),
      cpus: os.cpus(),
      networkInterfaces: os.networkInterfaces(),
      loadAverage: os.loadavg(),
      timestamp: new Date().toISOString()
    };

    // Enhanced hardware detection for bootable version
    try {
      // Get detailed hardware info using lshw
      await this.executeCommand('lshw -json').then(result => {
        try {
          this.systemInfo.detailedHardware = JSON.parse(result);
        } catch (e) {
          console.warn('Failed to parse lshw output:', e);
        }
      });

      // Get USB devices
      await this.executeCommand('lsusb').then(result => {
        this.systemInfo.usbDevices = result.split('\n').filter(line => line.trim());
      });

      // Get PCI devices
      await this.executeCommand('lspci').then(result => {
        this.systemInfo.pciDevices = result.split('\n').filter(line => line.trim());
      });

      // Get storage devices
      await this.executeCommand('lsblk -J').then(result => {
        try {
          this.systemInfo.storageDevices = JSON.parse(result);
        } catch (e) {
          console.warn('Failed to parse lsblk output:', e);
        }
      });

      // Get network interfaces with details
      await this.executeCommand('ip addr show').then(result => {
        this.systemInfo.networkDetails = result;
      });

    } catch (error) {
      console.warn('Some hardware detection commands failed:', error);
    }
  }

  executeCommand(command) {
    return new Promise((resolve, reject) => {
      exec(command, (error, stdout, stderr) => {
        if (error) {
          reject(`Error: ${error.message}`);
          return;
        }
        if (stderr) {
          console.warn(`Warning: ${stderr}`);
        }
        resolve(stdout);
      });
    });
  }

  setupIpcHandlers() {
    // System information
    ipcMain.handle('get-system-info', () => this.systemInfo);

    // Enhanced battery testing
    ipcMain.handle('get-battery-info', async () => {
      try {
        const acpiResult = await this.executeCommand('acpi -b');
        const uptimeResult = await this.executeCommand('cat /proc/uptime');
        
        return {
          acpi: acpiResult,
          uptime: uptimeResult,
          timestamp: Date.now()
        };
      } catch (error) {
        return { error: error.message };
      }
    });

    // CPU testing
    ipcMain.handle('run-cpu-stress-test', async (event, duration = 30) => {
      try {
        const result = await this.executeCommand(`stress --cpu ${os.cpus().length} --timeout ${duration}s --verbose`);
        return { success: true, output: result };
      } catch (error) {
        return { success: false, error: error.message };
      }
    });

    // Memory testing
    ipcMain.handle('run-memory-test', async (event, testSize = '100M') => {
      try {
        const result = await this.executeCommand(`memtester ${testSize} 1`);
        return { success: true, output: result };
      } catch (error) {
        return { success: false, error: error.message };
      }
    });

    // Storage testing
    ipcMain.handle('test-storage-devices', async () => {
      try {
        const devices = await this.executeCommand('lsblk -d -o NAME,SIZE,TYPE,MODEL');
        const smartResults = {};
        
        // Get SMART data for each device
        const deviceNames = devices.split('\n')
          .slice(1)
          .filter(line => line.trim())
          .map(line => line.split(/\s+/)[0])
          .filter(name => name.startsWith('sd') || name.startsWith('nvme'));

        for (const device of deviceNames) {
          try {
            const smartData = await this.executeCommand(`smartctl -a /dev/${device}`);
            smartResults[device] = smartData;
          } catch (error) {
            smartResults[device] = `Error: ${error.message}`;
          }
        }

        return {
          devices: devices,
          smartData: smartResults
        };
      } catch (error) {
        return { error: error.message };
      }
    });

    // Network testing
    ipcMain.handle('test-network-interfaces', async () => {
      try {
        const interfaces = await this.executeCommand('ip link show');
        const wireless = await this.executeCommand('iwconfig').catch(() => 'No wireless interfaces');
        
        return {
          interfaces: interfaces,
          wireless: wireless
        };
      } catch (error) {
        return { error: error.message };
      }
    });

    // Temperature monitoring
    ipcMain.handle('get-temperature-info', async () => {
      try {
        const sensors = await this.executeCommand('sensors -A -j').catch(() => '{}');
        const thermal = await this.executeCommand('cat /proc/acpi/thermal_zone/*/temperature').catch(() => 'N/A');
        
        return {
          sensors: JSON.parse(sensors),
          thermal: thermal
        };
      } catch (error) {
        return { error: error.message };
      }
    });

    // Display testing
    ipcMain.handle('get-display-info', async () => {
      try {
        const xrandr = await this.executeCommand('xrandr --verbose');
        const fbset = await this.executeCommand('fbset -s').catch(() => 'N/A');
        
        return {
          xrandr: xrandr,
          fbset: fbset
        };
      } catch (error) {
        return { error: error.message };
      }
    });

    // Save test results
    ipcMain.handle('save-test-results', async (event, results) => {
      try {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const filename = `hardware-test-results-${timestamp}.json`;
        const filepath = path.join('/tmp', filename);
        
        const reportData = {
          timestamp: new Date().toISOString(),
          systemInfo: this.systemInfo,
          testResults: results,
          bootableVersion: true
        };
        
        fs.writeFileSync(filepath, JSON.stringify(reportData, null, 2));
        
        // Also try to save to USB drive if mounted
        const usbPaths = ['/media', '/mnt', '/run/media'];
        for (const basePath of usbPaths) {
          try {
            const dirs = fs.readdirSync(basePath);
            for (const dir of dirs) {
              const usbPath = path.join(basePath, dir);
              if (fs.existsSync(usbPath) && fs.statSync(usbPath).isDirectory()) {
                const usbFilepath = path.join(usbPath, filename);
                fs.copyFileSync(filepath, usbFilepath);
                console.log(`Results saved to USB: ${usbFilepath}`);
                break;
              }
            }
          } catch (e) {
            // Continue trying other paths
          }
        }
        
        return { success: true, filepath: filepath };
      } catch (error) {
        return { success: false, error: error.message };
      }
    });

    // System control
    ipcMain.handle('system-shutdown', async () => {
      try {
        await this.executeCommand('shutdown -h now');
        return { success: true };
      } catch (error) {
        return { success: false, error: error.message };
      }
    });

    ipcMain.handle('system-reboot', async () => {
      try {
        await this.executeCommand('reboot');
        return { success: true };
      } catch (error) {
        return { success: false, error: error.message };
      }
    });

    // Exit to command line
    ipcMain.handle('exit-to-console', () => {
      app.quit();
    });
  }
}

// Application lifecycle
const hardwareApp = new HardwareTestingApp();

app.whenReady().then(async () => {
  await hardwareApp.createWindow();
  hardwareApp.setupIpcHandlers();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', async () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    await hardwareApp.createWindow();
  }
});

// Handle any uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
}); 