<template>
  <div class="microphone-test">
    <div class="test-header">
      <h3>🎤 Microphone Test</h3>
      <p>We'll test your microphone to ensure it's working properly</p>
    </div>

    <div class="test-content">
      <div v-if="!permissionGranted && !permissionDenied" class="permission-request">
        <div class="permission-icon">🔒</div>
        <h4>Microphone Permission Required</h4>
        <p>Please allow microphone access to test your audio input</p>
        <button @click="requestPermission" class="permission-button">
          Grant Microphone Access
        </button>
      </div>

      <div v-else-if="permissionDenied" class="permission-denied">
        <div class="error-icon">❌</div>
        <h4>Microphone Access Denied</h4>
        <p>Microphone access was denied. Please enable microphone permissions in your browser settings and try again.</p>
        <button @click="requestPermission" class="retry-button">
          Try Again
        </button>
      </div>

      <div v-else-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Initializing microphone...</p>
      </div>

      <div v-else-if="error" class="error">
        <div class="error-icon">⚠️</div>
        <h4>Microphone Error</h4>
        <p>{{ error }}</p>
        <button @click="retryTest" class="retry-button">
          Retry Test
        </button>
      </div>

      <div v-else class="microphone-container">
        <div class="audio-visualizer">
          <div class="volume-meter">
            <div class="volume-bar" :style="{ height: volumeLevel + '%' }"></div>
          </div>
          <div class="volume-level-text">
            Volume: {{ Math.round(volumeLevel) }}%
          </div>
        </div>

        <div class="microphone-controls">
          <div class="status-indicator" :class="{ active: isRecording }">
            <div class="status-dot"></div>
            <span>{{ isRecording ? 'Recording...' : 'Ready to Record' }}</span>
          </div>

          <div class="recording-section">
            <button 
              @click="toggleRecording" 
              class="record-button"
              :class="{ recording: isRecording }"
            >
              {{ isRecording ? '⏹️ Stop Recording' : '🎙️ Start Recording' }}
            </button>
            
            <div v-if="recordingDuration > 0" class="recording-timer">
              Recording: {{ recordingDuration }}s
            </div>
          </div>

          <div v-if="audioBlob" class="playback-section">
            <h4>Test Recording</h4>
            <audio :src="audioUrl" controls class="audio-player"></audio>
            <p class="playback-instruction">Play back your recording to verify it sounds clear</p>
          </div>

          <div class="test-actions">
            <button @click="completeTest" class="action-button success" :disabled="!audioBlob">
              ✅ Microphone Works Fine
            </button>
            <button @click="failTest" class="action-button danger">
              ❌ Microphone Not Working
            </button>
          </div>
        </div>

        <div class="test-instructions">
          <h4>Testing Instructions:</h4>
          <ol>
            <li>Speak into your microphone - you should see the volume meter respond</li>
            <li>Click "Start Recording" and speak for a few seconds</li>
            <li>Click "Stop Recording" and play back the audio</li>
            <li>If you can hear your voice clearly, click "Microphone Works Fine"</li>
          </ol>
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
      mediaRecorder: null,
      audioContext: null,
      analyser: null,
      permissionGranted: false,
      permissionDenied: false,
      loading: false,
      error: null,
      isRecording: false,
      volumeLevel: 0,
      audioBlob: null,
      audioUrl: null,
      recordingDuration: 0,
      recordingTimer: null,
      animationFrame: null
    }
  },
  mounted() {
    this.checkMicrophoneSupport()
  },
  beforeUnmount() {
    this.cleanup()
  },
  methods: {
    checkMicrophoneSupport() {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        this.error = 'Microphone is not supported in this browser'
        return
      }
    },

    async requestPermission() {
      this.loading = true
      this.error = null
      this.permissionDenied = false

      try {
        const constraints = {
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true
          }
        }

        this.stream = await navigator.mediaDevices.getUserMedia(constraints)
        this.permissionGranted = true
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

    setupAudioAnalysis() {
      try {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
        this.analyser = this.audioContext.createAnalyser()
        
        const source = this.audioContext.createMediaStreamSource(this.stream)
        source.connect(this.analyser)
        
        this.analyser.fftSize = 256
        this.startVolumeMonitoring()
        this.loading = false
      } catch (err) {
        console.error('Audio analysis setup error:', err)
        this.error = 'Failed to set up audio analysis'
        this.loading = false
      }
    },

    startVolumeMonitoring() {
      const bufferLength = this.analyser.frequencyBinCount
      const dataArray = new Uint8Array(bufferLength)

      const updateVolume = () => {
        if (!this.analyser) return

        this.analyser.getByteFrequencyData(dataArray)
        
        let sum = 0
        for (let i = 0; i < bufferLength; i++) {
          sum += dataArray[i]
        }
        
        const average = sum / bufferLength
        this.volumeLevel = (average / 255) * 100
        
        this.animationFrame = requestAnimationFrame(updateVolume)
      }

      updateVolume()
    },

    toggleRecording() {
      if (this.isRecording) {
        this.stopRecording()
      } else {
        this.startRecording()
      }
    },

    startRecording() {
      if (!this.stream) return

      try {
        this.mediaRecorder = new MediaRecorder(this.stream)
        const chunks = []

        this.mediaRecorder.ondataavailable = (event) => {
          if (event.data.size > 0) {
            chunks.push(event.data)
          }
        }

        this.mediaRecorder.onstop = () => {
          this.audioBlob = new Blob(chunks, { type: 'audio/wav' })
          this.audioUrl = URL.createObjectURL(this.audioBlob)
        }

        this.mediaRecorder.start()
        this.isRecording = true
        this.recordingDuration = 0
        
        this.recordingTimer = setInterval(() => {
          this.recordingDuration++
        }, 1000)

      } catch (err) {
        console.error('Recording start error:', err)
        this.error = 'Failed to start recording'
      }
    },

    stopRecording() {
      if (this.mediaRecorder && this.mediaRecorder.state === 'recording') {
        this.mediaRecorder.stop()
      }
      
      this.isRecording = false
      
      if (this.recordingTimer) {
        clearInterval(this.recordingTimer)
        this.recordingTimer = null
      }
    },

    completeTest() {
      this.$emit('test-completed')
      this.cleanup()
    },

    failTest() {
      this.$emit('test-failed')
      this.cleanup()
    },

    retryTest() {
      this.cleanup()
      this.error = null
      this.permissionDenied = false
      this.audioBlob = null
      this.audioUrl = null
      this.recordingDuration = 0
      this.requestPermission()
    },

    cleanup() {
      if (this.animationFrame) {
        cancelAnimationFrame(this.animationFrame)
        this.animationFrame = null
      }

      if (this.recordingTimer) {
        clearInterval(this.recordingTimer)
        this.recordingTimer = null
      }

      if (this.mediaRecorder && this.mediaRecorder.state === 'recording') {
        this.mediaRecorder.stop()
      }

      if (this.stream) {
        this.stream.getTracks().forEach(track => track.stop())
        this.stream = null
      }

      if (this.audioContext && this.audioContext.state !== 'closed') {
        this.audioContext.close()
        this.audioContext = null
      }

      if (this.audioUrl) {
        URL.revokeObjectURL(this.audioUrl)
        this.audioUrl = null
      }
    }
  }
}
</script>

<style scoped>
.microphone-test {
  width: 100%;
}

.test-header {
  text-align: center;
  margin-bottom: 2rem;
}

.test-header h3 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: #ffffff;
  font-weight: 600;
}

.test-header p {
  color: #cccccc;
}

.permission-request,
.permission-denied,
.loading,
.error {
  text-align: center;
  padding: 2rem;
  color: #cccccc;
}

.permission-icon,
.error-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.permission-request h4,
.permission-denied h4,
.error h4 {
  margin-bottom: 1rem;
  color: #ffffff;
  font-weight: 600;
}

.permission-button,
.retry-button {
  padding: 0.8rem 2rem;
  background: #ff6b00;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 600;
}

.permission-button:hover,
.retry-button:hover {
  background: #ff8533;
  transform: translateY(-2px);
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #333333;
  border-top: 4px solid #ff6b00;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.microphone-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.audio-visualizer {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 2rem;
  background: #262626;
  border-radius: 8px;
  border: 1px solid #333333;
}

.volume-meter {
  width: 60px;
  height: 200px;
  background: #333333;
  border-radius: 30px;
  position: relative;
  overflow: hidden;
  border: 2px solid #555555;
}

.volume-bar {
  position: absolute;
  bottom: 0;
  width: 100%;
  background: linear-gradient(to top, #ff6b00, #ff8533, #ffaa66);
  border-radius: 30px;
  transition: height 0.1s ease;
}

.volume-level-text {
  font-weight: 500;
  color: #ffffff;
}

.microphone-controls {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  align-items: center;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  background: #f0f0f0;
  font-size: 0.9rem;
  color: #666;
}

.status-indicator.active {
  background: rgba(244, 67, 54, 0.1);
  color: #f44336;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #ccc;
}

.status-indicator.active .status-dot {
  background: #f44336;
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.5; }
  100% { opacity: 1; }
}

.recording-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.record-button {
  padding: 1rem 2rem;
  border: none;
  border-radius: 50px;
  font-size: 1.1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 600;
  background: #ff6b00;
  color: white;
}

.record-button.recording {
  background: #f44336;
  animation: recordingPulse 2s infinite;
}

@keyframes recordingPulse {
  0% { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0.7); }
  70% { box-shadow: 0 0 0 10px rgba(244, 67, 54, 0); }
  100% { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0); }
}

.record-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.recording-timer {
  font-size: 1.2rem;
  font-weight: 600;
  color: #f44336;
}

.playback-section {
  text-align: center;
  padding: 1.5rem;
  background: #262626;
  border-radius: 8px;
  border: 1px solid #333333;
  width: 100%;
  max-width: 400px;
}

.playback-section h4 {
  margin-bottom: 1rem;
  color: #ffffff;
  font-weight: 600;
}

.audio-player {
  width: 100%;
  margin-bottom: 1rem;
}

.playback-instruction {
  color: #cccccc;
  font-size: 0.9rem;
}

.test-actions {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  justify-content: center;
}

.action-button {
  padding: 0.8rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 500;
}

.action-button.success {
  background: #ff6b00;
  color: white;
}

.action-button.danger {
  background: #f44336;
  color: white;
}

.action-button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.action-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.test-instructions {
  background: #262626;
  padding: 1.5rem;
  border-radius: 8px;
  border-left: 4px solid #ff6b00;
  border: 1px solid #333333;
}

.test-instructions h4 {
  margin-bottom: 1rem;
  color: #ff6b00;
  font-weight: 600;
}

.test-instructions ol {
  color: #cccccc;
  line-height: 1.6;
}

.test-instructions li {
  margin-bottom: 0.5rem;
}

@media (max-width: 768px) {
  .microphone-container {
    gap: 1.5rem;
  }
  
  .audio-visualizer {
    padding: 1.5rem;
  }
  
  .volume-meter {
    width: 50px;
    height: 150px;
  }
  
  .test-actions {
    flex-direction: column;
    align-items: center;
  }
  
  .action-button {
    width: 100%;
    max-width: 250px;
  }
}
</style> 