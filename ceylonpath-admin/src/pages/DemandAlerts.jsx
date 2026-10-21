import { CheckCircle, Clock, AlertTriangle, XCircle, ChevronRight } from 'lucide-react'
import { useState } from 'react'

const alerts = [
  {
    id: 1, title: 'Demand Surge Detected',
    region: 'Colombo Metro Area', type: 'Demand Surge',
    severity: 'critical', status: 'active',
    time: '2026-10-17 08:12', message:
      'Arrivals 38% above forecast threshold. Model confidence: 94.2%. Immediate capacity review recommended.',
    model: 'STGNN-GRU v2.1', driver: 'Holiday surge + flight influx',
  },
  {
    id: 2, title: 'Capacity Threshold Breach',
    region: 'Galle Fort Heritage Zone', type: 'Capacity Threshold',
    severity: 'high', status: 'active',
    time: '2026-10-17 05:45', message:
      'Footfall at 92% of maximum safe capacity. Heritage site risk alert triggered.',
    model: 'STGNN-GRU v2.1', driver: 'Weekend overflow + tour buses',
  },
  {
    id: 3, title: 'Weather Risk Warning',
    region: 'Ella Mountain Trail', type: 'Climate Risk',
    severity: 'medium', status: 'active',
    time: '2026-10-16 19:30', message:
      'Monsoon rainfall index 2.3σ above baseline. Trail accessibility may be impacted.',
    model: 'Climate Overlay v1.0', driver: 'Rainfall anomaly',
  },
  {
    id: 4, title: 'Low Season Demand Drop',
    region: 'Jaffna Peninsula', type: 'Demand Drop',
    severity: 'low', status: 'resolved',
    time: '2026-10-15 14:20', message:
      'Arrivals 22% below seasonal forecast. Resolved: regional promotion campaign activated.',
    model: 'STGNN-GRU v2.1', driver: 'Low season + event gap',
  },
]

const severityConfig = {
  critical: { label: 'Critical', bg: 'rgba(239,68,68,0.12)',   border: 'rgba(239,68,68,0.3)',   text: '#f87171',                     icon: XCircle },
  high:     { label: 'High',     bg: 'rgba(251,146,60,0.1)',   border: 'rgba(251,146,60,0.3)',  text: '#fb923c',                     icon: AlertTriangle },
  medium:   { label: 'Medium',   bg: 'rgba(212,168,67,0.1)',   border: 'rgba(212,168,67,0.25)', text: 'var(--color-gold-400)',        icon: Clock },
  low:      { label: 'Low',      bg: 'rgba(0,180,166,0.08)',   border: 'rgba(0,180,166,0.2)',   text: 'var(--color-teal-400)',        icon: CheckCircle },
}

export default function DemandAlerts() {
  const [activeFilter, setActiveFilter] = useState('all')

  const filtered = alerts.filter(a =>
    activeFilter === 'all' ? true :
    activeFilter === 'active' ? a.status === 'active' :
    a.severity === activeFilter
  )

  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Demand Alerts</h1>
          <span className="badge badge-danger">3 Active</span>
        </div>
        <p className="page-desc">
          Automated anomaly detection from the STGNN-GRU forecasting pipeline.
          Alerts fire when actual or predicted demand deviates beyond configured thresholds.
        </p>
      </div>

      {/* Stats */}
      <div className="grid-4 mb-6">
        {[
          { label: 'Critical',  value: 1, color: '#f87171' },
          { label: 'High',      value: 1, color: '#fb923c' },
          { label: 'Medium',    value: 1, color: 'var(--color-gold-400)' },
          { label: 'Resolved',  value: 1, color: 'var(--color-teal-400)' },
        ].map(({ label, value, color }) => (
          <div key={label} className="stat-card">
            <span className="stat-label">{label} Alerts</span>
            <span className="stat-value" style={{ color }}>{value}</span>
          </div>
        ))}
      </div>

      {/* Filter Bar */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '20px', flexWrap: 'wrap' }}>
        {['all', 'active', 'critical', 'high', 'medium', 'low'].map(f => (
          <button key={f} id={`alert-filter-${f}`} onClick={() => setActiveFilter(f)} style={{
            padding: '6px 14px', borderRadius: '99px', fontSize: '12px', cursor: 'pointer',
            border: '1px solid',
            borderColor: activeFilter === f ? 'var(--color-burgundy-600)' : 'var(--color-border)',
            background: activeFilter === f ? 'rgba(107,26,58,0.3)' : 'transparent',
            color: activeFilter === f ? 'var(--color-burgundy-200)' : 'var(--color-text-muted)',
            fontWeight: activeFilter === f ? 600 : 400,
            transition: 'all 0.15s',
            textTransform: 'capitalize',
          }}>
            {f}
          </button>
        ))}
      </div>

      {/* Alert Cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {filtered.map(({ id, title, region, type, severity, status, time, message, model, driver }) => {
          const cfg = severityConfig[severity]
          const Icon = cfg.icon
          return (
            <div key={id} style={{
              background: cfg.bg,
              border: `1px solid ${cfg.border}`,
              borderRadius: 'var(--radius-lg)',
              padding: '20px 24px',
              position: 'relative',
              transition: 'transform 0.2s ease',
              cursor: 'pointer',
            }}
              onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-2px)'}
              onMouseLeave={e => e.currentTarget.style.transform = 'translateY(0)'}
              id={`alert-card-${id}`}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px' }}>
                <div style={{ display: 'flex', gap: '14px', flex: 1 }}>
                  <Icon size={20} color={cfg.text} style={{ marginTop: '2px', flexShrink: 0 }} />
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                      <span style={{ fontSize: '15px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                        {title}
                      </span>
                      <span style={{
                        fontSize: '10px', padding: '2px 7px', borderRadius: '99px',
                        background: status === 'active' ? 'rgba(239,68,68,0.15)' : 'rgba(0,180,166,0.12)',
                        color: status === 'active' ? '#f87171' : 'var(--color-teal-400)',
                        border: `1px solid ${status === 'active' ? 'rgba(239,68,68,0.25)' : 'rgba(0,180,166,0.2)'}`,
                        fontWeight: 600,
                      }}>
                        {status}
                      </span>
                    </div>
                    <div style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginBottom: '8px' }}>
                      {region} · {type} · {time}
                    </div>
                    <p style={{ fontSize: '13.5px', color: 'var(--color-text-secondary)', lineHeight: 1.6 }}>
                      {message}
                    </p>
                    <div style={{ display: 'flex', gap: '12px', marginTop: '10px', fontSize: '11.5px' }}>
                      <span style={{ color: 'var(--color-text-muted)' }}>
                        🤖 <span style={{ color: 'var(--color-text-secondary)' }}>{model}</span>
                      </span>
                      <span style={{ color: 'var(--color-text-muted)' }}>
                        📌 <span style={{ color: 'var(--color-text-secondary)' }}>{driver}</span>
                      </span>
                    </div>
                  </div>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', alignItems: 'flex-end' }}>
                  <span className={`badge badge-${severity === 'critical' || severity === 'high' ? 'danger' : severity === 'medium' ? 'gold' : 'teal'}`}
                    style={{ color: cfg.text }}>
                    {cfg.label}
                  </span>
                  <button style={{
                    display: 'flex', alignItems: 'center', gap: '4px',
                    fontSize: '11.5px', color: 'var(--color-text-muted)',
                    background: 'transparent', border: 'none', cursor: 'pointer',
                  }} id={`alert-action-${id}`}>
                    View <ChevronRight size={12} />
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
