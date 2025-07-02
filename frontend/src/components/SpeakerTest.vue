<template>
  <div class="speaker-test-container">
    <div class="test-header">
      <h2>
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-volume-2"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"></polygon><path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07"></path></svg>
        Speaker Test
      </h2>
      <div class="test-description">Test your speakers by playing a sound sequence through each channel.</div>
    </div>

    <div class="test-area">
      <div class="speaker-view">
        <div class="main-content">
          <div class="visualizer-container">
            <div class="speakers-container">
              <div class="speaker-box" :class="{ active: currentTestStep === 'Left' || currentTestStep === 'Both' }">
                <div class="speaker-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"></rect><circle cx="12" cy="14" r="4"></circle><line x1="12" y1="6" x2="12" y2="6"></line></svg>
                  <div class="wave-container" v-if="currentTestStep === 'Left' || currentTestStep === 'Both'">
                    <div class="wave"></div>
                    <div class="wave"></div>
                    <div class="wave"></div>
                  </div>
                </div>
                <span class="speaker-label">Left</span>
              </div>
              
              <div class="speaker-box" :class="{ active: currentTestStep === 'Right' || currentTestStep === 'Both' }">
                <div class="speaker-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"></rect><circle cx="12" cy="14" r="4"></circle><line x1="12" y1="6" x2="12" y2="6"></line></svg>
                  <div class="wave-container" v-if="currentTestStep === 'Right' || currentTestStep === 'Both'">
                    <div class="wave"></div>
                    <div class="wave"></div>
                    <div class="wave"></div>
                  </div>
                </div>
                <span class="speaker-label">Right</span>
              </div>
            </div>

            <div class="output-selector">
              <label for="speakerSelect">Speaker:</label>
              <select 
                id="speakerSelect" 
                v-model="selectedSpeakerId" 
                @change="switchSpeaker"
                :disabled="isPlaying || availableSpeakers.length <= 0"
              >
                <option v-if="availableSpeakers.length <= 0" value="">No output devices found</option>
                <option 
                  v-for="speaker in availableSpeakers" 
                  :key="speaker.deviceId" 
                  :value="speaker.deviceId"
                >
                  {{ speaker.label || `Output ${speaker.deviceId.slice(0, 4)}...` }}
                </option>
              </select>
            </div>

            <button @click="playFullTest" class="action-button primary large" :disabled="isPlaying">
              <span v-if="!isPlaying" class="play-button-content">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-play"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
                Play Sound
              </span>
              <span v-else class="playing-indicator">
                <div class="audio-wave"></div>
                Playing {{ currentTestStep === 'Both' ? 'Both Speakers' : currentTestStep + ' Speaker' }}
              </span>
            </button>
          </div>
        </div>
        
        <div class="controls-bar">
          <button @click="failTest" class="action-button danger" :disabled="isPlaying">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-x"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            <span>Not Working</span>
          </button>
          <button @click="completeTest" class="action-button success" :disabled="isPlaying">
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
  name: 'SpeakerTest',
  data() {
    return {
      isPlaying: false,
      currentTestStep: '',
      audioContext: null,
      oscillator: null,
      gainNode: null,
      panNode: null,
      testSequence: ['Left', 'Right', 'Both'],
      testTimeout: null,
      availableSpeakers: [],
      selectedSpeakerId: '',
      testCompleted: false
    }
  },
  mounted() {
    this.initializeAudioContext()
    this.enumerateSpeakers()
  },
  beforeUnmount() {
    this.cleanup()
  },
  methods: {
    async initializeAudioContext() {
      try {
        if (!this.audioContext || this.audioContext.state === 'closed') {
          this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
          
          // Set the audio output device if one is selected
          if (this.selectedSpeakerId && this.audioContext.setSinkId) {
            await this.audioContext.setSinkId(this.selectedSpeakerId);
          }
        }
      } catch (err) {
        console.error('Audio context initialization error:', err);
      }
    },

    async enumerateSpeakers() {
      try {
        const devices = await navigator.mediaDevices.enumerateDevices()
        this.availableSpeakers = devices.filter(device => device.kind === 'audiooutput')
        
        // If we haven't selected a speaker yet and we have available speakers,
        // select the first one
        if (!this.selectedSpeakerId && this.availableSpeakers.length > 0) {
          this.selectedSpeakerId = this.availableSpeakers[0].deviceId
        }
        
        console.log('Available speakers:', this.availableSpeakers)
      } catch (err) {
        console.error('Error enumerating speakers:', err)
      }
    },

    async switchSpeaker() {
      if (this.isPlaying) return
      
      try {
        // Reinitialize audio context with new output device
        if (this.audioContext) {
          await this.audioContext.close()
          this.audioContext = null
        }
        await this.initializeAudioContext()
      } catch (err) {
        console.error('Error switching speaker:', err)
      }
    },
    
    async playFullTest() {
      if (this.isPlaying) return;
      this.isPlaying = true;

      for (let i = 0; i < this.testSequence.length; i++) {
        const step = this.testSequence[i];
        this.currentTestStep = step;
        await this.playSound(step);
        if (!this.isPlaying) break; 
        if (i < this.testSequence.length - 1) {
            await new Promise(resolve => setTimeout(resolve, 500)); // Pause between sounds
        }
      }

      this.stopSound();
    },

    async playSound(type) {
        if (!this.audioContext) this.initializeAudioContext();
        if (this.audioContext.state === 'suspended') await this.audioContext.resume();

        this.stopSound(false); // Stop previous sound without setting isPlaying to false

        return new Promise(resolve => {
            this.oscillator = this.audioContext.createOscillator();
            this.gainNode = this.audioContext.createGain();
            this.panNode = this.audioContext.createStereoPanner();

            this.oscillator.type = 'sine';
            this.oscillator.frequency.setValueAtTime(440, this.audioContext.currentTime);

            if (type === 'Left') this.panNode.pan.setValueAtTime(-1, this.audioContext.currentTime);
            else if (type === 'Right') this.panNode.pan.setValueAtTime(1, this.audioContext.currentTime);
            else this.panNode.pan.setValueAtTime(0, this.audioContext.currentTime);

            this.gainNode.gain.setValueAtTime(0.5, this.audioContext.currentTime); // Use a fixed volume

            this.oscillator.connect(this.gainNode).connect(this.panNode).connect(this.audioContext.destination);
            this.oscillator.start();

            this.testTimeout = setTimeout(() => {
                this.stopSound(false);
                resolve();
            }, 1500); // Play each sound for 1.5 seconds
        });
    },

    stopSound(endTest = true) {
        if (this.testTimeout) {
            clearTimeout(this.testTimeout);
            this.testTimeout = null;
        }
        if (this.oscillator) {
            this.oscillator.stop();
            this.oscillator.disconnect();
            this.oscillator = null;
        }
        if(endTest){
            this.isPlaying = false;
            this.currentTestStep = '';
        }
    },

    completeTest() {
      if (this.testCompleted || this.isPlaying) {
        return;
      }
      this.$emit('test-completed', 'speakers');
      this.testCompleted = true;
      this.cleanup();
    },

    failTest() {
      if (this.testCompleted || this.isPlaying) {
        return;
      }
      this.$emit('test-failed', 'speakers');
      this.testCompleted = true;
      this.cleanup();
    },

    cleanup() {
      this.stopSound();
      if (this.audioContext && this.audioContext.state !== 'closed') {
        this.audioContext.close()
      }
    }
  }
}
</script>

<style scoped>
.speaker-test-container {
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
  background-color: #252526;
  border-radius: 8px;
  overflow: hidden;
  position: relative;
}

/* --- Main Speaker View --- */
.speaker-view {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.main-content {
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
  box-sizing: border-box;
}

.speakers-container {
  display: flex;
  justify-content: center;
  gap: 3rem;
  width: 100%;
  background: #141414;
  padding: 2rem;
  border-radius: 8px;
}

.speaker-box {
  flex: 1;
  max-width: 160px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
  border-radius: 8px;
  background: #2c2c2e;
  border: 1px solid #444;
  transition: all 0.3s ease;
}

.speaker-box.active {
  border-color: #ff9800;
  box-shadow: 0 0 15px rgba(255, 152, 0, 0.3);
  background: #2a2a2a;
}

.speaker-icon {
  position: relative;
  color: #888;
  transition: color 0.3s ease;
}

.speaker-box.active .speaker-icon {
  color: #ff9800;
}

.speaker-label {
  font-size: 1rem;
  font-weight: 500;
  color: #888;
}

.speaker-box.active .speaker-label {
  color: #ff9800;
}

.wave-container {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  display: flex;
  align-items: center;
  gap: 3px;
}

.wave {
  width: 3px;
  height: 3px;
  background-color: #ff9800;
  animation: wave-animation 1s infinite ease-in-out;
}

.wave:nth-child(2) {
  animation-delay: 0.2s;
}

.wave:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes wave-animation {
  0%, 100% { height: 3px; }
  50% { height: 15px; }
}

.output-selector {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0;
  box-sizing: border-box;
}

.output-selector label {
  color: #e0e0e0;
  font-size: 0.95rem;
  min-width: 70px;
}

.output-selector select {
  flex: 1;
  padding: 0.75rem;
  border-radius: 4px;
  border: 1px solid #444;
  background: #1a1a1a;
  color: #e0e0e0;
  font-size: 0.95rem;
  cursor: pointer;
  max-width: calc(100% - 90px);
  box-sizing: border-box;
}

.output-selector select:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.output-selector select:focus {
  outline: none;
  border-color: #666;
}

.output-selector select option {
  background: #1a1a1a;
  color: #e0e0e0;
}

.action-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  font-size: 0.95rem;
  font-weight: 500;
  border-radius: 4px;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
  color: #000;
  background: #fff;
}

.action-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.action-button.danger {
  background: #dc3545;
  color: #fff;
}

.action-button.success {
  background: #28a745;
  color: #fff;
}

.action-button.primary.large {
  width: 100%;
  padding: 1rem;
  font-size: 1.1rem;
  background: #ff6b00;
  color: #fff;
  border: none;
  border-radius: 4px;
  transition: all 0.2s ease;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.action-button.primary.large:hover:not(:disabled) {
  background: #e65c00;
}

.action-button.primary.large:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.play-button-content {
  display: flex;
  align-items: center;
  gap: 8px;
}

.play-button-content svg {
  margin-top: -1px;
}

.playing-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
}

.audio-wave {
  width: 24px;
  height: 24px;
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.audio-wave::before,
.audio-wave::after {
  content: '';
  width: 5px;
  height: 100%;
  background-color: white;
  animation: wave 1s infinite ease-in-out;
}

.audio-wave::after {
  animation-delay: -0.5s;
}

@keyframes wave {
  0%, 100% { height: 5%; }
  50% { height: 100%; }
}

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
  margin-top: auto;
  box-sizing: border-box;
}
</style> 