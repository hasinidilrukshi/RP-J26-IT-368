import { BrowserRouter, Routes, Route, useLocation } from 'react-router-dom'
import Sidebar from './components/Sidebar'
import TopBar from './components/TopBar'

// Pages — Primary Research
import Dashboard from './pages/Dashboard'
import DemandAnalytics from './pages/DemandAnalytics'
import ForecastDrivers from './pages/ForecastDrivers'
import MarketGraph from './pages/MarketGraph'
import DemandAlerts from './pages/DemandAlerts'
import SpatialDemandMap from './pages/SpatialDemandMap'
import ModelManagement from './pages/ModelManagement'
import DataSources from './pages/DataSources'
import Login from './pages/Login'

// Pages — Shared Platform
import Users from './pages/Users'
import Emergencies from './pages/Emergencies'
import RoutesPage from './pages/Routes'
import Destinations from './pages/Destinations'
import RiskZones from './pages/RiskZones'

/* ─── Shell wrapper (needs router context for location) ─────────────────── */
function AppShell() {
  const location = useLocation()
  const isLoginPage = location.pathname === '/login'

  if (isLoginPage) {
    return (
      <Routes>
        <Route path="/login" element={<Login />} />
      </Routes>
    )
  }

  return (
    <div className="app-shell">
      <Sidebar />
      <div className="main-content">
        <TopBar />
        <Routes>
          <Route path="/"                   element={<Dashboard />} />
          <Route path="/demand-analytics"   element={<DemandAnalytics />} />
          <Route path="/forecast-drivers"   element={<ForecastDrivers />} />
          <Route path="/market-graph"       element={<MarketGraph />} />
          <Route path="/demand-alerts"      element={<DemandAlerts />} />
          <Route path="/spatial-demand-map" element={<SpatialDemandMap />} />
          <Route path="/model-management"   element={<ModelManagement />} />
          <Route path="/data-sources"       element={<DataSources />} />
          <Route path="/users"              element={<Users />} />
          <Route path="/emergencies"        element={<Emergencies />} />
          <Route path="/routes"             element={<RoutesPage />} />
          <Route path="/destinations"       element={<Destinations />} />
          <Route path="/risk-zones"         element={<RiskZones />} />
          {/* Catch-all → Dashboard */}
          <Route path="*"                   element={<Dashboard />} />
        </Routes>
      </div>
    </div>
  )
}

/* ─── Root App ──────────────────────────────────────────────────────────── */
export default function App() {
  return (
    <BrowserRouter>
      <AppShell />
    </BrowserRouter>
  )
}
