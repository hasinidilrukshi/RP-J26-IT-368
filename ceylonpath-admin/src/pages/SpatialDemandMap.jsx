import { Map, ZoomIn, ZoomOut, Layers, Target } from 'lucide-react'
import { useState } from 'react'

const districts = [
  { name: 'Colombo',       x: 22, y: 62, r: 22, demand: 0.95, color: '#a8296a' },
  { name: 'Kandy',         x: 48, y: 42, r: 18, demand: 0.82, color: '#b8306a' },
  { name: 'Galle',         x: 28, y: 82, r: 16, demand: 0.74, color: '#c44070' },
  { name: 'Sigiriya',      x: 56, y: 28, r: 15, demand: 0.71, color: '#c94878' },
  { name: 'Ella',          x: 62, y: 70, r: 13, demand: 0.60, color: '#d97098' },
  { name: 'Mirissa',       x: 32, y: 88, r: 12, demand: 0.55, color: '#d97098' },
  { name: 'Nuwara Eliya',  x: 55, y: 56, r: 12, demand: 0.53, color: '#d97098' },
  { name: 'Trincomalee',   x: 72, y: 30, r: 11, demand: 0.44, color: '#00b4a6' },
  { name: 'Jaffna',        x: 50, y: 8,  r: 10, demand: 0.30, color: '#1ecfbe' },
  { name: 'Anuradhapura',  x: 44, y: 22, r: 11, demand: 0.38, color: '#1ecfbe' },
  { name: 'Yala',          x: 66, y: 84, r: 11, demand: 0.48, color: '#00b4a6' },
  { name: 'Batticaloa',    x: 80, y: 58, r: 9,  demand: 0.25, color: '#5ee0d4' },
]

export default function SpatialDemandMap() {
  const [zoomLevel, setZoomLevel] = useState(1)
  const [showLayers, setShowLayers] = useState(true)

  // Zoom Controllers
  const handleZoomIn = () => setZoomLevel(prev => Math.min(prev + 0.25, 2.0))
  const handleZoomOut = () => setZoomLevel(prev => Math.max(prev - 0.25, 0.75))
  const handleResetZoom = () => setZoomLevel(1)
  const handleToggleLayers = () => setShowLayers(prev => !prev)

  // Dynamic SVG ViewBox calculation
  const viewBoxSize = 100 / zoomLevel
  const viewBoxOffset = (100 - viewBoxSize) / 2
  const viewBoxString = `${viewBoxOffset} ${viewBoxOffset} ${viewBoxSize} ${viewBoxSize}`

  const avgDemand = (districts.reduce((s, d) => s + d.demand, 0) / districts.length) * 100

  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Spatial Demand Map</h1>
          <span className="badge badge-teal">Geo-Intelligence</span>
        </div>
        <p className="page-desc">
          Geographic visualization of tourism demand intensity across Sri Lanka's districts.
          Bubble size and color encode relative demand strength from the STGNN model.
        </p>
      </div>

      <div className="grid-2 mb-6" style={{ gridTemplateColumns: '1fr 260px' }}>
        {/* Map Panel */}
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {/* Map Toolbar with Functional Buttons */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: '8px',
            padding: '12px 16px', borderBottom: '1px solid var(--color-border)',
          }}>
            <Map size={14} color="var(--color-teal-400)" />
            <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-primary)' }}>
              Sri Lanka — Demand Heatmap
            </span>
            <div style={{ marginLeft: 'auto', display: 'flex', gap: '6px' }}>
              <button onClick={handleZoomIn} title="Zoom In" className="topbar-btn" style={{ width: '30px', height: '30px', cursor: 'pointer' }}>
                <ZoomIn size={13} />
              </button>
              <button onClick={handleZoomOut} title="Zoom Out" className="topbar-btn" style={{ width: '30px', height: '30px', cursor: 'pointer' }}>
                <ZoomOut size={13} />
              </button>
              <button onClick={handleToggleLayers} title="Toggle Layers" className="topbar-btn" style={{ width: '30px', height: '30px', cursor: 'pointer', background: showLayers ? 'rgba(0,180,166,0.2)' : 'transparent' }}>
                <Layers size={13} />
              </button>
              <button onClick={handleResetZoom} title="Reset View" className="topbar-btn" style={{ width: '30px', height: '30px', cursor: 'pointer' }}>
                <Target size={13} />
              </button>
            </div>
          </div>

          {/* Dynamic SVG Map */}
          <svg viewBox={viewBoxString} style={{ width: '100%', height: '480px', background: 'var(--color-bg-deep)', transition: 'all 0.3s ease' }}>
            <defs>
              <pattern id="mapgrid" width="5" height="5" patternUnits="userSpaceOnUse">
                <path d="M 5 0 L 0 0 0 5" fill="none" stroke="rgba(0,180,166,0.05)" strokeWidth="0.2" />
              </pattern>
            </defs>
            <rect width="100" height="100" fill="url(#mapgrid)" />

            {/* Sri Lanka simplified outline */}
            <polygon
              points="50,5 62,8 74,20 80,32 82,50 78,65 72,78 62,88 50,94 38,90 28,80 20,68 18,55 22,42 30,28 40,16"
              fill="rgba(26,17,24,0.8)"
              stroke="rgba(168,41,106,0.3)"
              strokeWidth="0.6"
            />

            {/* Demand Bubbles */}
            {districts.map(({ name, x, y, r, demand: _demand, color }) => (
              <g key={name}>
                {showLayers && (
                  <circle cx={x} cy={y} r={r * 1.5} fill={`${color}12`} />
                )}
                <circle cx={x} cy={y} r={r * 0.6}
                  fill={`${color}55`}
                  stroke={color}
                  strokeWidth="0.4"
                />
                {r >= 13 && (
                  <text x={x} y={y + r * 0.6 + 2.5}
                    textAnchor="middle"
                    fontSize="2.5"
                    fill="rgba(240,232,236,0.7)">
                    {name}
                  </text>
                )}
              </g>
            ))}
          </svg>

          {/* Color Scale Legend */}
          <div style={{
            padding: '10px 16px',
            borderTop: '1px solid var(--color-border)',
            display: 'flex', alignItems: 'center', gap: '12px', fontSize: '11px',
            color: 'var(--color-text-muted)',
          }}>
            <span>Demand Intensity:</span>
            <div style={{
              flex: 1, height: '6px', borderRadius: '99px',
              background: 'linear-gradient(90deg, var(--color-teal-500), var(--color-gold-500), var(--color-burgundy-500))',
            }} />
            <span>Low → High</span>
          </div>
        </div>

        {/* District Stats */}
        <div className="card" style={{ padding: '16px', overflowY: 'auto', maxHeight: '540px' }}>
          <div style={{ marginBottom: '14px' }}>
            <div className="section-title" style={{ fontSize: '15px' }}>District Rankings</div>
            <div className="section-subtitle">By demand intensity index</div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {[...districts].sort((a, b) => b.demand - a.demand).map(({ name, demand, color }, i) => (
              <div key={name}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                  <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                    <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', minWidth: '16px' }}>
                      #{i + 1}
                    </span>
                    <span style={{ fontSize: '12.5px', color: 'var(--color-text-primary)' }}>{name}</span>
                  </div>
                  <span style={{ fontSize: '12px', color, fontWeight: 600 }}>
                    {(demand * 100).toFixed(0)}%
                  </span>
                </div>
                <div style={{ height: '4px', background: 'var(--color-bg-elevated)', borderRadius: '99px', overflow: 'hidden' }}>
                  <div style={{
                    height: '100%', width: `${demand * 100}%`,
                    background: `linear-gradient(90deg, ${color}88, ${color})`,
                    borderRadius: '99px',
                  }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid-4">
        {[
          { label: 'Districts Monitored', value: districts.length },
          { label: 'Avg Demand Index',    value: `${avgDemand.toFixed(1)}%` },
          { label: 'Peak District',       value: 'Colombo' },
          { label: 'Below 40% Threshold', value: districts.filter(d => d.demand < 0.4).length },
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