<template>
    <div class="keyboard-test-container">
        <div class="test-header">
            <h2>
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                    class="feather feather-keyboard">
                    <rect x="2" y="6" width="20" height="12" rx="2" ry="2"></rect>
                    <line x1="6" y1="10" x2="6" y2="10"></line>
                    <line x1="10" y1="10" x2="10" y2="10"></line>
                    <line x1="14" y1="10" x2="14" y2="10"></line>
                    <line x1="18" y1="10" x2="18" y2="10"></line>
                    <line x1="8" y1="14" x2="8" y2="14"></line>
                    <line x1="12" y1="14" x2="12" y2="14"></line>
                    <line x1="16" y1="14" x2="16" y2="14"></line>
                    <line x1="6" y1="14" x2="6" y2="14"></line>
                </svg>
                Keyboard Test
            </h2>
            <p class="test-description">Press each key on your keyboard to verify they are working correctly.</p>
        </div>
        <div class="test-area">
            <div class="keyboard-view">
                <div class="keyboard-container">
                    <div class="keyboard-section function-row">
                        <div class="keyboard-row">
                            <div v-for="key in keyboardLayout.functions[0]" :key="key.code" :data-code="key.code"
                                class="key" :class="[key.style, { pressed: key.pressed, active: key.active, tested: key.tested, releasing: key.releasing }]">
                                <span v-if="key.code !== 'blank'">{{ key.display }}</span>
                            </div>
                        </div>
                    </div>

                    <div class="keyboard-section main-section">
                        <div class="main-keys">
                            <div v-for="(row, rowIndex) in keyboardLayout.main" :key="`row-${rowIndex}`"
                                class="keyboard-row">
                                <div v-for="key in row" :key="key.code" :data-code="key.code" class="key"
                                    :class="[key.style, { pressed: key.pressed, active: key.active, tested: key.tested, releasing: key.releasing }]">
                                    <span>{{ key.display }}</span>
                                </div>
                            </div>
                        </div>

                        <div class="side-section">
                            <div class="nav-keys">
                                <div v-for="(row, rowIndex) in keyboardLayout.navigation" :key="`nav-row-${rowIndex}`"
                                    class="keyboard-row">
                                    <div v-for="key in row" :key="key.code" :data-code="key.code" class="key"
                                        :class="[key.style, { pressed: key.pressed, active: key.active, tested: key.tested, releasing: key.releasing }]">
                                        <span>{{ key.display }}</span>
                                    </div>
                                </div>
                            </div>
                            <div class="arrow-keys">
                                <div v-for="(row, rowIndex) in keyboardLayout.arrows" :key="`arrow-row-${rowIndex}`"
                                    class="keyboard-row">
                                    <div v-for="key in row" :key="key.code" :data-code="key.code" class="key"
                                        :class="[key.style, { pressed: key.pressed, active: key.active, tested: key.tested, releasing: key.releasing }]">
                                        <span v-if="key.code !== 'blank'">{{ key.display }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
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
const keyboardLayoutDefinition = {
    main: [
        [{ code: 'Backquote', display: '`' }, { code: 'Digit1', display: '1' }, { code: 'Digit2', display: '2' }, { code: 'Digit3', display: '3' }, { code: 'Digit4', display: '4' }, { code: 'Digit5', display: '5' }, { code: 'Digit6', display: '6' }, { code: 'Digit7', display: '7' }, { code: 'Digit8', display: '8' }, { code: 'Digit9', display: '9' }, { code: 'Digit0', display: '0' }, { code: 'Minus', display: '-' }, { code: 'Equal', display: '=' }, { code: 'Backspace', style: 'utility key-backspace' }],
        [{ code: 'Tab', style: 'utility key-tab' }, { code: 'KeyQ', display: 'Q' }, { code: 'KeyW', display: 'W' }, { code: 'KeyE', display: 'E' }, { code: 'KeyR', display: 'R' }, { code: 'KeyT', display: 'T' }, { code: 'KeyY', display: 'Y' }, { code: 'KeyU', display: 'U' }, { code: 'KeyI', display: 'I' }, { code: 'KeyO', display: 'O' }, { code: 'KeyP', display: 'P' }, { code: 'BracketLeft', display: '[' }, { code: 'BracketRight', display: ']' }, { code: 'Backslash', display: '\\', style: 'utility key-backslash' }],
        [{ code: 'CapsLock', display: 'Caps', style: 'utility key-caps' }, { code: 'KeyA', display: 'A' }, { code: 'KeyS', display: 'S' }, { code: 'KeyD', display: 'D' }, { code: 'KeyF', display: 'F' }, { code: 'KeyG', display: 'G' }, { code: 'KeyH', display: 'H' }, { code: 'KeyJ', display: 'J' }, { code: 'KeyK', display: 'K' }, { code: 'KeyL', display: 'L' }, { code: 'Semicolon', display: ';' }, { code: 'Quote', display: '\'' }, { code: 'Enter', style: 'utility key-enter' }],
        [{ code: 'ShiftLeft', display: 'Shift', style: 'utility key-shift-left' }, { code: 'KeyZ', display: 'Z' }, { code: 'KeyX', display: 'X' }, { code: 'KeyC', display: 'C' }, { code: 'KeyV', display: 'V' }, { code: 'KeyB', display: 'B' }, { code: 'KeyN', display: 'N' }, { code: 'KeyM', display: 'M' }, { code: 'Comma', display: ',' }, { code: 'Period', display: '.' }, { code: 'Slash', display: '/' }, { code: 'ShiftRight', display: 'Shift', style: 'utility key-shift-right' }],
        [{ code: 'ControlLeft', display: 'Ctrl', style: 'utility' }, { code: 'MetaLeft', display: 'Win', style: 'utility' }, { code: 'AltLeft', display: 'Alt', style: 'utility' }, { code: 'Space', style: 'key-space' }, { code: 'AltRight', display: 'Alt', style: 'utility' }, { code: 'MetaRight', display: 'Win', style: 'utility' }, { code: 'ControlRight', display: 'Ctrl', style: 'utility' }]
    ],
    functions: [
        [{ code: 'Escape', display: 'Esc', style: 'utility' }, { code: 'blank', style: 'key-blank-f' }, { code: 'F1', style: 'utility' }, { code: 'F2', style: 'utility' }, { code: 'F3', style: 'utility' }, { code: 'F4', style: 'utility' }, { code: 'blank', style: 'key-blank-f' }, { code: 'F5', style: 'utility' }, { code: 'F6', style: 'utility' }, { code: 'F7', style: 'utility' }, { code: 'F8', style: 'utility' }, { code: 'blank', style: 'key-blank-f' }, { code: 'F9', style: 'utility' }, { code: 'F10', style: 'utility' }, { code: 'F11', style: 'utility' }, { code: 'F12', style: 'utility' }]
    ],
    navigation: [
        [{ code: 'Insert', display: 'Ins', style: 'utility' }, { code: 'Home', style: 'utility' }, { code: 'PageUp', display: 'PgUp', style: 'utility' }],
        [{ code: 'Delete', display: 'Del', style: 'utility' }, { code: 'End', style: 'utility' }, { code: 'PageDown', display: 'PgDn', style: 'utility' }]
    ],
    arrows: [
        [{ code: 'blank', style: 'key-blank' }, { code: 'ArrowUp', display: '↑', style: 'utility' }, { code: 'blank', style: 'key-blank' }],
        [{ code: 'ArrowLeft', display: '←', style: 'utility' }, { code: 'ArrowDown', display: '↓', style: 'utility' }, { code: 'ArrowRight', display: '→', style: 'utility' }]
    ]
};

export default {
    name: 'KeyboardTest',
    data() {
        return {
            keyboardLayout: {
                main: [],
                functions: [],
                navigation: [],
                arrows: [],
            },
            testCompleted: false
        }
    },
    computed: {
        pressedKeysCount() {
            const allKeys = Object.values(this.keyboardLayout).flat(2);
            return allKeys.filter(k => k.pressed).length;
        },
    },
    created() {
        this.initializeKeyboard();
    },
    mounted() {
        window.addEventListener('keydown', this.handleKeyDown);
        window.addEventListener('keyup', this.handleKeyUp);
    },
    beforeUnmount() {
        window.removeEventListener('keydown', this.handleKeyDown);
        window.removeEventListener('keyup', this.handleKeyUp);
    },
    methods: {
        initializeKeyboard() {
            for (const section in keyboardLayoutDefinition) {
                this.keyboardLayout[section] = keyboardLayoutDefinition[section].map(row =>
                    row.map(key => {
                        const isBlank = key.code === 'blank';
                        const display = isBlank ? '' : (key.display || key.code);
                        if (!isBlank);
                        return { ...key, display, pressed: false, active: false, releasing: false, tested: false, code: isBlank ? `blank-${Math.random()}` : key.code };
                    })
                );
            }
        },
        handleKeyDown(e) {
            e.preventDefault();
            const key = this.findKey(e.code);
            if (key) {
                key.releasing = false;
                key.pressed = true;
                key.active = true;
                key.tested = true;
            }
        },
        handleKeyUp(e) {
            const key = this.findKey(e.code);
            if (key) {
                key.pressed = false;
                key.active = false;
                key.releasing = true;
                setTimeout(() => {
                    if (key) key.releasing = false;
                }, 150); // Match the keyRelease animation duration
            }
        },
        findKey(code) {
            for (const section in this.keyboardLayout) {
                for (const row of this.keyboardLayout[section]) {
                    const found = row.find(k => k.code === code);
                    if (found) return found;
                }
            }
            return null;
        },
        completeTest() {
            if (this.testCompleted) {
                return;
            }
            this.$emit('test-completed', 'keyboard');
            this.testCompleted = true;
        },
        failTest() {
            if (this.testCompleted) {
                return;
            }
            this.$emit('test-failed', 'keyboard');
            this.testCompleted = true;
        },
        resetTest() {
            this.initializeKeyboard();
        }
    }
}
</script>

<style scoped>
@keyframes keyPress {
    0% {
        transform: translateY(0);
        border-bottom-width: 3px;
    }
    100% {
        transform: translateY(2px);
        border-bottom-width: 1px;
    }
}

@keyframes keyRelease {
    0% {
        transform: translateY(2px);
        border-bottom-width: 1px;
    }
    100% {
        transform: translateY(0);
        border-bottom-width: 3px;
    }
}

.keyboard-test-container {
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

.keyboard-view {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
}

.keyboard-content {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 1rem;
    margin: 1rem;
    background: #1e1e1e;
    border-radius: 8px;
    border: 1px solid #333;
}

.test-info {
    text-align: center;
    margin-bottom: 1.5rem;
}

.test-info .status {
    font-size: 1.1rem;
    color: #e0e0e0;
}

.keyboard-container {
    display: flex;
    flex-direction: column;
    gap: 6px;
    padding: 1rem;
    background-color: #1a1a1a;
    border-radius: 8px;
    border: 1px solid #333;
    width: 100%;
    max-width: 1200px;
}

.keyboard-section {
    display: flex;
    gap: 6px;
}

.main-section {
    display: flex;
    gap: 24px;
}

.main-keys {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.side-section {
    display: flex;
    flex-direction: column;
    gap: 24px;
}

.nav-keys, .arrow-keys {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.arrow-keys {
    margin-top: 30px;
}

.keyboard-row {
    display: flex;
    gap: 6px;
}

.key {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    height: 45px;
    min-width: 45px;
    padding: 0 5px;
    background-color: #444;
    color: #fff;
    border-radius: 6px;
    border: 1px solid #333;
    border-bottom: 3px solid #333;
    font-family: 'Consolas', 'Monaco', monospace;
    font-size: 0.85rem;
    transition: background-color 0.05s cubic-bezier(0.4, 0, 0.2, 1);
    user-select: none;
    flex-grow: 1;
    position: relative;
    top: 0;
}

.key.tested {
    background-color: #ff6b00;
}

.key.pressed {
    animation: keyPress 0.1s cubic-bezier(0.4, 0, 0.2, 1) forwards;
}

.key.releasing {
    animation: keyRelease 0.15s cubic-bezier(0.2, 0, 0.4, 1) forwards;
}

.key.active {
    background-color: #ff6b00;
    animation: keyPress 0.1s cubic-bezier(0.4, 0, 0.2, 1) forwards;
    box-shadow: 0 0 5px rgba(255, 107, 0, 0.5);
}

.key.utility {
    background-color: #333;
    color: #ccc;
}

.key.utility.tested {
    background-color: #ff6b00;
    color: #fff;
}

.key.utility.pressed,
.key.utility.active {
    background-color: #ff6b00;
    color: #fff;
}

.key.utility.releasing {
    color: #fff;
}

.key-space {
    min-width: 250px;
}

.key-backspace {
    min-width: 85px;
}

.key-tab {
    min-width: 70px;
}

.key-caps {
    min-width: 85px;
}

.key-enter {
    min-width: 85px;
}

.key-shift-left {
    min-width: 100px;
}

.key-shift-right {
    min-width: 100px;
}

.key-blank {
    background-color: transparent;
    border-color: transparent;
    pointer-events: none;
}

.key-blank-f {
    background-color: transparent;
    border-color: transparent;
    pointer-events: none;
    min-width: 20px;
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
</style>