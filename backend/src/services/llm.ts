import type { LlmChatRequest, LlmChatResponse } from '../domain.js';

export interface LlmConfig {
  apiKey: string | undefined;
  baseUrl: string;
  model: string;
}

export function getLlmConfig(): LlmConfig {
  return {
    apiKey: process.env.DEEPSEEK_API_KEY ?? process.env.OPENAI_API_KEY,
    baseUrl: process.env.LLM_BASE_URL ?? 'https://api.deepseek.com',
    model: process.env.LLM_MODEL ?? 'deepseek-chat',
  };
}

export async function chatWithLlm(request: LlmChatRequest): Promise<LlmChatResponse> {
  const config = getLlmConfig();

  if (!config.apiKey) {
    return {
      ok: false,
      text: '',
      model: config.model,
      baseUrl: config.baseUrl,
      error: 'API Key 未配置。请在服务器环境变量中设置 DEEPSEEK_API_KEY 或 OPENAI_API_KEY',
    };
  }

  const model = request.model ?? config.model;
  const temperature = request.temperature ?? 0.7;

  try {
    const response = await fetch(`${config.baseUrl}/v1/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages: request.messages,
        temperature,
        max_tokens: 2048,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      return {
        ok: false,
        text: '',
        model,
        baseUrl: config.baseUrl,
        error: `API 请求失败: ${response.status} - ${errorText}`,
      };
    }

    const data = await response.json() as {
      choices?: Array<{
        message?: {
          content?: string;
        };
      }>;
      model?: string;
    };

    const text = data.choices?.[0]?.message?.content ?? '';

    return {
      ok: true,
      text,
      model: data.model ?? model,
      baseUrl: config.baseUrl,
    };
  } catch (error) {
    return {
      ok: false,
      text: '',
      model,
      baseUrl: config.baseUrl,
      error: error instanceof Error ? error.message : '请求失败',
    };
  }
}

export async function testLlmConnection(): Promise<LlmChatResponse> {
  return chatWithLlm({
    messages: [
      { role: 'system', content: '你是一个测试助手，请简洁回答。' },
      { role: 'user', content: '请回复"连接成功"' },
    ],
    temperature: 0.1,
  });
}

export function getLlmEnvStatus(): {
  hasApiKey: boolean;
  apiKeyPreview: string | null;
  baseUrl: string;
  model: string;
} {
  const config = getLlmConfig();
  const apiKey = config.apiKey;

  return {
    hasApiKey: Boolean(apiKey),
    apiKeyPreview: apiKey ? `${apiKey.slice(0, 8)}...${apiKey.slice(-4)}` : null,
    baseUrl: config.baseUrl,
    model: config.model,
  };
}
