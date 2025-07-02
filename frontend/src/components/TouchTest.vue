<template>
  <div class="touch-test-container">
    <div class="test-header">
      <h2>
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-smartphone"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line></svg>
        Touch Test
      </h2>
      <p>Test your touchscreen by completing the interactive challenges below</p>
    </div>

    <div class="test-area"
      @touchstart.prevent="handlePointerDown" 
      @touchmove.prevent="handlePointerMove" 
      @touchend.prevent="handlePointerUp"
      @mousedown.prevent="handlePointerDown" 
      @mousemove.prevent="handlePointerMove" 
      @mouseup.prevent="handlePointerUp"
      @mouseleave="handleMouseLeave">
      
      <div v-if="stage !== 'idle'" class="progress-indicator">
        <div class="progress-text">{{ completedChallenges }} challenges completed</div>
        <div class="progress-bar">
          <div class="progress-fill" :style="{ width: `${Math.min(completedChallenges * (100/5), 100)}%` }"></div>
        </div>
      </div>
      
      <div v-if="stage !== 'idle'" class="feedback-text" :class="{ success: currentChallenge.complete }">
        {{ feedbackText }}
      </div>
      
      <div v-if="stage === 'idle'" class="start-prompt">
        <div class="tap-instruction">Tap anywhere to begin</div>
      </div>
      
      <div class="challenge-area">
        <!-- Tap Challenge -->
        <div v-if="stage === 'tap'" class="target-container">
          <div class="target tap-target" :class="{ success: currentChallenge.complete }" :style="tapTargetStyle">
            <svg v-if="currentChallenge.complete" class="target-checkmark" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
              <path class="checkmark-check" fill="none" stroke="white" stroke-width="3" d="M4 12l5 5L20 7"/>
            </svg>
          </div>
        </div>

        <!-- Drag Challenge -->
        <div v-if="stage === 'drag'" class="target-container">
          <div class="target drag-target-area" :class="{ success: currentChallenge.complete }" :style="dragTargetStyle">
            <svg v-if="currentChallenge.complete" class="target-checkmark" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
              <path class="checkmark-check" fill="none" stroke="white" stroke-width="3" d="M4 12l5 5L20 7"/>
            </svg>
          </div>
          <div class="target drag-source" :style="dragSourceStyle"></div>
          <div class="drag-indicator" :style="dragIndicatorStyle">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
          </div>
        </div>
      </div>
    </div>

    <div class="controls-bar">
      <button @click="failTest" class="action-button danger">
        <span>Not Working</span>
      </button>
      <button @click="completeTest" class="action-button success">
        <span>Working</span>
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TouchTest',
  data() {
    const targetSize = 60;
    const padding = 20;

    return {
      stage: 'idle',
      feedbackText: 'Touch or click the screen to begin the test.',
      completedChallenges: 0,
      currentChallenge: { type: null, complete: false },
      
      tapTarget: { x: 0, y: 0, size: targetSize },
      dragSource: { x: 0, y: 0, size: targetSize, isDragging: false, touchId: null },
      dragTarget: { x: 0, y: 0, size: targetSize * 1.5 },
      
      targetSize,
      padding,
      successTimer: null,
      
      safeAreaMargin: {
        top: 150,      // Increased from 100
        bottom: 100,   // Increased from 40
        left: 100,     // Increased from 80
        right: 100     // Increased from 80
      }
    }
  },
  computed: {
    tapTargetStyle() { return this.getStyle(this.tapTarget); },
    dragSourceStyle() { return { ...this.getStyle(this.dragSource), transition: this.dragSource.isDragging ? 'none' : 'all 0.3s ease' }; },
    dragTargetStyle() { return this.getStyle(this.dragTarget); },
    dragIndicatorStyle() {
      const sourceCenter = {
        x: this.dragSource.x + this.dragSource.size / 2,
        y: this.dragSource.y + this.dragSource.size / 2
      };
      const targetCenter = {
        x: this.dragTarget.x + this.dragTarget.size / 2,
        y: this.dragTarget.y + this.dragTarget.size / 2
      };
      const midX = (sourceCenter.x + targetCenter.x) / 2;
      const midY = (sourceCenter.y + targetCenter.y) / 2;
      
      const angle = Math.atan2(targetCenter.y - sourceCenter.y, targetCenter.x - sourceCenter.x) * 180 / Math.PI;
      
      return {
        left: `${midX - 20}px`,
        top: `${midY - 20}px`,
        transform: `rotate(${angle}deg)`
      };
    }
  },
  mounted() {
    window.addEventListener('resize', this.handleResize);
    this.calculateGridPositions();
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.handleResize);
    this.clearSuccessTimer();
  },
  methods: {
    getStyle(target) {
      return { 
        left: `${target.x}px`, top: `${target.y}px`, 
        width: `${target.size}px`, height: `${target.size}px` 
      };
    },
    
    calculateGridPositions() {
      const challengeArea = document.querySelector('.challenge-area');
      if (!challengeArea) return;
      
      setTimeout(() => {
        const challengeArea = document.querySelector('.challenge-area');
        if (!challengeArea) return;
        
        const rect = challengeArea.getBoundingClientRect();
        this.safeAreaRect = {
          left: this.safeAreaMargin.left,
          top: this.safeAreaMargin.top,
          width: rect.width - this.safeAreaMargin.left - this.safeAreaMargin.right,
          height: rect.height - this.safeAreaMargin.top - this.safeAreaMargin.bottom
        };
      }, 0);
    },
    
    getRandomPosition() {
      if (!this.safeAreaRect) {
        const challengeArea = document.querySelector('.challenge-area');
        if (!challengeArea) return { x: 100, y: 150 };
        
        const rect = challengeArea.getBoundingClientRect();
        this.safeAreaRect = {
          left: this.safeAreaMargin.left,
          top: this.safeAreaMargin.top,
          width: rect.width - this.safeAreaMargin.left - this.safeAreaMargin.right,
          height: rect.height - this.safeAreaMargin.top - this.safeAreaMargin.bottom
        };
      }
      
      return {
        x: this.safeAreaRect.left + Math.random() * this.safeAreaRect.width,
        y: this.safeAreaRect.top + Math.random() * this.safeAreaRect.height
      };
    },
    
    handleResize() {
      this.calculateGridPositions();
      
      if (this.stage !== 'idle') {
        this.setupCurrentChallenge();
      }
    },
    
    startTest() {
      this.completedChallenges = 0;
      this.setupNextChallenge();
    },
    
    setupNextChallenge() {
      this.clearSuccessTimer();
      this.currentChallenge.complete = false;
      
      const challengeTypes = ['tap', 'drag'];
      const randomType = challengeTypes[Math.floor(Math.random() * challengeTypes.length)];
      
      this.currentChallenge.type = randomType;
      this.stage = randomType;
      
      this.setupCurrentChallenge();
    },
    
    setupCurrentChallenge() {
      switch (this.currentChallenge.type) {
        case 'tap':
          this.setupTapChallenge();
          break;
        case 'drag':
          this.setupDragChallenge();
          break;
      }
    },

    setupTapChallenge() {
      const position = this.getRandomPosition();
      this.feedbackText = 'Tap the circle.';
      this.tapTarget.x = position.x - this.targetSize / 2;
      this.tapTarget.y = position.y - this.targetSize / 2;
    },

    setupDragChallenge() {
      const sourcePos = this.getRandomPosition();
      let targetPos;
      let distance;
      const minDistance = 150; // Minimum drag distance
      const maxDistance = 300; // Maximum drag distance to keep it reasonable
      
      do {
        targetPos = this.getRandomPosition();
        distance = Math.sqrt(
          Math.pow(sourcePos.x - targetPos.x, 2) + 
          Math.pow(sourcePos.y - targetPos.y, 2)
        );
      } while (distance < minDistance || distance > maxDistance);
      
      this.feedbackText = 'Drag the orange circle into the outlined circle.';
      this.dragSource.x = sourcePos.x - this.dragSource.size / 2;
      this.dragSource.y = sourcePos.y - this.dragSource.size / 2;
      this.dragTarget.x = targetPos.x - this.dragTarget.size / 2;
      this.dragTarget.y = targetPos.y - this.dragTarget.size / 2;
    },

    showSuccessAndContinue() {
      this.currentChallenge.complete = true;
      this.completedChallenges++;
      
      this.clearSuccessTimer();
      
      this.successTimer = setTimeout(() => {
        this.setupNextChallenge();
      }, 400);
    },
    
    clearSuccessTimer() {
      if (this.successTimer) {
        clearTimeout(this.successTimer);
        this.successTimer = null;
      }
    },

    handlePointerDown(e) {
      const challengeArea = document.querySelector('.challenge-area');
      if (!challengeArea) return;
      
      if (e.type === 'mousedown' && e.button !== 0) return;
      
      const rect = challengeArea.getBoundingClientRect();
      const touches = e.changedTouches || [e];
      
      if (this.stage === 'idle') {
        this.startTest();
        return;
      }
      
      if (this.currentChallenge.complete) return;
      
      for (let touch of touches) {
        const touchId = touch.identifier ?? null;
        const touchPoint = { x: touch.clientX - rect.left, y: touch.clientY - rect.top };
        
        if (this.stage === 'tap' && this.isInsideCircle(touchPoint, this.tapTarget)) {
          this.showSuccessAndContinue();
        } 
        else if (this.stage === 'drag' && this.isInsideCircle(touchPoint, this.dragSource)) {
          this.dragSource.isDragging = true;
          this.dragSource.touchId = touchId;
        }
      }
    },

    handlePointerMove(e) {
      if (this.stage !== 'drag' || !this.dragSource.isDragging) return;
      
      if (e.type === 'mousemove' && e.buttons !== 1) {
        this.handlePointerUp(e);
        return;
      }
      
      const challengeArea = document.querySelector('.challenge-area');
      if (!challengeArea) return;
      
      const rect = challengeArea.getBoundingClientRect();
      const touches = e.changedTouches || [e];
      for (let touch of touches) {
        if ((touch.identifier ?? 'mouse') === this.dragSource.touchId) {
          this.dragSource.x = touch.clientX - rect.left - this.targetSize / 2;
          this.dragSource.y = touch.clientY - rect.top - this.targetSize / 2;
        }
      }
    },

    handlePointerUp(e) {
      const challengeArea = document.querySelector('.challenge-area');
      if (!challengeArea) return;
      
      const touches = e.changedTouches || [e];
      for (let touch of touches) {
        const touchId = touch.identifier ?? null;
        
        if (this.stage === 'drag' && touchId === this.dragSource.touchId) {
          this.dragSource.isDragging = false;
          this.dragSource.touchId = null;
          const sourceCenter = { x: this.dragSource.x + this.targetSize/2, y: this.dragSource.y + this.targetSize/2 };
          if (this.isInsideCircle(sourceCenter, this.dragTarget)) {
            this.showSuccessAndContinue();
          } else {
            const sourcePos = this.getRandomPosition();
            this.dragSource.x = sourcePos.x - this.dragSource.size / 2;
            this.dragSource.y = sourcePos.y - this.dragSource.size / 2;
          }
        }
      }
    },

    handleMouseLeave() {
      if (this.stage === 'drag' && this.dragSource.isDragging) {
        this.dragSource.isDragging = false;
        this.dragSource.touchId = null;
        
        const sourcePos = this.getRandomPosition();
        this.dragSource.x = sourcePos.x - this.dragSource.size / 2;
        this.dragSource.y = sourcePos.y - this.dragSource.size / 2;
      }
    },
    
    isInsideCircle(point, circle) {
      const radius = circle.size / 2;
      const circleCenterX = circle.x + radius;
      const circleCenterY = circle.y + radius;
      const distance = Math.sqrt(Math.pow(point.x - circleCenterX, 2) + Math.pow(point.y - circleCenterY, 2));
      return distance <= radius;
    },
    
    failTest() {
      this.$emit('test-failed', 'touch');
    },

    completeTest() {
      this.$emit('test-completed', 'touch');
    }
  }
}
</script>

<style scoped>
.touch-test-container {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.test-header {
  text-align: center;
  margin-bottom: 1rem;
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

.test-header p {
  color: #a0a0a0;
  font-size: 1rem;
  margin: 0;
}

.test-area {
  flex: 1;
  background-color: #252526;
  border-radius: 8px;
  position: relative;
  overflow: hidden;
  margin-bottom: 1rem;
  min-height: 400px;
  display: flex;
  flex-direction: column;
}

.challenge-area {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 10;
}

.progress-indicator {
  position: absolute;
  top: 0.75rem;
  left: 50%;
  transform: translateX(-50%);
  width: 80%;
  z-index: 30;
  text-align: center;
}

.progress-text {
  color: #a0a0a0;
  font-size: 0.9rem;
  margin-bottom: 0.25rem;
}

.progress-bar {
  height: 6px;
  background-color: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background-color: #ff6b00;
  border-radius: 3px;
  transition: width 0.3s ease;
}

.start-prompt {
  position: absolute;
  top: 0;
  left: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
  z-index: 15;
}

.tap-instruction {
  color: #e0e0e0;
  font-size: 1.5rem;
  font-weight: 500;
  animation: pulse 2s infinite;
  text-align: center;
  padding: 1rem;
}

.feedback-text {
  position: absolute;
  top: 3.5rem;
  left: 50%;
  transform: translateX(-50%);
  color: #e0e0e0;
  font-size: 1.2rem;
  font-weight: 500;
  transition: all 0.3s ease;
  z-index: 20;
  text-align: center;
  padding: 0 1rem;
  width: 80%;
}

.feedback-text.success {
  color: #28a745;
}

.target-container {
  width: 100%;
  height: 100%;
  position: absolute;
  top: 0;
  left: 0;
}

.target {
  position: absolute;
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.tap-target {
  background: #ff6b00;
  border: 2px solid #ff6b00;
}

.tap-target.success {
  background: #28a745;
  border-color: #28a745;
  transform: scale(1.1);
}

.drag-target-area {
  border: 2px dashed #ff6b00;
  background: transparent;
}

.drag-target-area.success {
  border-style: solid;
  border-color: #28a745;
  background: #28a745;
  transform: scale(1.1);
}

.drag-source {
  background: #ff6b00;
  z-index: 2;
}

.drag-indicator {
  position: absolute;
  width: 40px;
  height: 40px;
  display: flex;
  justify-content: center;
  align-items: center;
  color: #ff6b00;
  z-index: 5;
  animation: fadeInOut 2s infinite;
}

.drag-indicator svg {
  width: 100%;
  height: 100%;
  stroke: currentColor;
}

.target-checkmark {
  width: 24px;
  height: 24px;
  animation: checkmark-pop 0.2s ease-out forwards;
}

.checkmark-check {
  stroke-dasharray: 48;
  stroke-dashoffset: 48;
  animation: checkmark-stroke 0.2s cubic-bezier(0.65, 0, 0.45, 1) 0.1s forwards;
}

.tap-target.success, .drag-target-area.success {
  transition: all 0.2s ease;
}

@keyframes checkmark-pop {
  0% {
    transform: scale(0);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

@keyframes checkmark-stroke {
  100% {
    stroke-dashoffset: 0;
  }
}

.controls-bar {
  display: flex;
  justify-content: center;
  gap: 1rem;
}

.action-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.6rem 1.2rem;
  border-radius: 6px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 140px;
  border: 1px solid transparent;
}

.action-button.danger {
  background-color: #dc3545;
  color: #fff;
}

.action-button.success {
  background-color: #28a745;
  color: #fff;
}

@keyframes stroke {
  100% { stroke-dashoffset: 0; }
}

@keyframes scale {
  0%, 100% { transform: none; }
  50% { transform: scale3d(1.1, 1.1, 1); }
}

@keyframes fill {
  100% { box-shadow: inset 0px 0px 0px 50px #28a745; }
}

@keyframes pulse {
  0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(255, 107, 0, 0.7); }
  70% { transform: scale(1); box-shadow: 0 0 0 20px rgba(255, 107, 0, 0); }
  100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(255, 107, 0, 0); }
}

@keyframes fadeInOut {
  0%, 100% { opacity: 0.4; }
  50% { opacity: 1; }
}
</style> 