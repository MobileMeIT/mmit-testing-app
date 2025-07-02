<template>
  <div class="webcam-test-container">
    <div class="test-header">
      <h2><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-video"><polygon points="23 7 16 12 23 17 23 7"></polygon><rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect></svg> Webcam Test</h2>
    </div>

    <div class="test-area">
      <!-- Initial State: Checking Permission -->
      <div v-if="checkingPermission" class="state-panel checking-permission">
        <div class="spinner"></div>
        <p>Checking for camera permissions...</p>
      </div>

      <!-- Permission Request State -->
      <div v-else-if="!permissionGranted && !permissionDenied" class="state-panel permission-request">
        <div class="panel-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-lock"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
        </div>
        <h3>Camera Permission Required</h3>
        <p>Please allow camera access to test your webcam.</p>
        <button @click="requestPermission" class="action-button primary">
          Grant Camera Access
        </button>
      </div>

      <!-- Permission Denied State -->
      <div v-else-if="permissionDenied" class="state-panel permission-denied">
        <div class="panel-icon error-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-x-circle"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
        </div>
        <h3>Camera Access Denied</h3>
        <p>Please enable camera permissions in your browser settings and try again.</p>
        <button @click="requestPermission" class="action-button primary">
          Try Again
        </button>
      </div>

      <!-- Main Camera View -->
      <div v-else>
        <div class="camera-view">
          <div class="video-container">
            <div v-if="loading" class="video-overlay loading">
              <div class="spinner"></div>
              <p>Initializing camera...</p>
            </div>
            <div v-if="error" class="video-overlay error">
               <div class="panel-icon error-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-alert-triangle"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
              </div>
              <h3>Camera Error</h3>
              <p>{{ error }}</p>
              <button @click="retryTest" class="action-button primary">Retry Test</button>
            </div>
            <video
              ref="videoElement"
              autoplay
              muted
              playsinline
              class="camera-preview"
              :class="{ blurred: loading || error }"
            ></video>
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
  name: 'WebcamTest',
  data() {
    return {
      stream: null,
      permissionGranted: false,
      permissionDenied: false,
      loading: false,
      error: null,
      snapshotTaken: false,
      showRetryButton: false,
      retryTimer: null,
      checkingPermission: true
    }
  },
  mounted() {
    this.initializeTest();
  },
  beforeUnmount() {
    this.stopCamera()
  },
  methods: {
    async initializeTest() {
      // Check for basic camera support
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        this.error = 'Camera is not supported in this browser.';
        this.permissionGranted = true; // Show the error state in the camera view
        this.checkingPermission = false;
        return;
      }

      // Check for Permissions API
      if (typeof navigator.permissions?.query !== 'function') {
        console.warn('Permissions API not supported. Relying on user action to grant permission.');
        // UI will default to showing 'Grant Permission' button, which is the desired fallback.
        this.checkingPermission = false;
        return;
      }

      try {
        const permissionStatus = await navigator.permissions.query({ name: 'camera' });
        this.handlePermissionState(permissionStatus.state);
        // React to permission changes made by the user in browser settings
        permissionStatus.onchange = () => {
          this.handlePermissionState(permissionStatus.state);
        };
      } catch (err) {
        console.error("Error querying camera permissions:", err);
        this.error = "Could not verify camera permissions. Please grant access when prompted.";
        this.permissionGranted = true; // Show error state
      } finally {
        this.checkingPermission = false;
      }
    },

    handlePermissionState(state) {
      if (state === 'granted') {
        this.permissionGranted = true;
        this.permissionDenied = false;
        // If permission is granted, and we don't have a stream, get it.
        if (!this.stream) {
          this.requestPermission();
        }
      } else if (state === 'prompt') {
        // Ready for user to click the button
        this.permissionGranted = false;
        this.permissionDenied = false;
      } else if (state === 'denied') {
        this.permissionDenied = true;
        this.permissionGranted = false;
        this.stopCamera(); // Ensure camera is off if permission is revoked
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
        
        if (!this.$refs.videoElement) {
          console.error('Video element not found. This should not happen.')
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
      this.$emit('test-completed', 'webcam')
      this.stopCamera()
    },
    
    failTest() {
      this.$emit('test-failed', 'webcam')
      this.stopCamera()
    },
    
    retryTest() {
      this.error = null
      this.permissionDenied = false
      this.loading = false
      this.stopCamera()
      this.requestPermission()
    },
    
    stopCamera() {
      if (this.stream) {
        this.stream.getTracks().forEach(track => track.stop())
        this.stream = null
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
.webcam-test-container {
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
}

.test-area {
  flex-grow: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  background-color: #252526;
  border-radius: 8px;
  overflow: hidden;
  position: relative;
}

/* --- State Panels (Permission, Error) --- */
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

/* --- Main Camera View --- */
.camera-view {
  width: 100%;
  max-width: 600px;
  margin: 1rem auto;
  display: flex;
  flex-direction: column;
  background: #1e1e1e;
  border-radius: 8px;
  border: 1px solid #333;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.video-container {
  position: relative;
  background-color: #000;
  display: flex;
  align-items: center;
  justify-content: center;
  aspect-ratio: 16/9;
  overflow: hidden;
  border-radius: 8px;
}

.camera-preview {
  width: 100%;
  height: 100%;
  object-fit: contain;
  transition: filter 0.3s ease;
}

.camera-preview.blurred {
  filter: blur(8px);
}

.video-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 10;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background-color: rgba(0, 0, 0, 0.6);
  color: #fff;
  text-align: center;
  padding: 1rem;
}

.video-overlay.error .panel-icon {
  margin-bottom: 0.5rem;
}


/* --- Controls Bar --- */
.controls-bar {
  flex-shrink: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1.5rem;
  padding: 1rem;
  width: 100%;
  background-color: #2c2c2e;
  border-top: 1px solid #444;
}


/* --- Common Elements --- */
.action-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  font-weight: 600;
  border-radius: 6px;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
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
  to { transform: rotate(360deg); }
}
</style> 