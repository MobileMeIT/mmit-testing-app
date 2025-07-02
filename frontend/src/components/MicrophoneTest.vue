<template>
  <div class="mic-test-container">
    <div class="test-header">
      <h2>
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-mic"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"></path><path d="M19 10v2a7 7 0 0 1-14 0v-2"></path><line x1="12" y1="19" x2="12" y2="23"></line><line x1="8" y1="23" x2="16" y2="23"></line></svg>
        Microphone Test
      </h2>
      <p class="test-description">Speak into your microphone and check if the volume bar responds.</p>
    </div>

    <div class="test-area">
      <!-- Initial State: Checking Permission -->
      <div v-if="checkingPermission" class="state-panel checking-permission">
        <div class="spinner"></div>
        <p>Checking for microphone permissions...</p>
      </div>

      <!-- Permission Request State -->
      <div v-else-if="!permissionGranted && !permissionDenied" class="state-panel">
        <div class="panel-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-lock"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
        </div>
        <h3>Microphone Permission Required</h3>
        <p>Please allow microphone access to test your audio input.</p>
        <button @click="requestPermission" class="action-button primary">
          Grant Microphone Access
        </button>
      </div>

      <!-- Permission Denied State -->
      <div v-else-if="permissionDenied" class="state-panel">
        <div class="panel-icon error-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-x-circle"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
        </div>
        <h3>Microphone Access Denied</h3>
        <p>Please enable microphone permissions in your browser settings and try again.</p>
        <button @click="requestPermission" class="action-button primary">
          Try Again
        </button>
      </div>
      
      <!-- Loading or Error State -->
      <div v-else-if="loading || error" class="state-panel">
        <div v-if="loading" class="loading-state">
            <div class="spinner"></div>
            <p>Initializing microphone...</p>
        </div>
        <div v-if="error" class="error-state">
            <div class="panel-icon error-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-alert-triangle"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
            </div>
            <h3>Microphone Error</h3>
            <p>{{ error }}</p>
            <button @click="retryTest" class="action-button primary">Retry Test</button>
        </div>
      </div>

      <!-- Main Mic View -->
      <div v-else class="mic-view">
        <div class="visualizer-container">
          <canvas ref="waveformCanvas" class="waveform-display"></canvas>
          <div class="volume-meter">
            <div class="volume-bar" :style="{ width: volumeLevel + '%' }"></div>
          </div>
          <div class="mic-selector">
            <label for="micSelect">Microphone:</label>
            <select 
              id="micSelect" 
              v-model="selectedMicId" 
              @change="switchMicrophone"
              :disabled="loading || availableMics.length <= 0"
            >
              <option v-if="availableMics.length <= 0" value="">No microphones found</option>
              <option 
                v-for="mic in availableMics" 
                :key="mic.deviceId" 
                :value="mic.deviceId"
              >
                {{ mic.label || `Microphone ${mic.deviceId.slice(0, 4)}...` }}
              </option>
            </select>
          </div>
        </div>
        <div class="controls-bar">
          <button @click="failTest" class="action-button danger">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-x"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            <span>Not Working</span>
          </button>
          <button @click="completeTest" class="action-button success">
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
  name: 'MicrophoneTest',
  data() {
    return {
      stream: null,
      audioContext: null,
      analyser: null,
      permissionGranted: false,
      permissionDenied: false,
      loading: false,
      error: null,
      volumeLevel: 0,
      animationFrame: null,
      checkingPermission: true,
      waveformDataArray: null,
      canvasCtx: null,
      canvasWidth: 0,
      canvasHeight: 0,
      availableMics: [],
      selectedMicId: ''
    }
  },
  mounted() {
    this.initializeTest();
  },
  beforeUnmount() {
    this.cleanup()
  },
  methods: {
    async initializeTest() {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        this.error = 'Microphone is not supported in this browser';
        this.loading = false;
        this.checkingPermission = false;
        return;
      }
      
      if (typeof navigator.permissions?.query !== 'function') {
        console.warn('Permissions API not supported. User must manually grant permission.');
        this.checkingPermission = false;
        // Fallback to old behavior: show permission request
        return;
      }

      try {
        const permissionStatus = await navigator.permissions.query({ name: 'microphone' });
        this.handlePermissionState(permissionStatus.state);
        permissionStatus.onchange = () => {
          this.handlePermissionState(permissionStatus.state);
        };
      } catch (err) {
        console.error("Error querying microphone permissions:", err);
        this.error = "Could not verify microphone permissions.";
        this.checkingPermission = false;
      }
    },

    handlePermissionState(state) {
      this.checkingPermission = false;
      if (state === 'granted') {
        this.permissionGranted = true;
        this.permissionDenied = false;
        if (!this.stream) {
          this.requestPermission(false); // false to not show loading screen
        }
      } else if (state === 'prompt') {
        this.permissionGranted = false;
        this.permissionDenied = false;
      } else if (state === 'denied') {
        this.permissionDenied = true;
        this.permissionGranted = false;
        this.cleanup();
      }
    },

    async requestPermission(showLoading = true) {
      this.loading = showLoading;
      this.error = null
      this.permissionDenied = false

      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          this.error = 'Microphone is not supported in this browser';
          this.loading = false;
          return;
      }

      try {
        const constraints = {
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
            ...(this.selectedMicId && { deviceId: { exact: this.selectedMicId } })
          }
        }

        this.stream = await navigator.mediaDevices.getUserMedia(constraints)
        this.permissionGranted = true
        
        // Enumerate available microphones after permission is granted
        await this.enumerateMicrophones()
        
        this.setupAudioAnalysis()
      } catch (err) {
        console.error('Microphone access error:', err)
        this.loading = false

        if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
          this.permissionDenied = true
        } else if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') {
          this.error = 'No microphone device found'
        } else if (err.name === 'NotReadableError' || err.name === 'TrackStartError') {
          this.error = 'Microphone is already in use by another application'
        } else {
          this.error = `Microphone error: ${err.message}`
        }
      }
    },

    async enumerateMicrophones() {
      try {
        const devices = await navigator.mediaDevices.enumerateDevices()
        this.availableMics = devices.filter(device => device.kind === 'audioinput')
        
        // If we haven't selected a mic yet and we have available mics,
        // select the first one
        if (!this.selectedMicId && this.availableMics.length > 0) {
          this.selectedMicId = this.availableMics[0].deviceId
        }
        
        console.log('Available microphones:', this.availableMics)
      } catch (err) {
        console.error('Error enumerating microphones:', err)
      }
    },

    async switchMicrophone() {
      if (this.loading) return
      
      this.loading = true
      this.cleanup()
      await this.requestPermission()
    },

    setupAudioAnalysis() {
      try {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
        this.analyser = this.audioContext.createAnalyser()
        
        const source = this.audioContext.createMediaStreamSource(this.stream)
        source.connect(this.analyser)
        
        this.analyser.fftSize = 2048 // Increased for better waveform resolution
        this.waveformDataArray = new Uint8Array(this.analyser.frequencyBinCount)
        
        // Setup canvas
        const canvas = this.$refs.waveformCanvas
        this.canvasCtx = canvas.getContext('2d')
        this.resizeCanvas()
        window.addEventListener('resize', this.resizeCanvas)
        
        this.startVolumeMonitoring()
        this.loading = false
      } catch (err) {
        console.error('Audio analysis setup error:', err)
        this.error = 'Failed to set up audio analysis'
        this.loading = false
      }
    },

    resizeCanvas() {
      const canvas = this.$refs.waveformCanvas
      if (!canvas) return
      
      canvas.width = canvas.offsetWidth * window.devicePixelRatio
      canvas.height = canvas.offsetHeight * window.devicePixelRatio
      this.canvasWidth = canvas.width
      this.canvasHeight = canvas.height
      
      if (this.canvasCtx) {
        this.canvasCtx.scale(window.devicePixelRatio, window.devicePixelRatio)
      }
    },

    startVolumeMonitoring() {
      const updateVisuals = () => {
        if (!this.analyser || !this.canvasCtx) return

        // Update volume bar
        this.analyser.getByteTimeDomainData(this.waveformDataArray)
        let sumSquares = 0.0
        for (const amplitude of this.waveformDataArray) {
          const val = (amplitude / 128.0) - 1.0
          sumSquares += val * val
        }
        const rms = Math.sqrt(sumSquares / this.waveformDataArray.length)
        this.volumeLevel = rms * 100 * 2 // Multiplier for better visualization

        // Draw waveform
        const canvas = this.$refs.waveformCanvas
        const ctx = this.canvasCtx
        const width = canvas.offsetWidth
        const height = canvas.offsetHeight
        
        ctx.fillStyle = '#1a1a1a'
        ctx.fillRect(0, 0, width, height)
        
        ctx.lineWidth = 2
        ctx.strokeStyle = '#ff9800'
        ctx.beginPath()
        
        const sliceWidth = width / this.waveformDataArray.length
        let x = 0
        
        for (let i = 0; i < this.waveformDataArray.length; i++) {
          const v = this.waveformDataArray[i] / 128.0
          const y = v * height / 2
          
          if (i === 0) {
            ctx.moveTo(x, y)
          } else {
            ctx.lineTo(x, y)
          }
          
          x += sliceWidth
        }
        
        ctx.lineTo(width, height / 2)
        ctx.stroke()

        this.animationFrame = requestAnimationFrame(updateVisuals)
      }

      updateVisuals()
    },

    completeTest() {
      this.$emit('test-completed', 'microphone')
      this.cleanup()
    },

    failTest() {
      this.$emit('test-failed', 'microphone')
      this.cleanup()
    },

    retryTest() {
      this.error = null
      this.permissionDenied = false
      this.loading = true
      this.cleanup()
      this.requestPermission()
    },

    cleanup() {
      if (this.animationFrame) {
        cancelAnimationFrame(this.animationFrame)
        this.animationFrame = null
      }
      
      window.removeEventListener('resize', this.resizeCanvas)
      
      if (this.stream) {
        this.stream.getTracks().forEach(track => track.stop())
        this.stream = null
      }
      
      if (this.audioContext) {
        this.audioContext.close()
        this.audioContext = null
      }
      
      this.analyser = null
      this.canvasCtx = null
    }
  }
}
</script>

<style scoped>
.mic-test-container {
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

/* --- State Panels (Permission, Error, Loading) --- */
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

.panel-icon {
  margin-bottom: 1rem;
  color: #ff6b00;
}

.panel-icon.error-icon {
  color: #dc3545;
}

.state-panel.checking-permission p {
  margin-top: 1rem;
  font-size: 1rem;
  color: #a0a0a0;
}

/* --- Main Mic View --- */
.mic-view {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.visualizer-container {
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

.waveform-display {
  width: 100%;
  height: 120px;
  background: #141414;
  border-radius: 8px;
  overflow: hidden;
  position: relative;
  aspect-ratio: 16/9;
}

.volume-meter {
  width: 100%;
  height: 8px;
  background: #141414;
  border-radius: 4px;
  overflow: hidden;
  position: relative;
}

.volume-bar {
  height: 100%;
  background: #ff9800;
  transition: width 0.1s ease-out;
  border-radius: 4px;
  box-shadow: 0 0 10px rgba(255, 152, 0, 0.3);
}

/* --- Controls Bar --- */
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

.action-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.3);
}

.action-button.primary {
  background-color: #ff6b00;
}
.action-button.primary:hover {
  background-color: #e65c00;
}

.action-button.success {
  background-color: #28a745;
}
.action-button.success:hover {
  background-color: #218838;
}

.action-button.danger {
  background-color: #dc3545;
}
.action-button.danger:hover {
  background-color: #c82333;
}

.spinner {
  border: 4px solid rgba(255, 255, 255, 0.2);
  border-left-color: #ff6b00;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.mic-selector {
  padding: 1rem 0 0 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  border-top: 1px solid #333;
}

.mic-selector label {
  color: #e0e0e0;
  font-size: 0.95rem;
}

.mic-selector select {
  padding: 0.5rem;
  border-radius: 4px;
  border: 1px solid #444;
  background: #1a1a1a;
  color: #e0e0e0;
  font-size: 0.95rem;
  cursor: pointer;
  min-width: 200px;
}

.mic-selector select:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.mic-selector select:focus {
  outline: none;
  border-color: #ff6b00;
}

.mic-selector select option {
  background: #1a1a1a;
  color: #e0e0e0;
}
</style>