import { ShieldAlert, MapPin, TrendingUp, Eye, Plus } from 'lucide-react'

const riskZones = [
  {
    id: 1, name: 'Colombo Coastal Strip',     region: 'Western',
    type: 'Flood Risk', risk: 'high',  area: '42 km²',
    affected_routes: ['LK-SC-02'],  population_at_risk: 18400,
    last_incident: '2026-09-12', trend: 'increasing',
    description: 'Recurring flash flood zone during NE monsoon. Sea-level rise exacerbating risk.',
  },
  {
    id: 2, name: 'Ella Escarpment Trail',     region: 'Uva',
    type: 'Landslide Risk', risk: 'high', area: '18 km²',
    affected_routes: ['LK-HC-03'],  population_at_risk: 2200,
    last_incident: '2026-08-28', trend: 'stable',
    description: 'Steep terrain with unstable laterite soils. High risk during heavy rainfall events.',
  },
  {
    id: 3, name: 'Yala Wildlife Periphery',  region: 'Southern',
    type: 'Wildlife Encounter', risk: 'medium', area: '65 km²',
    affected_routes: ['LK-WS-05'],  population_at_risk: 600,
    last_incident: '2026-10-01', trend: 'stable',
    description: 'Elephant and leopard movement corridors overlapping with tourist access roads.',
  },
  {
    id: 4, name: 'Nuwara Eliya Frost Zone',  region: 'Central',
    type: 'Climate Hazard', risk: 'low', area: '28 km²',
    affected_routes: ['LK-HC-03'],  population_at_risk: 800,
    last_incident: '2026-07-15', trend: 'decreasing',
    description: 'Seasonal frost hazard affecting road access to highland tea estates.',
  },
  {
    id: 5, name: 'Jaffna Lagoon Ferry Zone', region: 'Northern',
    type: 'Maritime Risk', risk: 'medium', area: '12 km²',
    affected_routes: ['LK-NR-04'],  population_at_risk: 1100,
    last_incident: '2026-06-20', trend: 'stable',
    description: 'Rough sea conditions during inter-monsoon periods affecting ferry operations.',
  },
]

const riskConfig = {
  high:   { bg: 'rgba(239,68,68,0.1)',    text: '#f87171',                    border: 'rgba(239,68,68,0.25)'    },
  medium: { bg: 'rgba(212,168,67,0.1)',   text: 'var(--color-gold-400)',      border: 'rgba(212,168,67,0.25)'   },
  low:    { bg: 'rgba(0,180,166,0.08)',   text: 'var(--color-teal-400)',      border: 'rgba(0,180,166,0.2)'     },
}

const trendIcon = {
  increasing: '↑',
  stable:     '→',
  decreasing: '↓',
}
const trendColor = {
  increasing: '#f87171',
  stable:     'var(--color-text-muted)',
  decreasing: 'var(--color-teal-400)',
}

export default function RiskZones() {
  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Risk Zones & Hazards</h1>
          <span className="badge badge-danger">2 High Risk</span>
        </div>
        <p className="page-desc">
          Hazard zone registry with risk assessments, affected routes, and trend monitoring
          for safe tourism management across Sri Lanka.
        </p>
      </div>

      {/* Stats */}
      <div className="grid-4 mb-6">
        {[
          { label: 'Total Risk Zones',    value: riskZones.length },
          { label: 'High Risk',           value: riskZones.filter(r => r.risk === 'high').length,   color: '#f87171' },
          { label: 'Medium Risk',         value: riskZones.filter(r => r.risk === 'medium').length, color: 'var(--color-gold-400)' },
          { label: 'Population at Risk',  value: riskZones.reduce((s, r) => s + r.population_at_risk, 0).toLocaleString() },
        ].map(({ label, value, color }) => (
          <div key={label} className="stat-card">
            <span className="stat-label">{label}</span>
            <span className="stat-value" style={color ? { color } : {}}>{value}</span>
          </div>
        ))}
      </div>

      {/* Header Action */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '16px' }}>
        <button id="add-riskzone-btn" style={{
          display: 'flex', alignItems: 'center', gap: '6px',
          padding: '9px 16px', borderRadius: 'var(--radius-md)',
          background: 'rgba(239,68,68,0.12)', border: '1px solid rgba(239,68,68,0.25)',
          color: '#f87171', fontSize: '13px', cursor: 'pointer',
        }}>
          <Plus size={14} /> Add Zone
        </button>
      </div>

      {/* Risk Zone Cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {riskZones.map(({ id, name, region, type, risk, area, affected_routes, population_at_risk, last_incident, trend, description }) => {
          const cfg = riskConfig[risk]
          return (
            <div key={id} id={`riskzone-${id}`} style={{
              background: 'var(--color-bg-card)',
              border: `1px solid ${cfg.border}`,
              borderRadius: 'var(--radius-lg)', padding: '20px 24px',
              transition: 'all 0.2s ease',
            }}
              onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-2px)'}
              onMouseLeave={e => e.currentTarget.style.transform = 'none'}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px', flexWrap: 'wrap' }}>
                <div style={{ flex: 1 }}>
                  {/* Title Row */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
                    <ShieldAlert size={17} color={cfg.text} />
                    <span style={{ fontSize: '15px', fontWeight: 700, color: 'var(--color-text-primary)' }}>{name}</span>
                    <span style={{
                      fontSize: '10px', padding: '2px 8px', borderRadius: '99px', fontWeight: 600,
                      background: cfg.bg, color: cfg.text, border: `1px solid ${cfg.border}`,
                      textTransform: 'capitalize',
                    }}>{risk} risk</span>
                    <span style={{
                      fontSize: '13px', fontWeight: 700, color: trendColor[trend],
                    }} title={`Trend: ${trend}`}>
                      {trendIcon[trend]}
                    </span>
                  </div>

                  {/* Meta Row */}
                  <div style={{ display: 'flex', gap: '16px', fontSize: '12px', color: 'var(--color-text-muted)', marginBottom: '10px', flexWrap: 'wrap' }}>
                    <span><MapPin size={10} style={{ display: 'inline' }} /> {region}</span>
                    <span>Type: <span style={{ color: 'var(--color-text-secondary)' }}>{type}</span></span>
                    <span>Area: <span style={{ color: 'var(--color-text-secondary)' }}>{area}</span></span>
                    <span>Last Incident: <span style={{ color: 'var(--color-text-secondary)' }}>{last_incident}</span></span>
                  </div>

                  {/* Description */}
                  <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', lineHeight: 1.6, marginBottom: '12px', maxWidth: '600px' }}>
                    {description}
                  </p>

                  {/* Affected routes */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px' }}>
                    <span style={{ color: 'var(--color-text-muted)' }}>Affected Routes:</span>
                    {affected_routes.map(r => (
                      <span key={r} className="badge badge-gold" style={{ fontSize: '10px' }}>{r}</span>
                    ))}
                    <span style={{ color: 'var(--color-text-muted)', marginLeft: '12px' }}>
                      Pop. at risk: <span style={{ color: cfg.text, fontWeight: 600 }}>
                        {population_at_risk.toLocaleString()}
                      </span>
                    </span>
                  </div>
                </div>

                {/* Actions */}
                <div style={{ display: 'flex', gap: '8px' }}>
                  <button id={`riskzone-view-${id}`} style={{
                    display: 'flex', alignItems: 'center', gap: '5px',
                    padding: '7px 12px', borderRadius: 'var(--radius-md)',
                    background: 'transparent', border: '1px solid var(--color-border)',
                    color: 'var(--color-text-muted)', fontSize: '12px', cursor: 'pointer',
                  }}>
                    <Eye size={12} /> View Map
                  </button>
                  <button id={`riskzone-trend-${id}`} style={{
                    display: 'flex', alignItems: 'center', gap: '5px',
                    padding: '7px 12px', borderRadius: 'var(--radius-md)',
                    background: 'rgba(107,26,58,0.2)', border: '1px solid var(--color-border-hover)',
                    color: 'var(--color-burgundy-200)', fontSize: '12px', cursor: 'pointer',
                  }}>
                    <TrendingUp size={12} /> Trend
                  </button>
                </div>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
