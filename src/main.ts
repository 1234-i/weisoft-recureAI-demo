import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import { defineCustomElements } from 'pcm-agents/loader';
// 确保在创建应用前定义自定义元素
defineCustomElements();
createApp(App).mount('#app')
