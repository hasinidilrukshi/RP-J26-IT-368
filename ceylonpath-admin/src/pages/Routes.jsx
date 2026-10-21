import { Route, Plus, Clock, Users, MapPin, ChevronRight } from 'lucide-react'

const routes = [
  {
    id: 1, name: 'Cultural Triangle Circuit', code: 'LK-CT-01',
    start: 'Colombo', end: 'Sigiriya', waypoints: ['Kandy', 'Dambulla', 'Polonnaruwa'],
    distance: '312 km', duration: '3 days', type: 'Cultural', status: 'active', avgVisitors: 2840,
  },
  {
    id: 2, name: 'Southern Coast Explorer', code: 'LK-SC-02',
    start: 'Colombo', end: 'Tangalle', waypoints: ['Galle', 'Unawatuna', 'Mirissa'],
    distance: '198 km', duration: '2 days', type: 'Beach', status: 'active', avgVisitors: 2120,
  },
  {
    id: 3, name: 'Hill Country Heritage Trail', code: 'LK-HC-03',
    start: 'Kandy', end: 'Ella', waypoints: ['Nuwara Eliya', 'Horton Plains'],
    distance: '145 km', duration: '2 days', type: 'Nature', status: 'active', avgVisitors: 1680,
  },
  {
    id: 4, name: 'Northern Discovery Route', code: 'LK-NR-04',
    start: 'Colombo', end: 'Jaffna', waypoints: ['Anuradhapura', 'Vavuniya'],
    distance: '410 km', duration: '4 days', type: 'Historical', status: 'draft', avgVisitors: 540,
  },
  {
    id: 5, name: 'Wildlife Safari Circuit', code: 'LK-WS-05',
    start: 'Colombo', end: 'Arugam Bay', waypoints: ['Yala', 'Lahugala'],
    distance: '285 km', duration: '3 days', type: 'Wildlife', status: 'active', avgVisitors: 1940,
  },
]

const typeColors = {
  Cultural:   { bg: 'rgba(107,26,58,0.2)',  text: 'var(--color-burgundy-200)' },
  Beach:      { bg: 'rgba(0,180,166,0.1)',  text: 'var(--color-teal-300)'     },
  Nature:     { bg: 'rgba(52,211,153,0.1)', text: '#6ee7b7'                    },
  Historical: { bg: 'rgba(212,168,67,0.1)', text: 'var(--color-gold-400)'     },
  Wildlife:   { bg: 'rgba(96,165,250,0.1)', text: '#93c5fd'                    },
}

export default function Routes() {
  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Routes</h1>
          <span className="badge badge-gold">{routes.length} Routes</span>
        </div>
        <p className="page-desc">Manage tourism route definitions, waypoints, and visitor flow data.</p>
      </div>

      {/* Stats */}
      <div className="grid-4 mb-6">
        {[
          { label: 'Total Routes',  value: routes.length },
          { label: 'Active',        value: routes.filter(r => r.status === 'active').length, color: 'var(--color-teal-400)' },
          { label: 'Avg Visitors',  value: Math.round(routes.reduce((s, r) => s + r.avgVisitors, 0) / routes.length).toLocaleString() },
          { label: 'Route Types',   value: new Set(routes.map(r => r.type)).size },
        ].map(({ label, value, color }) => (
          <div key={label} className="stat-card">
            <span className="stat-label">{label}</span>
            <span className="stat-value" style={color ? { color } : {}}>{value}</span>
          </div>
        ))}
      </div>

      {/* Header Action */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '16px' }}>
        <button id="add-route-btn" style={{
          display: 'flex', alignItems: 'center', gap: '6px',
          padding: '9px 16px', borderRadius: 'var(--radius-md)',
          background: 'rgba(107,26,58,0.3)', border: '1px solid var(--color-border-hover)',
          color: 'var(--color-burgundy-200)', fontSize: '13px', cursor: 'pointer',
        }}>
          <Plus size={14} /> New Route
        </button>
      </div>

      {/* Route Cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {routes.map(({ id, name, start, end, waypoints, distance, duration, type, status, avgVisitors }) => {
          const tc = typeColors[type]
          return (
            <div key={id} id={`route-card-${id}`} className="card" style={{
              display: 'flex', alignItems: 'center', gap: '20px', flexWrap: 'wrap',
              cursor: 'pointer', transition: 'all 0.2s ease',
            }}
              onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--color-border-hover)'; e.currentTarget.style.transform = 'translateX(4px)' }}
              onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--color-border)'; e.currentTarget.style.transform = 'none' }}
            >
              {/* Icon */}
              <div style={{
                width: '42px', height: '42px', borderRadius: 'var(--radius-md)',
                background: tc.bg, display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
              }}>
                <Route size={20} color={tc.text} />
              </div>

              {/* Info */}
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                  <span style={{ fontSize: '15px', fontWeight: 700, color: 'var(--color-text-primary)' }}>{name}</span>
                  <span style={{ fontSize: '10px', padding: '2px 7px', borderRadius: '99px', background: tc.bg, color: tc.text, fontWeight: 600 }}>{type}</span>
                  <span style={{
                    fontSize: '10px', padding: '2px 7px', borderRadius: '99px', fontWeight: 600,
                    background: status === 'active' ? 'rgba(0,180,166,0.1)' : 'rgba(107,26,58,0.15)',
                    color: status === 'active' ? 'var(--color-teal-400)' : 'var(--color-text-muted)',
                  }}>{status}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: 'var(--color-text-muted)' }}>
                  <MapPin size={10} /> {start}
                  {waypoints.map((wp, i) => (
                    <span key={i}> → {wp}</span>
                  ))}
                  <span> → {end}</span>
                </div>
              </div>

              {/* Meta */}
              <div style={{ display: 'flex', gap: '24px', fontSize: '12.5px' }}>
                {[
                  { icon: MapPin, label: distance },
                  { icon: Clock, label: duration },
                  { icon: Users, label: `${avgVisitors.toLocaleString()}/mo` },
                ].map(({ icon: Icon, label }) => (
                  <div key={label} style={{ display: 'flex', alignItems: 'center', gap: '5px', color: 'var(--color-text-muted)' }}>
                    <Icon size={12} /> <span>{label}</span>
                  </div>
                ))}
              </div>

              <ChevronRight size={16} color="var(--color-text-muted)" />
            </div>
          )
        })}
      </div>
    </div>
  )
}
