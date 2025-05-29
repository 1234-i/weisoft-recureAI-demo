<script setup lang="ts">
import { ref, onMounted } from 'vue'
import {PcmZyghModal} from 'pcm-agents-vue'
// 共享 token
const SHARED_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuaWNrbmFt";

// 普通聊天模态框
const isModalOpen = ref(false)
const customInputs = ref({
  type: '转行建议',
  file_url: '/resources/file/20250527/d0120aad3e90a8df0e608e6a74febae7.html',
  file_name: '产量与效益分析页.html'
})

// 模态框元素引用
const modalRef = ref(null)

const openChatModal = () => {
  const modalElement = document.getElementById('pcm-hr-chat-modal') as any
    if (modalElement) {
      modalElement.customInputs = customInputs.value
    }
  // 直接打开模态框，通过prop传递customInputs
  isModalOpen.value = true
}

const conversationId = ref('')

const handleModalClosed = () => {
  console.log('聊天窗口已关闭')
  isModalOpen.value = false
}

const handleStreamComplete = (event: CustomEvent) => {
  console.log('流式响应完成:', event.detail)
}

const handleConversationStart = (event: CustomEvent) => {
  console.log('会话开始:', event.detail)
  conversationId.value = event.detail.conversation_id
}

const handleInterviewComplete = (event: CustomEvent) => {
  console.log('面试完成:', event.detail)
  isModalOpen.value = false
}

</script>

<template>
  <main>
    <img alt="Vue logo" class="logo" src="./assets/logo.svg" width="125" height="125" />
    <div class="button-group">
      <button @click="openChatModal">打开职业规划助手</button>
    </div>
    
    <!-- 聊天模态框 - 通过prop传递customInputs -->
    <PcmZyghModal
      ref="modalRef"
      id="pcm-hr-chat-modal"
      modal-title="职业规划助手"
      :conversation-id="conversationId"
      :is-open="isModalOpen"
      :token="SHARED_TOKEN"
      :custom-inputs="customInputs"
      @modal-closed="handleModalClosed"
      @stream-complete="handleStreamComplete"
      @conversation-start="handleConversationStart"
      @interview-complete="handleInterviewComplete"
    ></PcmZyghModal>
  </main>
</template>

<style scoped>
header {
  line-height: 1.5;
}

.logo {
  display: block;
  margin: 0 auto 2rem;
}

.button-group {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

button {
  padding: 8px 16px;
  background-color: #1890ff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

button:hover {
  background-color: #40a9ff;
}

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
    padding-right: calc(var(--section-gap) / 2);
  }

  .logo {
    margin: 0 2rem 0 0;
  }

  header .wrapper {
    display: flex;
    place-items: flex-start;
    flex-wrap: wrap;
  }
}
</style>