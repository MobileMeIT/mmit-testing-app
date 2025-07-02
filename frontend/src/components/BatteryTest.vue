<template>
  <div class="battery-test-container">
    <div class="test-header">
      <h2>
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-battery-charging"><path d="M5 18H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h3.19M15 6h2a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-3.19"></path><line x1="23" y1="13" x2="23" y2="11"></line><polyline points="11 6 7 12 13 12 9 18"></polyline></svg>
        Battery Test
      </h2>
      <p class="test-description">Follow the instructions to test your battery and charging functionality.</p>
    </div>

    <div class="test-area">
      <div v-if="!batterySupported" class="state-panel">
        <div class="panel-icon error-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-alert-triangle"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
        </div>
        <h3>Battery API Not Supported</h3>
        <p>Your browser doesn't support battery status detection.</p>
      </div>

      <div v-else class="battery-view">
        <div class="status-container">
          <!-- Battery Status Display -->
          <div class="battery-status" :class="{ 'charging': isCharging }">
            <div class="battery-icon">
              <div class="battery-level" :style="{ width: batteryLevel + '%' }"></div>
              <div v-if="isCharging" class="charging-bolt">⚡</div>
            </div>
            <div class="battery-info">
              <span>{{ batteryLevel }}%</span>
              <span>{{ isCharging ? 'Charging' : 'Not Charging' }}</span>
            </div>
          </div>

          <!-- Test Instructions -->
          <div class="test-instructions">
            <div v-if="testPhase === 'initial'" class="instruction-step">
              <h3>Step 1: Connect Charger</h3>
              <p>Please connect your charger to begin the test.</p>
              <div class="timer" v-if="isCharging">
                Starting test in {{ initialDelay }}s...
              </div>
            </div>

            <div v-else-if="testPhase === 'charging1'" class="instruction-step">
              <h3>Step 2: Keep Charging</h3>
              <p>Keep your device plugged in.</p>
              <div class="timer">
                Time remaining: {{ timer }}s
              </div>
            </div>

            <div v-else-if="testPhase === 'discharging'" class="instruction-step">
              <h3>Step 3: Unplug Charger</h3>
              <p>Please unplug your charger and run on battery.</p>
              <div class="timer" v-if="!isCharging">
                Time remaining: {{ timer }}s
              </div>
            </div>

            <div v-else-if="testPhase === 'charging2'" class="instruction-step">
              <h3>Step 4: Reconnect Charger</h3>
              <p>Please plug your charger back in.</p>
              <div class="timer" v-if="isCharging">
                Time remaining: {{ timer }}s
              </div>
            </div>

            <div v-else-if="testPhase === 'complete'" class="instruction-step success">
              <h3>Test Complete!</h3>
              <p>Battery and charging functionality verified.</p>
            </div>
          </div>
        </div>

        <div class="controls-bar">
          <button @click="failTest" class="action-button danger">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-x"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            <span>Not Working</span>
          </button>
          <button 
            @click="completeTest" 
            class="action-button success"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-check"><polyline points="20 6 9 17 4 12"></polyline></svg>
            <span>Working</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'BatteryTest',
  data() {
    return {
      batterySupported: false,
      batteryManager: null,
      isCharging: false,
      batteryLevel: 0,
      testPhase: 'initial',
      timer: 5,
      initialDelay: 2,
      timerInterval: null,
      testStarted: false,
      initialBatteryLevel: 0,
      testCompleted: false,
      phasesCompleted: {
        charging1: false,
        discharging: false,
        charging2: false
      }
    }
  },
  async mounted() {
    try {
      if ('getBattery' in navigator) {
        this.batteryManager = await navigator.getBattery()
        if (this.batteryManager) {
          this.batterySupported = true
          this.setupBatteryListeners()
          this.updateBatteryStatus()
          this.initialBatteryLevel = this.batteryManager.level
        } else {
          throw new Error('Battery manager not available')
        }
      }
    } catch (error) {
      console.error('Battery API error:', error)
      this.batterySupported = false
      this.cleanup()
    }
  },
  beforeUnmount() {
    this.cleanup()
  },
  methods: {
    setupBatteryListeners() {
      if (!this.batteryManager) return

      this.batteryManager.addEventListener('chargingchange', this.handleChargingChange)
      this.batteryManager.addEventListener('levelchange', this.updateBatteryStatus)
    },

    updateBatteryStatus() {
      if (!this.batteryManager) return
      
      const previousChargingState = this.isCharging
      this.isCharging = this.batteryManager.charging
      this.batteryLevel = Math.round(this.batteryManager.level * 100)
      
      // Start test sequence when charger is first connected
      if (this.testPhase === 'initial' && this.isCharging && !this.testStarted) {
        this.testStarted = true
        this.startInitialDelay()
      }

      // Handle charging state changes
      if (previousChargingState !== this.isCharging) {
        this.handleChargingChange()
      }
    },

    handleChargingChange() {
      if (!this.batteryManager) return

      switch (this.testPhase) {
        case 'charging1':
          if (!this.isCharging) {
            this.failTest('Charger disconnected too early')
          }
          break

        case 'discharging':
          if (this.isCharging) {
            clearInterval(this.timerInterval)
            this.phasesCompleted.discharging = true
            this.startCharging2Phase()
          }
          break

        case 'charging2':
          if (!this.isCharging) {
            this.failTest('Charger disconnected during final charging phase')
          }
          break
      }
    },

    startInitialDelay() {
      this.clearTimer()
      let delay = this.initialDelay
      this.timerInterval = setInterval(() => {
        if (!this.isCharging) {
          this.clearTimer()
          return
        }
        delay--
        this.initialDelay = delay
        if (delay <= 0) {
          this.clearTimer()
          this.startCharging1Phase()
        }
      }, 1000)
    },

    startCharging1Phase() {
      if (!this.isCharging) {
        this.failTest('Charger must be connected to start charging phase')
        return
      }

      this.clearTimer()
      this.testPhase = 'charging1'
      this.timer = 5

      this.startTimer(() => {
        if (this.isCharging) {
          this.phasesCompleted.charging1 = true
          this.testPhase = 'discharging'
          this.timer = 5
        } else {
          this.failTest('Charger disconnected during first charging phase')
        }
      })
    },

    startCharging2Phase() {
      if (!this.isCharging) {
        this.failTest('Charger must be connected to start final charging phase')
        return
      }

      this.clearTimer()
      this.testPhase = 'charging2'
      this.timer = 5

      this.startTimer(() => {
        if (this.isCharging) {
          this.phasesCompleted.charging2 = true
          this.testPhase = 'complete'
          this.testCompleted = true
        } else {
          this.failTest('Charger disconnected during final charging phase')
        }
      })
    },

    startTimer(callback) {
      this.clearTimer()
      let remainingTime = this.timer
      
      this.timerInterval = setInterval(() => {
        if (!this.batterySupported || !this.batteryManager) {
          this.clearTimer()
          this.failTest('Battery API became unavailable')
          return
        }
        
        remainingTime--
        this.timer = remainingTime
        
        if (remainingTime <= 0) {
          this.clearTimer()
          callback()
        }
      }, 1000)
    },

    clearTimer() {
      if (this.timerInterval) {
        clearInterval(this.timerInterval)
        this.timerInterval = null
      }
    },

    completeTest() {
      if (this.testCompleted) {
        return;
      }
      this.$emit('test-completed', 'battery')
      this.testCompleted = true;
      this.cleanup();
    },

    failTest(reason = '') {
      console.error('Battery test failed:', reason);
      this.$emit('test-failed', 'battery');
      this.testCompleted = true;
      this.cleanup();
    },

    cleanup() {
      this.clearTimer()
      
      if (this.batteryManager) {
        this.batteryManager.removeEventListener('chargingchange', this.handleChargingChange)
        this.batteryManager.removeEventListener('levelchange', this.updateBatteryStatus)
      }
    }
  },
  computed: {
    allPhasesCompleted() {
      return this.phasesCompleted.charging1 && 
             this.phasesCompleted.discharging && 
             this.phasesCompleted.charging2
    }
  }
}
</script>

<style scoped>
.battery-test-container {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
}

.test-header {
  text-align: center;
  margin-bottom: 1.5rem;
  flex-shrink: 0;
}

.test-header h2 {
  display: inline-flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.5rem;
  font-weight: 600;
  color: #e0e0e0;
  margin-bottom: 0.5rem;
}

.test-description {
  color: #a0a0a0;
  font-size: 0.95rem;
  margin: 0;
}

.test-area {
  flex-grow: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  background-color: #1e1e1e;
  border-radius: 8px;
  overflow: hidden;
  position: relative;
}

.battery-view {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.status-container {
  width: 100%;
  max-width: 600px;
  margin: 2rem auto;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  background: #2c2c2e;
  border-radius: 12px;
  border: 1px solid #333;
  padding: 1.5rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.battery-status {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 1.5rem;
  background: #1e1e1e;
  border-radius: 8px;
  border: 1px solid #333;
}

.battery-icon {
  width: 60px;
  height: 30px;
  border: 2px solid #666;
  border-radius: 4px;
  position: relative;
  padding: 2px;
}

.battery-icon:after {
  content: '';
  position: absolute;
  right: -6px;
  top: 50%;
  transform: translateY(-50%);
  width: 4px;
  height: 10px;
  background: #666;
  border-radius: 0 2px 2px 0;
}

.battery-level {
  height: 100%;
  background: #28a745;
  border-radius: 2px;
  transition: width 0.3s ease;
}

.charging .battery-level {
  background: #ff9800;
}

.charging-bolt {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 16px;
  color: #000;
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.5);
}

.battery-info {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  color: #e0e0e0;
}

.test-instructions {
  padding: 1.5rem;
  background: #1e1e1e;
  border-radius: 8px;
  border: 1px solid #333;
}

.instruction-step {
  text-align: center;
}

.instruction-step h3 {
  color: #e0e0e0;
  margin: 0 0 1rem;
}

.instruction-step p {
  color: #a0a0a0;
  margin: 0 0 1rem;
}

.timer {
  font-size: 1.25rem;
  font-weight: 600;
  color: #ff9800;
}

.success h3 {
  color: #28a745;
}

.controls-bar {
  width: 100%;
  display: flex;
  justify-content: center;
  gap: 1rem;
  padding: 1rem;
  background-color: #2c2c2e;
  border-top: 1px solid #444;
  margin-top: auto;
}

.action-button {
  min-width: 140px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  border: none;
  color: white;
}

.action-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.action-button:not(:disabled):hover {
  transform: translateY(-2px);
}

.action-button.success {
  background-color: #28a745;
}

.action-button.success:not(:disabled):hover {
  background-color: #218838;
}

.action-button.danger {
  background-color: #dc3545;
}

.action-button.danger:not(:disabled):hover {
  background-color: #c82333;
}

.panel-icon {
  margin-bottom: 1rem;
  color: #ff6b00;
}

.panel-icon.error-icon {
  color: #dc3545;
}

.state-panel {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 2rem;
  color: #cccccc;
  flex-grow: 1;
}

.state-panel h3 {
  font-size: 1.25rem;
  font-weight: 600;
  margin-top: 1rem;
  margin-bottom: 0.5rem;
  color: #ffffff;
}

.state-panel p {
  max-width: 350px;
  margin-bottom: 1.5rem;
  line-height: 1.6;
}
</style> 