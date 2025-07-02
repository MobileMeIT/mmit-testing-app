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
          <div class="panel-icon">
             <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-play-circle"><circle cx="12" cy="12" r="10"></circle><polygon points="10 8 16 12 10 16 10 8"></polygon></svg>
          </div>
          <h3>Test your Speakers</h3>
          <p>Click the button below to play a test sound. The sound will play on the left, then right, then both speakers.</p>

          <button @click="playFullTest" class="action-button primary large" :disabled="isPlaying">
            <span v-if="!isPlaying">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-play"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
              Play Sound
            </span>
            <span v-else class="playing-indicator">
              <div class="audio-wave"></div>
              Playing ({{ currentTestStep }})
            </span>
          </button>
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
      testTimeout: null
    }
  },
  mounted() {
    this.initializeAudioContext()
  },
  beforeUnmount() {
    this.cleanup()
  },
  methods: {
    initializeAudioContext() {
      try {
        if (!this.audioContext || this.audioContext.state === 'closed') {
          this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
        }
      } catch (err) {
        console.error('Audio context initialization error:', err);
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
      this.$emit('test-completed', 'speakers')
      this.cleanup()
    },

    failTest() {
      this.$emit('test-failed', 'speakers')
      this.cleanup()
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
  flex-grow: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  padding: 2rem;
  margin: 1rem;
  background: #1e1e1e;
  border-radius: 8px;
  border: 1px solid #333;
  color: #cccccc;
}

.main-content h3 {
  font-size: 1.25rem;
  font-weight: 600;
  margin-top: 1rem;
  margin-bottom: 0.5rem;
  color: #ffffff;
}

.main-content p {
  margin-bottom: 1.5rem;
  line-height: 1.6;
}

.panel-icon {
  margin-bottom: 1rem;
  color: #ff6b00;
}

.action-button.large {
  padding: 1rem 2rem;
  font-size: 1.1rem;
  min-width: 200px;
  height: 50px;
}

.playing-indicator {
  display: flex;
  align-items: center;
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

.volume-control {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-top: 2rem;
    width: 100%;
    max-width: 300px;
    color: #999;
}

.volume-slider {
    flex-grow: 1;
    -webkit-appearance: none;
    appearance: none;
    width: 100%;
    height: 8px;
    background: #444;
    border-radius: 5px;
    outline: none;
    opacity: 0.9;
    transition: opacity .2s;
}

.volume-slider:hover {
    opacity: 1;
}

.volume-slider::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 20px;
    height: 20px;
    background: #ff6b00;
    cursor: pointer;
    border-radius: 50%;
}

.volume-slider::-moz-range-thumb {
    width: 20px;
    height: 20px;
    background: #ff6b00;
    cursor: pointer;
    border-radius: 50%;
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

.button-group {
    display: flex;
    gap: 1rem;
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

.action-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.action-button.primary {
  background-color: #ff6b00;
}
.action-button.primary:hover:not(:disabled) {
  background-color: #e65c00;
}

.action-button.success {
  background-color: #28a745;
}
.action-button.success:hover:not(:disabled) {
  background-color: #218838;
}

.action-button.danger {
  background-color: #dc3545;
}
.action-button.danger:hover:not(:disabled) {
  background-color: #c82333;
}

.action-button.primary.large {
  padding: 0.8rem 1.5rem;
  font-size: 1rem;
}

.playing-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

/* --- Audio Wave Animation --- */
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
</style> 