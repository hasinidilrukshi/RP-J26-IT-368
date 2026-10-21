import { useEffect, useState } from 'react'
import { useLocation } from 'react-router-dom'
import { Bell, Search, RefreshCw, Sun, Moon } from 'lucide-react'

/* Map route paths to page titles */
const PAGE_TITLES = {
  '/':                  { title: 'Dashboard',             sub: 'Tourism Intelligence Overview' },
  '/demand-analytics':  { title: 'Demand Analytics',      sub: 'Tourist flow trends and patterns' },
  '/forecast-drivers':  { title: 'Forecast Drivers',      sub: 'Feature importance & model inputs' },
  '/market-graph':      { title: 'Market Graph',          sub: 'Core research focus — spatio-temporal demand network' },
  '/demand-alerts':     { title: 'Demand Alerts',         sub: 'Anomaly detection & threshold alerts' },
  '/spatial-demand-map':{ title: 'Spatial Demand Map',    sub: 'Geo-visual demand distribution across Sri Lanka' },
  '/model-management':  { title: 'Model Management',      sub: 'STGNN-GRU model registry & evaluation' },
  '/data-sources':      { title: 'Data Sources & Upload', sub: 'Manage datasets and ingestion pipelines' },
  '/login':             { title: 'Login',                 sub: 'Admin authentication' },
  '/users':             { title: 'Users',                 sub: 'Platform user management' },
  '/emergencies':       { title: 'Emergencies',           sub: 'Active incident response' },
  '/routes':            { title: 'Routes',                sub: 'Tourism route management' },
  '/destinations':      { title: 'Destinations',          sub: 'Destination registry and metadata' },
  '/risk-zones':        { title: 'Risk Zones & Hazards',  sub: 'Hazard mapping and risk assessments' },
}

const THEME_STORAGE_KEY = 'ceylonpath_theme'

export default function TopBar() {
  const location = useLocation()
  const { title, sub } = PAGE_TITLES[location.pathname] || PAGE_TITLES['/']
  const [theme, setTheme] = useState(() => {
    const savedTheme = localStorage.getItem(THEME_STORAGE_KEY)
    return savedTheme === 'light' || savedTheme === 'dark' ? savedTheme : 'dark'
  })

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
    localStorage.setItem(THEME_STORAGE_KEY, theme)
  }, [theme])

  const toggleTheme = () => {
    setTheme(currentTheme => currentTheme === 'dark' ? 'light' : 'dark')
  }

  return (
    <header className="topbar">
      {/* Left: Breadcrumb + Title */}
      <div className="topbar-left">
        <div>
          <span className="topbar-breadcrumb">CeylonPath Admin &rsaquo; </span>
          <span className="topbar-title">{title}</span>
          {sub && (
            <div style={{ fontSize: '11.5px', color: 'var(--color-text-muted)', marginTop: '1px' }}>
              {sub}
            </div>
          )}
        </div>
      </div>

      {/* Right: Status + Actions */}
      <div className="topbar-right">
        {/* API Status Indicator */}
        <div className="status-chip" title="FastAPI backend at http://127.0.0.1:8000">
          <span className="status-dot" />
          API Online
        </div>

        <button
          className="topbar-btn"
          id="topbar-theme-btn"
          title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
          aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
          onClick={toggleTheme}
        >
          {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
        </button>

        {/* Search */}
        <button className="topbar-btn" id="topbar-search-btn" title="Search">
          <Search size={16} />
        </button>

        {/* Refresh */}
        <button className="topbar-btn" id="topbar-refresh-btn" title="Refresh data">
          <RefreshCw size={16} />
        </button>

        {/* Notifications */}
        <button className="topbar-btn" id="topbar-notifications-btn" title="Notifications">
          <Bell size={16} />
          <span className="dot" />
        </button>
      </div>
    </header>
  )
}
