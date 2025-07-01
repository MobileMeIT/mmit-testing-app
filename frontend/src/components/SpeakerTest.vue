<template>
  <div class="speaker-test">
    <div class="test-header">
      <h3>🔊 Speaker Test</h3>
      <p>We'll test your speakers to ensure they're working properly</p>
    </div>

    <div class="test-content">
      <div class="speaker-container">
        <div class="volume-controls">
          <h4>Volume Control</h4>
          <div class="volume-slider-container">
            <span class="volume-label">🔈</span>
            <input 
              type="range" 
              min="0" 
              max="100" 
              v-model="volume" 
              class="volume-slider"
              @input="updateVolume"
            />
            <span class="volume-label">🔊</span>
          </div>
          <div class="volume-display">Volume: {{ volume }}%</div>
        </div>

        <div class="test-tones">
          <h4>Test Audio</h4>
          <div class="tone-buttons">
            <button 
              @click="playTone('left')" 
              class="tone-button"
              :class="{ playing: playingTone === 'left' }"
            >
              🎵 Left Channel
            </button>
            <button 
              @click="playTone('right')" 
              class="tone-button"
              :class="{ playing: playingTone === 'right' }"
            >
              🎵 Right Channel
            </button>
            <button 
              @click="playTone('both')" 
              class="tone-button"
              :class="{ playing: playingTone === 'both' }"
            >
              🎵 Both Channels
            </button>
            <button 
              @click="playTone('sweep')" 
              class="tone-button"
              :class="{ playing: playingTone === 'sweep' }"
            >
              🎵 Frequency Sweep
            </button>
          </div>
          
          <div v-if="playingTone" class="playing-indicator">
            <div class="audio-wave"></div>
            <span>Playing {{ playingTone === 'both' ? 'stereo' : playingTone }} test tone...</span>
            <button @click="stopTone" class="stop-button">⏹️ Stop</button>
          </div>
        </div>

        <div class="speaker-check">
          <h4>Speaker Check</h4>
          <div class="check-questions">
            <div class="question">
              <label class="checkbox-container">
                <input type="checkbox" v-model="canHearLeft">
                <span class="checkmark"></span>
                I can hear sound from the left speaker/earphone
              </label>
            </div>
            <div class="question">
              <label class="checkbox-container">
                <input type="checkbox" v-model="canHearRight">
                <span class="checkmark"></span>
                I can hear sound from the right speaker/earphone
              </label>
            </div>
            <div class="question">
              <label class="checkbox-container">
                <input type="checkbox" v-model="soundQuality">
                <span class="checkmark"></span>
                The sound quality is clear without distortion
              </label>
            </div>
            <div class="question">
              <label class="checkbox-container">
                <input type="checkbox" v-model="volumeWorking">
                <span class="checkmark"></span>
                Volume controls work properly
              </label>
            </div>
          </div>
        </div>

        <div class="test-actions">
          <button 
            @click="completeTest" 
            class="action-button success" 
            :disabled="!allChecksCompleted"
          >
            ✅ Speakers Work Fine
          </button>
          <button @click="failTest" class="action-button danger">
            ❌ Speakers Not Working
          </button>
        </div>

        <div class="test-instructions">
          <h4>Testing Instructions:</h4>
          <ol>
            <li>Adjust the volume to a comfortable level</li>
            <li>Test each channel (left/right) individually</li>
            <li>Test both channels together</li>
            <li>Try the frequency sweep to test different tones</li>
            <li>Check all boxes that apply to your experience</li>
            <li>Click "Speakers Work Fine" if everything sounds good</li>
          </ol>
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
      volume: 50,
      playingTone: null,
      audioContext: null,
      oscillator: null,
      gainNode: null,
      panNode: null,
      canHearLeft: false,
      canHearRight: false,
      soundQuality: false,
      volumeWorking: false
    }
  },
  computed: {
    allChecksCompleted() {
      return this.canHearLeft && this.canHearRight && this.soundQuality && this.volumeWorking
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
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
      } catch (err) {
        console.error('Audio context initialization error:', err)
      }
    },

    updateVolume() {
      if (this.gainNode) {
        this.gainNode.gain.value = this.volume / 100
      }
    },

    async playTone(type) {
      if (this.playingTone) {
        this.stopTone()
      }

      if (!this.audioContext) {
        this.initializeAudioContext()
      }

      // Resume audio context if suspended
      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume()
      }

      this.playingTone = type

      if (type === 'sweep') {
        this.playSweep()
      } else {
        this.playStandardTone(type)
      }
    },

    playStandardTone(type) {
      this.oscillator = this.audioContext.createOscillator()
      this.gainNode = this.audioContext.createGain()
      this.panNode = this.audioContext.createStereoPanner()

      // Set frequency (440Hz = A4 note)
      this.oscillator.frequency.setValueAtTime(440, this.audioContext.currentTime)
      this.oscillator.type = 'sine'

      // Set pan based on type
      if (type === 'left') {
        this.panNode.pan.setValueAtTime(-1, this.audioContext.currentTime)
      } else if (type === 'right') {
        this.panNode.pan.setValueAtTime(1, this.audioContext.currentTime)
      } else {
        this.panNode.pan.setValueAtTime(0, this.audioContext.currentTime)
      }

      // Set volume
      this.gainNode.gain.setValueAtTime(this.volume / 100, this.audioContext.currentTime)

      // Connect nodes
      this.oscillator.connect(this.gainNode)
      this.gainNode.connect(this.panNode)
      this.panNode.connect(this.audioContext.destination)

      // Start playing
      this.oscillator.start()

      // Auto-stop after 3 seconds
      setTimeout(() => {
        if (this.playingTone === type) {
          this.stopTone()
        }
      }, 3000)
    },

    playSweep() {
      this.oscillator = this.audioContext.createOscillator()
      this.gainNode = this.audioContext.createGain()

      this.oscillator.type = 'sine'
      this.gainNode.gain.setValueAtTime(this.volume / 100, this.audioContext.currentTime)

      // Frequency sweep from 200Hz to 2000Hz over 5 seconds
      this.oscillator.frequency.setValueAtTime(200, this.audioContext.currentTime)
      this.oscillator.frequency.exponentialRampToValueAtTime(2000, this.audioContext.currentTime + 5)

      this.oscillator.connect(this.gainNode)
      this.gainNode.connect(this.audioContext.destination)

      this.oscillator.start()

      // Auto-stop after 5 seconds
      setTimeout(() => {
        if (this.playingTone === 'sweep') {
          this.stopTone()
        }
      }, 5000)
    },

    stopTone() {
      if (this.oscillator) {
        this.oscillator.stop()
        this.oscillator = null
      }
      if (this.gainNode) {
        this.gainNode = null
      }
      if (this.panNode) {
        this.panNode = null
      }
      this.playingTone = null
    },

    completeTest() {
      this.$emit('test-completed')
      this.cleanup()
    },

    failTest() {
      this.$emit('test-failed')
      this.cleanup()
    },

    cleanup() {
      this.stopTone()

      if (this.audioContext && this.audioContext.state !== 'closed') {
        this.audioContext.close()
        this.audioContext = null
      }
    }
  }
}
</script>

<style scoped>
.speaker-test {
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

.speaker-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.volume-controls {
  background: #262626;
  padding: 1.5rem;
  border-radius: 8px;
  border: 1px solid #333333;
  text-align: center;
}

.volume-controls h4 {
  margin-bottom: 1rem;
  color: #ffffff;
  font-weight: 600;
}

.volume-slider-container {
  display: flex;
  align-items: center;
  gap: 1rem;
  justify-content: center;
  margin-bottom: 0.5rem;
}

.volume-slider {
  width: 200px;
  height: 6px;
  border-radius: 3px;
  background: #ddd;
  outline: none;
  -webkit-appearance: none;
}

.volume-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #ff6b00;
  cursor: pointer;
}

.volume-slider::-moz-range-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #ff6b00;
  cursor: pointer;
  border: none;
}

.volume-label {
  font-size: 1.2rem;
}

.volume-display {
  font-weight: 500;
  color: #ffffff;
}

.test-tones {
  background: #262626;
  padding: 1.5rem;
  border-radius: 8px;
  border: 1px solid #333333;
}

.test-tones h4 {
  margin-bottom: 1rem;
  color: #ffffff;
  font-weight: 600;
  text-align: center;
}

.tone-buttons {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.tone-button {
  padding: 0.8rem 1rem;
  border: none;
  border-radius: 8px;
  background: #ff6b00;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.9rem;
  font-weight: 600;
}

.tone-button:hover {
  background: #ff8533;
  transform: translateY(-2px);
}

.tone-button.playing {
  background: #f44336;
  animation: playingPulse 1s infinite;
}

@keyframes playingPulse {
  0% { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0.7); }
  70% { box-shadow: 0 0 0 10px rgba(244, 67, 54, 0); }
  100% { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0); }
}

.playing-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 1rem;
  background: rgba(244, 67, 54, 0.1);
  border-radius: 8px;
  color: #f44336;
}

.audio-wave {
  width: 20px;
  height: 20px;
  background: linear-gradient(45deg, #f44336 25%, transparent 25%),
              linear-gradient(-45deg, #f44336 25%, transparent 25%),
              linear-gradient(45deg, transparent 75%, #f44336 75%),
              linear-gradient(-45deg, transparent 75%, #f44336 75%);
  background-size: 4px 4px;
  background-position: 0 0, 0 2px, 2px -2px, -2px 0px;
  animation: wave 1s linear infinite;
}

@keyframes wave {
  0% { background-position: 0 0, 0 2px, 2px -2px, -2px 0px; }
  100% { background-position: 4px 0, 4px 2px, 6px -2px, 2px 0px; }
}

.stop-button {
  padding: 0.5rem 1rem;
  background: #f44336;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.8rem;
}

.speaker-check {
  background: #262626;
  padding: 1.5rem;
  border-radius: 8px;
  border-left: 4px solid #ff6b00;
  border: 1px solid #333333;
}

.speaker-check h4 {
  margin-bottom: 1rem;
  color: #ff6b00;
  font-weight: 600;
}

.check-questions {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.question {
  display: flex;
  align-items: center;
}

.checkbox-container {
  display: flex;
  align-items: center;
  cursor: pointer;
  font-size: 0.95rem;
  color: #cccccc;
}

.checkbox-container input {
  margin-right: 0.8rem;
  transform: scale(1.2);
  accent-color: #ff6b00;
}

.test-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
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
  .speaker-container {
    gap: 1.5rem;
  }
  
  .volume-slider-container {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .volume-slider {
    width: 250px;
  }
  
  .tone-buttons {
    grid-template-columns: 1fr;
  }
  
  .playing-indicator {
    flex-direction: column;
    text-align: center;
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