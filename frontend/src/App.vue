<template>
  <div class="app-layout">
    <!-- Left Sidebar -->
    <aside class="sidebar">
      <div class="sidebar-header">
        <div class="brand-icon">🔧</div>
        <h2>MMIT Suite</h2>
      </div>
      <nav class="test-nav">
        <ul>
          <li 
            :class="{ active: activeTest === 'webcam' }"
            @click="setActiveTest('webcam')"
          >
            <div class="test-icon">📹</div>
            <span class="test-name">Camera Test</span>
            <span class="status-indicator" :class="getTestStatusClass('webcam')"></span>
          </li>
          <li 
            :class="{ active: activeTest === 'microphone' }"
            @click="setActiveTest('microphone')"
          >
            <div class="test-icon">🎤</div>
            <span class="test-name">Microphone Test</span>
            <span class="status-indicator" :class="getTestStatusClass('microphone')"></span>
          </li>
          <li 
            :class="{ active: activeTest === 'speakers' }"
            @click="setActiveTest('speakers')"
          >
            <div class="test-icon">🔊</div>
            <span class="test-name">Speaker Test</span>
            <span class="status-indicator" :class="getTestStatusClass('speakers')"></span>
          </li>
        </ul>
      </nav>
       <div class="sidebar-footer">
          <div v-if="allTestsCompleted" class="summary">
            <h4>All Tests Complete</h4>
            <p>{{ getOverallStatusText() }}</p>
          </div>
          <button v-if="allTestsCompleted" @click="exportResults" class="action-button primary">📊 Export Report</button>
          <button @click="resetTests" class="action-button secondary">🔄 Reset Tests</button>
       </div>
    </aside>

    <!-- Main Content -->
    <main class="main-content">
      <div class="test-panel-wrapper">
         <WebcamTest v-if="activeTest === 'webcam'" @test-completed="onTestCompleted('webcam')" @test-failed="onTestFailed('webcam')" />
         <MicrophoneTest v-if="activeTest === 'microphone'" @test-completed="onTestCompleted('microphone')" @test-failed="onTestFailed('microphone')" />
         <SpeakerTest v-if="activeTest === 'speakers'" @test-completed="onTestCompleted('speakers')" @test-failed="onTestFailed('speakers')" />
      </div>
    </main>
  </div>
</template>

<script>
import WebcamTest from './components/WebcamTest.vue'
import MicrophoneTest from './components/MicrophoneTest.vue'
import SpeakerTest from './components/SpeakerTest.vue'

export default {
  name: 'App',
  components: {
    WebcamTest,
    MicrophoneTest,
    SpeakerTest
  },
  data() {
    return {
      activeTest: 'webcam', // Start with webcam test
      results: {
        webcam: null, // null: pending, true: pass, false: fail
        microphone: null,
        speakers: null
      }
    }
  },
  computed: {
    allTestsCompleted() {
      return Object.values(this.results).every(r => r !== null);
    }
  },
  methods: {
    setActiveTest(testType) {
      this.activeTest = testType;
    },
    onTestCompleted(testType) {
      this.results[testType] = true;
      this.autoAdvance(testType);
    },
    onTestFailed(testType) {
      this.results[testType] = false;
    },
    autoAdvance(currentTest) {
        const tests = ['webcam', 'microphone', 'speakers'];
        const currentIndex = tests.indexOf(currentTest);
        if (currentIndex < tests.length - 1) {
          // Find next test that is not yet completed
          for(let i = currentIndex + 1; i < tests.length; i++) {
            if (this.results[tests[i]] === null) {
              this.setActiveTest(tests[i]);
              return;
            }
          }
          // If all next tests are done, look from start
           for(let i = 0; i < currentIndex; i++) {
            if (this.results[tests[i]] === null) {
              this.setActiveTest(tests[i]);
              return;
            }
          }
        }
    },
    resetTests() {
        this.activeTest = 'webcam';
        this.results = {
            webcam: null,
            microphone: null,
            speakers: null
        };
    },
    getTestStatusClass(testType) {
        if (this.results[testType] === true) return 'completed-success';
        if (this.results[testType] === false) return 'completed-fail';
        return 'pending';
    },
    getOverallStatusText() {
      const passed = Object.values(this.results).filter(r => r === true).length;
      const failed = Object.values(this.results).filter(r => r === false).length;
      
      if (failed === 0) return 'All Systems Go!';
      return `${passed} Passed, ${failed} Failed`;
    },
    exportResults() {
      const report = {
        timestamp: new Date().toISOString(),
        results: this.results,
        summary: this.getOverallStatusText()
      }
      
      const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `mmit-test-results-${new Date().toISOString().split('T')[0]}.json`;
      a.click();
      URL.revokeObjectURL(url);
    },
  }
}
</script>

<style scoped>
/* Global Layout */
.app-layout {
  display: flex;
  min-height: 100vh;
  background-color: #0d0d0d; /* Slightly darker bg */
  color: #d4d4d4; /* Softer text color */
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
}

/* Sidebar */
.sidebar {
  width: 250px; /* Reduced width */
  flex-shrink: 0;
  background-color: #141414; /* Darker sidebar */
  border-right: 1px solid #262626; /* Softer border */
  display: flex;
  flex-direction: column;
  padding: 1rem; /* Reduced padding */
  transition: width 0.3s ease;
}

.sidebar-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 2rem; /* Reduced margin */
  padding: 0.5rem;
  flex-shrink: 0;
}

.sidebar-header .brand-icon {
  font-size: 1.5rem; /* Reduced icon size */
  color: #ff6b00;
}

.sidebar-header h2 {
  font-size: 1.25rem; /* Reduced font size */
  font-weight: 600;
  color: #f0f0f0;
  margin: 0;
}

/* Test Navigation */
.test-nav {
  flex-grow: 1;
}
.test-nav ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.test-nav li {
  display: flex;
  align-items: center;
  padding: 0.75rem 1rem; /* Reduced padding */
  margin-bottom: 0.5rem; /* Reduced margin */
  border-radius: 6px; /* Sharper radius */
  cursor: pointer;
  transition: background-color 0.2s ease, border-color 0.2s ease, color 0.2s ease;
  border: 1px solid transparent; /* Full border, transparent by default */
  color: #a0a0a0;
}

.test-nav li:hover {
  background-color: #222;
  color: #fff;
}

.test-nav li.active {
  background-color: rgba(255, 107, 0, 0.08); /* Slightly less background */
  border-color: rgba(255, 107, 0, 0.5); /* Full border color for active */
  color: #ff9854; /* Brighter active color */
  font-weight: 500; /* Medium weight */
}

.test-nav .test-icon {
  font-size: 1.2rem; /* Reduced icon size */
  margin-right: 0.8rem;
  width: 20px;
  text-align: center;
}

/* Status Indicator in Sidebar */
.status-indicator {
  width: 8px; /* Smaller indicator */
  height: 8px;
  border-radius: 50%;
  margin-left: auto; /* Push to the right */
  transition: background-color 0.3s ease, box-shadow 0.3s ease;
  box-shadow: 0 0 6px transparent;
}

.status-indicator.pending {
  background-color: #555; /* Darker pending */
}

.status-indicator.completed-success {
  background-color: #28a745;
  box-shadow: 0 0 6px #28a745;
}

.status-indicator.completed-fail {
  background-color: #dc3545;
  box-shadow: 0 0 6px #dc3545;
}

/* Sidebar Footer */
.sidebar-footer {
  margin-top: auto;
  padding-top: 1rem; /* Reduced padding */
  border-top: 1px solid #262626;
  flex-shrink: 0;
}

.summary {
  text-align: center;
  margin-bottom: 1rem;
  padding: 0.75rem;
  background-color: #1f1f1f;
  border-radius: 6px;
}

.summary h4 {
  font-size: 0.9rem; /* Reduced font size */
  margin: 0 0 0.25rem;
  color: #fff;
}

.summary p {
  margin: 0;
  font-size: 0.8rem;
  color: #ff6b00;
  font-weight: 500;
}

.action-button {
  width: 100%;
  padding: 0.6rem 1rem; /* Reduced padding */
  border: 1px solid transparent;
  border-radius: 6px; /* Sharper radius */
  font-size: 0.9rem; /* Reduced font size */
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 0.5rem;
}

.action-button.primary {
  background: #ff6b00;
  color: white;
  border-color: #ff6b00;
}
.action-button.primary:hover {
  background: #e66000;
  border-color: #e66000;
}

.action-button.secondary {
  background: transparent;
  color: #a0a0a0;
  border-color: #444;
}
.action-button.secondary:hover {
  background: #222;
  color: #fff;
  border-color: #555;
}

/* Main Content */
.main-content {
  flex: 1;
  padding: 2rem; /* Reduced padding */
  overflow-y: auto;
}

.test-panel-wrapper {
  background-color: #141414; /* Match sidebar */
  border-radius: 8px; /* Sharper radius */
  padding: 2rem;
  border: 1px solid #262626;
  min-height: 100%;
  box-shadow: 0 4px 25px rgba(0,0,0,0.2);
}
</style> 