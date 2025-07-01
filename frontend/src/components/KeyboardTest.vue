<template>
  <div class="keyboard-test-container">
    <div class="test-header">
      <h2><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-keyboard"><rect x="2" y="6" width="20" height="12" rx="2" ry="2"></rect><line x1="6" y1="10" x2="6" y2="10"></line><line x1="10" y1="10" x2="10" y2="10"></line><line x1="14" y1="10" x2="14" y2="10"></line><line x1="18" y1="10" x2="18" y2="10"></line><line x1="8" y1="14" x2="8" y2="14"></line><line x1="12" y1="14" x2="12" y2="14"></line><line x1="16" y1="14" x2="16" y2="14"></line><line x1="6" y1="14" x2="6" y2="14"></line></svg> Keyboard Test</h2>
    </div>

    <div class="test-area">
      <div class="keyboard-view">
        <div class="test-info">
          <p>Press each key on your keyboard. The corresponding key below will light up.</p>
          <div class="status">
            Remaining keys: <strong>{{ remainingKeysCount }}</strong>
          </div>
        </div>

        <div class="keyboard-container">
          <div class="keyboard-section main-keyboard">
            <div class="keyboard-row function-keys">
                <div v-for="key in keyboardLayout.functions[0]" :key="key.code" :data-code="key.code" class="key" :class="[key.style, { pressed: key.pressed, active: key.active }]">
                    <span v-if="key.code !== 'blank'">{{ key.display }}</span>
                </div>
            </div>
            <div class="keyboard main-keys">
                <div v-for="(row, rowIndex) in keyboardLayout.main" :key="`row-${rowIndex}`" class="keyboard-row">
                    <div v-for="key in row" :key="key.code" :data-code="key.code" class="key" :class="[key.style, { pressed: key.pressed, active: key.active }]">
                        <span>{{ key.display }}</span>
                    </div>
                </div>
            </div>
          </div>
          <div class="keyboard-section side-keys">
              <div class="keyboard navigation-keys">
                 <div v-for="(row, rowIndex) in keyboardLayout.navigation" :key="`nav-row-${rowIndex}`" class="keyboard-row">
                    <div v-for="key in row" :key="key.code" :data-code="key.code" class="key" :class="[key.style, { pressed: key.pressed, active: key.active }]">
                        <span>{{ key.display }}</span>
                    </div>
                </div>
              </div>
              <div class="keyboard arrow-keys">
                 <div v-for="(row, rowIndex) in keyboardLayout.arrows" :key="`arrow-row-${rowIndex}`" class="keyboard-row">
                    <div v-for="key in row" :key="key.code" :data-code="key.code" class="key" :class="[key.style, { pressed: key.pressed, active: key.active }]">
                        <span v-if="key.code !== 'blank'">{{ key.display }}</span>
                    </div>
                </div>
              </div>
          </div>
        </div>

        <div class="controls-bar">
           <button @click="failTest" class="action-button danger">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-x"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            <span>Not Working</span>
          </button>
          <button @click="completeTest" class="action-button success" :disabled="!allKeysPressed">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-check"><polyline points="20 6 9 17 4 12"></polyline></svg>
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
      [{ code: 'Escape', display: 'Esc', style: 'utility' }, {code: 'blank', style: 'key-blank-f'}, { code: 'F1', style: 'utility' }, { code: 'F2', style: 'utility' }, { code: 'F3', style: 'utility' }, { code: 'F4', style: 'utility' }, {code: 'blank', style: 'key-blank-f'}, { code: 'F5', style: 'utility' }, { code: 'F6', style: 'utility' }, { code: 'F7', style: 'utility' }, { code: 'F8', style: 'utility' }, {code: 'blank', style: 'key-blank-f'}, { code: 'F9', style: 'utility' }, { code: 'F10', style: 'utility' }, { code: 'F11', style: 'utility' }, { code: 'F12', style: 'utility' }]
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
      totalKeys: 0,
    }
  },
  computed: {
    pressedKeysCount() {
      const allKeys = Object.values(this.keyboardLayout).flat(2);
      return allKeys.filter(k => k.pressed).length;
    },
    remainingKeysCount() {
      return this.totalKeys - this.pressedKeysCount;
    },
    allKeysPressed() {
      return this.remainingKeysCount === 0;
    }
  },
  watch: {
    allKeysPressed(isComplete) {
      if (isComplete) {
        this.completeTest();
      }
    }
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
      let total = 0;
      for (const section in keyboardLayoutDefinition) {
          this.keyboardLayout[section] = keyboardLayoutDefinition[section].map(row => 
            row.map(key => {
              const isBlank = key.code === 'blank';
              const display = isBlank ? '' : (key.display || key.code);
              if (!isBlank) total++;
              return { ...key, display, pressed: false, active: false, code: isBlank ? `blank-${Math.random()}`: key.code };
            })
          );
      }
      this.totalKeys = total;
    },
    handleKeyDown(e) {
      e.preventDefault();
      const key = this.findKey(e.code);
      if (key) {
        key.pressed = true;
        key.active = true;
      }
    },
    handleKeyUp(e) {
      const key = this.findKey(e.code);
      if (key) {
        key.active = false;
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
      this.$emit('test-completed', 'keyboard');
    },
    failTest() {
      this.$emit('test-failed', 'keyboard');
    },
    resetTest() {
        this.initializeKeyboard();
    }
  }
}
</script>

<style scoped>
.keyboard-test-container {
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
}
.test-area {
  flex-grow: 1;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #252526;
  border-radius: 8px;
  padding: 1rem;
  overflow: auto;
}
.keyboard-view {
  width: 100%;
  max-width: 1200px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
}
.test-info {
  text-align: center;
  color: #a0a0a0;
}
.test-info .status {
  margin-top: 0.5rem;
  font-size: 1.1rem;
  color: #e0e0e0;
}
.keyboard-container {
    display: flex;
    gap: 1.5rem;
    padding: 1rem;
    background-color: #1a1a1a;
    border-radius: 8px;
    border: 1px solid #333;
}
.keyboard-section {
    display: flex;
    flex-direction: column;
    gap: 6px;
}
.keyboard {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.keyboard-row {
  display: flex;
  justify-content: center;
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
  transition: all 0.1s ease;
  user-select: none;
  flex-grow: 1;
}
.key.key-blank, .key.key-blank-f {
    background-color: transparent;
    border: none;
}
.key.key-blank-f {
    flex-grow: 0.5;
}
.key.pressed {
  background-color: #28a745;
  border-color: #208637;
  color: white;
}
.key.utility {
  background-color: #555;
}
.key.utility.pressed {
  background-color: #28a745;
}
.key.active {
  transform: translateY(2px);
  border-bottom-width: 1px;
  box-shadow: 0 0 8px rgba(255, 255, 255, 0.5);
}
/* Special key sizes */
.key.key-backspace { flex-grow: 2; }
.key.key-tab { flex-grow: 1.5; }
.key.key-backslash { flex-grow: 1.5; }
.key.key-caps { flex-grow: 1.8; }
.key.key-enter { flex-grow: 2.2; }
.key.key-shift-left { flex-grow: 2.3; }
.key.key-shift-right { flex-grow: 2.7; }
.key.key-space { flex-grow: 6; }

.function-keys {
    margin-bottom: 1rem;
}
.arrow-keys .keyboard-row:first-child {
    justify-content: center;
}
.arrow-keys .keyboard-row:last-child {
    justify-content: space-between;
}
.controls-bar {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  width: 100%;
  padding-top: 1.5rem;
  margin-top: 1rem;
  border-top: 1px solid #3c3c3c;
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
  border: 1px solid;
}

.action-button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.action-button.danger {
  background-color: #dc3545;
  border-color: #dc3545;
  color: #fff;
}
.action-button.danger:not(:disabled):hover {
  background-color: #c82333;
  border-color: #bd2130;
}

.action-button.success {
  background-color: #28a745;
  border-color: #28a745;
  color: #fff;
}
.action-button.success:not(:disabled):hover {
  background-color: #218838;
  border-color: #1e7e34;
}
</style> 