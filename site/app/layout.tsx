import { Footer, Layout, Navbar } from 'nextra-theme-docs'
import { Head } from 'nextra/components'
import { getPageMap } from 'nextra/page-map'
import 'nextra-theme-docs/style.css'
import type { Metadata } from 'next'

const REPO = 'https://github.com/a-tokyo/agent-skills-harness'
// Production URL — override on Vercel with NEXT_PUBLIC_SITE_URL once the domain is known.
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://agent-skills-harness.vercel.app'
const DESCRIPTION =
  'A factory for building production-grade agent skills — benchmarked against gold standards, autonomously improved via autoresearch, and verified by multi-agent consensus.'

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: 'Agent Skills Harness',
    template: '%s – Agent Skills Harness'
  },
  description: DESCRIPTION,
  applicationName: 'Agent Skills Harness',
  authors: [{ name: 'Ahmed Tokyo', url: 'https://github.com/a-tokyo' }],
  creator: 'Ahmed Tokyo',
  keywords: [
    'agent skills',
    'SKILL.md',
    'AI agents',
    'autoresearch',
    'skill factory',
    'LLM-as-judge',
    'agent skill harness'
  ],
  openGraph: {
    type: 'website',
    siteName: 'Agent Skills Harness',
    title: 'Agent Skills Harness',
    description: DESCRIPTION,
    url: SITE_URL
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Agent Skills Harness',
    description: DESCRIPTION
  }
}

const navbar = (
  <Navbar
    logo={<b>Agent Skills Harness</b>}
    projectLink={REPO}
  />
)

const footer = (
  <Footer>
    MIT {new Date().getFullYear()} © <a href="https://github.com/a-tokyo">Ahmed Tokyo</a>.
  </Footer>
)

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" dir="ltr" suppressHydrationWarning>
      <Head color={{ hue: 158, saturation: 72 }} />
      <body>
        <Layout
          navbar={navbar}
          footer={footer}
          pageMap={await getPageMap()}
          docsRepositoryBase={`${REPO}/tree/main/site`}
        >
          {children}
        </Layout>
      </body>
    </html>
  )
}
