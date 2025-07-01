<template>
  <div class="webcam-test">
    <div class="test-header">
      <h3>📹 Webcam Test</h3>
      <p>We'll test your camera to ensure it's working properly</p>
    </div>

    <div class="test-content">
      <div v-if="!permissionGranted && !permissionDenied" class="permission-request">
        <div class="permission-icon">🔒</div>
        <h4>Camera Permission Required</h4>
        <p>Please allow camera access to test your webcam</p>
        <button @click="requestPermission" class="permission-button">
          Grant Camera Access
        </button>
      </div>

      <div v-else-if="permissionDenied" class="permission-denied">
        <div class="error-icon">❌</div>
        <h4>Camera Access Denied</h4>
        <p>Camera access was denied. Please enable camera permissions in your browser settings and try again.</p>
        <button @click="requestPermission" class="retry-button">
          Try Again
        </button>
      </div>

      <div v-else-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Initializing camera...</p>
        <button v-if="showRetryButton" @click="forceRetry" class="retry-button" style="margin-top: 1rem;">
          Camera Taking Too Long? Try Again
        </button>
      </div>

      <div v-else-if="error" class="error">
        <div class="error-icon">⚠️</div>
        <h4>Camera Error</h4>
        <p>{{ error }}</p>
        <button @click="retryTest" class="retry-button">
          Retry Test
        </button>
      </div>

      <div v-else class="camera-container">
        <video
          ref="videoElement"
          autoplay
          muted
          playsinline
          controls="false"
          class="camera-preview"
        ></video>
        
        <div class="camera-controls">
          <div class="status-indicator" :class="{ active: isStreaming }">
            <div class="status-dot"></div>
            <span>{{ isStreaming ? 'Camera Active' : 'Camera Inactive' }}</span>
          </div>
          
          <div class="test-actions">
            <button @click="takeSnapshot" class="action-button primary">
              📸 Take Test Photo
            </button>
            <button @click="completeTest" class="action-button success" :disabled="!snapshotTaken">
              ✅ Camera Works Fine
            </button>
            <button @click="failTest" class="action-button danger">
              ❌ Camera Not Working
            </button>
          </div>
        </div>

        <div v-if="snapshotTaken" class="snapshot-preview">
          <h4>Test Photo Captured</h4>
          <canvas ref="snapshotCanvas" class="snapshot-canvas"></canvas>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'WebcamTest',
  data() {
    return {
      stream: null,
      permissionGranted: false,
      permissionDenied: false,
      loading: false,
      error: null,
      isStreaming: false,
      snapshotTaken: false,
      showRetryButton: false,
      retryTimer: null
    }
  },
  mounted() {
    this.checkCameraSupport()
  },
  beforeUnmount() {
    this.stopCamera()
  },
  methods: {
    checkCameraSupport() {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        this.error = 'Camera is not supported in this browser'
        return
      }
    },
    
    async requestPermission() {
      this.loading = true
      this.error = null
      this.permissionDenied = false
      this.showRetryButton = false
      
      // Show retry button after 3 seconds if still loading
      this.retryTimer = setTimeout(() => {
        if (this.loading) {
          this.showRetryButton = true
        }
      }, 3000)
      
      try {
        const constraints = {
          video: {
            width: { ideal: 1280 },
            height: { ideal: 720 },
            facingMode: 'user'
          }
        }
        
        this.stream = await navigator.mediaDevices.getUserMedia(constraints)
        console.log('Camera stream obtained:', this.stream)
        this.permissionGranted = true
        
        // Wait for Vue to update the DOM
        await this.$nextTick()
        
        // Wait a bit more to ensure video element is ready
        await new Promise(resolve => setTimeout(resolve, 300))
        
        // Wait for video element to be available in DOM
        let attempts = 0
        while (!this.$refs.videoElement && attempts < 10) {
          await new Promise(resolve => setTimeout(resolve, 100))
          attempts++
        }
        
        if (!this.$refs.videoElement) {
          console.error('Video element not found after multiple attempts')
          this.error = 'Unable to initialize camera interface. Please refresh and try again.'
          this.loading = false
          this.clearRetryTimer()
          return
        }
        
        this.setupCamera()
      } catch (err) {
        console.error('Camera access error:', err)
        this.loading = false
        this.clearRetryTimer()
        
        if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
          this.permissionDenied = true
        } else if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') {
          this.error = 'No camera device found'
        } else if (err.name === 'NotReadableError' || err.name === 'TrackStartError') {
          this.error = 'Camera is already in use by another application'
        } else {
          this.error = `Camera error: ${err.message}`
        }
      }
    },
    
    setupCamera() {
      console.log('Setting up camera...', { stream: !!this.stream, videoElement: !!this.$refs.videoElement })
      
      if (this.stream && this.$refs.videoElement) {
        const video = this.$refs.videoElement
        video.srcObject = this.stream
        
        // Multiple event listeners to ensure we catch when video is ready
        const onVideoReady = () => {
          console.log('Video is ready!')
          this.loading = false
          this.isStreaming = true
          this.clearRetryTimer()
        }
        
        video.onloadedmetadata = onVideoReady
        video.oncanplay = onVideoReady
        video.onloadeddata = onVideoReady
        
        // Force play the video
        video.play().catch(err => {
          console.error('Error playing video:', err)
        })
        
        // Fallback in case events don't fire
        setTimeout(() => {
          if (this.loading) {
            console.log('Fallback: forcing camera ready state')
            this.loading = false
            this.isStreaming = true
            this.clearRetryTimer()
          }
        }, 1500)
      } else {
        console.error('Missing stream or video element:', { stream: !!this.stream, videoElement: !!this.$refs.videoElement })
      }
    },
    
    takeSnapshot() {
      if (!this.$refs.videoElement || !this.$refs.snapshotCanvas) return
      
      const video = this.$refs.videoElement
      const canvas = this.$refs.snapshotCanvas
      const ctx = canvas.getContext('2d')
      
      canvas.width = video.videoWidth
      canvas.height = video.videoHeight
      
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
      this.snapshotTaken = true
    },
    
    completeTest() {
      this.$emit('test-completed')
      this.stopCamera()
    },
    
    failTest() {
      this.$emit('test-failed')
      this.stopCamera()
    },
    
    retryTest() {
      this.error = null
      this.permissionDenied = false
      this.snapshotTaken = false
      this.loading = false
      this.isStreaming = false
      this.stopCamera()
      this.requestPermission()
    },
    
    stopCamera() {
      if (this.stream) {
        this.stream.getTracks().forEach(track => track.stop())
        this.stream = null
        this.isStreaming = false
      }
      this.clearRetryTimer()
    },
    
    clearRetryTimer() {
      if (this.retryTimer) {
        clearTimeout(this.retryTimer)
        this.retryTimer = null
      }
      this.showRetryButton = false
    },
    
    forceRetry() {
      console.log('Force retrying camera setup...')
      this.retryTest()
    }
  }
}
</script>

<style scoped>
.webcam-test {
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

.camera-container {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.camera-preview {
  width: 100%;
  max-width: 640px;
  height: auto;
  border-radius: 10px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  margin: 0 auto;
  display: block;
}

.camera-controls {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  align-items: center;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  background: #333333;
  font-size: 0.9rem;
  color: #cccccc;
  border: 1px solid #555555;
}

.status-indicator.active {
  background: rgba(255, 107, 0, 0.1);
  color: #ff6b00;
  border: 1px solid #ff6b00;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #ccc;
}

.status-indicator.active .status-dot {
  background: #ff6b00;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.5; }
  100% { opacity: 1; }
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

.action-button.primary {
  background: #ff6b00;
  color: white;
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

.snapshot-preview {
  text-align: center;
  margin-top: 1rem;
}

.snapshot-preview h4 {
  margin-bottom: 1rem;
  color: #ff6b00;
  font-weight: 600;
}

.snapshot-canvas {
  max-width: 300px;
  max-height: 200px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

@media (max-width: 768px) {
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