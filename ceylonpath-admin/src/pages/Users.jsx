import { Users, Plus, Search, MoreHorizontal, Shield, UserCheck, UserX } from 'lucide-react'

const users = [
  { id: 1, name: 'Amal Perera',     email: 'amal@ceylonpath.lk',  role: 'Research Lead',    status: 'active',   joined: '2025-02-10', module: 'Analytics' },
  { id: 2, name: 'Dilani Fernando', email: 'dilani@ceylonpath.lk', role: 'Field Officer',    status: 'active',   joined: '2025-05-18', module: 'Emergencies' },
  { id: 3, name: 'Kasun Silva',     email: 'kasun@ceylonpath.lk',  role: 'Data Engineer',   status: 'active',   joined: '2025-07-02', module: 'Data Sources' },
  { id: 4, name: 'Nimali Jayantha', email: 'nimali@ceylonpath.lk', role: 'Route Planner',   status: 'inactive', joined: '2025-09-12', module: 'Routes' },
  { id: 5, name: 'Ruwan Bandara',   email: 'ruwan@ceylonpath.lk',  role: 'Risk Analyst',    status: 'active',   joined: '2025-11-24', module: 'Risk Zones' },
  { id: 6, name: 'Sithumi Wickrama',email: 'sithumi@ceylonpath.lk',role: 'Destination Mgr', status: 'active',   joined: '2026-01-08', module: 'Destinations' },
]

export default function UsersPage() {
  return (
    <div className="page-container fade-in-up">
      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Users</h1>
          <span className="badge badge-teal">{users.length} Members</span>
        </div>
        <p className="page-desc">Manage platform users, roles, and access permissions.</p>
      </div>

      {/* Stats */}
      <div className="grid-4 mb-6">
        {[
          { label: 'Total Users', value: users.length, icon: Users },
          { label: 'Active',      value: users.filter(u => u.status === 'active').length,   icon: UserCheck },
          { label: 'Inactive',    value: users.filter(u => u.status === 'inactive').length, icon: UserX    },
          { label: 'Admins',      value: 1, icon: Shield },
        ].map(({ label, value, icon: Icon }) => (
          <div key={label} className="stat-card">
            <div className="flex justify-between items-center">
              <span className="stat-label">{label}</span>
              <Icon size={15} color="var(--color-burgundy-500)" />
            </div>
            <span className="stat-value">{value}</span>
          </div>
        ))}
      </div>

      {/* Table */}
      <div className="card">
        <div className="section-header">
          <div>
            <div className="section-title">Platform Users</div>
            <div className="section-subtitle">All registered team members</div>
          </div>
          <div style={{ display: 'flex', gap: '10px' }}>
            <div style={{ position: 'relative' }}>
              <Search size={13} style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
              <input id="user-search" placeholder="Search users…" style={{
                paddingLeft: '30px', padding: '8px 12px 8px 30px',
                background: 'var(--color-bg-elevated)', border: '1px solid var(--color-border)',
                borderRadius: 'var(--radius-md)', color: 'var(--color-text-primary)',
                fontSize: '12.5px', outline: 'none', width: '180px',
              }} />
            </div>
            <button id="add-user-btn" style={{
              display: 'flex', alignItems: 'center', gap: '6px',
              padding: '8px 14px', borderRadius: 'var(--radius-md)',
              background: 'rgba(107,26,58,0.3)', border: '1px solid var(--color-border-hover)',
              color: 'var(--color-burgundy-200)', fontSize: '12.5px', cursor: 'pointer',
            }}>
              <Plus size={13} /> Invite User
            </button>
          </div>
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--color-border)' }}>
              {['User', 'Role', 'Module', 'Joined', 'Status', ''].map(h => (
                <th key={h} style={{
                  textAlign: 'left', padding: '10px 12px',
                  fontSize: '11px', fontWeight: 600,
                  color: 'var(--color-text-muted)',
                  textTransform: 'uppercase', letterSpacing: '0.6px',
                }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {users.map(({ id, name, email, role, status, joined, module }) => (
              <tr key={id} id={`user-row-${id}`} style={{ borderBottom: '1px solid var(--color-border)', transition: 'background 0.15s' }}
                onMouseEnter={e => e.currentTarget.style.background = 'rgba(107,26,58,0.06)'}
                onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
              >
                <td style={{ padding: '14px 12px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{
                      width: '32px', height: '32px', borderRadius: '50%',
                      background: 'linear-gradient(135deg, var(--color-burgundy-700), var(--color-burgundy-500))',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: '12px', fontWeight: 700, color: 'var(--color-burgundy-100)',
                    }}>
                      {name.charAt(0)}
                    </div>
                    <div>
                      <div style={{ fontSize: '13.5px', fontWeight: 600, color: 'var(--color-text-primary)' }}>{name}</div>
                      <div style={{ fontSize: '11.5px', color: 'var(--color-text-muted)' }}>{email}</div>
                    </div>
                  </div>
                </td>
                <td style={{ padding: '14px 12px', fontSize: '13px', color: 'var(--color-text-secondary)' }}>{role}</td>
                <td style={{ padding: '14px 12px', fontSize: '13px', color: 'var(--color-text-muted)' }}>{module}</td>
                <td style={{ padding: '14px 12px', fontSize: '12.5px', color: 'var(--color-text-muted)' }}>{joined}</td>
                <td style={{ padding: '14px 12px' }}>
                  <span style={{
                    fontSize: '11px', padding: '3px 10px', borderRadius: '99px', fontWeight: 600,
                    background: status === 'active' ? 'rgba(0,180,166,0.12)' : 'rgba(107,26,58,0.15)',
                    color: status === 'active' ? 'var(--color-teal-400)' : 'var(--color-text-muted)',
                    border: `1px solid ${status === 'active' ? 'rgba(0,180,166,0.2)' : 'var(--color-border)'}`,
                  }}>
                    {status}
                  </span>
                </td>
                <td style={{ padding: '14px 12px' }}>
                  <button id={`user-menu-${id}`} style={{
                    background: 'transparent', border: 'none', cursor: 'pointer',
                    color: 'var(--color-text-muted)', padding: '4px',
                  }}>
                    <MoreHorizontal size={15} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
