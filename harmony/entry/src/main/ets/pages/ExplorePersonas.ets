import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import {
  PersonaCategory,
  SearchCategory,
  CategoryInfo,
  PersonaSearchResult,
  SearchHistoryItem
} from '../common/Models'
import {
  Icon,
  IconSize,
  getCategoryIconType
} from '../components/CustomIcon'

const FALLBACK_SAFE_TOP_VP: number = 52

const CATEGORIES: CategoryInfo[] = [
  { id: 'all', name: '全部', icon: '', description: '查看所有人物' },
  { id: 'business', name: '商业', icon: '', description: '企业家、商业领袖' },
  { id: 'finance', name: '金融', icon: '', description: '投资大师、炒股高手' },
  { id: 'tech', name: '科技', icon: '', description: '科技先驱、创新者' },
  { id: 'politics', name: '政治', icon: '', description: '政治人物、领袖' },
  { id: 'culture', name: '文化', icon: '', description: '文化名人、艺术家' },
  { id: 'sports', name: '体育', icon: '', description: '体育明星、运动员' },
  { id: 'entertainment', name: '娱乐', icon: '', description: '娱乐明星、艺人' },
  { id: 'education', name: '教育', icon: '', description: '教育家、学者' },
  { id: 'philosophy', name: '哲学', icon: '', description: '思想家、哲学家' }
]

const MOCK_SEARCH_RESULTS: PersonaSearchResult[] = [
  {
    id: 'warren-buffett',
    displayName: '沃伦·巴菲特',
    subtitle: '伯克希尔·哈撒韦公司创始人',
    category: 'finance',
    coverSeed: 'buffett',
    matchReason: ['价值投资', '长期持股', '炒股哲学'],
    hotLevel: 5,
    tags: ['投资大师', '首富', '慈善家']
  },
  {
    id: 'jack-ma',
    displayName: '马云',
    subtitle: '阿里巴巴创始人',
    category: 'business',
    coverSeed: 'jackma',
    matchReason: ['电商', '互联网创业', '商业领袖'],
    hotLevel: 5,
    tags: ['互联网', '企业家', '创新者']
  },
  {
    id: 'elon-musk',
    displayName: '埃隆·马斯克',
    subtitle: '特斯拉、SpaceX创始人',
    category: 'tech',
    coverSeed: 'musk',
    matchReason: ['科技创新', '创业精神', '改变世界'],
    hotLevel: 5,
    tags: ['科技狂人', '企业家', '梦想家']
  },
  {
    id: 'steve-jobs',
    displayName: '史蒂夫·乔布斯',
    subtitle: '苹果公司创始人',
    category: 'tech',
    coverSeed: 'steve-jobs',
    matchReason: ['产品哲学', '用户体验', '创新设计'],
    hotLevel: 5,
    tags: ['产品经理', '设计思维', '完美主义']
  },
  {
    id: 'confucius',
    displayName: '孔子',
    subtitle: '儒家学派创始人',
    category: 'philosophy',
    coverSeed: 'confucius',
    matchReason: ['儒家思想', '中华文化', '教育理念'],
    hotLevel: 4,
    tags: ['哲学家', '教育家', '思想家']
  },
  {
    id: 'zhang-yiming',
    displayName: '张一鸣',
    subtitle: '字节跳动创始人',
    category: 'tech',
    coverSeed: 'zhang-yiming',
    matchReason: ['算法推荐', '字节跳动', '创业故事'],
    hotLevel: 4,
    tags: ['今日头条', '抖音', '科技企业家']
  }
]

@Entry
@Component
struct ExplorePersonas {
  @State searchText: string = ''
  @State selectedCategory: SearchCategory = 'all'
  @State searchResults: PersonaSearchResult[] = []
  @State isSearching: boolean = false
  @State searchHistory: SearchHistoryItem[] = []
  @State showHistory: boolean = false
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0

  aboutToAppear(): void {
    this.loadSafeInsets()
    this.loadMockResults()
  }

  loadSafeInsets(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      fetchSafeAreaInsets(ctx).then((insets) => {
        this.safeTopVp = insets.topVp
        this.safeBottomVp = insets.bottomVp
      })
    } catch (_e) {
      // 忽略错误
    }
  }

  loadMockResults(): void {
    this.searchResults = MOCK_SEARCH_RESULTS
  }

  topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

  performSearch(keyword: string): void {
    if (!keyword.trim()) {
      this.searchResults = MOCK_SEARCH_RESULTS
      this.showHistory = false
      return
    }

    this.isSearching = true
    this.showHistory = false

    setTimeout(() => {
      const lowerKeyword = keyword.toLowerCase()

      this.searchResults = MOCK_SEARCH_RESULTS.filter((person) => {
        const nameMatch = person.displayName.toLowerCase().includes(lowerKeyword)
        const tagMatch = person.tags.some(tag => tag.toLowerCase().includes(lowerKeyword))
        const reasonMatch = person.matchReason.some(reason => reason.toLowerCase().includes(lowerKeyword))
        const subtitleMatch = person.subtitle.toLowerCase().includes(lowerKeyword)

        return nameMatch || tagMatch || reasonMatch || subtitleMatch
      }).map((person) => {
        const matchReasons: string[] = []
        if (person.displayName.toLowerCase().includes(lowerKeyword)) {
          matchReasons.push('名称匹配')
        }
        person.tags.forEach(tag => {
          if (tag.toLowerCase().includes(lowerKeyword)) {
            matchReasons.push(tag)
          }
        })
        person.matchReason.forEach(reason => {
          if (reason.toLowerCase().includes(lowerKeyword)) {
            matchReasons.push(reason)
          }
        })

        const uniqueReasons: string[] = []
        const seen = new Set<string>()
        const combinedReasons = matchReasons.concat(person.matchReason)
        for (let i = 0; i < combinedReasons.length && uniqueReasons.length < 5; i++) {
          if (!seen.has(combinedReasons[i])) {
            seen.add(combinedReasons[i])
            uniqueReasons.push(combinedReasons[i])
          }
        }

        const result: PersonaSearchResult = {
          id: person.id,
          displayName: person.displayName,
          subtitle: person.subtitle,
          category: person.category,
          coverSeed: person.coverSeed,
          matchReason: uniqueReasons,
          hotLevel: person.hotLevel,
          tags: person.tags
        }
        return result
      })

      this.searchResults.sort((a, b) => b.hotLevel - a.hotLevel)
      this.isSearching = false
    }, 300)
  }

  filterByCategory(category: SearchCategory): void {
    this.selectedCategory = category

    if (this.searchText.trim()) {
      this.performSearch(this.searchText)
    } else {
      if (category === 'all') {
        this.searchResults = MOCK_SEARCH_RESULTS
      } else {
        this.searchResults = MOCK_SEARCH_RESULTS.filter(p => p.category === category)
      }
    }
  }

  selectPersona(person: PersonaSearchResult): void {
    router.pushUrl({
      url: 'pages/ProfileDetail',
      params: {
        profileId: person.id
      }
    })
  }

  getCategoryName(categoryId: SearchCategory): string {
    const category = CATEGORIES.find(c => c.id === categoryId)
    return category ? category.name : ''
  }

  // 获取分类渐变色
  getCategoryGradient(category: SearchCategory): string[] {
    const gradientMap: Record<SearchCategory, string[]> = {
      'all': [MintColors.mintPale, MintColors.lavenderPale],
      'business': [MintColors.mintPale, 'rgba(78, 205, 196, 0.08)'],
      'finance': ['rgba(232, 184, 109, 0.1)', MintColors.lavenderPale],
      'tech': [MintColors.mintBg, 'rgba(78, 205, 196, 0.06)'],
      'politics': [MintColors.lavenderPale, 'rgba(184, 169, 217, 0.08)'],
      'culture': ['rgba(224, 120, 128, 0.08)', MintColors.lavenderPale],
      'sports': ['rgba(61, 189, 156, 0.1)', MintColors.mintPale],
      'entertainment': [MintColors.lavenderPale, 'rgba(168, 153, 199, 0.08)'],
      'education': [MintColors.mintBg, MintColors.lavenderPale],
      'philosophy': ['rgba(155, 138, 196, 0.1)', MintColors.lavenderPale]
    }
    return gradientMap[category] || gradientMap['all']
  }

  // 获取头像渐变
  getAvatarGradient(category: SearchCategory): string[] {
    const gradientMap: Record<SearchCategory, string[]> = {
      'all': [MintColors.mintLight, MintColors.mint],
      'business': [MintColors.mintLight, MintColors.mintDark],
      'finance': ['#EDD48B', MintColors.warning],
      'tech': [MintColors.mintLight, MintColors.mint],
      'politics': [MintColors.lavenderLight, MintColors.lavender],
      'culture': [MintColors.lavenderLight, MintColors.lavender],
      'sports': ['#7FD4C0', MintColors.mintDark],
      'entertainment': [MintColors.lavenderLight, MintColors.lavenderDark],
      'education': [MintColors.mintLight, MintColors.mint],
      'philosophy': [MintColors.lavenderLight, MintColors.lavender]
    }
    return gradientMap[category] || gradientMap['all']
  }

  // 获取分类标签背景
  getCategoryChipBg(categoryId: string, isSelected: boolean): string {
    if (isSelected) {
      return MintColors.mint
    }
    const bgMap: Record<string, string> = {
      'all': MintColors.categoryAll,
      'business': MintColors.categoryBusiness,
      'finance': MintColors.categoryFinance,
      'tech': MintColors.categoryTech,
      'politics': MintColors.categoryPolitics,
      'culture': MintColors.categoryCulture,
      'sports': MintColors.categorySports,
      'entertainment': MintColors.categoryEntertainment,
      'education': MintColors.categoryEducation,
      'philosophy': MintColors.categoryPhilosophy
    }
    return bgMap[categoryId] || MintColors.categoryAll
  }

  // 获取分类图标色
  getCategoryChipColor(categoryId: string, isSelected: boolean): string {
    if (isSelected) {
      return '#FFFFFF'
    }
    const colorMap: Record<string, string> = {
      'all': MintColors.mint,
      'business': MintColors.mintDark,
      'finance': MintColors.warning,
      'tech': MintColors.mint,
      'politics': MintColors.lavender,
      'culture': MintColors.error,
      'sports': MintColors.success,
      'entertainment': MintColors.lavender,
      'education': MintColors.mint,
      'philosophy': MintColors.lavenderDark
    }
    return colorMap[categoryId] || MintColors.mint
  }

  @Builder
  buildHotStars(level: number) {
    Row({ space: 2 }) {
      ForEach([0, 1, 2, 3, 4], (_: number, index: number) => {
        Icon({
          iconType: 'star',
          iconSize: 9,
          iconColor: index < level ? MintColors.warning : MintColors.border
        })
      })
    }
  }

  @Builder
  buildPersonaCard(person: PersonaSearchResult) {
    Column() {
      Row({ space: Spacing.md }) {
        // 头像
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(52)
            .height(52)
            .borderRadius(26)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [[this.getAvatarGradient(person.category)[0], 0], [this.getAvatarGradient(person.category)[1], 1]]
            })

          Text(person.displayName.charAt(0))
            .fontSize(Typography.size.xl)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .shadow({
          radius: 12,
          color: 'rgba(78, 205, 196, 0.15)',
          offsetX: 0,
          offsetY: 4
        })

        // 信息
        Column({ space: 5 }) {
          Row({ space: Spacing.xs }) {
            Text(person.displayName)
              .fontSize(Typography.size.bodyLg)
              .fontWeight(FontWeight.Medium)
              .fontColor(MintColors.textPrimary)

            this.buildHotStars(person.hotLevel)
          }

          Text(person.subtitle)
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.textMuted)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 标签
          Row({ space: 5 }) {
            Column() {
              Text(this.getCategoryName(person.category))
                .fontSize(Typography.size.xs)
                .fontColor(MintColors.mintDark)
            }
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(MintColors.mintBg)
            .borderRadius(BorderRadius.tag)

            ForEach(person.tags.slice(0, 2), (tag: string) => {
              Column() {
                Text(tag)
                  .fontSize(Typography.size.xs)
                  .fontColor(MintColors.textMuted)
              }
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .backgroundColor(MintColors.backgroundSecondary)
              .borderRadius(BorderRadius.tag)
            }, (tag: string) => tag)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 箭头
        Icon({
          iconType: 'arrowRight',
          iconSize: 18,
          iconColor: MintColors.textMuted
        })
        .padding({ left: Spacing.xs })
      }
      .width('100%')

      // 匹配原因
      if (this.searchText.trim() && person.matchReason.length > 0) {
        Column({ space: 5 }) {
          Text('匹配原因')
            .fontSize(Typography.size.xs)
            .fontColor(MintColors.textMuted)

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(person.matchReason.slice(0, 3), (reason: string) => {
              Column() {
                Text(reason)
                  .fontSize(Typography.size.xs)
                  .fontColor(MintColors.mintDark)
              }
              .margin({ right: 5, bottom: 3 })
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor(MintColors.mintBg)
              .borderRadius(BorderRadius.chip)
            }, (reason: string) => reason)
          }
        }
        .margin({ top: Spacing.sm })
        .padding({ left: Spacing.md })
      }
    }
    .width('100%')
    .padding(Spacing.md)
    .backgroundColor(MintColors.cardPrimary)
    .borderRadius(BorderRadius.xxl)
    .border({
      width: 0.5,
      color: MintColors.border,
      radius: BorderRadius.xxl
    })
    .shadow({
      radius: 16,
      color: 'rgba(78, 205, 196, 0.06)',
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.selectPersona(person)
    })
  }

  @Builder
  buildCategoryChip(category: CategoryInfo) {
    Column() {
      Row({ space: 4 }) {
        Icon({
          iconType: getCategoryIconType(category.id),
          iconSize: 10,
          iconColor: this.getCategoryChipColor(category.id, this.selectedCategory === category.id)
        })
        Text(category.name)
          .fontSize(Typography.size.caption)
          .fontColor(this.getCategoryChipColor(category.id, this.selectedCategory === category.id))
      }
    }
    .padding({
      left: Spacing.md,
      right: Spacing.md,
      top: Spacing.sm,
      bottom: Spacing.sm
    })
    .backgroundColor(this.getCategoryChipBg(category.id, this.selectedCategory === category.id))
    .borderRadius(BorderRadius.xxl)
    .border({
      width: this.selectedCategory === category.id ? 0 : 0.5,
      color: MintColors.borderLight,
      radius: BorderRadius.xxl
    })
    .onClick(() => {
      this.filterByCategory(category.id)
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景
      Column() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(MintColors.background)

        // 顶部光晕 - 薄荷绿
        Column()
          .width(280)
          .height(180)
          .borderRadius(140)
          .backgroundColor('rgba(78, 205, 196, 0.08)')
          .blur(80)
          .position({ x: -80, y: -50 })

        // 右上光晕 - 淡紫
        Column()
          .width(240)
          .height(160)
          .borderRadius(120)
          .backgroundColor('rgba(184, 169, 217, 0.07)')
          .blur(60)
          .position({ right: -60, y: -30 })
      }
      .width('100%')
      .height('100%')

      // 左上返回按钮
      Button() {
        Icon({
          iconType: 'arrowLeft',
          iconSize: 16,
          iconColor: MintColors.mintDark
        })
      }
      .width(38)
      .height(38)
      .backgroundColor(MintColors.surfaceGlass)
      .borderRadius(19)
      .shadow({
        radius: 10,
        color: 'rgba(78, 205, 196, 0.1)',
        offsetX: 0,
        offsetY: 3
      })
      .position({ x: Spacing.page.horizontal, y: this.topInsetVp() + 12 })
      .onClick(() => {
        router.back()
      })

      Scroll() {
        Column({ space: Spacing.md }) {
          // 大标题区
          Column({ space: Spacing.xs }) {
            Text('寻访前人')
              .fontSize(Typography.size.hero)
              .fontWeight(Typography.weight.bold)
              .fontColor(MintColors.textPrimary)

            Text('探索名人的阶段人格，与不同人生节点对话')
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textMuted)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ top: this.topInsetVp() + 60 })

          // 搜索框（毛玻璃）
          Column() {
            Row({ space: Spacing.sm }) {
              Icon({
                iconType: 'search',
                iconSize: 16,
                iconColor: MintColors.textMuted
              })

              TextInput({ placeholder: '搜索名人、角色、故事...', text: this.searchText })
                .layoutWeight(1)
                .placeholderColor(MintColors.textPlaceholder)
                .placeholderFont({
                  size: Typography.size.body,
                  weight: FontWeight.Normal
                })
                .fontSize(Typography.size.body)
                .fontColor(MintColors.textPrimary)
                .backgroundColor(Color.Transparent)
                .caretColor(MintColors.mint)
                .onChange((value: string) => {
                  this.searchText = value
                })
                .onSubmit(() => {
                  this.performSearch(this.searchText)
                })

              if (this.searchText.length > 0) {
                Column() {
                  Icon({
                    iconType: 'close',
                    iconSize: 12,
                    iconColor: MintColors.textMuted
                  })
                }
                .width(24)
                .height(24)
                .backgroundColor(MintColors.backgroundSecondary)
                .borderRadius(12)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => {
                  this.searchText = ''
                  this.performSearch('')
                })
              }
            }
            .width('100%')
            .padding({
              left: Spacing.md,
              right: Spacing.md,
              top: Spacing.sm,
              bottom: Spacing.sm
            })
          }
          .width('100%')
          .backgroundColor(MintColors.surfaceGlass)
          .borderRadius(BorderRadius.xxl)
          .border({
            width: 0.5,
            color: MintColors.border,
            radius: BorderRadius.xxl
          })
          .shadow({
            radius: 20,
            color: 'rgba(78, 205, 196, 0.08)',
            offsetX: 0,
            offsetY: 6
          })

          // 分类横滚
          Scroll() {
            Row({ space: Spacing.xs }) {
              ForEach(CATEGORIES, (category: CategoryInfo) => {
                this.buildCategoryChip(category)
              }, (category: CategoryInfo) => category.id)
            }
            .padding({
              left: 0,
              right: 0
            })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .width('100%')
          .padding({ left: 0, right: 0 })

          // 统计
          Row() {
            Text(`找到 ${this.searchResults.length} 个相关人物`)
              .fontSize(Typography.size.sm)
              .fontColor(MintColors.textMuted)
          }
          .width('100%')
          .padding({ top: Spacing.xs })

          // 人物卡片列表
          Column({ space: Spacing.sm }) {
            if (this.isSearching) {
              Column() {
                Text('搜索中...')
                  .fontSize(Typography.size.body)
                  .fontColor(MintColors.textSecondary)
              }
              .width('100%')
              .padding(Spacing.xl)
            } else if (this.searchResults.length === 0) {
              Column({ space: Spacing.md }) {
                Icon({
                  iconType: 'sad',
                  iconSize: 32,
                  iconColor: MintColors.textMuted
                })
                Text('暂无匹配结果')
                  .fontSize(Typography.size.bodyLg)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(MintColors.textSecondary)
                Text('试试其他关键词或分类')
                  .fontSize(Typography.size.caption)
                  .fontColor(MintColors.textMuted)
              }
              .width('100%')
              .padding(Spacing.xl)
              .alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.searchResults, (person: PersonaSearchResult) => {
                this.buildPersonaCard(person)
              }, (person: PersonaSearchResult) => person.id)
            }
          }
          .padding({ bottom: this.safeBottomVp + Spacing.xl })
        }
        .padding({
          left: Spacing.page.horizontal,
          right: Spacing.page.horizontal
        })
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MintColors.background)
  }
}
