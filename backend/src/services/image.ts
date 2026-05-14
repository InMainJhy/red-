import type { ArenaRun } from '../domain.js';

export interface ImageGenConfig {
  apiKey: string | undefined;
  baseUrl: string;
  model: string;
}

export function getImageGenConfig(): ImageGenConfig {
  return {
    apiKey: process.env.SILICONFLOW_API_KEY,
    baseUrl: process.env.IMAGE_BASE_URL || 'https://api.siliconflow.cn',
    model: process.env.IMAGE_MODEL || 'Kwai-Kolors/Kolors',
  };
}

export function getImageEnvStatus(): {
  hasApiKey: boolean;
  apiKeyPreview: string | null;
  baseUrl: string;
  model: string;
} {
  const config = getImageGenConfig();
  const apiKey = config.apiKey;
  return {
    hasApiKey: !!apiKey,
    apiKeyPreview: apiKey ? `${apiKey.slice(0, 8)}...${apiKey.slice(-4)}` : null,
    baseUrl: config.baseUrl,
    model: config.model,
  };
}

export interface GeneratePosterRequest {
  topic: string;
  mode: string;
  participants: Array<{
    displayName: string;
    stageLabel: string;
  }>;
  summary?: {
    title?: string;
    consensus?: string;
    narrativeHook?: string;
  };
  stylePrompt?: string;
  imageSize?: string;
}

export interface GeneratePosterResponse {
  ok: boolean;
  imageUrl?: string;
  imageBase64?: string;
  model: string;
  error?: string;
  prompt: string;
}

function buildPosterPrompt(request: GeneratePosterRequest): string {
  const participants = request.participants.map(p => p.displayName).join('、');
  const topic = request.topic;
  const mode = request.mode === 'debate' ? '辩论' : '圆桌讨论';
  const consensus = request.summary?.consensus || '';
  const disagreements = request.summary?.disagreements?.join('；') || '';
  const advice = request.summary?.actionableAdvice?.slice(0, 3).map((a, i) => `${i + 1}. ${a}`).join('  ') || '';
  const customStyle = request.stylePrompt || '';

  const prompt = `信息图风格知识科普海报，中文排版，竖版布局，从上到下分为清晰的模块区域。

【顶部区域】
- 大号加粗主标题："${topic}"
- 副标题/引言：${consensus || mode + '精华总结'}

${mode === 'debate' ? `【中间上部：双栏对比区】
- 左右对称两栏布局，用对比色区分两个阵营
- 左栏标题标注第一个阵营的核心判断，右栏标注第二个阵营的核心判断
- 每栏包含3个带扁平化矢量图标的要点
- 每栏底部有对话气泡，引用${participants}的关键发言` : `【中间上部：角色观点区】
- ${participants}每人一个卡片模块
- 每个卡片包含角色名、核心观点、带图标的要点
- 卡片之间用连接线或箭头表示对话关系`}

${disagreements ? `【中间：核心分歧区】
- 居中标题"核心分歧"
- 双向箭头连接对立观点：${disagreements}
- 用醒目的对比色（如红vs蓝）区分不同立场` : ''}

${advice ? `【中下部：行动建议区】
- 三栏卡片式布局，带数字序号和对勾图标
- 内容：${advice}` : ''}

【底部区域】
- 深色高亮背景的最终结论区
- 简洁有力的总结语

整体风格要求：
- 扁平化矢量图标，简约无衬线中文字体
- 模块化卡片设计，圆角矩形，信息层级清晰
- 配色根据主题灵活变化：可使用渐变色、对比色、互补色等，每次生成尝试不同的配色方案，如深蓝配金色、紫红配青绿、暖橙配深灰、翡翠绿配珊瑚粉等
- 背景干净专业，可以是浅色、深色或渐变背景
- 易读性强，类似微信公众号知识科普长图的排版风格
- 不需要人物照片，用图标和文字传达信息
${customStyle}`;

  return prompt;
}

export async function generatePoster(request: GeneratePosterRequest): Promise<GeneratePosterResponse> {
  const config = getImageGenConfig();

  if (!config.apiKey) {
    return {
      ok: false,
      model: config.model,
      prompt: '',
      error: 'SILICONFLOW_API_KEY 未配置，请在环境变量中设置',
    };
  }

  const prompt = buildPosterPrompt(request);
  const imageSize = request.imageSize || '1024x1024';

  try {
    const response = await fetch(`${config.baseUrl}/v1/images/generations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.apiKey}`,
      },
      body: JSON.stringify({
        model: config.model,
        prompt,
        image_size: imageSize,
        batch_size: 1,
        num_inference_steps: 20,
        guidance_scale: 7.5,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      return {
        ok: false,
        model: config.model,
        prompt,
        error: `图片生成请求失败: ${response.status} - ${errorText}`,
      };
    }

    const data = await response.json() as {
      images?: Array<{ url?: string }>;
      timings?: Record<string, unknown>;
      seed?: number;
    };

    const imageUrl = data.images?.[0]?.url;

    if (!imageUrl) {
      return {
        ok: false,
        model: config.model,
        prompt,
        error: '图片生成成功但未返回URL',
      };
    }

    // 硅基流动的图片URL有效期1小时，尝试下载并转为base64
    let imageBase64: string | undefined;
    try {
      const imgResponse = await fetch(imageUrl);
      if (imgResponse.ok) {
        const buffer = await imgResponse.arrayBuffer();
        const base64 = Buffer.from(buffer).toString('base64');
        imageBase64 = `data:image/png;base64,${base64}`;
      }
    } catch {
      // 下载失败，只返回URL
    }

    return {
      ok: true,
      imageUrl,
      imageBase64,
      model: config.model,
      prompt,
    };
  } catch (error) {
    return {
      ok: false,
      model: config.model,
      prompt,
      error: error instanceof Error ? error.message : '图片生成失败',
    };
  }
}

export async function generatePosterFromRun(run: ArenaRun, stylePrompt?: string): Promise<GeneratePosterResponse> {
  return generatePoster({
    topic: run.topic,
    mode: run.mode,
    participants: run.participants.map(p => ({
      displayName: p.displayName,
      stageLabel: p.stageLabel,
    })),
    summary: run.summary,
    stylePrompt,
  });
}
