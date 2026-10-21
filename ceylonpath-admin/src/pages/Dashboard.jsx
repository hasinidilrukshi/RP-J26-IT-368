import React from 'react'
import {
  Users, MapPin, AlertTriangle,
  Activity, Globe, BarChart3, ArrowUpRight, ArrowDownRight
} from 'lucide-react'

const stats = [
  { label: 'Total Arrivals (MTD)', value: '142,830', delta: '+8.4%', up: true, icon: Users },
  { label: 'Forecast Accuracy',    value: '91.2%',   delta: '+1.1%', up: true, icon: Activity },
  { label: 'Active Destinations',  value: '38',       delta: '0',    up: true, icon: MapPin },
  { label: 'Active Alerts',        value: '3',        delta: '+2',   up: false, icon: AlertTriangle },
]

const recentAlerts = [
  { id: 1, region: 'Colombo Metro', type: 'Demand Surge',       severity: 'high',   time: '2h ago' },
  { id: 2, region: 'Galle Fort',    type: 'Capacity Threshold', severity: 'medium', time: '5h ago' },
  { id: 3, region: 'Ella Trail',    type: 'Weather Risk',       severity: 'low',    time: '1d ago' },
]

const topDestinations = [
  { name: 'Sigiriya Rock',   visits: 12480, share: 0.87 },
  { name: 'Temple of Tooth', visits: 10920, share: 0.76 },
  { name: 'Mirissa Beach',   visits: 9340,  share: 0.65 },
  { name: 'Yala National',   visits: 8100,  share: 0.57 },
  { name: 'Ella Rock',       visits: 7450,  share: 0.52 },
]

// 7-Day Demand Forecast Data
const forecastData = [
  { day: 'Mon', value: 4200, height: 55 },
  { day: 'Tue', value: 4600, height: 65 },
  { day: 'Wed', value: 5100, height: 72 },
  { day: 'Thu', value: 4800, height: 68 },
  { day: 'Fri', value: 6200, height: 85 },
  { day: 'Sat', value: 7100, height: 100 },
  { day: 'Sun', value: 6800, height: 92 },
]

export default function Dashboard() {
  return (
    <div className="page-container fade-in-up">
      {/* Page Header */}
      <div className="page-header mb-6">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title text-2xl font-bold">Tourism Intelligence Dashboard</h1>
          <span className="badge badge-teal px-2.5 py-0.5 text-xs rounded bg-emerald-950 text-emerald-400 border border-emerald-800">Live</span>
        </div>
        <p className="page-desc text-sm text-white">
          Real-time overview of tourism demand across Sri Lanka. Powered by STGNN-GRU
          spatio-temporal forecasting models.
        </p>
      </div>

      {/* KPI Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {stats.map(({ label, value, delta, up, icon: Icon }) => (
          <div key={label} className="stat-card bg-gray-900/60 border border-gray-800 p-4 rounded-xl">
            <div className="flex justify-between items-center mb-2">
              <span className="stat-label text-xs text-gray-400 uppercase tracking-wider">{label}</span>
              <Icon size={16} className="text-amber-400" />
            </div>
            <div className="stat-value text-2xl font-bold text-gray-100 mb-1">{value}</div>
            {delta !== '0' && (
              <div className={`stat-delta flex items-center gap-1 text-xs font-medium ${up ? 'text-emerald-400' : 'text-rose-400'}`}>
                {up ? <ArrowUpRight size={13} /> : <ArrowDownRight size={13} />}
                {delta} vs last month
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Main grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Top Destinations */}
        <div className="card bg-gray-900/60 border border-gray-800 p-5 rounded-xl">
          <div className="section-header flex justify-between items-center mb-4">
            <div>
              <div className="section-title font-semibold text-gray-200">Top Destinations</div>
              <div className="section-subtitle text-xs text-gray-400">By visitor volume this month</div>
            </div>
            <span className="badge flex items-center gap-1 text-xs px-2 py-1 rounded bg-gray-800 text-gray-300 border border-gray-700">
              <Globe size={10} /> MTD
            </span>
          </div>
          <div className="flex flex-col gap-3.5">
            {topDestinations.map(({ name, visits, share }) => (
              <div key={name}>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-200 font-medium">{name}</span>
                  <span className="text-gray-400 text-xs">{visits.toLocaleString()}</span>
                </div>
                <div className="h-1.5 bg-gray-800 rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-gray-600 rounded-full transition-all duration-500"
                    style={{ width: `${share * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Alerts */}
        <div className="card bg-gray-900/60 border border-gray-800 p-5 rounded-xl">
          <div className="section-header flex justify-between items-center mb-4">
            <div>
              <div className="section-title font-semibold text-gray-200">Recent Alerts</div>
              <div className="section-subtitle text-xs text-gray-400">Latest anomaly detections</div>
            </div>
            <span className="badge badge-danger text-xs px-2 py-1 rounded bg-rose-950 text-rose-300 border border-rose-800">3 Active</span>
          </div>
          <div className="flex flex-col gap-3">
            {recentAlerts.map(({ id, region, type, severity, time }) => (
              <div key={id} className="flex items-center justify-between p-3 bg-gray-800/40 rounded-lg border border-gray-800">
                <div>
                  <div className="text-sm font-semibold text-gray-200">{region}</div>
                  <div className="text-xs text-gray-400 mt-0.5">{type}</div>
                </div>
                <div className="text-right">
                  <span className={`text-xs px-2 py-0.5 rounded font-medium ${
                    severity === 'high' ? 'bg-rose-950 text-rose-300 border border-rose-800' :
                    severity === 'medium' ? 'bg-amber-950 text-amber-300 border border-amber-800' :
                    'bg-emerald-950 text-emerald-300 border border-emerald-800'
                  }`}>
                    {severity}
                  </span>
                  <div className="text-xs text-gray-500 mt-1">{time}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Fixed 7-Day Forecast Bar Chart Summary */}
      <div className="card bg-gray-900/60 border border-gray-800 p-5 rounded-xl">
        <div className="section-header flex justify-between items-center mb-6">
          <div>
            <div className="section-title font-semibold text-gray-200">7-Day Demand Forecast</div>
            <div className="section-subtitle text-xs text-gray-400">STGNN-GRU model prediction summary</div>
          </div>
          <span className="badge badge-teal flex items-center gap-1 text-xs px-2.5 py-1 rounded bg-emerald-950 text-emerald-400 border border-emerald-800">
            <BarChart3 size={10} /> Model v2.1
          </span>
        </div>

        {/* Responsive Flex Bar Chart with Values */}
        <div className="grid grid-cols-7 gap-3 pt-4">
          {forecastData.map((item) => (
            <div key={item.day} className="flex flex-col items-center gap-2">
              {/* Top Numerical Value Label */}
              <span className="text-[11px] font-semibold text-amber-300">
                {item.value.toLocaleString()}
              </span>

              {/* Bar Container */}
              <div className="h-40 w-full flex items-end justify-center bg-gray-800/20 rounded-lg p-1">
                <div 
                  className="w-full max-w-[42px] rounded-t-md transition-all duration-500 bg-gradient-to-t from-[#4a2c11] via-[#8f6d3c] to-[#c89d52] border-t border-[#d7b779] shadow-lg shadow-amber-950/30"
                  style={{ height: `${item.height}%` }}
                />
              </div>

              {/* Day Label */}
              <span className="text-xs font-medium text-gray-300 mt-1">
                {item.day}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}