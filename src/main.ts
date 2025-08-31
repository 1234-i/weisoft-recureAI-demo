import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'

// 引入Web Components
import { defineCustomElements } from 'pcm-agents/loader';

// 确保在创建应用前定义自定义元素
defineCustomElements();

const app = createApp(App)

app.mount('#app')
