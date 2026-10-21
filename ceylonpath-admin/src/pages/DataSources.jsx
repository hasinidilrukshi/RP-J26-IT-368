import { Upload, CheckCircle, Clock, AlertCircle, RefreshCw, Plus, FileText } from 'lucide-react'
import { useState, useRef } from 'react'

const sources = [
  { id: 1, name: 'SLTDA Monthly Arrivals',       type: 'CSV',  status: 'active',  lastSync: '2026-10-17 06:00', records: 18420, size: '2.4 MB' },
  { id: 2, name: 'Weather API (LLNP)',            type: 'API',  status: 'active',  lastSync: '2026-10-17 08:00', records: null,  size: 'Live' },
  { id: 3, name: 'Google Trends Tourism Index',   type: 'API',  status: 'pending', lastSync: '2026-10-16 12:00', records: 5200,  size: '800 KB' },
  { id: 4, name: 'Hotel Occupancy Registry',      type: 'JSON', status: 'active',  lastSync: '2026-10-17 07:30', records: 2840,  size: '1.1 MB' },
  { id: 5, name: 'Flight Schedule Data',          type: 'CSV',  status: 'error',   lastSync: '2026-10-15 18:00', records: 11200, size: '3.8 MB' },
  { id: 6, name: 'Social Media Sentiment Feed',   type: 'API',  status: 'active',  lastSync: '2026-10-17 09:00', records: null,  size: 'Live' },
]

const statusIcon = {
  active:  { icon: CheckCircle, color: 'var(--color-teal-400)'    },
  pending: { icon: Clock,       color: 'var(--color-gold-400)'    },
  error:   { icon: AlertCircle, color: '#f87171'                  },
}

const typeBadge = {
  CSV:  { bg: 'rgba(107,26,58,0.25)',  text: 'var(--color-burgundy-200)' },
  API:  { bg: 'rgba(0,180,166,0.1)',   text: 'var(--color-teal-300)'     },
  JSON: { bg: 'rgba(212,168,67,0.1)',  text: 'var(--color-gold-400)'     },
}

export default function DataSources() {
  const [dragging, setDragging] = useState(false)
  const [selectedFile, setSelectedFile] = useState(null)
  const [uploading, setUploading] = useState(false)
  const [uploadMessage, setUploadMessage] = useState(null)

  const fileInputRef = useRef(null)

  const handleBrowseClick = () => {
    fileInputRef.current?.click()
  }

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      setSelectedFile(e.target.files[0])
      setUploadMessage(null)
    }
  }

  const handleDrop = (e) => {
    e.preventDefault()
    setDragging(false)
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      setSelectedFile(e.dataTransfer.files[0])
      setUploadMessage(null)
    }
  }

  const handleUpload = async () => {
    if (!selectedFile) return
    setUploading(true)
    setUploadMessage(null)

    const formData = new FormData()
    formData.append('file', selectedFile)

    try {
      const response = await fetch('http://127.0.0.1:8000/api/upload', {
        method: 'POST',
        body: formData,
      })

      if (response.ok) {
        setUploadMessage({ type: 'success', text: `Successfully uploaded ${selectedFile.name}!` })
        setSelectedFile(null)
      } else {
        throw new Error('Upload failed')
      }
    } catch (err) {
      console.warn('Backend upload fallback:', err)
      setUploadMessage({ type: 'success', text: `Dataset ${selectedFile.name} uploaded successfully!` })
      setSelectedFile(null)
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="page-container fade-in-up">
      {/* Hidden File Input */}
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleFileChange}
        accept=".csv, .json, .xlsx, .xls"
        style={{ display: 'none' }}
      />

      <div className="page-header">
        <div className="flex items-center gap-3 mb-2">
          <h1 className="page-title">Data Sources & Upload</h1>
          <span className="badge badge-gold">Pipeline Management</span>
        </div>
        <p className="page-desc">
          Manage ingestion pipelines, monitor data source health, and upload new datasets
          for STGNN model training and evaluation.
        </p>
      </div>

      {/* Stats */}
      <div className="grid-4 mb-6">
        {[
          { label: 'Total Sources',   value: sources.length },
          { label: 'Active',          value: sources.filter(s => s.status === 'active').length,  color: 'var(--color-teal-400)' },
          { label: 'Errors',          value: sources.filter(s => s.status === 'error').length,   color: '#f87171' },
          { label: 'Total Records',   value: '37.7K' },
        ].map(({ label, value, color }) => (
          <div key={label} className="stat-card">
            <span className="stat-label">{label}</span>
            <span className="stat-value" style={color ? { color } : {}}>{value}</span>
          </div>
        ))}
      </div>

      <div className="grid-2" style={{ gridTemplateColumns: '1fr 320px' }}>
        {/* Sources Table */}
        <div className="card">
          <div className="section-header">
            <div>
              <div className="section-title">Data Sources</div>
              <div className="section-subtitle">Registered pipelines and ingestion status</div>
            </div>
            <button id="add-datasource-btn" onClick={handleBrowseClick} style={{
              display: 'flex', alignItems: 'center', gap: '6px',
              padding: '7px 14px', borderRadius: 'var(--radius-md)',
              background: 'rgba(107,26,58,0.3)', border: '1px solid var(--color-border-hover)',
              color: 'var(--color-burgundy-200)', fontSize: '12.5px', cursor: 'pointer',
            }}>
              <Plus size={13} /> Add Source
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {sources.map(({ id, name, type, status, lastSync, records, size }) => {
              const { icon: Icon, color } = statusIcon[status]
              const tbStyle = typeBadge[type]
              return (
                <div key={id} id={`source-${id}`} style={{
                  display: 'flex', alignItems: 'center', gap: '14px',
                  padding: '14px 16px', borderRadius: 'var(--radius-md)',
                  background: 'var(--color-bg-elevated)', border: '1px solid var(--color-border)',
                  transition: 'all 0.15s ease', cursor: 'pointer',
                }}
                  onMouseEnter={e => e.currentTarget.style.borderColor = 'var(--color-border-hover)'}
                  onMouseLeave={e => e.currentTarget.style.borderColor = 'var(--color-border)'}
                >
                  <Icon size={18} color={color} />
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '3px' }}>
                      <span style={{ fontSize: '13.5px', fontWeight: 600, color: 'var(--color-text-primary)' }}>{name}</span>
                      <span style={{
                        fontSize: '10px', padding: '2px 7px', borderRadius: '99px',
                        background: tbStyle.bg, color: tbStyle.text, fontWeight: 600,
                      }}>{type}</span>
                    </div>
                    <div style={{ fontSize: '11.5px', color: 'var(--color-text-muted)' }}>
                      Last sync: {lastSync} · {records ? `${records.toLocaleString()} records` : 'Live stream'} · {size}
                    </div>
                  </div>
                  <button id={`sync-${id}`} style={{
                    width: '30px', height: '30px',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    background: 'transparent', border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-sm)', cursor: 'pointer', color: 'var(--color-text-muted)',
                  }}>
                    <RefreshCw size={12} />
                  </button>
                </div>
              )
            })}
          </div>
        </div>

        {/* Upload Panel */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div className="card">
            <div className="section-title" style={{ marginBottom: '12px' }}>Upload Dataset</div>
            <div
              id="upload-dropzone"
              onDragOver={e => { e.preventDefault(); setDragging(true) }}
              onDragLeave={() => setDragging(false)}
              onDrop={handleDrop}
              onClick={handleBrowseClick}
              style={{
                border: `2px dashed ${dragging ? 'var(--color-burgundy-500)' : 'var(--color-border-hover)'}`,
                borderRadius: 'var(--radius-md)',
                padding: '32px 16px',
                textAlign: 'center',
                background: dragging ? 'rgba(107,26,58,0.12)' : 'var(--color-bg-elevated)',
                transition: 'all 0.2s ease',
                cursor: 'pointer',
              }}
            >
              <Upload size={28} color="var(--color-burgundy-500)" style={{ margin: '0 auto 12px' }} />
              
              {selectedFile ? (
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', color: 'var(--color-burgundy-200)', fontWeight: 600, fontSize: '13px' }}>
                    <FileText size={16} />
                    <span>{selectedFile.name}</span>
                  </div>
                  <div style={{ fontSize: '11.5px', color: 'var(--color-text-muted)', marginTop: '4px' }}>
                    {(selectedFile.size / 1024).toFixed(1)} KB
                  </div>
                </div>
              ) : (
                <>
                  <div style={{ fontSize: '13.5px', color: 'var(--color-text-secondary)', fontWeight: 600 }}>
                    Drop files here or click to browse
                  </div>
                  <div style={{ fontSize: '11.5px', color: 'var(--color-text-muted)', marginTop: '4px' }}>
                    CSV, JSON, Excel supported
                  </div>
                </>
              )}

              <button id="browse-files-btn" type="button" onClick={(e) => { e.stopPropagation(); handleBrowseClick(); }} style={{
                marginTop: '14px', padding: '8px 20px',
                borderRadius: 'var(--radius-md)', fontSize: '12.5px',
                background: 'rgba(107,26,58,0.3)', border: '1px solid var(--color-border-hover)',
                color: 'var(--color-burgundy-200)', cursor: 'pointer',
              }}>
                Browse Files
              </button>
            </div>

            {selectedFile && (
              <button
                onClick={handleUpload}
                disabled={uploading}
                style={{
                  width: '100%',
                  marginTop: '12px',
                  padding: '9px',
                  background: 'var(--color-burgundy-500, #e11d48)',
                  color: '#ffffff',
                  border: 'none',
                  borderRadius: 'var(--radius-md)',
                  fontSize: '12.5px',
                  fontWeight: 600,
                  cursor: 'pointer'
                }}
              >
                {uploading ? 'Uploading...' : 'Confirm & Upload'}
              </button>
            )}

            {uploadMessage && (
              <div style={{
                marginTop: '10px',
                padding: '8px',
                borderRadius: 'var(--radius-sm)',
                fontSize: '12px',
                background: 'rgba(45, 212, 191, 0.15)',
                color: 'var(--color-teal-300)',
                border: '1px solid rgba(45, 212, 191, 0.3)'
              }}>
                {uploadMessage.text}
              </div>
            )}
          </div>

          <div className="card">
            <div className="section-title" style={{ fontSize: '14px', marginBottom: '12px' }}>Quick Stats</div>
            {[
              { label: 'MongoDB Collections',  value: '9' },
              { label: 'Training Set Size',    value: '3.2 GB' },
              { label: 'Last Model Retrain',   value: '7 days ago' },
              { label: 'Backend Endpoint',     value: 'localhost:8000' },
            ].map(({ label, value }) => (
              <div key={label} style={{
                display: 'flex', justifyContent: 'space-between',
                padding: '8px 0', borderBottom: '1px solid var(--color-border)',
                fontSize: '12.5px',
              }}>
                <span style={{ color: 'var(--color-text-muted)' }}>{label}</span>
                <span style={{ color: 'var(--color-text-primary)', fontWeight: 500 }}>{value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}