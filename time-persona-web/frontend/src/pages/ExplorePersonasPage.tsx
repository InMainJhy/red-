import { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, Search, X } from 'lucide-react';
import { PersonaApi } from '../services/api';
import type { PresetProfile, PersonaSearchResult, SearchCategory } from '../types';

const CATEGORIES: { id: SearchCategory; name: string }[] = [
  { id: 'all', name: '全部' }, { id: 'business', name: '商业' },
  { id: 'finance', name: '金融' }, { id: 'tech', name: '科技' },
  { id: 'politics', name: '政治' }, { id: 'culture', name: '文化' },
  { id: 'sports', name: '体育' }, { id: 'entertainment', name: '娱乐' },
  { id: 'education', name: '教育' }, { id: 'philosophy', name: '哲学' },
];

const KEYWORDS: Record<string, string[]> = {
  business: ['business', 'founder', 'ceo', '创业', '企业', '商业'],
  finance: ['invest', 'investor', 'market', 'capital', '股票', '投资', '金融'],
  tech: ['tech', 'apple', 'tesla', 'algorithm', '科技', '技术', '产品'],
  politics: ['politics', 'emperor', 'dynasty', '政治', '皇帝', '朝代'],
  culture: ['writer', 'artist', 'poet', '文化', '艺术', '作家'],
  sports: ['sports', 'athlete', '体育', '运动员'],
  entertainment: ['actor', 'singer', 'movie', '娱乐', '演员'],
  education: ['education', 'teacher', 'scholar', '教育', '学者'],
  philosophy: ['philosophy', 'thinker', '儒家', '哲学', '思想'],
};

export default function ExplorePersonasPage() {
  const [searchText, setSearchText] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<SearchCategory>('all');
  const [allResults, setAllResults] = useState<PersonaSearchResult[]>([]);
  const [filteredResults, setFilteredResults] = useState<PersonaSearchResult[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => { loadPresets(); }, []);

  useEffect(() => { filterResults(); }, [searchText, selectedCategory, allResults]);

  function resolveCategory(profile: PresetProfile): SearchCategory {
    const text = `${profile.id} ${profile.displayName} ${profile.subtitle} ${profile.biography} ${profile.highlights.join(' ')}`.toLowerCase();
    for (const [cat, keywords] of Object.entries(KEYWORDS)) {
      if (keywords.some(kw => text.includes(kw))) return cat as SearchCategory;
    }
    if (profile.category === 'history') return 'politics';
    if (profile.category === 'fictional') return 'entertainment';
    return 'business';
  }

  function mapToSearchResult(profile: PresetProfile): PersonaSearchResult {
    const category = resolveCategory(profile);
    return {
      id: profile.id,
      displayName: profile.displayName,
      subtitle: profile.subtitle,
      category,
      coverSeed: profile.coverSeed,
      matchReason: [CATEGORIES.find(c => c.id === category)?.name || '', profile.subtitle],
      hotLevel: profile.highlights.length >= 3 ? 5 : 4,
      tags: profile.highlights.slice(0, 3),
    };
  }

  async function loadPresets() {
    setLoading(true);
    try {
      const presets = await PersonaApi.getPresets();
      const results = presets.map(mapToSearchResult).sort((a, b) => b.hotLevel - a.hotLevel);
      setAllResults(results);
      setFilteredResults(results);
    } catch { } finally { setLoading(false); }
  }

  function filterResults() {
    let base = selectedCategory === 'all' ? allResults : allResults.filter(r => r.category === selectedCategory);
    if (searchText.trim()) {
      const kw = searchText.toLowerCase();
      base = base.filter(r =>
        r.displayName.toLowerCase().includes(kw) ||
        r.subtitle.toLowerCase().includes(kw) ||
        r.tags.some(t => t.toLowerCase().includes(kw))
      );
    }
    setFilteredResults(base);
  }

  return (
    <div className="min-h-screen bg-background relative">
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute -top-16 -left-16 w-64 h-64 rounded-full bg-mint/5 blur-3xl" />
        <div className="absolute -top-8 -right-16 w-56 h-56 rounded-full bg-lavender/5 blur-3xl" />
      </div>

      <div className="relative max-w-2xl mx-auto px-4 pt-6 pb-12">
        {/* Header */}
        <div className="flex items-center gap-3 mb-6">
          <Link to="/" className="w-9 h-9 rounded-full bg-white/80 backdrop-blur flex items-center justify-center shadow-sm border border-slate-100 hover:bg-white transition-colors">
            <ArrowLeft size={16} className="text-mint-dark" />
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-slate-900">寻访前人</h1>
            <p className="text-sm text-slate-400">探索不同人生阶段的视角</p>
          </div>
        </div>

        {/* Search */}
        <div className="relative mb-4">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            value={searchText}
            onChange={e => setSearchText(e.target.value)}
            placeholder="搜索人物、角色或话题..."
            className="w-full pl-10 pr-10 py-3 bg-white/80 backdrop-blur rounded-xxl border border-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-mint/30 shadow-sm"
          />
          {searchText && (
            <button onClick={() => setSearchText('')} className="absolute right-3 top-1/2 -translate-y-1/2 w-6 h-6 rounded-full bg-slate-100 flex items-center justify-center">
              <X size={12} className="text-slate-400" />
            </button>
          )}
        </div>

        {/* Categories */}
        <div className="flex gap-2 overflow-x-auto pb-3 mb-4 scrollbar-hide">
          {CATEGORIES.map(cat => (
            <button
              key={cat.id}
              onClick={() => setSelectedCategory(cat.id)}
              className={`flex-shrink-0 px-4 py-2 rounded-pill text-sm font-medium transition-all ${
                selectedCategory === cat.id
                  ? 'bg-mint text-white shadow-sm'
                  : 'bg-white text-slate-500 border border-slate-100 hover:border-mint/30'
              }`}
            >
              {cat.name}
            </button>
          ))}
        </div>

        {/* Results count */}
        <p className="text-xs text-slate-400 mb-3">
          {loading ? '加载中...' : `找到 ${filteredResults.length} 个相关人物`}
        </p>

        {/* Results */}
        {loading ? (
          <div className="text-center py-12 text-slate-400">
            <div className="animate-spin w-8 h-8 border-2 border-mint border-t-transparent rounded-full mx-auto mb-3" />
            <p>正在从后端加载人物...</p>
          </div>
        ) : filteredResults.length === 0 ? (
          <div className="text-center py-12 text-slate-400">
            <p className="text-lg font-medium text-slate-500 mb-1">暂无匹配结果</p>
            <p className="text-sm">试试其他关键词或分类</p>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredResults.map(person => (
              <div
                key={person.id}
                onClick={() => navigate(`/profile/${person.id}`)}
                className="flex items-center gap-3 p-4 bg-white rounded-xxl border border-slate-100 shadow-card hover:shadow-md transition-all cursor-pointer"
              >
                <div className="w-13 h-13 rounded-full bg-gradient-to-br from-mint to-mint-dark flex items-center justify-center text-white font-bold text-lg flex-shrink-0" style={{ width: 52, height: 52 }}>
                  {person.displayName.charAt(0)}
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-slate-800">{person.displayName}</h3>
                  <p className="text-sm text-slate-400 truncate">{person.subtitle}</p>
                  <div className="flex gap-1 mt-1.5 flex-wrap">
                    <span className="text-xs bg-mint-bg text-mint-dark px-2 py-0.5 rounded-full">
                      {CATEGORIES.find(c => c.id === person.category)?.name}
                    </span>
                    {person.tags.slice(0, 2).map(tag => (
                      <span key={tag} className="text-xs bg-slate-50 text-slate-400 px-2 py-0.5 rounded-full">{tag}</span>
                    ))}
                  </div>
                </div>
                <ChevronRightIcon />
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function ChevronRightIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-slate-300 flex-shrink-0">
      <path d="m9 18 6-6-6-6" />
    </svg>
  );
}
