import { TrendingUp, Filter, Download, Calendar } from 'lucide-react'

const markets = [
  { country: 'India',         arrivals: 48200, yoy: '+12.4%', up: true,  share: '33.8%' },
  { country: 'China',         arrivals: 22100, yoy: '+5.1%',  up: true,  share: '15.5%' },
  { country: 'United Kingdom',arrivals: 18400, yoy: '-2.3%',  up: false, share: '12.9%' },
  { country: 'Germany',       arrivals: 12800, yoy: '+7.8%',  up: true,  share: '9.0%'  },
  { country: 'Australia',     arrivals: 10500, yoy: '+3.2%',  up: true,  share: '7.4%'  },
  { country: 'France',        arrivals: 9300,  yoy: '-1.1%',  up: false, share: '6.5%'  },
  { country: 'USA',           arrivals: 8900,  yoy: '+9.7%',  up: true,  share: '6.2%'  },
  { country: 'Others',        arrivals: 12630, yoy: '+4.4%',  up: true,  share: '8.7%'  },
]

export default function DemandAnalytics() {
  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Demand Analytics</h1>
          <span className="badge badge-gold">Tourism Demand</span>
        </div>
        <p className="page-desc">
          Granular analysis of tourist arrivals, market segments, and seasonal demand
          patterns sourced from Sri Lanka Tourism Development Authority data.
        </p>
      </div>

      {/* Controls */}
      <div className="flex items-center gap-3 mb-6">
        <button className="topbar-btn" id="demand-analytics-filter-btn" title="Filter">
          <Filter size={15} />
        </button>
        <button className="topbar-btn" id="demand-analytics-calendar-btn" title="Date range">
          <Calendar size={15} />
        </button>
        <button className="topbar-btn" id="demand-analytics-export-btn" title="Export CSV">
          <Download size={15} />
        </button>
        <div style={{ marginLeft: 'auto', display: 'flex', gap: '8px' }}>
          {['1W', '1M', '3M', '6M', '1Y'].map(p => (
            <button key={p} id={`period-${p}`} style={{
              padding: '5px 12px',
              borderRadius: '99px',
              border: '1px solid var(--color-border)',
              background: p === '1M' ? 'rgba(107,26,58,0.35)' : 'transparent',
              color: p === '1M' ? 'var(--color-burgundy-200)' : 'var(--color-text-muted)',
              fontSize: '12px',
              cursor: 'pointer',
              transition: 'all 0.15s',
            }}>
              {p}
            </button>
          ))}
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid-4 mb-6">
        {[
          { label: 'Total Arrivals (1M)',  value: '142,830', delta: '+8.4%'  },
          { label: 'Avg Daily Arrivals',   value: '4,627',   delta: '+7.9%'  },
          { label: 'Peak Day Arrivals',    value: '7,210',   delta: '+15.2%' },
          { label: 'Departure Rate',       value: '98.3%',   delta: '+0.4%'  },
        ].map(({ label, value, delta }) => (
          <div key={label} className="stat-card">
            <span className="stat-label">{label}</span>
            <span className="stat-value">{value}</span>
            <span className="stat-delta up">{delta}</span>
          </div>
        ))}
      </div>

      {/* Market Share Table */}
      <div className="card">
        <div className="section-header">
          <div>
            <div className="section-title">Arrivals by Source Market</div>
            <div className="section-subtitle">Month-to-date by country of origin</div>
          </div>
          <span className="badge badge-burgundy">
            <TrendingUp size={10} /> Oct 2026
          </span>
        </div>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--color-border)' }}>
              {['Country', 'Arrivals', 'YoY Change', 'Market Share'].map(h => (
                <th key={h} style={{
                  textAlign: 'left',
                  padding: '10px 12px',
                  fontSize: '11px',
                  fontWeight: 600,
                  color: 'var(--color-text-muted)',
                  textTransform: 'uppercase',
                  letterSpacing: '0.6px',
                }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {markets.map(({ country, arrivals, yoy, up, share }) => (
              <tr key={country} style={{
                borderBottom: '1px solid var(--color-border)',
                transition: 'background 0.15s',
              }}
                onMouseEnter={e => e.currentTarget.style.background = 'rgba(107,26,58,0.08)'}
                onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
              >
                <td style={{ padding: '12px', fontSize: '13.5px', color: 'var(--color-text-primary)' }}>
                  {country}
                </td>
                <td style={{ padding: '12px', fontSize: '13.5px', color: 'var(--color-text-secondary)' }}>
                  {arrivals.toLocaleString()}
                </td>
                <td style={{ padding: '12px' }}>
                  <span className={`stat-delta ${up ? 'up' : 'down'}`}>{yoy}</span>
                </td>
                <td style={{ padding: '12px', width: '180px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{
                      flex: 1, height: '5px',
                      background: 'var(--color-bg-elevated)',
                      borderRadius: '99px', overflow: 'hidden',
                    }}>
                      <div style={{
                        height: '100%',
                        width: share,
                        background: 'linear-gradient(90deg, var(--color-burgundy-700), var(--color-burgundy-400))',
                        borderRadius: '99px',
                      }} />
                    </div>
                    <span style={{ fontSize: '12px', color: 'var(--color-text-muted)', minWidth: '36px' }}>{share}</span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
