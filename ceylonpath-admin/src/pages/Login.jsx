import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Compass, Eye, EyeOff, ArrowRight, Lock, Mail } from 'lucide-react'

export default function Login() {
  const [showPw, setShowPw] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const navigate = useNavigate()

  const handleSubmit = e => {
    e.preventDefault()
    // Navigate to dashboard upon successful login
    navigate('/')
  }

  return (
    <div className="login-page" style={{
      minHeight: '100vh',
      width: '100vw',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* Centered Glassmorphism Login Card */}
      <div className="login-card" style={{
        position: 'relative',
        zIndex: 1,
        width: '100%',
        maxWidth: '420px',
        backgroundColor: 'rgba(26, 17, 24, 0.85)',
        backdropFilter: 'blur(16px)',
        border: '1px solid rgba(168, 41, 106, 0.3)',
        borderRadius: '16px',
        padding: '36px 32px',
        boxShadow: '0 20px 40px rgba(0, 0, 0, 0.5)',
        color: '#ffffff',
      }}>
        {/* Brand Row */}
        <div className="login-logo-row" style={{ display: 'flex', gap: '12px', alignItems: 'center', marginBottom: '28px' }}>
          <div className="login-logo" style={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '48px',
            height: '48px',
            borderRadius: '12px',
            background: 'linear-gradient(135deg, #a8296a, #6b1a3a)',
            boxShadow: '0 4px 12px rgba(168, 41, 106, 0.3)'
          }}>
            <Compass size={24} color="#e9a0be" />
          </div>
          <div>
            <div style={{ fontSize: '18px', fontWeight: 700, color: '#ffffff' }}>
              CeylonPath Admin
            </div>
            <div style={{ fontSize: '11px', color: '#e9a0be', letterSpacing: '0.8px', textTransform: 'uppercase', fontWeight: 500 }}>
              Tourism Intelligence
            </div>
          </div>
        </div>

        <h1 style={{ fontSize: '24px', fontWeight: 800, color: '#ffffff', marginBottom: '8px' }}>
          Welcome back
        </h1>
        <p style={{ fontSize: '13.5px', color: 'rgba(240, 232, 236, 0.6)', marginBottom: '28px' }}>
          Sign in to access the research dashboard
        </p>

        <form onSubmit={handleSubmit} id="login-form" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div className="form-group">
            <label className="label" htmlFor="email" style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', marginBottom: '6px', color: 'rgba(240, 232, 236, 0.8)' }}>
              Email address
            </label>
            <div style={{ position: 'relative' }}>
              <Mail size={15} style={{
                position: 'absolute', left: '13px', top: '50%', transform: 'translateY(-50%)',
                color: 'rgba(240, 232, 236, 0.5)', pointerEvents: 'none',
              }} />
              <input
                id="email"
                type="email"
                style={{
                  width: '100%',
                  padding: '10px 12px 10px 38px',
                  backgroundColor: 'rgba(18, 10, 15, 0.6)',
                  border: '1px solid rgba(168, 41, 106, 0.3)',
                  borderRadius: '8px',
                  color: '#ffffff',
                  fontSize: '13.5px',
                  outline: 'none',
                  boxSizing: 'border-box'
                }}
                placeholder="admin@ceylonpath.lk"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label className="label" htmlFor="password" style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', marginBottom: '6px', color: 'rgba(240, 232, 236, 0.8)' }}>
              Password
            </label>
            <div style={{ position: 'relative' }}>
              <Lock size={15} style={{
                position: 'absolute', left: '13px', top: '50%', transform: 'translateY(-50%)',
                color: 'rgba(240, 232, 236, 0.5)', pointerEvents: 'none',
              }} />
              <input
                id="password"
                type={showPw ? 'text' : 'password'}
                style={{
                  width: '100%',
                  padding: '10px 40px 10px 38px',
                  backgroundColor: 'rgba(18, 10, 15, 0.6)',
                  border: '1px solid rgba(168, 41, 106, 0.3)',
                  borderRadius: '8px',
                  color: '#ffffff',
                  fontSize: '13.5px',
                  outline: 'none',
                  boxSizing: 'border-box'
                }}
                placeholder="••••••••"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
              />
              <button type="button" onClick={() => setShowPw(!showPw)} style={{
                position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)',
                background: 'none', border: 'none', cursor: 'pointer',
                color: 'rgba(240, 232, 236, 0.5)',
              }}>
                {showPw ? <EyeOff size={15} /> : <Eye size={15} />}
              </button>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '20px' }}>
            <a href="#" style={{ fontSize: '12.5px', color: '#e9a0be', textDecoration: 'none' }}>
              Forgot password?
            </a>
          </div>

          <button type="submit" className="login-submit-btn" style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '8px',
            width: '100%',
            padding: '12px',
            borderRadius: '8px',
            border: 'none',
            color: '#ffffff',
            fontWeight: '700',
            fontSize: '14.5px',
            cursor: 'pointer',
          }}>
            Sign In <ArrowRight size={15} />
          </button>
        </form>

        <div style={{
          marginTop: '28px', padding: '14px', borderRadius: '8px',
          background: 'rgba(0,180,166,0.06)', border: '1px solid rgba(0,180,166,0.15)',
          fontSize: '12px', color: 'rgba(240, 232, 236, 0.6)', textAlign: 'center',
        }}>
          API connected to{' '}
          <span style={{ color: '#1ecfbe', fontWeight: 600 }}>
            http://127.0.0.1:8000
          </span>
        </div>
      </div>
    </div>
  )
}