import { ImageResponse } from 'next/og'

export const alt = 'Agent Skills Harness — build production-grade agent skills'
export const size = { width: 1200, height: 630 }
export const contentType = 'image/png'

// Generated OG/Twitter card image (Next file convention sets both og:image and twitter:image).
export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          background: '#0a0a0a',
          color: '#ffffff',
          padding: '80px',
          fontFamily: 'sans-serif'
        }}
      >
        <div style={{ display: 'flex', fontSize: 28, letterSpacing: 6, color: '#34d399', textTransform: 'uppercase' }}>
          Agent Skills Harness
        </div>
        <div style={{ display: 'flex', fontSize: 76, fontWeight: 700, lineHeight: 1.05, marginTop: 28, maxWidth: 960 }}>
          Build production-grade agent skills.
        </div>
        <div style={{ display: 'flex', fontSize: 30, color: '#a1a1aa', marginTop: 28, maxWidth: 900 }}>
          Benchmarked, autonomously improved, and verified by an independent multi-agent panel.
        </div>
      </div>
    ),
    { ...size }
  )
}
