import { Star, Plus, Search, Globe, Camera } from 'lucide-react'

const destinations = [
  { id: 1, name: 'Sigiriya Rock Fortress',  region: 'North Central', type: 'Heritage',  rating: 4.9, visitors: 12480, status: 'active',   img: '🏰' },
  { id: 2, name: 'Temple of the Sacred Tooth', region: 'Kandy',   type: 'Religious', rating: 4.8, visitors: 10920, status: 'active',   img: '🛕' },
  { id: 3, name: 'Mirissa Beach',           region: 'Southern',      type: 'Beach',    rating: 4.6, visitors: 9340,  status: 'active',   img: '🏖️' },
  { id: 4, name: 'Yala National Park',      region: 'Southern',      type: 'Wildlife', rating: 4.7, visitors: 8100,  status: 'active',   img: '🦁' },
  { id: 5, name: 'Ella Rock Trail',         region: 'Uva',           type: 'Nature',   rating: 4.5, visitors: 7450,  status: 'active',   img: '🌿' },
  { id: 6, name: 'Galle Fort',             region: 'Southern',      type: 'Heritage', rating: 4.8, visitors: 11200, status: 'active',   img: '🏯' },
  { id: 7, name: 'Jaffna Old Town',        region: 'Northern',      type: 'Cultural', rating: 4.3, visitors: 3200,  status: 'active',   img: '🏛️' },
  { id: 8, name: 'Horton Plains',          region: 'Central',       type: 'Nature',   rating: 4.4, visitors: 5800,  status: 'seasonal', img: '🌄' },
]

const typeColors = {
  Heritage:  '#a8296a', Religious: '#d4a843', Beach:   '#00b4a6',
  Wildlife:  '#60a5fa', Nature:    '#4ade80', Cultural: '#c084fc',
  seasonal:  '#f87171',
}

export default function Destinations() {
  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Destinations</h1>
          <span className="badge badge-burgundy">{destinations.length} Listed</span>
        </div>
        <p className="page-desc">Registry of tourist destinations, metadata, and visitor statistics.</p>
      </div>

      {/* Stats */}
      <div className="grid-4 mb-6">
        {[
          { label: 'Total Destinations', value: destinations.length },
          { label: 'Avg Rating',         value: (destinations.reduce((s, d) => s + d.rating, 0) / destinations.length).toFixed(1) },
          { label: 'Monthly Visitors',   value: destinations.reduce((s, d) => s + d.visitors, 0).toLocaleString() },
          { label: 'Destination Types',  value: new Set(destinations.map(d => d.type)).size },
        ].map(({ label, value }) => (
          <div key={label} className="stat-card">
            <span className="stat-label">{label}</span>
            <span className="stat-value">{value}</span>
          </div>
        ))}
      </div>

      {/* Controls */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px' }}>
        <div style={{ position: 'relative', flex: 1, maxWidth: '280px' }}>
          <Search size={13} style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
          <input id="destination-search" placeholder="Search destinations…" style={{
            width: '100%', paddingLeft: '32px', padding: '9px 12px 9px 32px',
            background: 'var(--color-bg-card)', border: '1px solid var(--color-border)',
            borderRadius: 'var(--radius-md)', color: 'var(--color-text-primary)',
            fontSize: '12.5px', outline: 'none',
          }} />
        </div>
        <div style={{ marginLeft: 'auto' }}>
          <button id="add-destination-btn" style={{
            display: 'flex', alignItems: 'center', gap: '6px',
            padding: '9px 16px', borderRadius: 'var(--radius-md)',
            background: 'rgba(107,26,58,0.3)', border: '1px solid var(--color-border-hover)',
            color: 'var(--color-burgundy-200)', fontSize: '13px', cursor: 'pointer',
          }}>
            <Plus size={14} /> Add Destination
          </button>
        </div>
      </div>

      {/* Destination Grid */}
      <div className="grid-3">
        {destinations.map(({ id, name, region, type, rating, visitors, img }) => (
          <div key={id} id={`dest-card-${id}`} style={{
            background: 'var(--color-bg-card)', border: '1px solid var(--color-border)',
            borderRadius: 'var(--radius-lg)', overflow: 'hidden',
            transition: 'all 0.25s ease', cursor: 'pointer',
          }}
            onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-4px)'; e.currentTarget.style.boxShadow = 'var(--shadow-card)'; e.currentTarget.style.borderColor = 'var(--color-border-hover)' }}
            onMouseLeave={e => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = 'none'; e.currentTarget.style.borderColor = 'var(--color-border)' }}
          >
            {/* Header */}
            <div style={{
              height: '80px', display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: `linear-gradient(135deg, ${typeColors[type]}22, ${typeColors[type]}08)`,
              borderBottom: '1px solid var(--color-border)', fontSize: '36px',
            }}>
              {img}
            </div>

            {/* Body */}
            <div style={{ padding: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '8px' }}>
                <div>
                  <div style={{ fontSize: '14px', fontWeight: 700, color: 'var(--color-text-primary)', marginBottom: '3px' }}>{name}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '5px', fontSize: '11.5px', color: 'var(--color-text-muted)' }}>
                    <Globe size={10} /> {region}
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '3px', fontSize: '12px', fontWeight: 600, color: 'var(--color-gold-400)' }}>
                  <Star size={12} fill="var(--color-gold-400)" /> {rating}
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span style={{
                  fontSize: '11px', padding: '3px 9px', borderRadius: '99px', fontWeight: 600,
                  background: `${typeColors[type]}18`, color: typeColors[type],
                }}>
                  {type}
                </span>
                <span style={{ fontSize: '12px', color: 'var(--color-text-muted)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Camera size={11} /> {visitors.toLocaleString()}/mo
                </span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
