import { Info } from 'lucide-react'

const drivers = [
  { name: 'Historical Arrivals (Lag 1)',  importance: 0.92, category: 'temporal',  direction: 'positive' },
  { name: 'Holiday Calendar Events',      importance: 0.84, category: 'event',     direction: 'positive' },
  { name: 'Flight Connectivity Index',    importance: 0.78, category: 'transport', direction: 'positive' },
  { name: 'Exchange Rate (USD/LKR)',       importance: 0.71, category: 'economic',  direction: 'negative' },
  { name: 'Rainfall Anomaly Index',        importance: 0.65, category: 'climate',   direction: 'negative' },
  { name: 'Hotel Occupancy Rate',          importance: 0.61, category: 'capacity',  direction: 'positive' },
  { name: 'Social Media Sentiment',        importance: 0.54, category: 'digital',   direction: 'positive' },
  { name: 'Regional GDP Growth',           importance: 0.48, category: 'economic',  direction: 'positive' },
  { name: 'Air Quality Index',             importance: 0.37, category: 'climate',   direction: 'negative' },
  { name: 'Competing Destination Price',   importance: 0.29, category: 'market',    direction: 'negative' },
]

const categoryColors = {
  temporal:  { bg: 'rgba(0,180,166,0.12)',    text: 'var(--color-teal-300)',   border: 'rgba(0,180,166,0.2)' },
  event:     { bg: 'rgba(212,168,67,0.12)',   text: 'var(--color-gold-400)',   border: 'rgba(212,168,67,0.2)' },
  transport: { bg: 'rgba(107,26,58,0.25)',    text: 'var(--color-burgundy-200)', border: 'rgba(107,26,58,0.4)' },
  economic:  { bg: 'rgba(239,68,68,0.1)',     text: '#f87171',                 border: 'rgba(239,68,68,0.2)' },
  climate:   { bg: 'rgba(96,165,250,0.1)',    text: '#93c5fd',                 border: 'rgba(96,165,250,0.2)' },
  capacity:  { bg: 'rgba(167,139,250,0.1)',   text: '#c4b5fd',                 border: 'rgba(167,139,250,0.2)' },
  digital:   { bg: 'rgba(52,211,153,0.1)',    text: '#6ee7b7',                 border: 'rgba(52,211,153,0.2)' },
  market:    { bg: 'rgba(251,191,36,0.1)',    text: '#fcd34d',                 border: 'rgba(251,191,36,0.2)' },
}

export default function ForecastDrivers() {
  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Forecast Drivers</h1>
          <span className="badge badge-teal">Feature Analysis</span>
        </div>
        <p className="page-desc">
          SHAP-based feature importance scores for the STGNN-GRU demand forecasting model.
          Understand what drives tourism demand predictions.
        </p>
      </div>

      {/* Summary cards */}
      <div className="grid-3 mb-6">
        {[
          { label: 'Total Features',      value: '10',   sub: 'In active model v2.1' },
          { label: 'Top Driver Score',    value: '0.92', sub: 'Historical Arrivals (Lag 1)' },
          { label: 'Negative Drivers',    value: '4',    sub: 'Reducing demand confidence' },
        ].map(({ label, value, sub }) => (
          <div key={label} className="stat-card">
            <span className="stat-label">{label}</span>
            <span className="stat-value">{value}</span>
            <span className="text-xs text-muted">{sub}</span>
          </div>
        ))}
      </div>

      {/* Feature Importance Chart */}
      <div className="card">
        <div className="section-header">
          <div>
            <div className="section-title">Feature Importance (SHAP Values)</div>
            <div className="section-subtitle">Sorted by absolute contribution to demand forecast</div>
          </div>
          <button style={{
            display: 'flex', alignItems: 'center', gap: '6px',
            background: 'transparent', border: 'none',
            color: 'var(--color-text-muted)', fontSize: '12px', cursor: 'pointer',
          }} id="forecast-drivers-info-btn">
            <Info size={13} /> Model Details
          </button>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {drivers.map(({ name, importance, category, direction }, i) => {
            const colors = categoryColors[category]
            return (
              <div key={name} style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                <span style={{
                  minWidth: '22px', fontSize: '12px',
                  color: 'var(--color-text-muted)', textAlign: 'right',
                }}>
                  {i + 1}
                </span>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                    <span style={{ fontSize: '13.5px', color: 'var(--color-text-primary)' }}>{name}</span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{
                        fontSize: '11px', padding: '2px 8px', borderRadius: '99px',
                        background: colors.bg, color: colors.text, border: `1px solid ${colors.border}`,
                        fontWeight: 600,
                      }}>
                        {category}
                      </span>
                      <span style={{
                        fontSize: '13px', fontWeight: 700,
                        color: direction === 'positive' ? 'var(--color-teal-400)' : '#f87171',
                      }}>
                        {importance.toFixed(2)}
                      </span>
                    </div>
                  </div>
                  <div style={{
                    height: '6px', background: 'var(--color-bg-elevated)',
                    borderRadius: '99px', overflow: 'hidden',
                  }}>
                    <div style={{
                      height: '100%',
                      width: `${importance * 100}%`,
                      background: direction === 'positive'
                        ? 'linear-gradient(90deg, var(--color-teal-500), var(--color-teal-300))'
                        : 'linear-gradient(90deg, #dc2626, #f87171)',
                      borderRadius: '99px',
                      transition: 'width 0.7s ease',
                    }} />
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
