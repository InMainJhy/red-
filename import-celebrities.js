#!/usr/bin/env node
/**
 * 名人数据库批量导入脚本
 * 适用于：一个 EPUB/TXT 文件包含多个名人的情况
 * 
 * 使用方法：
 * 1. 将名人文件放入 /opt/persona-library/ 目录
 * 2. 运行：node import-celebrities.js
 */

import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import postgres from 'postgres';

// 数据库连接配置
const DATABASE_URL = process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/time_persona';

// 名人数据模板 - 您可以在这里添加更多名人
const DEFAULT_CELEBRITIES = [
  {
    id: 'steve-jobs',
    displayName: '史蒂夫·乔布斯',
    subtitle: '苹果联合创始人，改变世界的科技 visionary',
    category: 'celebrity',
    coverSeed: 'steve-jobs',
    biography: '史蒂夫·乔布斯（Steve Jobs, 1955-2011）是苹果公司的联合创始人，以其对完美主义的追求和改变世界的产品设计而闻名。他主导开发了 Macintosh、iPod、iPhone 和 iPad 等革命性产品，彻底改变了个人电脑、音乐、手机和平板电脑行业。',
    highlights: ['苹果联合创始人', 'iPhone 创造者', '皮克斯动画', '斯坦福演讲'],
    suggestedTopics: ['如何保持对产品的极致追求？', '面对失败时如何东山再起？', '创新思维如何培养？'],
    traits: ['完美主义', '极简主义', '现实扭曲力场'],
    values: ['创新', '设计', '用户体验']
  },
  {
    id: 'elon-musk',
    displayName: '埃隆·马斯克',
    subtitle: '特斯拉、SpaceX 创始人，火星殖民梦想家',
    category: 'celebrity',
    coverSeed: 'elon-musk',
    biography: '埃隆·马斯克（Elon Musk, 1971- ）是特斯拉、SpaceX、Neuralink 等多家公司的创始人，致力于推动人类成为多行星物种。他以第一性原理思考和疯狂的执行力闻名，正在改变汽车、航天、能源等多个行业。',
    highlights: ['特斯拉 CEO', 'SpaceX 创始人', '火星殖民计划', '第一性原理思考'],
    suggestedTopics: ['如何管理多家公司？', '第一性原理如何应用？', '面对质疑时如何坚持？'],
    traits: ['第一性原理', '执行力强', '敢于冒险'],
    values: ['人类未来', '可持续能源', '多行星物种']
  },
  {
    id: 'warren-buffett',
    displayName: '沃伦·巴菲特',
    subtitle: '股神，伯克希尔·哈撒韦董事长',
    category: 'celebrity',
    coverSeed: 'warren-buffett',
    biography: '沃伦·巴菲特（Warren Buffett, 1930- ）被誉为"股神"，是全球最成功的投资者之一，以价值投资理念闻名于世。他执掌伯克希尔·哈撒韦公司数十年，创造了惊人的投资回报，并承诺将绝大部分财富捐赠给慈善事业。',
    highlights: ['价值投资之父', '伯克希尔董事长', '复利奇迹', '慈善捐赠'],
    suggestedTopics: ['价值投资的核心理念是什么？', '如何保持长期投资的耐心？', '如何评估一家公司的价值？'],
    traits: ['价值投资', '长期主义', '理性冷静'],
    values: ['复利', '安全边际', '能力圈']
  },
  {
    id: 'jack-ma',
    displayName: '马云',
    subtitle: '阿里巴巴创始人，中国电商教父',
    category: 'celebrity',
    coverSeed: 'jack-ma',
    biography: '马云（Jack Ma, 1964- ）是阿里巴巴集团的创始人，被誉为中国电子商务的开拓者。他从英语教师起步，创建了全球最大的电商平台之一，深刻改变了中国乃至全球的商业格局。',
    highlights: ['阿里巴巴创始人', '淘宝之父', '支付宝创新', '英语老师出身'],
    suggestedTopics: ['如何在逆境中坚持梦想？', '创业初期如何组建团队？', '如何看待失败和挫折？'],
    traits: ['乐观坚韧', '善于演讲', '远见卓识'],
    values: ['让天下没有难做的生意', '客户第一', '拥抱变化']
  },
  {
    id: 'zhang-yiming',
    displayName: '张一鸣',
    subtitle: '字节跳动创始人，算法推荐先驱',
    category: 'celebrity',
    coverSeed: 'zhang-yiming',
    biography: '张一鸣（1983- ）是字节跳动公司的创始人，推出了今日头条、抖音/TikTok 等改变信息分发方式的产品。他以数据驱动和算法推荐技术闻名，重新定义了内容创作和消费的方式。',
    highlights: ['字节跳动创始人', '抖音/TikTok 之父', '算法推荐', '延迟满足感'],
    suggestedTopics: ['如何用数据驱动产品决策？', '延迟满足感如何培养？', '算法时代的创业机会？'],
    traits: ['理性冷静', '延迟满足', '数据驱动'],
    values: ['效率', '信息分发', '全球化']
  },
  {
    id: 'confucius',
    displayName: '孔子',
    subtitle: '儒家学派创始人，万世师表',
    category: 'celebrity',
    coverSeed: 'confucius',
    biography: '孔子（公元前551年-公元前479年），名丘，字仲尼，是中国古代伟大的思想家、教育家，儒家学派的创始人。他的思想影响了中国两千多年的文化，其核心包括仁、义、礼、智、信等价值观。',
    highlights: ['儒家创始人', '万世师表', '论语作者', '有教无类'],
    suggestedTopics: ['如何理解仁和礼的关系？', '中庸之道在现代的应用？', '教育的本质是什么？'],
    traits: ['仁爱', '智慧', '坚韧'],
    values: ['仁', '礼', '中庸', '修身齐家治国平天下']
  },
  {
    id: 'qin-shihuang',
    displayName: '秦始皇',
    subtitle: '中国历史上第一位皇帝，统一六国',
    category: 'celebrity',
    coverSeed: 'qin-shihuang',
    biography: '秦始皇（公元前259年-公元前210年），嬴姓，赵氏，名政，是中国历史上第一位皇帝。他统一了六国，建立了中央集权的秦朝，统一文字、货币、度量衡，修筑长城，对中国历史产生了深远影响。',
    highlights: ['统一六国', '始皇帝', '统一文字货币', '万里长城'],
    suggestedTopics: ['统一与分治的利弊？', '如何平衡权力与民生？', '改革如何推进？'],
    traits: ['雄才大略', '果断决绝', '集权统治'],
    values: ['统一', '法治', '中央集权']
  }
];

// 连接到数据库
async function connectDatabase() {
  console.log('正在连接数据库...');
  const sql = postgres(DATABASE_URL);
  try {
    await sql`SELECT 1`;
    console.log('✅ 数据库连接成功');
    return sql;
  } catch (error) {
    console.error('❌ 数据库连接失败:', error.message);
    process.exit(1);
  }
}

// 插入单个名人
async function insertCelebrity(sql, celebrity) {
  try {
    await sql`
      INSERT INTO profiles (
        id, display_name, subtitle, category, cover_seed,
        biography, highlights, suggested_topics,
        is_default, origin, created_at, updated_at
      ) VALUES (
        ${celebrity.id},
        ${celebrity.displayName},
        ${celebrity.subtitle},
        ${celebrity.category},
        ${celebrity.coverSeed},
        ${celebrity.biography},
        ${celebrity.highlights},
        ${celebrity.suggestedTopics},
        true,
        'bulk-import',
        NOW(),
        NOW()
      )
      ON CONFLICT (id) DO UPDATE SET
        display_name = EXCLUDED.display_name,
        subtitle = EXCLUDED.subtitle,
        biography = EXCLUDED.biography,
        highlights = EXCLUDED.highlights,
        suggested_topics = EXCLUDED.suggested_topics,
        updated_at = NOW()
    `;
    
    // 创建时间线节点
    const stages = [
      { label: '早期经历', type: 'early' },
      { label: '转折时期', type: 'turning-point' },
      { label: '稳定阶段', type: 'stable' },
      { label: '危机挑战', type: 'crisis' },
      { label: '巅峰成就', type: 'peak' }
    ];
    
    for (let i = 0; i < stages.length; i++) {
      const stage = stages[i];
      await sql`
        INSERT INTO timeline_nodes (
          id, profile_id, ordinal, time_label, stage_label, stage_type,
          key_event, summary, traits, values, tensions, source_evidence
        ) VALUES (
          ${`${celebrity.id}-${i + 1}`},
          ${celebrity.id},
          ${i},
          ${`阶段 ${i + 1}`},
          ${stage.label},
          ${stage.type},
          ${`${celebrity.displayName}的${stage.label}`},
          ${`${celebrity.displayName}在${stage.label}时期的重要经历...`},
          ${celebrity.traits},
          ${celebrity.values},
          ARRAY['挑战与机遇并存'],
          ARRAY[${{ quote: celebrity.biography.slice(0, 100), sourceLabel: '传记摘要' }}]
        )
        ON CONFLICT (id) DO NOTHING
      `;
    }
    
    console.log(`✅ 已导入: ${celebrity.displayName}`);
    return true;
  } catch (error) {
    console.error(`❌ 导入失败 ${celebrity.displayName}:`, error.message);
    return false;
  }
}

// 主函数
async function main() {
  console.log('🚀 开始批量导入名人数据库...\n');
  
  const sql = await connectDatabase();
  
  let successCount = 0;
  let failCount = 0;
  
  for (const celebrity of DEFAULT_CELEBRITIES) {
    const success = await insertCelebrity(sql, celebrity);
    if (success) {
      successCount++;
    } else {
      failCount++;
    }
  }
  
  console.log('\n📊 导入结果:');
  console.log(`   成功: ${successCount} 个`);
  console.log(`   失败: ${failCount} 个`);
  console.log(`   总计: ${DEFAULT_CELEBRITIES.length} 个`);
  
  // 查询当前总数
  const result = await sql`SELECT COUNT(*) as count FROM profiles WHERE is_default = true`;
  console.log(`\n📚 数据库中共有 ${result[0].count} 个名人`);
  
  await sql.end();
  console.log('\n✨ 导入完成！');
}

main().catch(console.error);
