import { useState } from 'react'
import { NavLink, useLocation } from 'react-router-dom'
import {
  LayoutDashboard,
  TrendingUp,
  SlidersHorizontal,
  Network,
  Bell,
  Map,
  BrainCircuit,
  Database,
  LogIn,
  Users,
  AlertTriangle,
  Route,
  MapPin,
  ShieldAlert,
  ChevronLeft,
  ChevronRight,
  Compass,
} from 'lucide-react'

/* ─── Navigation Structure ──────────────────────────────────────────────── */
const PRIMARY_NAV = [
  { path: '/',                  label: 'Dashboard',          icon: LayoutDashboard },
  { path: '/demand-analytics',  label: 'Demand Analytics',   icon: TrendingUp },
  { path: '/forecast-drivers',  label: 'Forecast Drivers',   icon: SlidersHorizontal },
  {
    path: '/market-graph',
    label: 'Market Graph',
    icon: Network,
    badge: { text: 'Core', type: 'info' },
  },
  {
    path: '/demand-alerts',
    label: 'Demand Alerts',
    icon: Bell,
    badge: { text: '3', type: 'danger' },
  },
  { path: '/spatial-demand-map', label: 'Spatial Demand Map', icon: Map },
  { path: '/model-management',  label: 'Model Management',   icon: BrainCircuit },
  { path: '/data-sources',      label: 'Data Sources & Upload', icon: Database },
  { path: '/login',             label: 'Login',              icon: LogIn },
]

const SHARED_NAV = [
  { path: '/users',             label: 'Users',              icon: Users },
  {
    path: '/emergencies',
    label: 'Emergencies',
    icon: AlertTriangle,
    badge: { text: '1', type: 'danger' },
  },
  { path: '/routes',            label: 'Routes',             icon: Route },
  { path: '/destinations',      label: 'Destinations',       icon: MapPin },
  { path: '/risk-zones',        label: 'Risk Zones & Hazards', icon: ShieldAlert },
]

/* ─── Sidebar Component ─────────────────────────────────────────────────── */
export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false)
  const location = useLocation()

  return (
    <aside className={`sidebar ${collapsed ? 'collapsed' : ''}`}>
      {/* Brand Header */}
      <div className="sidebar-header">
        <div className="brand-logo">
          <Compass size={20} color="#e9a0be" />
        </div>
        <div className="brand-text">
          <div className="brand-name">CeylonPath</div>
          <div className="brand-sub">Tourism Intelligence</div>
        </div>

        {/* Collapse Toggle */}
        <button
          className="collapse-btn"
          onClick={() => setCollapsed(!collapsed)}
          title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          id="sidebar-collapse-btn"
        >
          {collapsed
            ? <ChevronRight size={13} />
            : <ChevronLeft size={13} />
          }
        </button>
      </div>

      {/* Navigation */}
      <nav className="sidebar-nav">
        {/* Primary Research Section */}
        <div className="nav-section-label">Research &amp; Analytics</div>

        {PRIMARY_NAV.map(({ path, label, icon: Icon, badge }) => (
          <NavItem
            key={path}
            path={path}
            label={label}
            Icon={Icon}
            badge={badge}
            collapsed={collapsed}
            isActive={
              path === '/'
                ? location.pathname === '/'
                : location.pathname.startsWith(path)
            }
          />
        ))}

        {/* Divider */}
        <div className="nav-divider" />

        {/* Shared Platform Section */}
        <div className="nav-section-label">Platform Modules</div>

        {SHARED_NAV.map(({ path, label, icon: Icon, badge }) => (
          <NavItem
            key={path}
            path={path}
            label={label}
            Icon={Icon}
            badge={badge}
            collapsed={collapsed}
            isActive={location.pathname.startsWith(path)}
          />
        ))}
      </nav>

      {/* Footer / User */}
      <div className="sidebar-footer">
        <div className="user-profile" id="user-profile-btn">
          <div className="user-avatar">A</div>
          <div className="user-info">
            <div className="user-name">Admin User</div>
            <div className="user-role">Research Lead</div>
          </div>
        </div>
      </div>
    </aside>
  )
}

/* ─── Individual Nav Item ───────────────────────────────────────────────── */
function NavItem({ path, label, Icon, badge, collapsed, isActive }) {
  return (
    <NavLink
      to={path}
      id={`nav-${path.replace(/\//g, '') || 'dashboard'}`}
      className={`nav-item ${isActive ? 'active' : ''}`}
      title={collapsed ? label : undefined}
    >
      <Icon className="nav-icon" size={18} />
      <span className="nav-label">{label}</span>
      {badge && !collapsed && (
        <span className={`nav-badge ${badge.type}`}>{badge.text}</span>
      )}
    </NavLink>
  )
}
