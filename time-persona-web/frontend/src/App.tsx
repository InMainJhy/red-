import { BrowserRouter, Routes, Route } from 'react-router-dom';
import IndexPage from './pages/IndexPage';
import ExplorePersonasPage from './pages/ExplorePersonasPage';
import CreateRolePage from './pages/CreateRolePage';
import ProfileDetailPage from './pages/ProfileDetailPage';
import ArenaPage from './pages/ArenaPage';
import SummaryDetailPage from './pages/SummaryDetailPage';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<IndexPage />} />
        <Route path="/explore" element={<ExplorePersonasPage />} />
        <Route path="/create" element={<CreateRolePage />} />
        <Route path="/profile/:profileId" element={<ProfileDetailPage />} />
        <Route path="/arena/:profileId" element={<ArenaPage />} />
        <Route path="/summary/:summaryId" element={<SummaryDetailPage />} />
      </Routes>
    </BrowserRouter>
  );
}
