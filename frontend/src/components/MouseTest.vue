<template>
    <div class="mouse-test-container">
        <div class="test-header">
            <h2>
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                    class="feather feather-mouse-pointer">
                    <path d="M3 3l7.07 16.97 2.51-7.39 7.39-2.51L3 3z"></path>
                    <path d="M13 13l6 6"></path>
                </svg>
                Mouse Test
            </h2>
            <p class="test-description">Click each mouse button and scroll the wheel to verify they are working correctly.</p>
        </div>

        <div class="test-area">
            <div class="mouse-view">
                <div class="mouse-container">
                    <svg class="mouse-graphic" viewBox="0 0 120 160" xmlns="http://www.w3.org/2000/svg">
                        <!-- Mouse body -->
                        <path class="mouse-body" d="M20,40 L20,120 Q20,145 60,145 Q100,145 100,120 L100,40 Q100,15 60,15 Q20,15 20,40"
                            fill="#444" stroke="#333" stroke-width="2"></path>
                        
                        <!-- Left button -->
                        <path :class="['mouse-button', 'left-button', { 
                            pressed: leftPressed, 
                            tested: leftTested,
                            releasing: leftReleasing 
                        }]"
                            d="M20,40 L20,85 L60,85 L60,15 Q20,15 20,40" fill="#444" stroke="#333" stroke-width="2"></path>
                        
                        <!-- Right button -->
                        <path :class="['mouse-button', 'right-button', { 
                            pressed: rightPressed, 
                            tested: rightTested,
                            releasing: rightReleasing 
                        }]"
                            d="M60,15 L60,85 L100,85 L100,40 Q100,15 60,15" fill="#444" stroke="#333" stroke-width="2"></path>
                        
                        <!-- Scroll wheel -->
                        <rect :class="['scroll-area', { active: scrollActive, tested: scrollTested }]"
                            x="52" y="30" width="16" height="40" rx="8" fill="#333"></rect>
                        
                        <!-- Middle click area -->
                        <rect :class="['middle-button', { 
                            pressed: middlePressed, 
                            tested: middleTested,
                            releasing: middleReleasing 
                        }]"
                            x="52" y="30" width="16" height="40" rx="8" fill="transparent" stroke="#333" stroke-width="2"></rect>
                    </svg>

                    <div class="test-status">
                        <div :class="['test-item', { completed: leftTested }]">Left Click</div>
                        <div :class="['test-item', { completed: rightTested }]">Right Click</div>
                        <div :class="['test-item', { completed: middleTested }]">Middle Click</div>
                        <div :class="['test-item', { completed: scrollTested }]">Scroll Wheel</div>
                    </div>
                </div>

                <div class="controls-bar">
                    <button @click="failTest" class="action-button danger">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                            class="feather feather-x">
                            <line x1="18" y1="6" x2="6" y2="18"></line>
                            <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                        <span>Not Working</span>
                    </button>
                    <button @click="completeTest" class="action-button success">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                            class="feather feather-check">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                        <span>Working</span>
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'MouseTest',
    data() {
        return {
            leftPressed: false,
            rightPressed: false,
            middlePressed: false,
            scrollActive: false,
            leftTested: false,
            rightTested: false,
            middleTested: false,
            scrollTested: false,
            leftReleasing: false,
            rightReleasing: false,
            middleReleasing: false,
            scrollTimeout: null
        }
    },
    mounted() {
        window.addEventListener('mousedown', this.handleMouseDown);
        window.addEventListener('mouseup', this.handleMouseUp);
        window.addEventListener('contextmenu', this.handleContextMenu);
        window.addEventListener('wheel', this.handleWheel);
    },
    beforeUnmount() {
        window.removeEventListener('mousedown', this.handleMouseDown);
        window.removeEventListener('mouseup', this.handleMouseUp);
        window.removeEventListener('contextmenu', this.handleContextMenu);
        window.removeEventListener('wheel', this.handleWheel);
    },
    methods: {
        handleMouseDown(e) {
            e.preventDefault();
            switch (e.button) {
                case 0: // Left click
                    this.leftReleasing = false;
                    this.leftPressed = true;
                    this.leftTested = true;
                    break;
                case 1: // Middle click
                    this.middleReleasing = false;
                    this.middlePressed = true;
                    this.middleTested = true;
                    break;
                case 2: // Right click
                    this.rightReleasing = false;
                    this.rightPressed = true;
                    this.rightTested = true;
                    break;
            }
        },
        handleMouseUp(e) {
            switch (e.button) {
                case 0:
                    this.leftPressed = false;
                    this.leftReleasing = true;
                    setTimeout(() => {
                        this.leftReleasing = false;
                    }, 150);
                    break;
                case 1:
                    this.middlePressed = false;
                    this.middleReleasing = true;
                    setTimeout(() => {
                        this.middleReleasing = false;
                    }, 150);
                    break;
                case 2:
                    this.rightPressed = false;
                    this.rightReleasing = true;
                    setTimeout(() => {
                        this.rightReleasing = false;
                    }, 150);
                    break;
            }
        },
        handleContextMenu(e) {
            e.preventDefault();
        },
        handleWheel() {
            this.scrollActive = true;
            this.scrollTested = true;
            
            if (this.scrollTimeout) {
                clearTimeout(this.scrollTimeout);
            }
            
            this.scrollTimeout = setTimeout(() => {
                this.scrollActive = false;
            }, 150);
        },
        completeTest() {
            this.$emit('test-completed', 'mouse');
        },
        failTest() {
            this.$emit('test-failed', 'mouse');
        },
        resetTest() {
            this.leftPressed = false;
            this.rightPressed = false;
            this.middlePressed = false;
            this.scrollActive = false;
            this.leftTested = false;
            this.rightTested = false;
            this.middleTested = false;
            this.scrollTested = false;
        }
    }
}
</script>

<style scoped>
@keyframes buttonPress {
    0% {
        transform: translateY(0);
        filter: drop-shadow(0 2px 2px rgba(0, 0, 0, 0.2));
    }
    100% {
        transform: translateY(2px);
        filter: drop-shadow(0 0px 0px rgba(0, 0, 0, 0.2));
    }
}

@keyframes buttonRelease {
    0% {
        transform: translateY(2px);
        filter: drop-shadow(0 0px 0px rgba(0, 0, 0, 0.2));
    }
    100% {
        transform: translateY(0);
        filter: drop-shadow(0 2px 2px rgba(0, 0, 0, 0.2));
    }
}

.mouse-test-container {
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

.mouse-view {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
}

.mouse-container {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 2rem;
    padding: 2rem;
}

.mouse-graphic {
    width: 200px;
    height: 320px;
}

.mouse-button {
    transition: all 0.1s ease;
    transform-origin: top;
    filter: drop-shadow(0 2px 2px rgba(0, 0, 0, 0.2));
}

.mouse-button.pressed {
    fill: #ff6b00;
    animation: buttonPress 0.1s cubic-bezier(0.4, 0, 0.2, 1) forwards;
}

.mouse-button.releasing {
    animation: buttonRelease 0.15s cubic-bezier(0.2, 0, 0.4, 1) forwards;
}

.mouse-button.tested {
    fill: #ff6b00;
}

.scroll-area {
    transition: all 0.1s ease;
}

.scroll-area.active {
    fill: #ff6b00;
}

.scroll-area.tested {
    fill: #ff6b00;
}

.middle-button {
    transition: all 0.1s ease;
    transform-origin: top;
    filter: drop-shadow(0 2px 2px rgba(0, 0, 0, 0.2));
}

.middle-button.pressed {
    fill: #ff6b00;
    animation: buttonPress 0.1s cubic-bezier(0.4, 0, 0.2, 1) forwards;
}

.middle-button.releasing {
    animation: buttonRelease 0.15s cubic-bezier(0.2, 0, 0.4, 1) forwards;
}

.middle-button.tested {
    fill: #ff6b00;
}

.test-status {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
    justify-content: center;
}

.test-item {
    padding: 0.5rem 1rem;
    background: #333;
    border-radius: 4px;
    color: #ccc;
}

.test-item.completed {
    background: #ff6b00;
    color: white;
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
}

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
</style> 