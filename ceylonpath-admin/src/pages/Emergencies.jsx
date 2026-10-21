import { Radio, CheckCircle, Clock, MapPin, Phone } from 'lucide-react'

const emergencies = [
  {
    id: 1, title: 'Flash Flood Warning',   region: 'Kelani River Basin',
    type: 'Natural Disaster', severity: 'critical', status: 'active',
    reported: '2026-10-17 07:15', responder: 'NDRRMC Unit 3',
    affected: 1240, coords: '6.9271°N, 79.8612°E',
  },
  {
    id: 2, title: 'Road Blockage',         region: 'Kandy-Colombo Highway',
    type: 'Infrastructure', severity: 'high', status: 'active',
    reported: '2026-10-17 09:00', responder: 'Road Dev Authority',
    affected: 320, coords: '7.2906°N, 80.6337°E',
  },
  {
    id: 3, title: 'Medical Emergency Cluster', region: 'Galle Fort Area',
    type: 'Public Health', severity: 'medium', status: 'monitoring',
    reported: '2026-10-16 14:30', responder: 'MOH Galle',
    affected: 45, coords: '6.0535°N, 80.2210°E',
  },
  {
    id: 4, title: 'Wildlife Encroachment', region: 'Yala Buffer Zone',
    type: 'Safety', severity: 'low', status: 'resolved',
    reported: '2026-10-15 11:20', responder: 'Dept. of Wildlife',
    affected: 0, coords: '6.4142°N, 81.3189°E',
  },
]

const sevColor = {
  critical: '#f87171',
  high:     '#fb923c',
  medium:   'var(--color-gold-400)',
  low:      'var(--color-teal-400)',
}

export default function Emergencies() {
  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Emergencies</h1>
          <span className="badge badge-danger">1 Critical</span>
        </div>
        <p className="page-desc">
          Active incident response management for tourism-related emergencies across Sri Lanka.
        </p>
      </div>

      {/* Stats */}
      <div className="grid-4 mb-6">
        {[
          { label: 'Total Incidents',  value: emergencies.length },
          { label: 'Active',           value: emergencies.filter(e => e.status === 'active').length,    color: '#f87171' },
          { label: 'Monitoring',       value: emergencies.filter(e => e.status === 'monitoring').length, color: 'var(--color-gold-400)' },
          { label: 'People Affected',  value: emergencies.reduce((s, e) => s + e.affected, 0).toLocaleString() },
        ].map(({ label, value, color }) => (
          <div key={label} className="stat-card">
            <span className="stat-label">{label}</span>
            <span className="stat-value" style={color ? { color } : {}}>{value}</span>
          </div>
        ))}
      </div>

      {/* Emergency Cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {emergencies.map(({ id, title, region, type, severity, status, reported, responder, affected, coords }) => (
          <div key={id} id={`emergency-${id}`} style={{
            background: 'var(--color-bg-card)', borderRadius: 'var(--radius-lg)',
            border: `1px solid ${status === 'active' ? `${sevColor[severity]}44` : 'var(--color-border)'}`,
            padding: '20px 24px', transition: 'all 0.2s ease',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px', flexWrap: 'wrap' }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
                  {status === 'active'
                    ? <Radio size={16} color={sevColor[severity]} />
                    : status === 'monitoring'
                    ? <Clock size={16} color="var(--color-gold-400)" />
                    : <CheckCircle size={16} color="var(--color-teal-400)" />
                  }
                  <span style={{ fontSize: '15px', fontWeight: 700, color: 'var(--color-text-primary)' }}>{title}</span>
                  <span style={{
                    fontSize: '10px', padding: '2px 8px', borderRadius: '99px',
                    background: `${sevColor[severity]}18`, color: sevColor[severity],
                    border: `1px solid ${sevColor[severity]}33`, fontWeight: 600,
                    textTransform: 'capitalize',
                  }}>{severity}</span>
                </div>
                <div style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginBottom: '10px' }}>
                  <MapPin size={11} style={{ display: 'inline', marginRight: '4px' }} />{region} · {type} · {reported}
                </div>
                <div style={{ display: 'flex', gap: '20px', fontSize: '12.5px', flexWrap: 'wrap' }}>
                  <span style={{ color: 'var(--color-text-muted)' }}>
                    Responder: <span style={{ color: 'var(--color-text-secondary)', fontWeight: 500 }}>{responder}</span>
                  </span>
                  <span style={{ color: 'var(--color-text-muted)' }}>
                    Affected: <span style={{ color: sevColor[severity], fontWeight: 600 }}>{affected}</span>
                  </span>
                  <span style={{ color: 'var(--color-text-muted)' }}>
                    Coords: <span style={{ color: 'var(--color-text-secondary)' }}>{coords}</span>
                  </span>
                </div>
              </div>
              <div style={{ display: 'flex', gap: '8px' }}>
                <button id={`emergency-call-${id}`} style={{
                  display: 'flex', alignItems: 'center', gap: '5px',
                  padding: '7px 12px', borderRadius: 'var(--radius-md)',
                  background: 'transparent', border: '1px solid var(--color-border)',
                  color: 'var(--color-text-muted)', fontSize: '12px', cursor: 'pointer',
                }}>
                  <Phone size={12} /> Contact
                </button>
                <button id={`emergency-resolve-${id}`} style={{
                  padding: '7px 12px', borderRadius: 'var(--radius-md)',
                  background: status === 'resolved' ? 'rgba(0,180,166,0.1)' : 'rgba(107,26,58,0.25)',
                  border: `1px solid ${status === 'resolved' ? 'rgba(0,180,166,0.2)' : 'var(--color-border-hover)'}`,
                  color: status === 'resolved' ? 'var(--color-teal-400)' : 'var(--color-burgundy-200)',
                  fontSize: '12px', cursor: 'pointer',
                }}>
                  {status === 'resolved' ? 'Resolved' : 'Resolve'}
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
