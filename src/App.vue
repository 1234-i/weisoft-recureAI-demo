<script setup lang="ts">
import { ref, onMounted, nextTick, computed } from 'vue'
import CryptoJS from 'crypto-js' // 引入crypto-js，确保跨环境兼容

// 立即执行：在页面加载的最早阶段隐藏备案信息
(() => {
  const style = document.createElement('style')
  style.id = 'beian-hiding-style'
  style.textContent = `
    /* 立即隐藏备案信息 - 最高优先级 */
    .beian-info {
      display: none !important;
      visibility: hidden !important;
      opacity: 0 !important;
      height: 0 !important;
      overflow: hidden !important;
      position: absolute !important;
      left: -9999px !important;
      top: -9999px !important;
    }

    .ai-disclaimer {
      display: none !important;
      visibility: hidden !important;
      opacity: 0 !important;
      height: 0 !important;
      overflow: hidden !important;
      position: absolute !important;
      left: -9999px !important;
      top: -9999px !important;
    }

    /* 隐藏包含备案信息文本的元素 */
    *[class*="beian"] {
      display: none !important;
      visibility: hidden !important;
    }

    *[class*="disclaimer"] {
      display: none !important;
      visibility: hidden !important;
    }

    /* 针对Shadow DOM - 尝试使用CSS变量 */
    pcm-jlsx-modal,
    pcm-mnct-modal,
    pcm-zygh-modal,
    pcm-mnms-modal,
    pcm-jlpp-modal,
    pcm-jd-modal,
    pcm-msbg-modal,
    pcm-htws-modal,
    pcm-hyzj-modal,
    pcm-qgqjl-modal,
    pcm-hr-chat-modal {
      --beian-display: none !important;
      --disclaimer-display: none !important;
    }

    /* 尝试影响Shadow DOM内部样式 */
    :host(.beian-info),
    :host(.ai-disclaimer) {
      display: none !important;
    }
  `

  // 确保在DOM ready之前就添加样式
  if (document.head) {
    document.head.appendChild(style)
  } else {
    document.addEventListener('DOMContentLoaded', () => {
      document.head.appendChild(style)
    })
  }

  console.log('🚀 立即执行：备案信息隐藏CSS已注入')
})()

// 引入聘才猫Vue组件
import {
  PcmZyghModal,
  PcmMnmsModal,
  PcmJlppModal,
  PcmJdModal,
  PcmMsbgModal,
  PcmHtwsModal,
  PcmHyzjModal,
  PcmQgqjlModal,
  PcmHrChatModal
} from 'pcm-agents-vue'

// 使用CDN引入的Web Components，无需import

// SDK配置参数
const SDK_CONFIG = {
  secretId: 'ak-BMSZyMnACKX6MPNne9zPfdFA',
  secretKey: 'sk-qrFpGRrDiAcu0YSUirhOVgPBT83qusb5',
  userId: '76015687511834624'
}

// SDK鉴权密钥
const SHARED_TOKEN = ref('')
const tokenLoading = ref(false)
const tokenError = ref('')

// Web Component引用
const jlsxModalRef = ref(null)
const mnctExpertModalRef = ref(null)

// 加载状态
const loading = ref(false)

// 定义模态框类型
type ModalType = 'zygh' | 'mnms' | 'jlpp' | 'jlsx' | 'jd' | 'msbg' | 'htws' | 'hyzj' | 'qgqjl' | 'hrChat' | 'mnctExpert' | 'jlzz'

// 模态框状态管理
const modals = ref<Record<ModalType, boolean>>({
  zygh: false,      // 职业规划
  mnms: false,      // 模拟面试
  jlpp: false,      // 简历匹配
  jlsx: false,      // 简历筛选专家
  jd: false,        // 职位生成
  msbg: false,      // 面试报告
  htws: false,      // 劳动合同卫士
  hyzj: false,      // 会议总结
  qgqjl: false,     // 千岗千简历
  hrChat: false,    // HR聊天
  mnctExpert: false, // 面试出题专家
  jlzz: false       // 简历制作专家
})

// 会话ID管理
const conversationIds = ref<Record<ModalType, string>>({
  zygh: '',
  mnms: '',
  jlpp: '',
  jlsx: '',
  jd: '',
  msbg: '',
  htws: '',
  hyzj: '',
  qgqjl: '',
  hrChat: '',
  mnctExpert: '',
  jlzz: ''
})

// 智能体分类配置
const agentCategories = ref([
  {
    name: '高级智能体',
    description: '功能强大的专业级AI助手',
    icon: '⭐',
    agents: [
      {
        id: 'jlzz',
        title: '简历制作专家',
        description: '专业简历制作服务，打造完美求职简历，提升求职成功率',
        icon: '✨'
      },
      {
        id: 'jlsx',
        title: '简历筛选专家',
        description: '智能筛选简历，快速匹配合适候选人，提高招聘效率',
        icon: '🔍'
      }
    ]
  },
  {
    name: '求职者服务',
    description: '为求职者提供专业的职业发展服务',
    icon: '🎯',
    agents: [
      {
        id: 'zygh',
        title: '职业规划助手',
        description: '基于AI的智能职业规划建议，帮助求职者制定个人发展路径',
        icon: '🎯'
      },
      {
        id: 'mnms',
        title: '模拟面试',
        description: 'AI模拟真实面试场景，提供专业的面试训练和反馈',
        icon: '🎭'
      }
    ]
  },
  {
    name: 'HR招聘工具',
    description: '专业的人力资源管理和招聘工具',
    icon: '👥',
    agents: [
      {
        id: 'jlpp',
        title: '简历匹配',
        description: '智能分析简历与职位的匹配度，提供优化建议',
        icon: '📄'
      },
      {
        id: 'jd',
        title: '职位生成',
        description: 'AI智能生成职位描述，提高招聘效率',
        icon: '�'
      },
      {
        id: 'msbg',
        title: '面试报告',
        description: '生成详细的面试评估报告，辅助招聘决策',
        icon: '�'
      },
      {
        id: 'mnctExpert',
        title: '面试出题专家',
        description: '专业的面试题目生成和面试流程管理专家',
        icon: '🎓'
      },
      {
        id: 'qgqjl',
        title: '简历优化专家',
        description: '智能简历优化服务，为不同岗位定制专属简历内容',
        icon: '📝'
      },
      {
        id: 'hrChat',
        title: 'HR智能助手',
        description: '专业的HR咨询助手，解答招聘相关问题',
        icon: '�'
      }
    ]
  },
  {
    name: '办公效率工具',
    description: '提升日常办公效率的智能助手',
    icon: '📋',
    agents: [
      {
        id: 'hyzj',
        title: '会议总结助手',
        description: '自动生成会议纪要和总结，提高工作效率',
        icon: '📋'
      },
      {
        id: 'htws',
        title: '劳动合同卫士',
        description: '智能审查劳动合同条款，保障双方权益',
        icon: '🛡️'
      }
    ]
  }
])

// 为了向后兼容，保留原有的featureCards格式
const featureCards = computed(() => {
  const cards: Array<{
    id: ModalType
    title: string
    description: string
    icon: string
    category: string
  }> = []

  agentCategories.value.forEach(category => {
    category.agents.forEach(agent => {
      cards.push({
        id: agent.id as ModalType,
        title: agent.title,
        description: agent.description,
        icon: agent.icon,
        category: category.name
      })
    })
  })

  return cards
})

// 打开模态框
const openModal = (modalType: ModalType) => {
  console.log(`正在打开 ${modalType} 模态框`)
  loading.value = true

  // 模拟加载延迟，提供更好的用户体验
  setTimeout(async () => {
    modals.value[modalType] = true
    loading.value = false

    // 对于Web Components，需要设置属性
    if (modalType === 'jlsx') {
      await setupJlsxModal()
    } else if (modalType === 'mnctExpert') {
      await setupMnctExpertModal()
    } else if (modalType === 'jlzz') {
      await setupJlzzModal()
    } else if (modalType === 'qgqjl') {
      await setupQgqjlModal()
    }
  }, 300)
}

// 关闭模态框
const closeModal = (modalType: ModalType) => {
  modals.value[modalType] = false
}

// 通用事件处理
const handleModalClosed = (modalType: ModalType) => {
  console.log(`${modalType} 模态框已关闭`)
  closeModal(modalType)
}

const handleStreamComplete = (event: CustomEvent) => {
  console.log('流式响应完成:', event.detail)
}

const handleConversationStart = (event: CustomEvent, modalType: ModalType) => {
  console.log('会话开始:', event.detail)
  if (event.detail && event.detail.conversation_id) {
    conversationIds.value[modalType] = event.detail.conversation_id
  }
}

const handleInterviewComplete = (event: CustomEvent) => {
  console.log('面试完成:', event.detail)
}

const handleUploadSuccess = (event: CustomEvent) => {
  console.log('文件上传成功:', event.detail)
}

const handleGetResumeData = (event: CustomEvent) => {
  console.log('获取简历数据:', event.detail)
}

const handleTokenInvalid = () => {
  console.error('Token无效，请检查SDK密钥配置')
  alert('SDK密钥可能无效，请联系管理员。这是演示环境，某些功能可能受限。')
}

const handleError = (event: CustomEvent) => {
  console.error('发生错误:', event.detail)
}

// 简历筛选专家特有的事件处理函数
const handleResumeAnalysisComplete = (event: any) => {
  console.log('简历分析完成:', event.detail)
}

const handleResumeAnalysisStart = (event: any) => {
  console.log('简历分析开始:', event.detail)
}

const handleResumeDeleted = (event: any) => {
  console.log('简历删除:', event.detail)
}

const handleTaskCreated = (event: any) => {
  console.log('任务创建完成:', event.detail)
}

const handleTaskSwitch = (event: any) => {
  console.log('任务切换:', event.detail)
}

// 根据官方文档实现AK/SK签名认证获取Token
const getSDKToken = async () => {
  tokenLoading.value = true
  tokenError.value = ''

  try {
    // 1. 构造规范请求参数
    const method = 'GET'
    const apiUri = '/auth/access-token/' // 注意：必须以/结尾
    const timestamp = Math.floor(Date.now() / 1000) // 时间戳（秒）
    const user = SDK_CONFIG.userId // 使用userId作为user参数

    // 2. 创建待签字符串
    const stringToSign = `${method}@${apiUri}@${timestamp}`
    console.log('待签字符串:', stringToSign)

    // 3. 计算签名 (HMAC-SHA1 + Base64)
    const signature = await generateSignature(SDK_CONFIG.secretKey, stringToSign)
    console.log('生成的签名:', signature)

    // 4. 构造请求URL和Headers (使用代理)
    const baseUrl = '/api/agents/v1/auth/access-token'
    const fullUrl = `${baseUrl}?user=${encodeURIComponent(user)}`

    const headers = {
      'x-secret-id': SDK_CONFIG.secretId,
      'x-timestamp': timestamp.toString(),
      'x-signature': signature
    }

    console.log('请求URL:', fullUrl)
    console.log('请求Headers:', headers)

    // 5. 发送请求
    const response = await fetch(fullUrl, {
      method: 'GET',
      headers: headers
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    const data = await response.json()
    console.log('API响应:', data)

    // 6. 处理响应
    if (data.code === 0 && data.data && data.data.token) {
      SHARED_TOKEN.value = data.data.token
      console.log('SDK Token获取成功')
      tokenLoading.value = false
      return
    } else {
      throw new Error(data.message || data.msg || '获取token失败')
    }

  } catch (error) {
    console.error('获取token失败:', error)

    const errorMsg = error instanceof Error ? error.message : String(error)

    if (errorMsg.includes('Failed to fetch')) {
      tokenError.value = 'CORS跨域问题：浏览器阻止了跨域请求，请配置代理服务器'
    } else if (errorMsg.includes('CORS')) {
      tokenError.value = 'CORS跨域问题：需要配置代理服务器解决跨域限制'
    } else if (errorMsg.includes('Network')) {
      tokenError.value = '网络连接失败：请检查网络连接'
    } else {
      tokenError.value = `获取token失败: ${errorMsg}`
    }

    tokenLoading.value = false
  }
}

// 生成HMAC-SHA1签名的辅助函数
// const generateSignature = async (secretKey: string, stringToSign: string) => {
//   try {
//     // 将字符串转换为Uint8Array
//     const encoder = new TextEncoder()
//     const keyData = encoder.encode(secretKey)
//     const messageData = encoder.encode(stringToSign)

//     // 导入密钥
//     const cryptoKey = await crypto.subtle.importKey(
//       'raw',
//       keyData,
//       { name: 'HMAC', hash: 'SHA-1' },
//       false,
//       ['sign']
//     )

//     // 计算HMAC
//     const signature = await crypto.subtle.sign('HMAC', cryptoKey, messageData)

//     // 转换为Base64
//     const signatureArray = new Uint8Array(signature)
//     let binaryString = ''
//     for (let i = 0; i < signatureArray.length; i++) {
//       binaryString += String.fromCharCode(signatureArray[i])
//     }
//     const signatureBase64 = btoa(binaryString)

//     return signatureBase64
//   } catch (error) {
//     console.error('签名生成失败:', error)
//     // 如果Web Crypto API不可用，使用简单的fallback
//     return btoa(secretKey + stringToSign).substring(0, 28)
//   }
// }

// 生成HMAC-SHA1签名的辅助函数（替换原函数）
const generateSignature = (secretKey: string, stringToSign: string) => { 
  try {
    // 使用crypto-js的HMAC-SHA1算法
    const hmac = CryptoJS.HmacSHA1(stringToSign, secretKey);
    // 转换为Base64
    const signatureBase64 = CryptoJS.enc.Base64.stringify(hmac);
    console.log('生成的签名:', signatureBase64);
    return signatureBase64;
  } catch (error) {
    console.error('签名生成失败:', error);
    // 移除错误的fallback，强制报错以避免无效签名
    throw new Error('签名生成失败，请检查依赖是否正确安装');
  }
}

// 隐藏备案信息的函数 - 增强版（更全面的查找和隐藏）
const hideBeianInfo = () => {
  console.log('🔍 开始检查并隐藏备案信息...')

  try {
    // 1. 隐藏普通DOM中的备案信息
    const beianElements = document.querySelectorAll('.beian-info, .ai-disclaimer')
    beianElements.forEach((element) => {
      const el = element as HTMLElement
      if (el && el.style.display !== 'none') {
        el.style.display = 'none'
        el.style.visibility = 'hidden'
        el.style.opacity = '0'
        el.style.height = '0'
        console.log('✅ 已隐藏普通DOM中的备案信息元素:', el.className)
      }
    })

    // 2. 查找所有可能的模态框元素（这些元素包含shadow DOM）
    const modalSelectors = [
      'pcm-mnms-modal',
      'pcm-zygh-modal',
      'pcm-jlpp-modal',
      'pcm-jd-modal',
      'pcm-msbg-modal',
      'pcm-htws-modal',
      'pcm-hyzj-modal',
      'pcm-mnct-modal',
      'pcm-qgqjl-modal',
      'pcm-hr-chat-modal',
      'pcm-jlsx-modal',
      'pcm-mnct-modal',
      'pcm-zsk-chat-modal',
      'pcm-jlzz-modal',
      'pcm-mnms-zp-modal',
      'pcm-1zhanshi-mnms-modal'
    ]

    console.log('🔍 开始检查所有模态框选择器...')

    // 首先检查页面上实际存在哪些PCM组件
    const allPcmElements = document.querySelectorAll('[class*="pcm-"], [id*="pcm-"]')
    console.log('🔍 页面上找到的PCM元素:', Array.from(allPcmElements).map(el => el.tagName.toLowerCase()))

    modalSelectors.forEach(selector => {
      const modals = document.querySelectorAll(selector)
      modals.forEach((modal: any) => {
        // 检查模态框是否存在shadow DOM（不检查isOpen，因为可能还没设置）
        if (modal && modal.shadowRoot) {
          try {
            console.log(`🔍 检查 ${selector} 的Shadow DOM...`)

            // 在shadow DOM中查找备案信息 - 使用多种选择器
            const shadowBeianElements = modal.shadowRoot.querySelectorAll('.beian-info, .ai-disclaimer, div.ai-disclaimer')
            console.log(`🔍 在 ${selector} 中找到 ${shadowBeianElements.length} 个备案信息元素`)

            shadowBeianElements.forEach((element: HTMLElement, index: number) => {
              if (element) {
                console.log(`🔍 处理第 ${index + 1} 个备案信息元素:`, element.className, element.tagName)
                element.style.display = 'none'
                element.style.visibility = 'hidden'
                element.style.opacity = '0'
                element.style.height = '0'
                console.log(`✅ 已隐藏 ${selector} Shadow DOM中的备案信息元素 ${index + 1}`)
              }
            })

            // 额外查找包含备案信息文本的元素（只隐藏叶子节点，不隐藏容器）
            const allElements = modal.shadowRoot.querySelectorAll('p, span, a, div.ai-disclaimer')
            allElements.forEach((element: HTMLElement) => {
              // 只处理直接包含备案信息文本的元素，且不是重要的容器元素
              if (element.textContent &&
                  (element.textContent.includes('中央网信办生成式人工智能服务备案号') ||
                   element.textContent.includes('Hunan-PinCaiMao') ||
                   element.textContent.includes('所有内容均由AI生成仅供参考')) &&
                  // 排除重要的容器元素
                  !element.classList.contains('modal-overlay') &&
                  !element.classList.contains('modal-container') &&
                  !element.classList.contains('input-container') &&
                  element.tagName !== 'DIV' || element.classList.contains('ai-disclaimer')) {
                console.log(`🔍 找到包含备案信息文本的叶子元素:`, element.tagName, element.className)
                element.style.display = 'none'
                element.style.visibility = 'hidden'
                element.style.opacity = '0'
                element.style.height = '0'
                console.log(`✅ 已隐藏 ${selector} 中包含备案信息文本的叶子元素`)
              }
            })
          } catch (shadowError) {
            console.warn(`处理 ${selector} Shadow DOM时出错:`, shadowError)
          }
        } else {
          console.log(`🔍 ${selector} 没有Shadow DOM或不存在`)
        }
      })
    })

    // 额外检查：查找所有以pcm-开头的元素，防止遗漏
    const allPcmModals = document.querySelectorAll('[class*="pcm-modal"], [id*="pcm-modal"]')
    allPcmModals.forEach((modal: any) => {
      if (modal && modal.shadowRoot && modal.tagName) {
        const tagName = modal.tagName.toLowerCase()
        if (!modalSelectors.includes(tagName)) {
          console.log(`🔍 发现未列出的PCM模态框: ${tagName}`)
          try {
            const shadowBeianElements = modal.shadowRoot.querySelectorAll('.beian-info, .ai-disclaimer, div.ai-disclaimer')
            console.log(`🔍 在 ${tagName} 中找到 ${shadowBeianElements.length} 个备案信息元素`)

            shadowBeianElements.forEach((element: HTMLElement, index: number) => {
              if (element) {
                element.style.display = 'none'
                element.style.visibility = 'hidden'
                element.style.opacity = '0'
                element.style.height = '0'
                console.log(`✅ 已隐藏 ${tagName} Shadow DOM中的备案信息元素 ${index + 1}`)
              }
            })
          } catch (error) {
            console.warn(`处理 ${tagName} 时出错:`, error)
          }
        }
      }
    })
  } catch (error) {
    console.warn('隐藏备案信息时出错:', error)
  }

  console.log('🔍 备案信息检查完成')
}

// 监听所有模态框打开事件 - 即时隐藏版（在模态框打开瞬间隐藏）
const setupBeianHiding = () => {
  console.log('🔧 正在设置备案信息隐藏（即时隐藏版）...')

  // 立即执行一次隐藏
  hideBeianInfo()

  // 监听点击事件 - 使用更广泛的选择器
  document.addEventListener('click', (e) => {
    const target = e.target as HTMLElement
    console.log('🔍 检测到点击事件，目标元素:', target.className, target.tagName)

    // 检查是否点击了智能体卡片或其子元素
    let isAgentCardClick = false
    let currentElement = target

    // 向上遍历DOM树，查找智能体卡片
    for (let i = 0; i < 5; i++) {
      if (currentElement && currentElement.classList) {
        if (currentElement.classList.contains('agent-card') ||
            currentElement.classList.contains('try-button') ||
            currentElement.classList.contains('card-title') ||
            currentElement.classList.contains('card-description') ||
            currentElement.classList.contains('card-icon')) {
          isAgentCardClick = true
          break
        }
      }
      currentElement = currentElement.parentElement as HTMLElement
      if (!currentElement) break
    }

    if (isAgentCardClick) {
      console.log('🎯 检测到智能体卡片点击，立即开始隐藏备案信息')

      // 立即隐藏，不等待
      hideBeianInfo()

      // 快速连续隐藏，确保在模态框渲染过程中就隐藏
      setTimeout(hideBeianInfo, 10)
      setTimeout(hideBeianInfo, 50)
      setTimeout(hideBeianInfo, 100)
      setTimeout(hideBeianInfo, 200)
      setTimeout(hideBeianInfo, 300)
      setTimeout(hideBeianInfo, 500)
    }
  })

  // 使用MutationObserver监听DOM变化，立即隐藏新添加的备案信息
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            const element = node as Element
            // 如果添加的是PCM组件，立即隐藏其中的备案信息
            if (element.tagName && element.tagName.toLowerCase().includes('pcm-')) {
              console.log('🔍 检测到PCM组件添加，立即隐藏备案信息:', element.tagName)
              setTimeout(hideBeianInfo, 0)
              setTimeout(hideBeianInfo, 10)
              setTimeout(hideBeianInfo, 50)
            }
          }
        })
      }
    })
  })

  observer.observe(document.body, {
    childList: true,
    subtree: true
  })

  console.log('✅ 备案信息隐藏设置完成（即时隐藏版）')

  // 清理函数
  return () => {
    observer.disconnect()
  }
}

// 设置简历筛选专家Web Component
const setupJlsxModal = async () => {
  await nextTick() // 等待DOM更新

  const jlsxModal = document.getElementById('pcm-jlsx-modal') as any
  if (!jlsxModal) {
    console.warn('简历筛选专家Web Component未找到')
    return
  }

  // 设置Web Component属性
  jlsxModal.token = SHARED_TOKEN.value
  jlsxModal.modalTitle = '简历筛选专家'
  jlsxModal.icon = '/image/logo.png'
  jlsxModal.fullscreen = false
  jlsxModal.mobileUploadAble = false
  jlsxModal.isNeedClose = true
  jlsxModal.isShowHeader = true
  jlsxModal.zIndex = 1000
  jlsxModal.isOpen = true

  console.log('简历筛选专家Web Component已配置', jlsxModal)

  // 设置事件监听器
  jlsxModal.addEventListener('modalClosed', () => {
    console.log('简历筛选专家窗口已关闭')
    handleModalClosed('jlsx')
  })

  jlsxModal.addEventListener('resumeAnalysisComplete', handleResumeAnalysisComplete)
  jlsxModal.addEventListener('resumeAnalysisStart', handleResumeAnalysisStart)
  jlsxModal.addEventListener('resumeDeleted', handleResumeDeleted)
  jlsxModal.addEventListener('taskCreated', handleTaskCreated)
  jlsxModal.addEventListener('taskSwitch', handleTaskSwitch)
  jlsxModal.addEventListener('uploadSuccess', handleUploadSuccess as EventListener)
  jlsxModal.addEventListener('someErrorEvent', handleError as EventListener)
  jlsxModal.addEventListener('tokenInvalid', handleTokenInvalid as EventListener)
}

// 设置面试出题专家Web Component
const setupMnctExpertModal = async () => {
  await nextTick() // 等待DOM更新

  const mnctExpertModal = document.getElementById('pcm-mnct-expert-modal') as any
  if (!mnctExpertModal) {
    console.warn('面试出题专家Web Component未找到')
    return
  }

  console.log('找到面试出题专家Web Component:', mnctExpertModal)

  // 设置Web Component属性
  mnctExpertModal.token = SHARED_TOKEN.value
  mnctExpertModal.modalTitle = '面试出题专家'
  mnctExpertModal.icon = '/image/logo.png'
  mnctExpertModal.conversationId = conversationIds.value.mnctExpert
  mnctExpertModal.fullscreen = false
  mnctExpertModal.defaultQuery = '请您提问'
  mnctExpertModal.isNeedClose = true
  mnctExpertModal.isShowHeader = true
  mnctExpertModal.zIndex = 1000
  mnctExpertModal.isOpen = true

  console.log('面试出题专家Web Component已配置', mnctExpertModal)

  // 设置事件监听器
  mnctExpertModal.addEventListener('modalClosed', () => {
    console.log('面试出题专家窗口已关闭')
    handleModalClosed('mnctExpert')
  })

  mnctExpertModal.addEventListener('streamComplete', (event: any) => {
    console.log('流式响应完成:', event.detail)
    handleStreamComplete(event)
  })

  mnctExpertModal.addEventListener('conversationStart', (event: any) => {
    console.log('会话开始:', event.detail)
    handleConversationStart(event, 'mnctExpert')
  })

  mnctExpertModal.addEventListener('interviewComplete', (event: any) => {
    console.log('面试完成:', event.detail)
    handleModalClosed('mnctExpert')
  })

  mnctExpertModal.addEventListener('uploadSuccess', handleUploadSuccess as EventListener)
  mnctExpertModal.addEventListener('someErrorEvent', handleError as EventListener)
  mnctExpertModal.addEventListener('tokenInvalid', handleTokenInvalid as EventListener)
}

// 设置简历制作专家Web Component
const setupJlzzModal = async () => {
  await nextTick() // 等待DOM更新

  const jlzzModal = document.getElementById('pcm-jlzz-modal') as any
  if (!jlzzModal) {
    console.warn('简历制作专家Web Component未找到')
    return
  }

  // 设置Web Component属性
  jlzzModal.token = SHARED_TOKEN.value
  jlzzModal.modalTitle = '简历制作专家'
  jlzzModal.icon = '/image/logo.png'
  jlzzModal.conversationId = conversationIds.value.jlzz
  jlzzModal.fullscreen = false
  jlzzModal.isNeedClose = true
  jlzzModal.isShowHeader = true
  jlzzModal.zIndex = 1000
  jlzzModal.isOpen = true

  console.log('简历制作专家Web Component已配置', jlzzModal)

  // 设置事件监听器
  jlzzModal.addEventListener('modalClosed', () => {
    console.log('简历制作专家窗口已关闭')
    handleModalClosed('jlzz')
  })

  jlzzModal.addEventListener('streamComplete', (event: any) => {
    console.log('流式响应完成:', event.detail)
    handleStreamComplete(event)
  })

  jlzzModal.addEventListener('conversationStart', (event: any) => {
    console.log('会话开始:', event.detail)
    handleConversationStart(event, 'jlzz')
  })

  jlzzModal.addEventListener('interviewComplete', (event: any) => {
    console.log('分析完成:', event.detail)
    handleInterviewComplete(event)
  })

  jlzzModal.addEventListener('uploadSuccess', handleUploadSuccess as EventListener)
  jlzzModal.addEventListener('getResumeData', handleGetResumeData as EventListener)
  jlzzModal.addEventListener('someErrorEvent', handleError as EventListener)
  jlzzModal.addEventListener('tokenInvalid', handleTokenInvalid as EventListener)
}

// 设置千岗千简历Web Component
const setupQgqjlModal = async () => {
  await nextTick() // 等待DOM更新

  const qgqjlModal = document.getElementById('pcm-qgqjl-modal') as any
  if (!qgqjlModal) {
    console.warn('千岗千简历Web Component未找到')
    return
  }

  // 设置Web Component属性
  qgqjlModal.token = SHARED_TOKEN.value
  qgqjlModal.modalTitle = '简历优化专家'
  qgqjlModal.icon = '/image/logo.png'
  qgqjlModal.conversationId = conversationIds.value.qgqjl
  qgqjlModal.fullscreen = false
  qgqjlModal.defaultQuery = '请您提问'
  qgqjlModal.isOpen = true

  console.log('千岗千简历Web Component已配置', qgqjlModal)

  // 设置事件监听器
  qgqjlModal.addEventListener('modalClosed', () => {
    console.log('千岗千简历窗口已关闭')
    handleModalClosed('qgqjl')
  })

  qgqjlModal.addEventListener('streamComplete', (event: any) => {
    console.log('流式响应完成:', event.detail)
    handleStreamComplete(event)
  })

  qgqjlModal.addEventListener('conversationStart', (event: any) => {
    console.log('会话开始:', event.detail)
    handleConversationStart(event, 'qgqjl')
  })

  qgqjlModal.addEventListener('interviewComplete', (event: any) => {
    console.log('分析完成:', event.detail)
    handleInterviewComplete(event)
  })

  qgqjlModal.addEventListener('uploadSuccess', handleUploadSuccess as EventListener)
  qgqjlModal.addEventListener('someErrorEvent', handleError as EventListener)
  qgqjlModal.addEventListener('tokenInvalid', handleTokenInvalid as EventListener)

  // 可以设置自定义输入（可选）
  // qgqjlModal.customInputs = {
  //   job_info: "前端开发工程师，负责Web应用的开发与维护，要求熟悉React、TypeScript和现代前端工具链",
  //   file_url: "/resources/file/20250416/d258f91a1ff6061822f00b4e245dbd00.pdf",
  //   file_name: "简历.pdf"
  // };
}

// 立即注入CSS到页面头部来隐藏备案信息
const injectBeianHidingCSS = () => {
  const style = document.createElement('style')
  style.textContent = `
    /* 立即隐藏备案信息 - 最高优先级 */
    .beian-info,
    .ai-disclaimer {
      display: none !important;
      visibility: hidden !important;
      opacity: 0 !important;
      height: 0 !important;
      overflow: hidden !important;
      position: absolute !important;
      left: -9999px !important;
    }

    /* 隐藏包含备案信息的元素 */
    p:contains("中央网信办生成式人工智能服务备案号"),
    p:contains("Hunan-PinCaiMao"),
    p:contains("所有内容均由AI生成仅供参考"),
    span:contains("中央网信办"),
    span:contains("Hunan-PinCaiMao"),
    a[href*="pincaimao.com"] {
      display: none !important;
      visibility: hidden !important;
      opacity: 0 !important;
    }

    /* 隐藏可能的父容器 */
    div:has(.beian-info),
    div:has(.ai-disclaimer) {
      display: none !important;
    }
  `
  document.head.appendChild(style)
  console.log('✅ 已注入备案信息隐藏CSS')
}

// 组件挂载时获取token和设置备案信息隐藏
onMounted(() => {
  // 立即注入CSS
  injectBeianHidingCSS()

  getSDKToken()
  setupBeianHiding()
})

</script>

<template>
  <div class="app">
    <!-- 头部导航 -->
    <header class="header">
      <div class="container">
        <div class="header-content">
          <div class="logo-section">
            <img src="/image/logo.png" alt="未软科技" class="company-logo" />
            <div class="logo-text">
              <h1 class="logo-title">AI招聘助手演示平台</h1>
              <p class="logo-subtitle">智能化招聘解决方案</p>
            </div>
          </div>
          <div class="company-info">
            <span class="company-name">上海未软人工智能公司</span>
          </div>
        </div>
      </div>
    </header>

    <!-- 主要内容区域 -->
    <main class="main">
      <div class="container">
        <!-- 介绍区域 -->
        <section class="intro-section">
          <h2 class="section-title">智能招聘，未来已来</h2>
          <p class="section-description">
            体验最前沿的AI招聘技术，从职业规划到面试评估，从简历匹配到合同审查，
            全方位的智能化招聘解决方案，让招聘更高效、更精准、更智能。
          </p>

          <!-- Token状态显示 -->
          <div class="token-status">
            <div v-if="tokenLoading" class="status-item loading">
              <span class="status-icon">⏳</span>
              <span>正在获取系统授权...</span>
            </div>
            <div v-else-if="tokenError" class="status-item error">
              <span class="status-icon">❌</span>
              <span>{{ tokenError }}</span>
              <button @click="getSDKToken" class="retry-btn">重试</button>
            </div>
            <div v-else-if="SHARED_TOKEN" class="status-item success">
              <span class="status-icon">✅</span>
              <span>系统授权成功，所有功能已就绪</span>
            </div>
            <div v-else class="status-item waiting">
              <span class="status-icon">⚪</span>
              <span>等待获取系统授权</span>
              <button @click="getSDKToken" class="retry-btn">获取授权</button>
            </div>
          </div>
        </section>

        <!-- 智能体分类展示 -->
        <section class="agents-section">
          <div
            v-for="category in agentCategories"
            :key="category.name"
            class="category-section"
          >
            <div class="category-header">
              <span class="category-icon">{{ category.icon }}</span>
              <div class="category-info">
                <h3 class="category-title">{{ category.name }}</h3>
                <p class="category-description">{{ category.description }}</p>
              </div>
            </div>

            <div class="agents-grid">
              <div
                v-for="agent in category.agents"
                :key="agent.id"
                class="agent-card"
                :class="{ 'premium': category.name === '高级智能体' }"
                @click="openModal(agent.id as ModalType)"
              >
                <div class="card-header">
                  <span class="card-icon">{{ agent.icon }}</span>
                  <div v-if="category.name === '高级智能体'" class="premium-badge">高级</div>
                </div>
                <h4 class="card-title">{{ agent.title }}</h4>
                <p class="card-description">{{ agent.description }}</p>
                <div class="card-action">
                  <button class="try-button" :disabled="loading">
                    <span v-if="loading">加载中...</span>
                    <span v-else>立即体验</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </main>

    <!-- 页脚 -->
    <footer class="footer">
      <div class="container">
        <div class="footer-content">
          <div class="footer-info">
            <p>&copy; 2024 上海未软人工智能公司 版权所有</p>
            <p>AI招聘解决方案提供商</p>
          </div>
          <div class="footer-links">
            <a href="#" class="footer-link">关于我们</a>
            <a href="#" class="footer-link">联系我们</a>
            <a href="#" class="footer-link">技术支持</a>
          </div>
        </div>
      </div>
    </footer>

    <!-- 所有模态框组件 -->
    <!-- 职业规划助手 -->
    <PcmZyghModal
      v-if="SHARED_TOKEN"
      :is-open="modals.zygh"
      :token="SHARED_TOKEN"
      modal-title="AI职业规划助手"
      icon="/image/logo.png"
      :conversation-id="conversationIds.zygh"
      :custom-inputs="{ type: '长期规划' }"
      default-query="您好！我是AI职业规划助手，我可以帮助您制定个人职业发展规划。请告诉我您的职业背景和发展目标。"
      :fullscreen="false"
      :is-need-close="true"
      :is-show-header="true"
      file-preview-mode="drawer"
      @modal-closed="() => handleModalClosed('zygh')"
      @stream-complete="handleStreamComplete"
      @conversation-start="(e: any) => handleConversationStart(e, 'zygh')"
      @interview-complete="handleInterviewComplete"
      @token-invalid="handleTokenInvalid"
      @some-error-event="handleError"
    />

    <!-- 模拟面试 -->
    <PcmMnmsModal
      v-if="SHARED_TOKEN"
      :is-open="modals.mnms"
      :token="SHARED_TOKEN"
      modal-title="AI模拟面试系统"
      icon="/image/logo.png"
      :conversation-id="conversationIds.mnms"
      :custom-inputs="{}"
      default-query="欢迎使用AI模拟面试系统！请先上传您的简历，然后输入目标职位信息，我将为您模拟真实的面试场景。"
      :fullscreen="false"
      :is-need-close="true"
      :is-show-header="true"
      interview-mode="text"
      file-preview-mode="drawer"
      :show-copy-button="true"
      :show-feedback-buttons="true"
      @modal-closed="() => handleModalClosed('mnms')"
      @stream-complete="handleStreamComplete"
      @conversation-start="(e: any) => handleConversationStart(e, 'mnms')"
      @interview-complete="handleInterviewComplete"
      @token-invalid="handleTokenInvalid"
      @some-error-event="handleError"
    />

    <!-- 简历匹配 -->
    <PcmJlppModal
      v-if="SHARED_TOKEN"
      :is-open="modals.jlpp"
      :token="SHARED_TOKEN"
      modal-title="简历匹配分析"
      icon="/image/logo.png"
      :conversation-id="conversationIds.jlpp"
      :custom-inputs="{}"
      :fullscreen="false"
      :is-need-close="true"
      :is-show-header="true"
      file-preview-mode="drawer"
      @modal-closed="() => handleModalClosed('jlpp')"
      @stream-complete="handleStreamComplete"
      @conversation-start="(e: any) => handleConversationStart(e, 'jlpp')"
      @upload-success="handleUploadSuccess"
      @token-invalid="handleTokenInvalid"
    />

    <!-- 简历筛选专家 -->
    <pcm-jlsx-modal
      v-if="SHARED_TOKEN && modals.jlsx"
      id="pcm-jlsx-modal"
      ref="jlsxModalRef"
    ></pcm-jlsx-modal>

    <!-- 简历制作专家 -->
    <pcm-jlzz-modal
      v-if="SHARED_TOKEN && modals.jlzz"
      id="pcm-jlzz-modal"
      ref="jlzzModalRef"
      :token="SHARED_TOKEN"
      modal-title="简历制作专家"
      icon="/image/logo.png"
      :conversation-id="conversationIds.jlzz"
      :fullscreen="false"
      :is-need-close="true"
      :is-show-header="true"
      @modal-closed="() => handleModalClosed('jlzz')"
      @stream-complete="handleStreamComplete"
      @conversation-start="(e: any) => handleConversationStart(e, 'jlzz')"
      @interview-complete="handleInterviewComplete"
      @upload-success="handleUploadSuccess"
      @token-invalid="handleTokenInvalid"
      @some-error-event="handleError"
      @get-resume-data="handleGetResumeData"
    ></pcm-jlzz-modal>

    <!-- 职位生成 -->
    <PcmJdModal
      v-if="SHARED_TOKEN"
      :is-open="modals.jd"
      :token="SHARED_TOKEN"
      modal-title="智能职位生成"
      icon="/image/logo.png"
      :conversation-id="conversationIds.jd"
      :custom-inputs="{}"
      :fullscreen="false"
      :is-need-close="true"
      :is-show-header="true"
      file-preview-mode="drawer"
      @modal-closed="() => handleModalClosed('jd')"
      @stream-complete="handleStreamComplete"
      @conversation-start="(e: any) => handleConversationStart(e, 'jd')"
      @token-invalid="handleTokenInvalid"
    />

    <!-- 面试报告 -->
    <PcmMsbgModal
      v-if="SHARED_TOKEN"
      :is-open="modals.msbg"
      :token="SHARED_TOKEN"
      modal-title="面试评估报告"
      icon="/image/logo.png"
      :conversation-id="conversationIds.msbg"
      :custom-inputs="{}"
      :fullscreen="false"
      :is-need-close="true"
      :is-show-header="true"
      file-preview-mode="drawer"
      @modal-closed="() => handleModalClosed('msbg')"
      @stream-complete="handleStreamComplete"
      @conversation-start="(e: any) => handleConversationStart(e, 'msbg')"
      @upload-success="handleUploadSuccess"
      @token-invalid="handleTokenInvalid"
    />

    <!-- 劳动合同卫士 -->
    <PcmHtwsModal
      v-if="SHARED_TOKEN"
      :is-open="modals.htws"
      :token="SHARED_TOKEN"
      modal-title="劳动合同卫士"
      icon="/image/logo.png"
      :conversation-id="conversationIds.htws"
      :custom-inputs="{}"
      :fullscreen="false"
      :is-need-close="true"
      :is-show-header="true"
      file-preview-mode="drawer"
      @modal-closed="() => handleModalClosed('htws')"
      @stream-complete="handleStreamComplete"
      @conversation-start="(e: any) => handleConversationStart(e, 'htws')"
      @upload-success="handleUploadSuccess"
      @token-invalid="handleTokenInvalid"
    />

    <!-- 会议总结助手 -->
    <PcmHyzjModal
      v-if="SHARED_TOKEN"
      :is-open="modals.hyzj"
      :token="SHARED_TOKEN"
      modal-title="会议总结助手"
      icon="/image/logo.png"
      :conversation-id="conversationIds.hyzj"
      :custom-inputs="{}"
      :fullscreen="false"
      :is-need-close="true"
      :is-show-header="true"
      file-preview-mode="drawer"
      @modal-closed="() => handleModalClosed('hyzj')"
      @stream-complete="handleStreamComplete"
      @conversation-start="(e: any) => handleConversationStart(e, 'hyzj')"
      @upload-success="handleUploadSuccess"
      @token-invalid="handleTokenInvalid"
    />

    <!-- 面试出题专家 -->
    <pcm-mnct-modal
      v-if="SHARED_TOKEN && modals.mnctExpert"
      id="pcm-mnct-expert-modal"
      ref="mnctExpertModalRef"
    ></pcm-mnct-modal>

    <!-- 简历优化专家 -->
    <pcm-qgqjl-modal
      v-if="SHARED_TOKEN && modals.qgqjl"
      id="pcm-qgqjl-modal"
      ref="qgqjlModalRef"
      :token="SHARED_TOKEN"
      modal-title="简历优化专家"
      icon="/image/logo.png"
      :conversation-id="conversationIds.qgqjl"
      :fullscreen="false"
      default-query="请您提问"
    ></pcm-qgqjl-modal>

    <!-- HR智能助手 -->
    <PcmHrChatModal
      v-if="SHARED_TOKEN"
      :is-open="modals.hrChat"
      :token="SHARED_TOKEN"
      modal-title="HR智能助手"
      icon="/image/logo.png"
      :conversation-id="conversationIds.hrChat"
      default-query="您好，我是HR智能助手，有什么可以帮助您的吗？"
      :fullscreen="false"
      :is-need-close="true"
      :is-show-header="true"
      :enable-audio="true"
      :enable-voice="false"
      :display-content-status="true"
      :require-resume="false"
      :total-questions="10"
      :max-recording-time="300"
      :countdown-warning-time="30"
      to-email=""
      callback-url=""
      @modal-closed="() => handleModalClosed('hrChat')"
      @stream-complete="handleStreamComplete"
      @conversation-start="(e: any) => handleConversationStart(e, 'hrChat')"
      @interview-complete="handleInterviewComplete"
      @token-invalid="handleTokenInvalid"
    />

    <!-- 全局加载遮罩 -->
    <div v-if="loading" class="loading-overlay">
      <div class="loading-spinner">
        <div class="spinner"></div>
        <p>正在加载AI助手...</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* 全局样式重置 */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
  background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 25%, #16213e 50%, #0f3460 75%, #533483 100%);
  color: #e2e8f0;
  min-width: 1200px;
  overflow-x: auto;
  position: relative;
}

/* 添加动态背景效果 */
.app::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background:
    radial-gradient(circle at 20% 80%, rgba(120, 119, 198, 0.3) 0%, transparent 50%),
    radial-gradient(circle at 80% 20%, rgba(255, 119, 198, 0.3) 0%, transparent 50%),
    radial-gradient(circle at 40% 40%, rgba(120, 219, 255, 0.2) 0%, transparent 50%);
  z-index: -1;
  animation: backgroundShift 20s ease-in-out infinite;
}

@keyframes backgroundShift {
  0%, 100% { transform: translateX(0) translateY(0); }
  25% { transform: translateX(-5px) translateY(-10px); }
  50% { transform: translateX(10px) translateY(5px); }
  75% { transform: translateX(-3px) translateY(8px); }
}

.container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 24px;
}

/* 头部样式 - 现代科技感 */
.header {
  background: rgba(15, 15, 35, 0.8);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 0;
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 20px;
}

.company-logo {
  width: 56px;
  height: 56px;
  border-radius: 16px;
  object-fit: cover;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
  border: 2px solid rgba(255, 255, 255, 0.1);
}

.logo-text {
  color: #f8fafc;
}

.logo-title {
  font-size: 2rem;
  font-weight: 800;
  margin-bottom: 6px;
  background: linear-gradient(135deg, #f8fafc 0%, #cbd5e1 50%, #94a3b8 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  letter-spacing: -0.02em;
}

.logo-subtitle {
  font-size: 0.95rem;
  color: #94a3b8;
  margin: 0;
  font-weight: 500;
}

.company-info {
  color: #cbd5e1;
  font-weight: 600;
  font-size: 1.1rem;
  padding: 12px 24px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

/* 主要内容区域 */
.main {
  flex: 1;
  padding: 80px 0 60px;
}

/* 介绍区域 - 人文科技感 */
.intro-section {
  text-align: center;
  margin-bottom: 100px;
  position: relative;
}

.section-title {
  font-size: 3.5rem;
  font-weight: 900;
  margin-bottom: 24px;
  background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 25%, #cbd5e1 50%, #94a3b8 75%, #64748b 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  letter-spacing: -0.03em;
  line-height: 1.1;
  position: relative;
}

.section-title::after {
  content: '';
  position: absolute;
  bottom: -10px;
  left: 50%;
  transform: translateX(-50%);
  width: 100px;
  height: 4px;
  background: linear-gradient(90deg, #3b82f6, #8b5cf6, #ec4899);
  border-radius: 2px;
}

.section-description {
  font-size: 1.3rem;
  line-height: 1.7;
  max-width: 900px;
  margin: 0 auto 50px;
  color: #cbd5e1;
  font-weight: 400;
  letter-spacing: 0.01em;
}

/* Token状态样式 - 现代化 */
.token-status {
  display: flex;
  justify-content: center;
  margin-bottom: 50px;
}

.status-item {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  padding: 16px 28px;
  border-radius: 16px;
  font-weight: 600;
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
}

.status-item.loading {
  background: linear-gradient(135deg, rgba(251, 191, 36, 0.2), rgba(245, 158, 11, 0.1));
  color: #fef3c7;
  border-color: rgba(251, 191, 36, 0.3);
}

.status-item.error {
  background: linear-gradient(135deg, rgba(239, 68, 68, 0.2), rgba(220, 38, 38, 0.1));
  color: #fecaca;
  border-color: rgba(239, 68, 68, 0.3);
}

.status-item.success {
  background: linear-gradient(135deg, rgba(34, 197, 94, 0.2), rgba(22, 163, 74, 0.1));
  color: #bbf7d0;
  border-color: rgba(34, 197, 94, 0.3);
}

.status-icon {
  font-size: 1.3rem;
}

.retry-btn {
  background: rgba(255, 255, 255, 0.1);
  color: #f8fafc;
  border: 1px solid rgba(255, 255, 255, 0.2);
  padding: 8px 16px;
  border-radius: 12px;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.retry-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: translateY(-1px);
}

.status-item.success {
  background: rgba(40, 167, 69, 0.2);
  color: #d4edda;
  border: 1px solid rgba(40, 167, 69, 0.3);
}

.status-icon {
  font-size: 1.2rem;
}

.retry-btn {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  padding: 5px 12px;
  border-radius: 15px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.retry-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

/* 智能体分类样式 - 现代科技感 */
.agents-section {
  margin-bottom: 80px;
}

.category-section {
  margin-bottom: 70px;
}

.category-header {
  display: flex;
  align-items: center;
  gap: 20px;
  margin-bottom: 40px;
  padding: 28px 32px;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(255, 255, 255, 0.05) 100%);
  backdrop-filter: blur(20px);
  border-radius: 20px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  position: relative;
  overflow: hidden;
}

.category-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 4px;
  height: 100%;
  background: linear-gradient(180deg, #3b82f6, #8b5cf6, #ec4899);
}

.category-icon {
  font-size: 2.5rem;
  filter: drop-shadow(0 4px 8px rgba(0,0,0,0.2));
}

.category-info {
  flex: 1;
}

.category-title {
  font-size: 1.8rem;
  font-weight: 800;
  color: #f8fafc;
  margin-bottom: 8px;
  letter-spacing: -0.02em;
}

.category-description {
  color: #cbd5e1;
  font-size: 1rem;
  margin: 0;
  font-weight: 500;
}

.agents-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 24px;
  max-width: 1200px;
  margin: 0 auto;
}

/* 大屏幕适配 */
@media (min-width: 1600px) {
  .agents-grid {
    grid-template-columns: repeat(4, 1fr);
    gap: 32px;
  }
}

/* 中等屏幕适配 */
@media (max-width: 1400px) and (min-width: 1200px) {
  .agents-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

.agent-card {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(255, 255, 255, 0.05) 100%);
  backdrop-filter: blur(20px);
  border-radius: 24px;
  padding: 32px 24px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  cursor: pointer;
  border: 1px solid rgba(255, 255, 255, 0.2);
  min-height: 320px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  text-align: center;
  position: relative;
  overflow: hidden;
}

/* 卡片悬停效果 */
.agent-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(139, 92, 246, 0.1));
  opacity: 0;
  transition: opacity 0.3s ease;
}

.agent-card:hover::before {
  opacity: 1;
}

.agent-card:hover {
  transform: translateY(-8px) scale(1.02);
  box-shadow: 0 32px 64px rgba(0, 0, 0, 0.2);
  border-color: rgba(255, 255, 255, 0.3);
}

/* 高级智能体特殊样式 */
.agent-card.premium {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.2) 0%, rgba(139, 92, 246, 0.2) 50%, rgba(236, 72, 153, 0.2) 100%);
  border: 1px solid rgba(59, 130, 246, 0.3);
  box-shadow: 0 20px 40px rgba(59, 130, 246, 0.2);
}

.agent-card.premium::before {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.2), rgba(139, 92, 246, 0.2), rgba(236, 72, 153, 0.2));
}

.agent-card.premium:hover {
  box-shadow: 0 32px 64px rgba(59, 130, 246, 0.3);
  border-color: rgba(59, 130, 246, 0.5);
}

.premium-badge {
  position: absolute;
  top: 16px;
  right: 16px;
  background: linear-gradient(135deg, #3b82f6, #8b5cf6);
  color: white;
  padding: 6px 14px;
  border-radius: 16px;
  font-size: 0.75rem;
  font-weight: 700;
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
  z-index: 2;
}

.card-header {
  display: flex;
  justify-content: center;
  align-items: center;
  margin-bottom: 24px;
  position: relative;
}

.card-icon {
  font-size: 3.5rem;
  line-height: 1;
  filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.1));
  z-index: 2;
}

.card-title {
  font-size: 1.4rem;
  font-weight: 700;
  margin-bottom: 16px;
  color: #f8fafc;
  letter-spacing: -0.01em;
  z-index: 2;
  position: relative;
}

.card-description {
  color: #cbd5e1;
  line-height: 1.6;
  margin-bottom: 28px;
  font-size: 0.95rem;
  font-weight: 400;
  z-index: 2;
  position: relative;
}

.card-action {
  margin-top: auto;
  z-index: 2;
  position: relative;
}

.try-button {
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 50%, #ec4899 100%);
  color: white;
  border: none;
  padding: 14px 32px;
  border-radius: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  font-size: 0.95rem;
  letter-spacing: 0.01em;
  box-shadow: 0 8px 20px rgba(59, 130, 246, 0.3);
  width: 100%;
}

.try-button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 12px 28px rgba(59, 130, 246, 0.4);
  background: linear-gradient(135deg, #2563eb 0%, #7c3aed 50%, #db2777 100%);
}

.try-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* 页脚样式 - 现代科技感 */
.footer {
  background: rgba(15, 15, 35, 0.8);
  backdrop-filter: blur(20px);
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  margin-top: auto;
  box-shadow: 0 -8px 32px rgba(0, 0, 0, 0.2);
}

.footer-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 40px 0;
}

.footer-info p {
  margin-bottom: 8px;
  color: #cbd5e1;
  font-weight: 500;
}

.footer-info p:first-child {
  font-weight: 600;
  color: #f8fafc;
}

.footer-links {
  display: flex;
  gap: 32px;
}

.footer-link {
  color: #94a3b8;
  text-decoration: none;
  transition: all 0.3s ease;
  font-weight: 500;
  padding: 8px 16px;
  border-radius: 8px;
}

.footer-link:hover {
  color: #f8fafc;
  background: rgba(255, 255, 255, 0.1);
  transform: translateY(-1px);
}

/* 加载遮罩样式 - 现代科技感 */
.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, rgba(15, 15, 35, 0.9), rgba(26, 26, 46, 0.9));
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
  backdrop-filter: blur(20px);
}

.loading-spinner {
  text-align: center;
  color: #f8fafc;
  padding: 40px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(20px);
}

.spinner {
  width: 60px;
  height: 60px;
  border: 4px solid rgba(255, 255, 255, 0.1);
  border-top: 4px solid #3b82f6;
  border-right: 4px solid #8b5cf6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 24px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.loading-spinner p {
  font-size: 1.2rem;
  margin: 0;
  font-weight: 600;
  letter-spacing: 0.01em;
}

/* 滚动条美化 */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, #3b82f6, #8b5cf6);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, #2563eb, #7c3aed);
}

/* 选择文本样式 */
::selection {
  background: rgba(59, 130, 246, 0.3);
  color: #f8fafc;
}

/* 焦点样式 */
button:focus-visible,
.agent-card:focus-visible {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}

/* 平滑滚动 */
html {
  scroll-behavior: smooth;
}

/* 响应式设计增强 */
@media (max-width: 768px) {
  .app {
    min-width: auto;
  }

  .container {
    padding: 0 16px;
  }

  .section-title {
    font-size: 2.5rem;
  }

  .agents-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }

  .agent-card {
    min-height: 280px;
    padding: 24px 20px;
  }
}

/* 性能优化 */
.agent-card,
.category-header,
.status-item {
  will-change: transform;
}

/* 无障碍访问增强 */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }

  .app::before {
    animation: none;
  }
}
</style>

<!-- 全局CSS样式 - 隐藏备案信息 -->
<style>
/* 隐藏所有备案信息相关的元素 - 简化版 */
.beian-info {
  display: none !important;
  visibility: hidden !important;
  opacity: 0 !important;
  height: 0 !important;
  overflow: hidden !important;
  position: absolute !important;
  left: -9999px !important;
  top: -9999px !important;
}

.ai-disclaimer {
  display: none !important;
  visibility: hidden !important;
  opacity: 0 !important;
  height: 0 !important;
  overflow: hidden !important;
  position: absolute !important;
  left: -9999px !important;
  top: -9999px !important;
}

/* 隐藏包含备案信息类名的元素 */
*[class*="beian"] {
  display: none !important;
  visibility: hidden !important;
}

*[class*="disclaimer"] {
  display: none !important;
  visibility: hidden !important;
}
</style>