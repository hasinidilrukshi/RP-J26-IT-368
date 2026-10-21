import { BrainCircuit, Play, Download, Upload, BarChart3, CheckCircle, Clock } from 'lucide-react'

const models = [
  {
    id: 'stgnn-v21', name: 'STGNN-GRU v2.1', status: 'active',
    accuracy: 91.2, mae: 142, rmse: 201, trained: '2026-10-10',
    nodes: 12, horizons: '7-day', size: '150 KB',
    description: 'Spatio-temporal graph neural network with GRU units. Primary production model.',
  },
  {
    id: 'stgnn-v20', name: 'STGNN-GRU v2.0', status: 'archived',
    accuracy: 88.7, mae: 178, rmse: 238, trained: '2026-08-15',
    nodes: 10, horizons: '7-day', size: '148 KB',
    description: 'Previous production model. Archived after v2.1 validation passed.',
  },
  {
    id: 'baseline-arima', name: 'ARIMA Baseline', status: 'benchmark',
    accuracy: 74.3, mae: 320, rmse: 445, trained: '2026-06-01',
    nodes: 1, horizons: '14-day', size: '12 KB',
    description: 'Classical ARIMA baseline for benchmarking STGNN improvements.',
  },
]

const statusConfig = {
  active:    { bg: 'rgba(0,180,166,0.12)',  text: 'var(--color-teal-400)',   border: 'rgba(0,180,166,0.2)',  icon: CheckCircle },
  archived:  { bg: 'rgba(107,26,58,0.2)',   text: 'var(--color-burgundy-300)', border: 'rgba(107,26,58,0.3)', icon: Clock },
  benchmark: { bg: 'rgba(212,168,67,0.1)',  text: 'var(--color-gold-400)',   border: 'rgba(212,168,67,0.2)', icon: BarChart3 },
}

export default function ModelManagement() {
  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Model Management</h1>
          <span className="badge badge-teal">STGNN-GRU Registry</span>
        </div>
        <p className="page-desc">
          Manage, evaluate, and deploy STGNN-GRU forecasting model versions.
          Monitor performance metrics and control active deployment.
        </p>
      </div>

      {/* Quick Actions */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '24px', flexWrap: 'wrap' }}>
        {[
          { label: 'Run Evaluation', icon: Play,    id: 'model-run-eval'    },
          { label: 'Export Model',   icon: Download, id: 'model-export'      },
          { label: 'Upload Model',   icon: Upload,   id: 'model-upload'      },
        ].map(({ label, icon: Icon, id }) => (
          <button key={id} id={id} style={{
            display: 'flex', alignItems: 'center', gap: '8px',
            padding: '10px 18px', borderRadius: 'var(--radius-md)',
            background: 'var(--color-bg-card)', border: '1px solid var(--color-border)',
            color: 'var(--color-text-secondary)', fontSize: '13.5px', cursor: 'pointer',
            transition: 'all 0.2s ease',
          }}
            onMouseEnter={e => {
              e.currentTarget.style.background = 'rgba(107,26,58,0.25)'
              e.currentTarget.style.borderColor = 'var(--color-border-hover)'
              e.currentTarget.style.color = 'var(--color-text-primary)'
            }}
            onMouseLeave={e => {
              e.currentTarget.style.background = 'var(--color-bg-card)'
              e.currentTarget.style.borderColor = 'var(--color-border)'
              e.currentTarget.style.color = 'var(--color-text-secondary)'
            }}
          >
            <Icon size={15} /> {label}
          </button>
        ))}
      </div>

      {/* Model Cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {models.map(({ id, name, status, accuracy, mae, rmse, trained, nodes, horizons, size, description }) => {
          const cfg = statusConfig[status]
          const Icon = cfg.icon
          return (
            <div key={id} id={`model-card-${id}`} style={{
              background: 'var(--color-bg-card)',
              border: `1px solid ${status === 'active' ? 'rgba(0,180,166,0.25)' : 'var(--color-border)'}`,
              borderRadius: 'var(--radius-lg)',
              padding: '24px',
              transition: 'all 0.2s ease',
            }}
              onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-2px)'}
              onMouseLeave={e => e.currentTarget.style.transform = 'none'}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px', flexWrap: 'wrap' }}>
                {/* Left: Name + Meta */}
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
                    <BrainCircuit size={18} color={cfg.text} />
                    <span style={{ fontSize: '16px', fontWeight: 700, color: 'var(--color-text-primary)' }}>{name}</span>
                    <span style={{
                      fontSize: '11px', padding: '3px 10px', borderRadius: '99px',
                      background: cfg.bg, color: cfg.text, border: `1px solid ${cfg.border}`,
                      fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px',
                    }}>
                      <Icon size={10} /> {status}
                    </span>
                  </div>
                  <p style={{ fontSize: '13px', color: 'var(--color-text-muted)', marginBottom: '16px', maxWidth: '500px' }}>
                    {description}
                  </p>
                  {/* Meta */}
                  <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap', fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    {[
                      ['Trained', trained],
                      ['Nodes',   nodes],
                      ['Horizon', horizons],
                      ['Size',    size],
                    ].map(([k, v]) => (
                      <span key={k}>
                        {k}: <span style={{ color: 'var(--color-text-secondary)', fontWeight: 500 }}>{v}</span>
                      </span>
                    ))}
                  </div>
                </div>

                {/* Right: Metrics */}
                <div style={{ display: 'flex', gap: '20px' }}>
                  {[
                    { label: 'Accuracy', value: `${accuracy}%`, color: accuracy > 85 ? 'var(--color-teal-400)' : accuracy > 75 ? 'var(--color-gold-400)' : '#f87171' },
                    { label: 'MAE',      value: mae,             color: 'var(--color-text-primary)' },
                    { label: 'RMSE',     value: rmse,            color: 'var(--color-text-primary)' },
                  ].map(({ label, value, color }) => (
                    <div key={label} style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: '20px', fontWeight: 700, color, fontFamily: 'var(--font-display)' }}>{value}</div>
                      <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.6px' }}>{label}</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Accuracy bar */}
              <div style={{ marginTop: '16px' }}>
                <div style={{ height: '4px', background: 'var(--color-bg-elevated)', borderRadius: '99px', overflow: 'hidden' }}>
                  <div style={{
                    height: '100%', width: `${accuracy}%`,
                    background: `linear-gradient(90deg, ${accuracy > 85 ? 'var(--color-teal-500)' : 'var(--color-gold-500)'}, ${accuracy > 85 ? 'var(--color-teal-300)' : 'var(--color-gold-300)'})`,
                    borderRadius: '99px',
                  }} />
                </div>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
