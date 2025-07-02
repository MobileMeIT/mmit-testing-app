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
      <div class="feedback-text" :class="{ success: stage === 'completed' }">
        {{ feedbackText }}
      </div>
      
      <div v-if="stage === 'idle'" class="start-prompt">
        <div class="tap-instruction">Tap anywhere to begin</div>
      </div>
      
      <div v-if="stage !== 'idle' && stage !== 'completed'" class="target-container">
        <!-- Tap Stage -->
        <div v-if="stage === 'tap'" class="target tap-target" :style="tapTargetStyle"></div>

        <!-- Drag Stage -->
        <template v-if="stage === 'drag'">
          <div class="target drag-target-area" :style="dragTargetStyle"></div>
          <div class="target drag-source" :style="dragSourceStyle"></div>
          <div class="drag-indicator" :style="dragIndicatorStyle">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
          </div>
        </template>

        <!-- Hold and Tap Stage -->
        <template v-if="stage === 'holdAndTap'">
          <div class="target hold-target" :class="{ held: holdTarget.isHeld }" :style="holdTargetStyle">
            <div v-if="!holdTarget.isHeld" class="hold-indicator">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
            </div>
            <div v-else class="hold-progress-ring">
              <svg viewBox="0 0 36 36">
                <path class="progress-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"/>
                <path class="progress-meter" :stroke-dasharray="`${holdProgress}, 100`" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"/>
              </svg>
            </div>
          </div>
          <div v-if="showSecondTarget" class="target tap-target" :style="otherTapTargetStyle"></div>
        </template>
      </div>

      <!-- Completion Animation -->
      <div v-if="stage === 'completed'" class="completion-animation">
        <svg class="checkmark" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 52">
          <circle class="checkmark-circle" cx="26" cy="26" r="25" fill="none"/>
          <path class="checkmark-check" fill="none" d="M14.1 27.2l7.1 7.2 16.7-16.8"/>
        </svg>
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
      stage: 'idle', // idle, tap, drag, holdAndTap, completed
      feedbackText: 'Touch or click the screen to begin the test.',
      
      tapTarget: { x: 0, y: 0, size: targetSize },
      dragSource: { x: 0, y: 0, size: targetSize, isDragging: false, touchId: null },
      dragTarget: { x: 0, y: 0, size: targetSize * 1.5 },
      holdTarget: { x: 0, y: 0, size: targetSize, isHeld: false, touchId: null },
      otherTapTarget: { x: 0, y: 0, size: targetSize },
      
      targetSize,
      padding,
      holdTimer: null,
      holdProgress: 0,
      showSecondTarget: false,
      holdDuration: 800 // ms to hold before showing second target
    }
  },
  computed: {
    tapTargetStyle() { return this.getStyle(this.tapTarget); },
    dragSourceStyle() { return { ...this.getStyle(this.dragSource), transition: this.dragSource.isDragging ? 'none' : 'all 0.3s ease' }; },
    dragTargetStyle() { return this.getStyle(this.dragTarget); },
    holdTargetStyle() { return this.getStyle(this.holdTarget); },
    otherTapTargetStyle() { return this.getStyle(this.otherTapTarget); },
    dragIndicatorStyle() {
      // Position indicator between drag source and target
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
      
      // Calculate angle for arrow rotation
      const angle = Math.atan2(targetCenter.y - sourceCenter.y, targetCenter.x - sourceCenter.x) * 180 / Math.PI;
      
      return {
        left: `${midX - 20}px`,
        top: `${midY - 20}px`,
        transform: `rotate(${angle}deg)`
      };
    }
  },
  mounted() {
    // Initialize test area dimensions
    window.addEventListener('resize', this.handleResize);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.handleResize);
    this.clearHoldTimer();
  },
  methods: {
    getStyle(target) {
        return { 
            left: `${target.x}px`, top: `${target.y}px`, 
            width: `${target.size}px`, height: `${target.size}px` 
        };
    },
    
    handleResize() {
      if (this.stage !== 'idle') {
        const testArea = document.querySelector('.test-area');
        if (!testArea) return;
        
        const viewBox = testArea.getBoundingClientRect();
        const centerX = viewBox.width / 2;
        const centerY = viewBox.height / 2;
        const spacing = Math.min(viewBox.width * 0.3, 150);
        
        if (this.stage === 'tap') {
          this.tapTarget.x = centerX - this.targetSize / 2;
          this.tapTarget.y = centerY - this.targetSize / 2;
        } else if (this.stage === 'drag') {
          this.dragSource.x = centerX - spacing - this.dragSource.size / 2;
          this.dragSource.y = centerY - this.dragSource.size / 2;
          this.dragTarget.x = centerX + spacing - this.dragTarget.size / 2;
          this.dragTarget.y = centerY - this.dragTarget.size / 2;
        } else if (this.stage === 'holdAndTap') {
          this.holdTarget.x = centerX - spacing - this.holdTarget.size / 2;
          this.holdTarget.y = centerY - this.holdTarget.size / 2;
          this.otherTapTarget.x = centerX + spacing - this.otherTapTarget.size / 2;
          this.otherTapTarget.y = centerY - this.otherTapTarget.size / 2;
        }
      }
    },
    
    startTest() {
      this.setupTapStage();
    },

    setupTapStage() {
      const testArea = document.querySelector('.test-area');
      if (!testArea) return;
      
      const viewBox = testArea.getBoundingClientRect();
      const centerX = viewBox.width / 2;
      const centerY = viewBox.height / 2;
      
      this.stage = 'tap';
      this.feedbackText = 'Tap the circle.';
      this.tapTarget.x = centerX - this.targetSize / 2;
      this.tapTarget.y = centerY - this.targetSize / 2;
    },

    setupDragStage() {
      const testArea = document.querySelector('.test-area');
      if (!testArea) return;
      
      const viewBox = testArea.getBoundingClientRect();
      this.stage = 'drag';
      this.feedbackText = 'Drag the orange circle into the outlined circle.';
      
      // Calculate positions to be more centered with reasonable spacing
      const centerX = viewBox.width / 2;
      const centerY = viewBox.height / 2;
      const spacing = Math.min(viewBox.width * 0.3, 150); // Reasonable spacing that scales with container width
      
      this.dragSource.x = centerX - spacing - this.dragSource.size / 2;
      this.dragSource.y = centerY - this.dragSource.size / 2;
      this.dragTarget.x = centerX + spacing - this.dragTarget.size / 2;
      this.dragTarget.y = centerY - this.dragTarget.size / 2;
    },

    setupHoldAndTapStage() {
      const testArea = document.querySelector('.test-area');
      if (!testArea) return;
      
      const viewBox = testArea.getBoundingClientRect();
      this.stage = 'holdAndTap';
      this.feedbackText = 'Hold the circle until the second circle appears, then tap it.';
      
      // Calculate positions to be more centered with reasonable spacing
      const centerX = viewBox.width / 2;
      const centerY = viewBox.height / 2;
      const spacing = Math.min(viewBox.width * 0.3, 150); // Reasonable spacing that scales with container width
      
      this.holdTarget.x = centerX - spacing - this.holdTarget.size / 2;
      this.holdTarget.y = centerY - this.holdTarget.size / 2;
      this.otherTapTarget.x = centerX + spacing - this.otherTapTarget.size / 2;
      this.otherTapTarget.y = centerY - this.otherTapTarget.size / 2;
      
      this.showSecondTarget = false;
      this.holdProgress = 0;
    },

    completeStage() {
      if (this.stage === 'tap') this.setupDragStage();
      else if (this.stage === 'drag') this.setupHoldAndTapStage();
      else if (this.stage === 'holdAndTap') this.completeTestFlow();
    },
    
    completeTestFlow() {
      this.stage = 'completed';
      this.feedbackText = 'Touch test passed!';
      setTimeout(() => this.$emit('test-completed', 'touch'), 1500);
    },

    isInsideCircle(point, circle) {
      const radius = circle.size / 2;
      const circleCenterX = circle.x + radius;
      const circleCenterY = circle.y + radius;
      const distance = Math.sqrt(Math.pow(point.x - circleCenterX, 2) + Math.pow(point.y - circleCenterY, 2));
      return distance <= radius;
    },

    startHoldTimer() {
      this.clearHoldTimer();
      this.holdProgress = 0;
      
      const startTime = Date.now();
      const updateInterval = 30; // Update progress every 30ms
      
      this.holdTimer = setInterval(() => {
        const elapsed = Date.now() - startTime;
        this.holdProgress = Math.min(100, (elapsed / this.holdDuration) * 100);
        
        if (elapsed >= this.holdDuration) {
          this.clearHoldTimer();
          this.showSecondTarget = true;
        }
      }, updateInterval);
    },
    
    clearHoldTimer() {
      if (this.holdTimer) {
        clearInterval(this.holdTimer);
        this.holdTimer = null;
      }
    },

    handlePointerDown(e) {
      const testArea = document.querySelector('.test-area');
      if (!testArea) return;
      
      if (e.type === 'mousedown' && e.button !== 0) return;
      
      const viewBox = testArea.getBoundingClientRect();
      const touches = e.changedTouches || [e];
      
      if (this.stage === 'idle') {
        this.startTest();
        return;
      }
      
      for (let touch of touches) {
        const touchId = touch.identifier ?? 'mouse';
        const touchPoint = { x: touch.clientX - viewBox.left, y: touch.clientY - viewBox.top };
        
        if (this.stage === 'tap' && this.isInsideCircle(touchPoint, this.tapTarget)) {
            this.completeStage();
        } 
        else if (this.stage === 'drag' && this.isInsideCircle(touchPoint, this.dragSource)) {
            this.dragSource.isDragging = true;
            this.dragSource.touchId = touchId;
        }
        else if (this.stage === 'holdAndTap') {
            if (this.isInsideCircle(touchPoint, this.holdTarget) && this.holdTarget.touchId === null) {
                this.holdTarget.isHeld = true;
                this.holdTarget.touchId = touchId;
                this.startHoldTimer();
            } else if (this.showSecondTarget && this.isInsideCircle(touchPoint, this.otherTapTarget)) {
                this.completeStage();
            }
        }
      }
    },

    handlePointerMove(e) {
      if (this.stage !== 'drag' || !this.dragSource.isDragging) return;
      
      if (e.type === 'mousemove' && e.buttons !== 1) {
        this.handlePointerUp(e);
        return;
      }
      
      const testArea = document.querySelector('.test-area');
      if (!testArea) return;
      
      const viewBox = testArea.getBoundingClientRect();
      const touches = e.changedTouches || [e];
      for (let touch of touches) {
        if ((touch.identifier ?? 'mouse') === this.dragSource.touchId) {
          this.dragSource.x = touch.clientX - viewBox.left - this.targetSize / 2;
          this.dragSource.y = touch.clientY - viewBox.top - this.targetSize / 2;
        }
      }
    },

    handlePointerUp(e) {
      const testArea = document.querySelector('.test-area');
      if (!testArea) return;
      
      const touches = e.changedTouches || [e];
      for (let touch of touches) {
        const touchId = touch.identifier ?? 'mouse';
        if (this.stage === 'drag' && touchId === this.dragSource.touchId) {
            this.dragSource.isDragging = false;
            this.dragSource.touchId = null;
            const sourceCenter = { x: this.dragSource.x + this.targetSize/2, y: this.dragSource.y + this.targetSize/2 };
            if (this.isInsideCircle(sourceCenter, this.dragTarget)) {
                this.completeStage();
            } else {
                const viewBox = testArea.getBoundingClientRect();
                const centerX = viewBox.width / 2;
                const centerY = viewBox.height / 2;
                const spacing = Math.min(viewBox.width * 0.3, 150);
                
                this.dragSource.x = centerX - spacing - this.dragSource.size / 2;
                this.dragSource.y = centerY - this.dragSource.size / 2;
            }
        }
        else if (this.stage === 'holdAndTap' && touchId === this.holdTarget.touchId) {
            this.holdTarget.isHeld = false;
            this.holdTarget.touchId = null;
            this.clearHoldTimer();
        }
      }
    },

    handleMouseLeave() {
      if (this.stage === 'drag' && this.dragSource.isDragging) {
        this.dragSource.isDragging = false;
        this.dragSource.touchId = null;
        
        const testArea = document.querySelector('.test-area');
        if (!testArea) return;
        
        const viewBox = testArea.getBoundingClientRect();
        const centerX = viewBox.width / 2;
        const centerY = viewBox.height / 2;
        const spacing = Math.min(viewBox.width * 0.3, 150);
        
        this.dragSource.x = centerX - spacing - this.dragSource.size / 2;
        this.dragSource.y = centerY - this.dragSource.size / 2;
      }
      
      if (this.stage === 'holdAndTap' && this.holdTarget.isHeld) {
        this.holdTarget.isHeld = false;
        this.holdTarget.touchId = null;
        this.clearHoldTimer();
      }
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
  min-height: 300px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.start-prompt {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
}

.tap-instruction {
  color: #a0a0a0;
  font-size: 1.2rem;
  animation: pulse 2s infinite;
}

.feedback-text {
  position: absolute;
  top: 2rem;
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
}

.tap-target {
  background-color: #ff6b00;
  box-shadow: 0 0 20px #ff6b00;
  animation: pulse 2s infinite;
  transition: all 0.2s ease-in-out;
}

.drag-source {
  background-color: #ff6b00;
  z-index: 10;
}

.drag-target-area {
  border: 3px dashed #666;
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

.hold-target {
  background-color: #ff6b00;
  animation: pulse 2s infinite;
  transition: all 0.2s ease-in-out;
  display: flex;
  justify-content: center;
  align-items: center;
}

.hold-target.held {
  background-color: #e66000;
  transform: scale(0.9);
  animation: none;
}

.hold-indicator {
  color: rgba(255, 255, 255, 0.7);
  width: 60%;
  height: 60%;
  animation: fadeInOut 2s infinite;
}

.hold-indicator svg {
  width: 100%;
  height: 100%;
  stroke: currentColor;
}

.hold-progress-ring {
  width: 80%;
  height: 80%;
}

.hold-progress-ring svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.progress-bg {
  fill: none;
  stroke: rgba(255, 255, 255, 0.2);
  stroke-width: 3;
}

.progress-meter {
  fill: none;
  stroke: white;
  stroke-width: 3;
  stroke-linecap: round;
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

/* Completion Animation */
.completion-animation {
  z-index: 50;
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
}

.checkmark-circle {
  stroke-dasharray: 166;
  stroke-dashoffset: 166;
  stroke-width: 3;
  stroke-miterlimit: 10;
  stroke: #28a745;
  fill: none;
  animation: stroke 0.6s cubic-bezier(0.65, 0, 0.45, 1) forwards;
}

.checkmark {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  display: block;
  stroke-width: 3;
  stroke: #fff;
  stroke-miterlimit: 10;
  box-shadow: inset 0px 0px 0px #28a745;
  animation: fill .4s ease-in-out .4s forwards, scale .3s ease-in-out .9s both;
}

.checkmark-check {
  transform-origin: 50% 50%;
  stroke-dasharray: 48;
  stroke-dashoffset: 48;
  animation: stroke 0.3s cubic-bezier(0.65, 0, 0.45, 1) 0.8s forwards;
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