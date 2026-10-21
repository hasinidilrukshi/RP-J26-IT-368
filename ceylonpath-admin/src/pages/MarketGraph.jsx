import { Network, ZoomIn, ZoomOut, Maximize2, RefreshCw } from 'lucide-react'
import { useState } from 'react'

// ST-GNN Core Focus: Top 10 Tourist Source Markets (Origin Countries)
const nodes = [
  { id: 'india',     label: 'India',        x: 48,  y: 22,  size: 28, demand: 'high',   arrivals: '34,200', growth: '+14.2%' },
  { id: 'uk',        label: 'UK',           x: 30,  y: 42,  size: 24, demand: 'high',   arrivals: '22,100', growth: '+8.5%' },
  { id: 'russia',    label: 'Russia',       x: 68,  y: 35,  size: 26, demand: 'high',   arrivals: '28,900', growth: '+18.1%' },
  { id: 'germany',   label: 'Germany',      x: 22,  y: 60,  size: 20, demand: 'medium', arrivals: '15,400', growth: '+5.4%' },
  { id: 'china',     label: 'China',        x: 82,  y: 52,  size: 19, demand: 'medium', arrivals: '14,200', growth: '+11.0%' },
  { id: 'australia', label: 'Australia',    x: 75,  y: 78,  size: 17, demand: 'medium', arrivals: '11,800', growth: '+4.2%' },
  { id: 'france',    label: 'France',       x: 38,  y: 72,  size: 16, demand: 'medium', arrivals: '10,500', growth: '+3.9%' },
  { id: 'us',        label: 'US',           x: 12,  y: 32,  size: 14, demand: 'low',    arrivals: '8,200',  growth: '+2.1%' },
  { id: 'canada',    label: 'Canada',       x: 10,  y: 52,  size: 12, demand: 'low',    arrivals: '5,400',  growth: '+1.8%' },
  { id: 'maldives',  label: 'Maldives',     x: 52,  y: 62,  size: 13, demand: 'low',    arrivals: '6,100',  growth: '+6.5%' },
]

// Spatial Co-movement & Mobility Edges
const edges = [
  ['india', 'russia'], ['india', 'uk'], ['uk', 'germany'],
  ['uk', 'france'], ['russia', 'china'], ['germany', 'france'],
  ['australia', 'uk'], ['us', 'canada'], ['india', 'maldives'],
  ['china', 'australia'], ['germany', 'us']
]

const demandColors = {
  high:   '#a8296a',
  medium: '#d4a843',
  low:    '#00b4a6',
}

export default function MarketGraph() {
  const [selected, setSelected] = useState(null)
  const [zoomLevel, setZoomLevel] = useState(1)
  const [isFullscreen, setIsFullscreen] = useState(false)

  const active = nodes.find(n => n.id === selected)

  // Zoom Control Handlers
  const handleZoomIn = () => setZoomLevel(prev => Math.min(prev + 0.25, 2.5))
  const handleZoomOut = () => setZoomLevel(prev => Math.max(prev - 0.25, 0.6))
  const handleResetZoom = () => setZoomLevel(1)
  const handleToggleFullscreen = () => setIsFullscreen(prev => !prev)

  // Calculate SVG ViewBox dynamically based on zoom
  const viewBoxSize = 100 / zoomLevel
  const viewBoxOffset = (100 - viewBoxSize) / 2
  const viewBoxString = `${viewBoxOffset} ${viewBoxOffset} ${viewBoxSize} ${viewBoxSize}`

  return (
    <div className={`page-container fade-in-up ${isFullscreen ? 'fixed inset-0 z-50 bg-black p-6 overflow-auto' : ''}`}>
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Market Graph</h1>
          <span className="badge badge-burgundy">Core Research Focus</span>
        </div>
        <p className="page-desc">
          Spatio-temporal demand flow network across top 10 tourist origin markets.
          Node size encodes arrival volume; edges represent spatio-temporal co-movement corridors.
        </p>
      </div>

      <div className="grid-2 mb-6" style={{ gridTemplateColumns: '1fr 280px' }}>
        {/* Graph Canvas */}
        <div className="card" style={{ padding: '0', overflow: 'hidden', position: 'relative' }}>
          {/* Toolbar */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: '8px',
            padding: '12px 16px', borderBottom: '1px solid var(--color-border)',
          }}>
            <Network size={15} color="var(--color-burgundy-400)" />
            <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
              Demand Flow Network (10 Origin Countries)
            </span>
            <div style={{ marginLeft: 'auto', display: 'flex', gap: '6px' }}>
              <button
                onClick={handleZoomIn}
                title="Zoom In"
                className="topbar-btn"
                style={{ width: '30px', height: '30px' }}
              >
                <ZoomIn size={13} />
              </button>
              <button
                onClick={handleZoomOut}
                title="Zoom Out"
                className="topbar-btn"
                style={{ width: '30px', height: '30px' }}
              >
                <ZoomOut size={13} />
              </button>
              <button
                onClick={handleToggleFullscreen}
                title={isFullscreen ? "Exit Fullscreen" : "Fullscreen"}
                className="topbar-btn"
                style={{ width: '30px', height: '30px' }}
              >
                <Maximize2 size={13} />
              </button>
              <button
                onClick={handleResetZoom}
                title="Reset View"
                className="topbar-btn"
                style={{ width: '30px', height: '30px' }}
              >
                <RefreshCw size={13} />
              </button>
            </div>
          </div>

          {/* SVG Graph Canvas */}
          <svg
            viewBox={viewBoxString}
            style={{
              width: '100%',
              height: isFullscreen ? '70vh' : '420px',
              background: 'var(--color-bg-deep)',
              transition: 'all 0.25s ease-out'
            }}
          >
            {/* Grid */}
            <defs>
              <pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse">
                <path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(168,41,106,0.06)" strokeWidth="0.3" />
              </pattern>
            </defs>
            <rect width="100" height="100" fill="url(#grid)" />

            {/* Edges */}
            {edges.map(([a, b]) => {
              const na = nodes.find(n => n.id === a)
              const nb = nodes.find(n => n.id === b)
              if (!na || !nb) return null
              return (
                <line
                  key={`${a}-${b}`}
                  x1={na.x} y1={na.y} x2={nb.x} y2={nb.y}
                  stroke="rgba(168,41,106,0.35)"
                  strokeWidth="0.5"
                  strokeDasharray={na.demand === 'high' && nb.demand === 'high' ? '0' : '1,1'}
                />
              )
            })}

            {/* Nodes */}
            {nodes.map(({ id, label, x, y, size, demand }) => (
              <g key={id} onClick={() => setSelected(id === selected ? null : id)} style={{ cursor: 'pointer' }}>
                {/* Glow ring for selected node */}
                {selected === id && (
                  <circle
                    cx={x} cy={y}
                    r={size / 6 + 2.5}
                    fill="none"
                    stroke={demandColors[demand]}
                    strokeWidth="0.8"
                    opacity="0.8"
                  />
                )}
                <circle
                  cx={x} cy={y}
                  r={size / 6}
                  fill={`${demandColors[demand]}44`}
                  stroke={demandColors[demand]}
                  strokeWidth={selected === id ? '0.9' : '0.5'}
                />
                <text
                  x={x} y={y + size / 6 + 2.5}
                  textAnchor="middle"
                  fontSize="2.4"
                  fontWeight="600"
                  fill="var(--color-text-primary)"
                >
                  {label}
                </text>
              </g>
            ))}
          </svg>

          {/* Legend */}
          <div style={{
            display: 'flex', gap: '16px', padding: '10px 16px',
            borderTop: '1px solid var(--color-border)', fontSize: '11px',
            color: 'var(--color-text-muted)',
          }}>
            {Object.entries(demandColors).map(([level, color]) => (
              <div key={level} style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: color }} />
                {level.charAt(0).toUpperCase() + level.slice(1)} Demand
              </div>
            ))}
          </div>
        </div>

        {/* Node Inspector */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div className="section-title">Node Inspector</div>
          {active ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{
                padding: '16px', borderRadius: 'var(--radius-md)',
                background: 'var(--color-bg-elevated)',
                border: `1px solid ${demandColors[active.demand]}66`,
              }}>
                <div style={{ fontSize: '16px', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                  {active.label}
                </div>
                <div style={{ marginTop: '4px', display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                  <span className={`badge badge-${active.demand === 'high' ? 'burgundy' : active.demand === 'medium' ? 'gold' : 'teal'}`}>
                    {active.demand} demand tier
                  </span>
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {[
                  { label: 'Origin Country',     value: active.label },
                  { label: 'Monthly Arrivals',   value: active.arrivals },
                  { label: 'ST-GNN Growth Rate', value: active.growth },
                  { label: 'Connected Markets',  value: edges.filter(e => e.includes(active.id)).length },
                  { label: 'Centrality Index',   value: (active.size / 30).toFixed(2) },
                ].map(({ label, value }) => (
                  <div key={label} style={{
                    display: 'flex', justifyContent: 'space-between',
                    fontSize: '12.5px', padding: '8px 0',
                    borderBottom: '1px solid var(--color-border)',
                  }}>
                    <span style={{ color: 'var(--color-text-muted)' }}>{label}</span>
                    <span style={{ color: 'var(--color-text-primary)', fontWeight: 600 }}>{value}</span>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div style={{ color: 'var(--color-text-muted)', fontSize: '13px', textAlign: 'center', marginTop: '32px' }}>
              <Network size={32} style={{ margin: '0 auto 12px', opacity: 0.3 }} />
              Click a market node on the graph to inspect its properties
            </div>
          )}
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid-4">
        {[
          { label: 'Total Source Markets', value: `${nodes.length} Nodes` },
          { label: 'Spatial Graph Edges',   value: `${edges.length} Edges` },
          { label: 'High-Demand Markets',  value: `${nodes.filter(n => n.demand === 'high').length} Markets` },
          { label: 'Graph Density',        value: (edges.length / (nodes.length * (nodes.length - 1) / 2)).toFixed(2) },
        ].map(({ label, value }) => (
          <div key={label} className="stat-card">
            <span className="stat-label">{label}</span>
            <span className="stat-value">{value}</span>
          </div>
        ))}
      </div>
    </div>
  )
}