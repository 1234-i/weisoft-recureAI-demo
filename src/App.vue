<script setup lang="ts">
import { ref, onMounted } from "vue";
import { PcmZyghModal, PcmJlzzModal, PcmZskChatModal } from "pcm-agents-vue";
// 导入 naive-ui 组件
import {
  NModal,
  NButton,
  NSpace,
  NMessageProvider,
  NConfigProvider,
} from "naive-ui";

// Token 相关状态
const token = ref("");
const isTokenLoading = ref(false);
const customInputs = ref({
  type: "晋升路径",
  file_url: "/resources/file/20250418/590671879d5bf4b6ffe045664ff59ec7.pdf",
  file_name: "陈静- JAVA.pdf",
});

// 智能员工模态框状态
const isZskModalOpen = ref(false);
const isNaiveModalOpen = ref(false);

interface TokenData {
  token: string;
  time_expire: string;
}

// 获取 Token 的函数
const fetchToken = async (forceRefresh = false): Promise<string> => {
  try {
    // 如果不是强制刷新，先从缓存中获取 token
    if (!forceRefresh) {
      const cachedTokenData = localStorage.getItem("sdk_token");

      if (cachedTokenData) {
        const tokenData: TokenData = JSON.parse(cachedTokenData);
        const currentTime = Math.floor(Date.now() / 1000); // 当前时间戳（秒）
        const expireTime = parseInt(tokenData.time_expire);

        // 如果 token 未过期且距离过期时间超过30分钟，直接使用缓存的 token
        const thirtyMinutesInSeconds = 30 * 60;
        if (
          expireTime > currentTime &&
          expireTime - currentTime > thirtyMinutesInSeconds
        ) {
          console.log("使用缓存的 token");
          return tokenData.token;
        }

        console.log("token 即将过期（剩余不足30分钟），重新获取");
      }
    } else {
      console.log("强制刷新 token");
    }

    // 缓存不存在、已过期或强制刷新，重新获取 token
    const response = await fetch(
      "https://****/sys/sdk/access-token",
      {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const res = await response.json();
    console.log("获取token响应:", res);

    if (res && res.data) {
      const tokenData = res.data;
      // 保存到缓存
      localStorage.setItem("sdk_token", JSON.stringify(tokenData));
      return tokenData.token;
    }

    throw new Error("获取token失败：响应数据格式错误");
  } catch (error) {
    console.error("获取 token 失败:", error);
    return "";
  }
};

// 初始化获取 Token
const initToken = async () => {
  isTokenLoading.value = true;
  try {
    const accessToken = await fetchToken();
    token.value = accessToken;
    if (!accessToken) {
      console.error("获取 token 失败");
    }
  } catch (error) {
    console.error("初始化 token 失败:", error);
  } finally {
    isTokenLoading.value = false;
  }
};

// 处理 token 验证失败
const handleTokenInvalid = async () => {
  console.log("SDK密钥验证失败，重新获取token");

  // 强制刷新 token
  const newToken = await fetchToken(true);
  if (newToken) {
    token.value = newToken;
  } else {
    console.error("重新获取 token 失败");
  }
};

// 普通聊天模态框
const isModalOpen = ref(false);

// 简历制作模态框
const isJlzzModalOpen = ref(false);

// 模态框元素引用
const modalRef = ref(null);
const jlzzModalRef = ref(null);

const openChatModal = () => {
  // 检查是否有有效的 token
  if (!token.value) {
    console.error("没有有效的 token，无法打开聊天窗口");
    return;
  }

  // 直接打开模态框
  isModalOpen.value = true;
};

const openJlzzModal = () => {
  // 检查是否有有效的 token
  if (!token.value) {
    console.error("没有有效的 token，无法打开简历制作窗口");
    return;
  }

  // 直接打开模态框
  isJlzzModalOpen.value = true;
};

// 打开智能员工模态框（使用 naive-ui modal）
const openZskModal = () => {
  if (!token.value) {
    console.error("没有有效的 token，无法打开智能员工窗口");
    return;
  }

  isNaiveModalOpen.value = true;
  // 延迟一点打开内部的 PcmZskChatModal
  setTimeout(() => {
    isZskModalOpen.value = true;
  }, 100);
};

// 关闭智能员工模态框
const closeZskModal = () => {
  isZskModalOpen.value = false;
  isNaiveModalOpen.value = false;
};

const conversationId = ref("");

const handleModalClosed = () => {
  console.log("聊天窗口已关闭");
  isModalOpen.value = false;
};

const handleJlzzModalClosed = () => {
  console.log("简历制作窗口已关闭");
  isJlzzModalOpen.value = false;
};

// 智能员工模态框关闭处理
const handleZskModalClosed = () => {
  console.log("智能员工窗口已关闭");
  closeZskModal();
};

const handleStreamComplete = (event: CustomEvent) => {
  console.log("流式响应完成:", event.detail);
};

const handleConversationStart = (event: CustomEvent) => {
  console.log("会话开始:", event.detail);
  conversationId.value = event.detail.conversation_id;
};

const handleInterviewComplete = (event: CustomEvent) => {
  console.log("面试完成:", event.detail);
  isModalOpen.value = false;
};

// 智能员工会话开始处理
const handleZskConversationStart = (event: CustomEvent) => {
  console.log("智能员工会话开始:", event.detail);
};

const handleJlzzConversationStart = (event: CustomEvent) => {
  console.log("简历制作会话开始:", event.detail);
};


// 组件挂载时获取 token
onMounted(() => {
  initToken();
});
</script>

<template>
  <NConfigProvider>
    <NMessageProvider>
      <main>
        <img
          alt="Vue logo"
          class="logo"
          src="./assets/logo.svg"
          width="125"
          height="125"
        />

        <!-- Token 状态显示 -->
        <div class="token-status">
          <p v-if="isTokenLoading">正在获取 Token...</p>
          <p v-else-if="token" class="token-success">✅ Token 获取成功</p>
          <p v-else class="token-error">❌ Token 获取失败</p>
        </div>

        <NSpace vertical size="large">
          <NSpace justify="center">
            <NButton
              type="primary"
              size="large"
              @click="openChatModal"
              :disabled="!token || isTokenLoading"
            >
              打开职业规划助手
            </NButton>
            <NButton
              type="info"
              size="large"
              @click="openJlzzModal"
              :disabled="!token || isTokenLoading"
            >
              打开简历制作
            </NButton>
            <NButton
              type="success"
              size="large"
              @click="openZskModal"
              :disabled="!token || isTokenLoading"
            >
              🤖 打开智能员工助手
            </NButton>
            <NButton
              type="warning"
              size="large"
              @click="initToken"
              :loading="isTokenLoading"
            >
              重新获取Token
            </NButton>
          </NSpace>
        </NSpace>

        <!-- 聊天模态框 - 使用动态获取的token -->
        <PcmZyghModal
          v-if="token"
          ref="modalRef"
          id="pcm-chat-modal"
          modal-title="职业规划助手"
          :is-open="isModalOpen"
          :token="token"
          :custom-inputs="customInputs"
          @modal-closed="handleModalClosed"
          @stream-complete="handleStreamComplete"
          @conversation-start="handleConversationStart"
          @interview-complete="handleInterviewComplete"
          @token-invalid="handleTokenInvalid"
        ></PcmZyghModal>

        <!-- 简历制作模态框 -->
        <PcmJlzzModal
          v-if="token"
          ref="jlzzModalRef"
          id="pcm-jlzz-modal"
          modal-title="简历制作"
          icon="https://pub.pincaimao.com/static/common/i_pcm_logo.png"
          :fullscreen="false"
          :is-open="isJlzzModalOpen"
          :token="token"
          @modal-closed="handleJlzzModalClosed"
          @conversation-start="handleJlzzConversationStart"
          @token-invalid="handleTokenInvalid"
        ></PcmJlzzModal>

       

        <!-- 使用 naive-ui Modal 嵌套 PcmZskChatModal 智能员工组件 -->
        <n-modal
          v-model:show="isNaiveModalOpen"
          class="custom-card"
          preset="card"
          :style="{width: '600px'}"
          size="huge"
          :bordered="false"
          :auto-focus="false"
          :trap-focus="false"
          :mask-closable="false"
          :close-on-esc="false"
        >
          <PcmZskChatModal
            v-if="token"
            id="pcm-zsk-modal"
            :is-open="isZskModalOpen"
            :token="token"
            fullscreen="false"
            employee-id="137"
            @modal-closed="handleZskModalClosed"
            @conversation-start="handleZskConversationStart"
            @stream-complete="handleStreamComplete"
            @token-invalid="handleTokenInvalid"
          ></PcmZskChatModal>
        </n-modal>
      </main>
    </NMessageProvider>
  </NConfigProvider>
</template>

<style scoped>
header {
  line-height: 1.5;
}

.logo {
  display: block;
  margin: 0 auto 2rem;
}

.token-status {
  margin-bottom: 20px;
  padding: 15px;
  border-radius: 8px;
  text-align: center;
  font-weight: 500;
}

.token-success {
  color: #52c41a;
  background-color: #f6ffed;
  border: 1px solid #b7eb8f;
}

.token-error {
  color: #ff4d4f;
  background-color: #fff2f0;
  border: 1px solid #ffccc7;
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

button.disabled,
button:disabled {
  background-color: #d9d9d9;
  color: #00000040;
  cursor: not-allowed;
}

button.disabled:hover,
button:disabled:hover {
  background-color: #d9d9d9;
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